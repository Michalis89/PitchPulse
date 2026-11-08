# shellcheck shell=bash
# Shared helpers for ./dev.sh and ./stop-dev.sh. Source this file; do not execute it.
#
# Process model: every long-running PitchPulse process is started by dev.sh, and its
# identity (root PID + OS creation time) is recorded under tmp/dev/. Stopping walks the
# recorded process tree only: no process-name or port-based killing. A recorded PID that
# now belongs to a different (newer) process is never touched.

PP_ROOT=${PP_ROOT:?PP_ROOT must be set before sourcing scripts/dev-lib.sh}
PP_STATE_DIR="$PP_ROOT/tmp/dev"
PP_LOG_DIR="$PP_ROOT/logs/dev"
PP_HOST=127.0.0.1
PP_BACKEND_PORT=8080   # must match the target in client/proxy.conf.json
PP_FRONTEND_PORT=4200  # Angular dev-server default
PP_HEALTH_PATH=/api/v1/health

pp_info() { printf '[pitchpulse] %s\n' "$*"; }
pp_warn() { printf '[pitchpulse] WARNING: %s\n' "$*" >&2; }
pp_error() { printf '[pitchpulse] ERROR: %s\n' "$*" >&2; }

pp_is_windows() {
  case "$(uname -s)" in
    MINGW* | MSYS* | CYGWIN*) return 0 ;;
    *) return 1 ;;
  esac
}

# ---------------------------------------------------------------------------
# JDK 21 discovery. Nothing global is changed: the caller exports JAVA_HOME/PATH
# for its own process tree only.
# ---------------------------------------------------------------------------

PP_REQUIRED_JAVA=21

# Prints the major version reported by <home>/bin/<tool> (java or javac), or nothing.
pp_jdk_tool_major() {
  local home=$1 tool=$2 out version major
  [[ -x $home/bin/$tool || -x $home/bin/$tool.exe ]] || return 0
  out=$("$home/bin/$tool" -version 2>&1 | tr -d '\r') || return 0
  if [[ $tool == java ]]; then
    version=$(awk -F'"' '/version/ { print $2; exit }' <<<"$out")
  else
    version=$(awk '/^javac / { print $2; exit }' <<<"$out")
  fi
  major=${version%%.*}
  [[ $major == 1 ]] && major=$(cut -d. -f2 <<<"$version")
  printf '%s' "$major"
}

# Succeeds if <home> is a full JDK 21 (java AND javac report 21). Prints a reason otherwise.
pp_is_jdk21() {
  local home=$1 jv cv
  jv=$(pp_jdk_tool_major "$home" java)
  cv=$(pp_jdk_tool_major "$home" javac)
  if [[ $jv == "$PP_REQUIRED_JAVA" && $cv == "$PP_REQUIRED_JAVA" ]]; then return 0; fi
  if [[ -z $jv ]]; then echo "no working bin/java"
  elif [[ -z $cv ]]; then echo "java $jv but no javac (a JRE, not a JDK)"
  else echo "java $jv, javac $cv"
  fi
  return 1
}

# Candidate JDK homes in priority order, one per line (Unix-style paths).
pp_jdk_candidates() {
  local to_unix=(printf '%s')
  pp_is_windows && to_unix=(cygpath -u)
  [[ -n ${PITCHPULSE_JAVA_HOME:-} ]] && "${to_unix[@]}" "$PITCHPULSE_JAVA_HOME" && echo
  [[ -n ${JAVA_HOME:-} ]] && "${to_unix[@]}" "$JAVA_HOME" && echo
  if pp_is_windows; then
    local pf base
    for pf in "$(cygpath -u "${ProgramW6432:-${PROGRAMFILES:-C:\\Program Files}}")" "/c/Program Files"; do
      for base in "Eclipse Adoptium" "Java" "Microsoft" "Zulu" "Amazon Corretto" "BellSoft"; do
        compgen -G "$pf/$base/*21*" >/dev/null && ls -d "$pf/$base/"*21* | sort -rV
      done
    done
  else
    [[ -x /usr/libexec/java_home ]] && /usr/libexec/java_home -v "$PP_REQUIRED_JAVA" 2>/dev/null
    compgen -G "/usr/lib/jvm/*21*" >/dev/null && ls -d /usr/lib/jvm/*21* | sort -rV
    compgen -G "/Library/Java/JavaVirtualMachines/*21*" >/dev/null &&
      ls -d /Library/Java/JavaVirtualMachines/*21*/Contents/Home | sort -rV
  fi
  local path_java
  path_java=$(command -v java 2>/dev/null) || true
  if [[ -n $path_java ]]; then
    path_java=$(readlink -f "$path_java" 2>/dev/null || printf '%s' "$path_java")
    dirname "$(dirname "$path_java")"
  fi
}

