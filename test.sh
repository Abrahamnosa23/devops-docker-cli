#!/usr/bin/env bash
# test.sh - tests for the diagnostic-tool Docker image
set -u
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

IMAGE="diagnostic-tool-test"
PASS=0; FAIL=0

command -v docker >/dev/null 2>&1 || { echo "ERROR: docker is required"; exit 2; }
trap 'docker image rm -f "$IMAGE" >/dev/null 2>&1 || true' EXIT

echo "Building image..."
docker build -q -t "$IMAGE" . >/dev/null || { echo "FAIL: image build"; exit 1; }

# run_test <name> <expected-exit> <expected-output-regex|-> <args...>
run_test() {
  local name="$1" want_rc="$2" want_out="$3"; shift 3
  local out rc
  out="$(docker run --rm "$IMAGE" "$@" 2>&1)"; rc=$?
  if [[ $rc -ne $want_rc ]]; then
    echo "FAIL: $name (exit $rc, expected $want_rc)"; echo "$out" | sed 's/^/    /'; FAIL=$((FAIL+1)); return
  fi
  if [[ "$want_out" != "-" ]] && ! grep -Eqi "$want_out" <<<"$out"; then
    echo "FAIL: $name (output missing /$want_out/)"; FAIL=$((FAIL+1)); return
  fi
  echo "PASS: $name"; PASS=$((PASS+1))
}

run_test "help exits 0 and shows usage"          0 "usage"            help
run_test "default (no args) prints help"         0 "usage"
run_test "system exits 0 and shows kernel"       0 "kernel"           system
run_test "disk exits 0 and shows filesystem"     0 "filesystem|size"  disk
run_test "network localhost succeeds"            0 "resolved"         network localhost
run_test "network without host returns 2"        2 "requires"         network
run_test "network with invalid host returns 2"   2 "invalid"          network 'bad host!'
run_test "network unresolvable host returns 1"   1 "cannot resolve"   network no-such-host.invalid
run_test "invalid command returns 2"             2 "unknown command"  invalid-command
run_test "disk with bad path returns 2"          2 "does not exist"   disk /no/such/path

echo
echo "Passed: $PASS  Failed: $FAIL"
[[ $FAIL -eq 0 ]]
