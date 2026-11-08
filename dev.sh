#!/usr/bin/env bash
# Start the PitchPulse local development environment:
#   PostgreSQL (Docker Compose) -> Spring Boot backend -> Angular dev server.
# Re-running is safe: components that are already running are reused, not duplicated.
#
# Usage: bash ./dev.sh [--follow]
#   --follow   stay attached and stream logs; Ctrl+C then stops everything.
# Stop with: bash ./stop-dev.sh
set -uo pipefail

PP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/dev-lib.sh
source "$PP_ROOT/scripts/dev-lib.sh"

FOLLOW=0
for arg in "$@"; do
  case $arg in
    --follow | -f) FOLLOW=1 ;;
    -h | --help)
      sed -n '2,8p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      pp_error "Unknown option: $arg (see: bash ./dev.sh --help)"
      exit 2
      ;;
  esac
done

BACKEND_URL="http://$PP_HOST:$PP_BACKEND_PORT"
FRONTEND_URL="http://$PP_HOST:$PP_FRONTEND_PORT"
BACKEND_LOG="$PP_LOG_DIR/backend.log"
BUILD_LOG="$PP_LOG_DIR/backend-build.log"
FRONTEND_LOG="$PP_LOG_DIR/frontend.log"
INSTALL_LOG="$PP_LOG_DIR/frontend-install.log"
LOCK_DIR="$PP_STATE_DIR/dev.lock"
STARTED=()
DB_WAS_RUNNING=1
STARTUP_DONE=0

rel() { printf '%s' "${1#"$PP_ROOT"/}"; }

show_log_tail() {
  [[ -s $1 ]] || return 0
  printf '[pitchpulse] ---- last lines of %s ----\n' "$(rel "$1")" >&2
  tail -n "${2:-30}" "$1" | sed 's/\x1b\[[0-9;]*m//g' >&2
  printf '[pitchpulse] ----\n' >&2
}

release_lock() { rm -rf "$LOCK_DIR" 2>/dev/null || true; }