# Sets PP_JDK_HOME to the first JDK 21 found; on failure prints what was rejected
# and returns 1. PITCHPULSE_JAVA_HOME, when set, must be valid (no silent fallback).
pp_find_jdk21() {
  local home reason seen='|'
  PP_JDK_HOME='' PP_JDK_REJECTED=''
  if [[ -n ${PITCHPULSE_JAVA_HOME:-} ]]; then
    home=$PITCHPULSE_JAVA_HOME
    pp_is_windows && home=$(cygpath -u "$home")
    if reason=$(pp_is_jdk21 "$home"); then PP_JDK_HOME=$home; return 0; fi
    PP_JDK_REJECTED="  PITCHPULSE_JAVA_HOME=$PITCHPULSE_JAVA_HOME: $reason"
    return 1
  fi
  while IFS= read -r home; do
    home=${home%/}
    [[ -n $home && $seen != *"|$home|"* ]] || continue
    seen+="$home|"
    if reason=$(pp_is_jdk21 "$home"); then PP_JDK_HOME=$home; return 0; fi
    PP_JDK_REJECTED+="  $home: $reason"$'\n'
  done < <(pp_jdk_candidates)
  return 1
}

# Docker Compose scoped to this repository's compose.yaml and .env.
pp_compose() {
  docker compose --project-directory "$PP_ROOT" -f "$PP_ROOT/compose.yaml" "$@"
}

# ---------------------------------------------------------------------------
# Windows (Git Bash / MSYS2): inspect and stop process trees through PowerShell.
# ---------------------------------------------------------------------------

pp_powershell() {
  local encoded
  encoded=$(printf '%s' "\$ProgressPreference='SilentlyContinue'; $1" | iconv -f UTF-8 -t UTF-16LE | base64 -w 0)
  powershell.exe -NoLogo -NoProfile -NonInteractive -EncodedCommand "$encoded" | tr -d '\r'
}

# Prints the creation time (Windows FILETIME, UTC) of a Windows PID, or nothing.
pp_win_start_time() {
  [[ $1 =~ ^[0-9]+$ ]] || return 0
  pp_powershell "\$p = Get-CimInstance Win32_Process -Filter 'ProcessId=$1'; if (\$p) { \$p.CreationDate.ToFileTimeUtc() }"
}

