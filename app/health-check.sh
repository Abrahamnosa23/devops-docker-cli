#!/usr/bin/env bash
# health-check.sh - verifies the diagnostic tool is usable (exit 0 = healthy)
set -u
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -x "$DIR/diagnostic.sh" ]] || { echo "UNHEALTHY: diagnostic.sh missing or not executable" >&2; exit 1; }
"$DIR/diagnostic.sh" help >/dev/null 2>&1 || { echo "UNHEALTHY: help command failed" >&2; exit 1; }
echo "HEALTHY"
exit 0
