#!/usr/bin/env bash
# diagnostic - Dockerized Linux diagnostic CLI
# Exit codes: 0 success, 1 operational failure, 2 invalid command/input
set -u

EX_OK=0; EX_FAIL=1; EX_USAGE=2

usage() {
  cat <<'USAGE'
diagnostic - Linux diagnostic tool

Usage:
  diagnostic system            Show system information
  diagnostic network <host>    Check a hostname or IP address
  diagnostic disk [path]       Show disk information (default: /)
  diagnostic help              Show this help

Exit codes:
  0 success | 1 operational failure | 2 invalid command or input
USAGE
}

err() { echo "ERROR: $*" >&2; }

valid_host() {
  local h="$1" o
  [[ -n "$h" && ${#h} -le 253 ]] || return 1
  if [[ "$h" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
    local IFS=.
    for o in $h; do (( 10#$o <= 255 )) || return 1; done
    return 0
  fi
  if [[ "$h" == *:* ]]; then [[ "$h" =~ ^[0-9A-Fa-f:.]+$ ]]; return; fi
  [[ "$h" =~ ^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*$ ]]
}

cmd_system() {
  local os cpu
  os="$( [[ -r /etc/os-release ]] && ( . /etc/os-release; echo "${PRETTY_NAME:-unknown}" ) || uname -s )"
  cpu="$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2- | sed 's/^ *//')"
  echo "=== System Information ==="
  echo "Hostname         : $(hostname 2>/dev/null || uname -n)"
  echo "Current user     : $(id -un 2>/dev/null || echo unknown)"
  echo "Date/Time        : $(date '+%Y-%m-%d %H:%M:%S %Z')"
  echo "Operating system : $os"
  echo "Kernel           : $(uname -r)"
  echo "Architecture     : $(uname -m)"
  echo "Uptime           : $(uptime 2>/dev/null | sed 's/^ *//')"
  echo "CPU              : ${cpu:-unknown} ($(nproc 2>/dev/null || echo '?') core(s))"
  if command -v free >/dev/null 2>&1; then
    echo "Memory           : $(free -m | awk '/^Mem:/ {print "total " $2 " MB, used " $3 " MB, free " $4 " MB"}')"
  elif [[ -r /proc/meminfo ]]; then
    echo "Memory           : $(awk '/MemTotal/ {print int($2/1024) " MB total"}' /proc/meminfo)"
  fi
  return $EX_OK
}

cmd_network() {
  if [[ $# -lt 1 ]]; then err "network requires a <host> argument"; usage >&2; return $EX_USAGE; fi
  if [[ $# -gt 1 ]]; then err "network accepts exactly one <host> argument"; return $EX_USAGE; fi
  local host="$1" resolved
  valid_host "$host" || { err "invalid hostname or IP address: '$host'"; return $EX_USAGE; }
  echo "=== Network check: $host ==="
  resolved="$(getent ahosts "$host" 2>/dev/null | awk 'NR==1 {print $1}')"
  if [[ -z "$resolved" ]]; then
    err "cannot resolve '$host'"
    return $EX_FAIL
  fi
  echo "Resolved to : $resolved"
  if command -v ping >/dev/null 2>&1; then
    if ping -c 1 -W 2 "$host" >/dev/null 2>&1; then echo "Ping        : OK"
    else echo "Ping        : no reply (ICMP may be blocked)"; fi
  fi
  return $EX_OK
}

cmd_disk() {
  local path="${1:-/}"
  if [[ $# -gt 1 ]]; then err "disk accepts at most one [path] argument"; return $EX_USAGE; fi
  if [[ ! -e "$path" ]]; then err "path does not exist: $path"; return $EX_USAGE; fi
  echo "=== Disk Information ($path) ==="
  df -h "$path" || return $EX_FAIL
  return $EX_OK
}

main() {
  local cmd="${1:-}"
  case "$cmd" in
    system)           shift; [[ $# -eq 0 ]] || { err "system takes no arguments"; return $EX_USAGE; }; cmd_system ;;
    network)          shift; cmd_network "$@" ;;
    disk)             shift; cmd_disk "$@" ;;
    help|-h|--help)   usage; return $EX_OK ;;
    "")               err "no command given"; usage >&2; return $EX_USAGE ;;
    *)                err "unknown command: '$cmd'"; usage >&2; return $EX_USAGE ;;
  esac
}

main "$@"
exit $?