# pp_win_tree MODE ROOT_PID ROOT_TIME
#   MODE=status -> prints running | orphaned | stopped
#   MODE=kill   -> force-stops the recorded tree, children first, and prints what it stopped
# A child belongs to the tree only if its parent PID matches a tree member and it was
# created after that member. If a PID was reused, the newer occupant and its children
# are excluded, so unrelated processes are never selected.
pp_win_tree() {
  local mode=$1 root=$2 start=$3
  [[ $root =~ ^[0-9]+$ && $start =~ ^[0-9]+$ ]] || { [[ $mode == status ]] && echo stopped; return 0; }
  pp_powershell "
\$mode = '$mode'; \$rootId = [int]$root; \$rootTime = [long]$start
\$all = @(Get-CimInstance Win32_Process | ForEach-Object {
  [pscustomobject]@{ Id = [int]\$_.ProcessId; Parent = [int]\$_.ParentProcessId; Time = \$_.CreationDate.ToFileTimeUtc(); Name = \$_.Name } })
\$byId = @{}; foreach (\$p in \$all) { \$byId[\$p.Id] = \$p }
\$tree = New-Object System.Collections.Generic.List[object]
\$seen = @{}
\$rootAlive = \$false
if (\$byId.ContainsKey(\$rootId) -and \$byId[\$rootId].Time -eq \$rootTime) { \$rootAlive = \$true; \$tree.Add(\$byId[\$rootId]); \$seen[\$rootId] = \$true }
\$queue = New-Object System.Collections.Queue
\$queue.Enqueue(@(\$rootId, \$rootTime))
while (\$queue.Count -gt 0) {
  \$item = \$queue.Dequeue(); \$parentId = \$item[0]; \$parentTime = \$item[1]
  \$occupant = \$byId[\$parentId]
  foreach (\$c in \$all) {
    if (\$c.Parent -ne \$parentId -or \$c.Time -lt \$parentTime -or \$seen.ContainsKey(\$c.Id)) { continue }
    if (\$occupant -and \$occupant.Time -ne \$parentTime -and \$c.Time -ge \$occupant.Time) { continue }
    \$seen[\$c.Id] = \$true; \$tree.Add(\$c); \$queue.Enqueue(@(\$c.Id, \$c.Time))
  }
}
if (\$mode -eq 'status') {
  if (\$rootAlive) { 'running' } elseif (\$tree.Count -gt 0) { 'orphaned' } else { 'stopped' }
  exit 0
}
for (\$i = \$tree.Count - 1; \$i -ge 0; \$i--) {
  \$p = \$tree[\$i]
  try { Stop-Process -Id \$p.Id -Force -ErrorAction Stop; ('stopped {0} (pid {1})' -f \$p.Name, \$p.Id) } catch { if (Get-Process -Id \$p.Id -ErrorAction SilentlyContinue) { ('FAILED to stop {0} (pid {1})' -f \$p.Name, \$p.Id) } }
}
"
}

# ---------------------------------------------------------------------------
# Linux/macOS: each component runs in its own process group (job control).
# ---------------------------------------------------------------------------

pp_posix_start_time() {
  [[ $1 =~ ^[0-9]+$ ]] || return 0
  LC_ALL=C ps -o lstart= -p "$1" 2>/dev/null | tr -s ' ' | sed 's/^ //; s/ $//; s/ /_/g'
}

pp_posix_group_members() {
  pgrep -g "$1" 2>/dev/null || true
}

# pp_posix_tree MODE PGID START (same contract as pp_win_tree). A process group ID
# cannot be reused while any member is alive, so surviving members of a group whose
# leader has exited are still ours; a reused leader PID with another start time is not.
pp_posix_tree() {
  local mode=$1 pgid=$2 start=$3 current members
  [[ $pgid =~ ^[0-9]+$ && -n $start ]] || { [[ $mode == status ]] && echo stopped; return 0; }
  current=$(pp_posix_start_time "$pgid")
  if [[ -n $current && $current != "$start" ]]; then
    [[ $mode == status ]] && echo stopped
    return 0
  fi
  members=$(pp_posix_group_members "$pgid")
  if [[ $mode == status ]]; then
    if [[ -n $current ]]; then echo running; elif [[ -n $members ]]; then echo orphaned; else echo stopped; fi
    return 0
  fi
  [[ -n $members ]] || return 0
  kill -TERM -- "-$pgid" 2>/dev/null || true
  local i
  for i in $(seq 1 20); do
    [[ -z $(pp_posix_group_members "$pgid") ]] && { echo "stopped process group $pgid"; return 0; }
    sleep 0.5
  done
  kill -KILL -- "-$pgid" 2>/dev/null || true
  echo "force-stopped process group $pgid"
}

# ---------------------------------------------------------------------------
# Component state: tmp/dev/<name>.state holds key=value lines (never sourced).
# ---------------------------------------------------------------------------

pp_state_file() { printf '%s/%s.state' "$PP_STATE_DIR" "$1"; }