# Undo only what this run started. Database data is never deleted.
rollback() {
  local i
  for ((i = ${#STARTED[@]} - 1; i >= 0; i--)); do
    case ${STARTED[i]} in
      frontend) pp_stop_component frontend "Angular dev server" ;;
      backend) pp_stop_component backend "Spring Boot backend" ;;
    esac
  done
  if [[ $DB_WAS_RUNNING -eq 0 ]]; then
    pp_compose stop >/dev/null 2>&1 && pp_info "PostgreSQL stopped (data volume preserved)."
  fi
}

fail() {
  pp_error "$*"
  if [[ $STARTUP_DONE -eq 0 ]] && ((${#STARTED[@]} > 0 || DB_WAS_RUNNING == 0)); then
    pp_info "Rolling back components started by this run..."
    rollback
  fi
  release_lock
  exit 1
}

on_interrupt() {
  trap - INT TERM
  printf '\n'
  if [[ $STARTUP_DONE -eq 0 ]]; then
    pp_warn "Interrupted during startup."
    pp_info "Rolling back components started by this run..."
    rollback
    release_lock
  else
    pp_info "Ctrl+C received; stopping the environment..."
    bash "$PP_ROOT/stop-dev.sh"
  fi
  exit 130
}
trap on_interrupt INT TERM

# --------------------------------------------------------------------------- lock
mkdir -p "$PP_STATE_DIR" "$PP_LOG_DIR"
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  other=$(cat "$LOCK_DIR/pid" 2>/dev/null || true)
  if [[ $other =~ ^[0-9]+$ ]] && kill -0 "$other" 2>/dev/null; then
    pp_error "Another dev.sh (pid $other) is already starting PitchPulse. Wait for it to finish."
    exit 1
  fi
  rm -rf "$LOCK_DIR"
  mkdir "$LOCK_DIR" || { pp_error "Cannot create $(rel "$LOCK_DIR")."; exit 1; }
fi
echo $$ >"$LOCK_DIR/pid"

# ----------------------------------------------------------------------- preflight
pp_info "Checking prerequisites..."

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "'$1' was not found on PATH. $2"
}
need_cmd curl "Install curl (bundled with Git for Windows)."
if pp_is_windows; then
  need_cmd powershell.exe "It is required on Windows to track process trees."
  need_cmd iconv "Use Git Bash from Git for Windows."
  need_cmd cygpath "Use Git Bash from Git for Windows."
fi

need_cmd docker "Install Docker Desktop (or Docker Engine with Compose v2)."
docker compose version >/dev/null 2>&1 || fail "Docker Compose v2 is unavailable ('docker compose version' failed). Update Docker Desktop/Engine."
docker info >/dev/null 2>&1 || fail "The Docker engine is not reachable. Start Docker Desktop, wait until it reports 'running', then rerun."

# JDK 21 for the Maven Wrapper and the backend. Search order: PITCHPULSE_JAVA_HOME,
# JAVA_HOME, standard install folders (e.g. C:\Program Files\Eclipse Adoptium\jdk-21*),
# then java on PATH. Only this script's process tree sees the result; global
# JAVA_HOME/PATH (for example a system default of Java 17) stay unchanged.
if ! pp_find_jdk21; then
  [[ -n $PP_JDK_REJECTED ]] && printf '[pitchpulse] Rejected Java installations:\n%s\n' "${PP_JDK_REJECTED%$'\n'}" >&2
  [[ -n ${PITCHPULSE_JAVA_HOME:-} ]] && fail "PITCHPULSE_JAVA_HOME must point to a JDK 21 folder (containing bin/java and bin/javac 21), or unset it to search automatically."
  fail "No JDK 21 (java and javac 21) was found. Install Temurin 21 from https://adoptium.net (default folder: C:\\Program Files\\Eclipse Adoptium), or point this script to one with:  PITCHPULSE_JAVA_HOME=\"/path/to/jdk-21\" bash ./dev.sh"
fi
java_version=$("$PP_JDK_HOME/bin/java" -version 2>&1 | awk -F'"' '/version/ { print $2; exit }')
javac_version=$("$PP_JDK_HOME/bin/javac" -version 2>&1 | tr -d '\r' | awk '/^javac / { print $2; exit }')
JAVA_BIN="$PP_JDK_HOME/bin/java"
if pp_is_windows; then
  JAVA_HOME=$(cygpath -w "$PP_JDK_HOME") # mvnw.cmd expects a Windows path
else
  JAVA_HOME=$PP_JDK_HOME
fi
export JAVA_HOME
export PATH="$PP_JDK_HOME/bin:$PATH"
pp_info "  JDK 21: $JAVA_HOME (java $java_version, javac $javac_version; this session only)"

need_cmd node "Install Node.js 24 LTS (or 20.19+/22.12+)."
need_cmd npm "npm ships with Node.js; reinstall Node.js."
node_version=$(node --version 2>/dev/null | sed 's/^v//')
IFS=. read -r node_major node_minor _ <<<"$node_version"
case $node_major in
  20) ((node_minor >= 19)) || fail "Node.js $node_version is too old for Angular 21; use 20.19+, 22.12+ or 24 LTS." ;;
  22) ((node_minor >= 12)) || fail "Node.js $node_version is too old for Angular 21; use 22.12+ or 24 LTS." ;;
  24) ;;
  *) fail "Node.js $node_version is not supported by client/package.json engines (^20.19 || ^22.12 || ^24). Install Node.js 24 LTS." ;;
esac
npm_version=$(npm --version 2>/dev/null) || fail "npm is not working ('npm --version' failed)."

if pp_is_windows; then
  MVNW=(./mvnw.cmd)
  [[ -f $PP_ROOT/server/mvnw.cmd ]] || fail "server/mvnw.cmd is missing."
else
  MVNW=(bash ./mvnw)
  [[ -f $PP_ROOT/server/mvnw ]] || fail "server/mvnw is missing."
fi
pp_info "  Docker $(docker version --format '{{.Server.Version}}' 2>/dev/null), Compose $(docker compose version --short 2>/dev/null), Node $node_version, npm $npm_version"

