#!/usr/bin/env bash
# Stop the PitchPulse local development environment started by ./dev.sh.
# Stops only processes recorded by dev.sh (plus their children) and the project's
# Docker Compose services. Database volumes are never removed. Safe to run repeatedly.
#
# Usage: bash ./stop-dev.sh [--keep-db]
set -uo pipefail

PP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/dev-lib.sh
source "$PP_ROOT/scripts/dev-lib.sh"

KEEP_DB=0
for arg in "$@"; do
  case $arg in
    --keep-db) KEEP_DB=1 ;;
    -h | --help)
      sed -n '2,7p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      pp_error "Unknown option: $arg (see: bash ./stop-dev.sh --help)"
      exit 2
      ;;
  esac
done

if pp_is_windows && ! command -v powershell.exe >/dev/null 2>&1; then
  pp_error "powershell.exe is not on PATH; it is needed to inspect recorded Windows processes."
  exit 1
fi

pp_info "Stopping PitchPulse local development environment..."
rc=0
pp_stop_component frontend "Angular dev server" || rc=1
pp_stop_component backend "Spring Boot backend" || rc=1

if [[ $KEEP_DB -eq 1 ]]; then
  pp_info "PostgreSQL: left running (--keep-db)."
elif ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
  pp_warn "Docker is not reachable; PostgreSQL was not stopped. Start Docker and rerun this script if the container is still running."
  rc=1
elif [[ -z $(pp_compose ps --status running --quiet 2>/dev/null) ]]; then
  pp_info "PostgreSQL: not running."
elif pp_compose stop; then
  pp_info "PostgreSQL stopped. The data volume is preserved."
else
  pp_error "docker compose stop failed. Inspect with: docker compose ps"
  rc=1
fi

rm -f "$PP_STATE_DIR/frontend.url" 2>/dev/null || true
if [[ $rc -eq 0 ]]; then
  pp_info "PitchPulse is stopped. Logs remain in ${PP_LOG_DIR#"$PP_ROOT"/}/."
else
  pp_error "Shutdown finished with problems (see messages above)."
fi
exit "$rc"