# pp_record NAME BACKGROUND_PID -> records identity of a process started with '&'.
pp_record() {
  local name=$1 bgpid=$2 root start platform file
  mkdir -p "$PP_STATE_DIR"
  if pp_is_windows; then
    platform=windows
    root=$(cat "/proc/$bgpid/winpid" 2>/dev/null || true)
    start=$(pp_win_start_time "$root")
  else
    platform=posix
    root=$bgpid
    start=$(pp_posix_start_time "$root")
  fi
  file=$(pp_state_file "$name")
  printf 'platform=%s\nroot=%s\nstart=%s\nshell_pid=%s\n' "$platform" "$root" "$start" "$bgpid" >"$file.tmp"
  mv -f "$file.tmp" "$file"
}

# Sets PP_S_PLATFORM, PP_S_ROOT, PP_S_START from a state file; returns 1 if absent.
pp_state_read() {
  local file key value
  file=$(pp_state_file "$1")
  PP_S_PLATFORM='' PP_S_ROOT='' PP_S_START=''
  [[ -f $file ]] || return 1
  while IFS='=' read -r key value; do
    case $key in
      platform) PP_S_PLATFORM=$value ;;
      root) PP_S_ROOT=$value ;;
      start) PP_S_START=$value ;;
    esac
  done <"$file"
  return 0
}

pp_tree() {
  local mode=$1
  case $PP_S_PLATFORM in
    windows) pp_win_tree "$mode" "$PP_S_ROOT" "$PP_S_START" ;;
    posix) pp_posix_tree "$mode" "$PP_S_ROOT" "$PP_S_START" ;;
    *) [[ $mode == status ]] && echo stopped ;;
  esac
}

# Prints running | orphaned | stopped for a component. Removes stale state files.
pp_component_status() {
  local name=$1 status
  if ! pp_state_read "$name"; then
    echo stopped
    return 0
  fi
  status=$(pp_tree status)
  [[ $status == stopped ]] && rm -f "$(pp_state_file "$name")"
  echo "${status:-stopped}"
}

# Stops a recorded component tree. Safe to call repeatedly.
pp_stop_component() {
  local name=$1 label=$2 status output
  status=$(pp_component_status "$name")
  if [[ $status == stopped ]]; then
    pp_info "$label: not running."
    return 0
  fi
  pp_info "Stopping $label ($status)..."
  # pp_component_status ran in a subshell; load the identity into this shell.
  pp_state_read "$name" || return 0
  output=$(pp_tree kill)
  [[ -n $output ]] && printf '%s\n' "$output" | sed 's/^/[pitchpulse]   /'
  if [[ $(pp_tree status) != stopped ]]; then
    pp_error "$label could not be stopped completely. See the process list above."
    return 1
  fi
  rm -f "$(pp_state_file "$name")"
  pp_info "$label stopped."
}

# Prints "<name> (pid N)" for the process listening on a local TCP port, or nothing.
# Read-only: used for actionable messages, never to select processes to stop.
# (Windows loopback filtering can make unused ports time out instead of refusing,
# so the OS listener table is used rather than a connection attempt.)
pp_port_owner() {
  local port=$1 rc=0
  [[ $port =~ ^[0-9]+$ ]] || return 0
  if pp_is_windows; then
    pp_powershell "Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1 | ForEach-Object { \$p = Get-Process -Id \$_.OwningProcess -ErrorAction SilentlyContinue; '{0} (pid {1})' -f \$(if (\$p) { \$p.ProcessName } else { 'unknown' }), \$_.OwningProcess }"
  elif command -v lsof >/dev/null 2>&1; then
    lsof -nP -iTCP:"$port" -sTCP:LISTEN -Fpc 2>/dev/null | awk '/^p/{pid=substr($0,2)} /^c/{print substr($0,2) " (pid " pid ")"; exit}'
  else
    curl --silent --output /dev/null --connect-timeout 2 --max-time 3 "http://$PP_HOST:$port/" || rc=$?
    [[ $rc -eq 7 || $rc -eq 28 ]] || echo "unknown process"
  fi
}