# ----------------------------------------------------------------------- .env
ENV_FILE="$PP_ROOT/.env"
[[ -f $ENV_FILE ]] || fail "Missing .env. Create it with:  cp .env.example .env  and set DB_PASSWORD to a local-only password."

# Read only the expected keys (the file is never executed). Exported shell
# variables take precedence, matching Docker Compose's own .env behaviour.
env_value() {
  local key=$1 line value=''
  line=$(grep -E "^[[:space:]]*$key=" "$ENV_FILE" | tail -n 1 | tr -d '\r') || true
  [[ -n $line ]] || return 0
  value=${line#*=}
  if [[ $value =~ ^\"(.*)\"$ || $value =~ ^\'(.*)\'$ ]]; then value=${BASH_REMATCH[1]}; fi
  printf '%s' "$value"
}
DB_NAME=${DB_NAME:-$(env_value DB_NAME)}
DB_USERNAME=${DB_USERNAME:-$(env_value DB_USERNAME)}
DB_PASSWORD=${DB_PASSWORD:-$(env_value DB_PASSWORD)}
DB_PORT=${DB_PORT:-$(env_value DB_PORT)}
DB_NAME=${DB_NAME:-pitchpulse}
DB_USERNAME=${DB_USERNAME:-pitchpulse}
DB_PORT=${DB_PORT:-5432}
[[ -n $DB_PASSWORD ]] || fail "DB_PASSWORD is empty. Set it in .env (see .env.example)."
[[ $DB_PASSWORD != replace-with-a-local-development-password ]] || fail "DB_PASSWORD in .env is still the .env.example placeholder. Choose a local-only password."
[[ $DB_PORT =~ ^[0-9]+$ ]] || fail "DB_PORT in .env must be a number (found '$DB_PORT')."
export DB_NAME DB_USERNAME DB_PASSWORD DB_PORT
DB_URL=${DB_URL:-jdbc:postgresql://localhost:$DB_PORT/$DB_NAME}

# --------------------------------------------------------------- current state
backend_status=$(pp_component_status backend)
frontend_status=$(pp_component_status frontend)
for component in backend frontend; do
  status_var="${component}_status"
  if [[ ${!status_var} == orphaned ]]; then
    pp_warn "Leftover $component processes from an earlier run were found; cleaning them up."
    pp_stop_component "$component" "Leftover $component processes" || fail "Could not clean up leftover $component processes."
    printf -v "$status_var" stopped
  fi
done

# ------------------------------------------------------------------ PostgreSQL
if [[ -z $(pp_compose ps --status running --quiet postgres 2>/dev/null) ]]; then
  DB_WAS_RUNNING=0
fi
pp_info "Starting PostgreSQL (docker compose service 'postgres', 127.0.0.1:$DB_PORT) and waiting for health..."
if ! compose_out=$(pp_compose up --detach --wait --wait-timeout 90 postgres 2>&1); then
  printf '%s\n' "$compose_out" | tail -n 15 >&2
  owner=$(pp_port_owner "$DB_PORT")
  hint="Inspect with: docker compose logs postgres"
  [[ -n $owner && $DB_WAS_RUNNING -eq 0 ]] && hint="Port $DB_PORT is used by $owner. Stop it, or set another DB_PORT in .env."
  fail "PostgreSQL did not become healthy. $hint"
fi
if ! pp_compose exec -T postgres pg_isready -q -U "$DB_USERNAME" -d "$DB_NAME" >/dev/null 2>&1; then
  fail "PostgreSQL is running but database '$DB_NAME' is not accepting connections for user '$DB_USERNAME'. Inspect with: docker compose logs postgres"
fi
[[ $DB_WAS_RUNNING -eq 1 ]] && pp_info "PostgreSQL was already running; reusing it." || pp_info "PostgreSQL is healthy."

# --------------------------------------------------------------------- backend
backend_healthy() {
  curl --silent --fail --max-time 3 "$BACKEND_URL$PP_HEALTH_PATH" 2>/dev/null | grep -q '"status":"UP"'
}

if [[ $backend_status == running ]]; then
  backend_healthy || fail "A PitchPulse backend started by dev.sh is running but not healthy. See $(rel "$BACKEND_LOG"), or restart with: bash ./stop-dev.sh && bash ./dev.sh"
  pp_info "Spring Boot backend is already running (started earlier by dev.sh); reusing it."
else
  owner=$(pp_port_owner "$PP_BACKEND_PORT")
  [[ -z $owner ]] || fail "Port $PP_BACKEND_PORT is already used by $owner, which dev.sh did not start (for example a manual 'mvnw spring-boot:run' or 'java -jar'). Stop that process yourself, then rerun. dev.sh never kills processes it did not start."

  pp_info "Building backend with the Maven Wrapper (${MVNW[*]}); log: $(rel "$BUILD_LOG")"
  pp_info "  The first build downloads Maven and dependencies and can take a few minutes."
  if ! (cd "$PP_ROOT/server" && "${MVNW[@]}" --batch-mode --no-transfer-progress -DskipTests package) >"$BUILD_LOG" 2>&1 </dev/null; then
    show_log_tail "$BUILD_LOG" 40
    fail "Backend build failed. Fix the error above (full log: $(rel "$BUILD_LOG"))."
  fi
  jar=$(find "$PP_ROOT/server/target" -maxdepth 1 -name '*.jar' ! -name '*.original' -print -quit 2>/dev/null)
  [[ -n $jar ]] || fail "The build finished but no executable JAR was found in server/target/."
  # Run a copy so server/target stays writable for 'mvnw verify' while dev.sh runs (Windows locks open JARs).
  run_jar="$PP_STATE_DIR/pitchpulse-server.jar"
  cp -f "$jar" "$run_jar" || fail "Could not copy the backend JAR to $(rel "$run_jar")."
  # Relative, ASCII-only argument: the Windows Java launcher reads arguments in the ANSI
  # code page, which mangles non-ASCII checkout paths (for example Greek folder names).
  jar_arg=${run_jar#"$PP_ROOT"/}

  [[ -f $BACKEND_LOG ]] && mv -f "$BACKEND_LOG" "$PP_LOG_DIR/backend.previous.log"
  pp_info "Starting Spring Boot backend on $BACKEND_URL; log: $(rel "$BACKEND_LOG")"
  pp_is_windows || set -m # own process group on Linux/macOS
  (cd "$PP_ROOT" && DB_URL=$DB_URL SERVER_ADDRESS=$PP_HOST SERVER_PORT=$PP_BACKEND_PORT \
    exec nohup "$JAVA_BIN" -jar "$jar_arg") >"$BACKEND_LOG" 2>&1 </dev/null &
  backend_pid=$!
  pp_is_windows || set +m
  pp_record backend "$backend_pid"
  STARTED+=(backend)

  pp_info "Waiting for backend readiness at $BACKEND_URL$PP_HEALTH_PATH ..."
  for ((i = 0; i < 120; i++)); do
    backend_healthy && break
    if ! kill -0 "$backend_pid" 2>/dev/null; then
      show_log_tail "$BACKEND_LOG" 40
      fail "The backend exited during startup. Common causes: DB_PASSWORD in .env differs from the one the existing database volume was created with, a failed Flyway migration, or a busy port. Full log: $(rel "$BACKEND_LOG")"
    fi
    sleep 1
  done
  backend_healthy || { show_log_tail "$BACKEND_LOG" 40; fail "The backend did not report UP within 120 s. Full log: $(rel "$BACKEND_LOG")"; }
  pp_info "Backend is UP (database connectivity confirmed by the health endpoint)."
fi

# -------------------------------------------------------------------- frontend
frontend_ready() { curl --silent --fail --output /dev/null --max-time 3 "$FRONTEND_URL/" 2>/dev/null; }

if [[ $frontend_status == running ]]; then
  pp_info "Angular dev server is already running (started earlier by dev.sh); reusing it."
else
  if [[ ! -d $PP_ROOT/client/node_modules ]]; then
    pp_info "Installing frontend dependencies with 'npm ci' (first run); log: $(rel "$INSTALL_LOG")"
    if ! (cd "$PP_ROOT/client" && npm ci --no-audit --no-fund) >"$INSTALL_LOG" 2>&1 </dev/null; then
      show_log_tail "$INSTALL_LOG" 30
      fail "'npm ci' failed in client/. Full log: $(rel "$INSTALL_LOG")"
    fi
  elif [[ $PP_ROOT/client/package-lock.json -nt $PP_ROOT/client/node_modules/.package-lock.json ]]; then
    pp_warn "client/package-lock.json is newer than the installed dependencies. If the frontend fails, run: (cd client && npm ci)"
  fi

  owner=$(pp_port_owner "$PP_FRONTEND_PORT")
  [[ -z $owner ]] || fail "Port $PP_FRONTEND_PORT is already used by $owner, which dev.sh did not start (for example a manual 'npm start' or a Playwright run). Stop it yourself, then rerun."

  [[ -f $FRONTEND_LOG ]] && mv -f "$FRONTEND_LOG" "$PP_LOG_DIR/frontend.previous.log"
  pp_info "Starting Angular dev server ('npm start') on $FRONTEND_URL; log: $(rel "$FRONTEND_LOG")"
  pp_is_windows || set -m
  (cd "$PP_ROOT/client" && NG_CLI_ANALYTICS=false exec nohup npm start -- --port "$PP_FRONTEND_PORT") \
    >"$FRONTEND_LOG" 2>&1 </dev/null &
  frontend_pid=$!
  pp_is_windows || set +m
  pp_record frontend "$frontend_pid"
  STARTED+=(frontend)

  pp_info "Waiting for the Angular dev server to compile and listen..."
  for ((i = 0; i < 180; i++)); do
    frontend_ready && break
    if ! kill -0 "$frontend_pid" 2>/dev/null; then
      show_log_tail "$FRONTEND_LOG" 30
      fail "The Angular dev server exited during startup. If dependencies are broken, run: (cd client && npm ci). Full log: $(rel "$FRONTEND_LOG")"
    fi
    sleep 1
  done
  frontend_ready || { show_log_tail "$FRONTEND_LOG" 30; fail "The Angular dev server did not respond within 180 s. Full log: $(rel "$FRONTEND_LOG")"; }
fi

# The address Angular actually printed, when available.
actual_url=$(sed 's/\x1b\[[0-9;]*m//g' "$FRONTEND_LOG" 2>/dev/null | grep -oE 'https?://[^ /]+:[0-9]+/?' | head -n 1)
FRONTEND_URL=${actual_url%/}
FRONTEND_URL=${FRONTEND_URL:-http://$PP_HOST:$PP_FRONTEND_PORT}

if ! curl --silent --fail --max-time 5 "$FRONTEND_URL$PP_HEALTH_PATH" 2>/dev/null | grep -q '"status":"UP"'; then
  fail "The frontend is up but its /api proxy cannot reach the backend. Check client/proxy.conf.json targets $BACKEND_URL."
fi

STARTUP_DONE=1
release_lock
cat <<EOF

[pitchpulse] PitchPulse is running.
  Frontend     $FRONTEND_URL/
  Backend API  $BACKEND_URL$PP_HEALTH_PATH  (also proxied at $FRONTEND_URL$PP_HEALTH_PATH)
  PostgreSQL   127.0.0.1:$DB_PORT, database '$DB_NAME' (Compose service 'postgres'; data kept in a named volume)
  Logs         $(rel "$BACKEND_LOG"), $(rel "$FRONTEND_LOG"), $(rel "$BUILD_LOG")
               database: docker compose logs -f postgres
  Stop         bash ./stop-dev.sh
EOF

if [[ $FOLLOW -eq 1 ]]; then
  pp_info "Following logs. Press Ctrl+C to stop PitchPulse."
  tail -n 0 -F "$BACKEND_LOG" "$FRONTEND_LOG" &
  tail_pid=$!
  trap 'kill "$tail_pid" 2>/dev/null; on_interrupt' INT TERM
  wait "$tail_pid"
fi
exit 0
