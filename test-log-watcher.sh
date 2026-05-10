#!/usr/bin/env bash
# test-log-watcher.sh — integration tests for log-watcher.sh
set -uo pipefail

SCRIPT="./log-watcher.sh"
PASS=0
FAIL=0

pass() { echo "  [PASS] $1"; (( PASS++ )) || true; }
fail() { echo "  [FAIL] $1"; (( FAIL++ )) || true; }

assert_exit() {
    local desc="$1" expected="$2"; shift 2
    local actual=0
    "$@" >/dev/null 2>&1 || actual=$?
    if [[ "$actual" == "$expected" ]]; then
        pass "$desc"
    else
        fail "$desc (got $actual, want $expected)"
    fi
}

TMPLOG=$(mktemp)
trap 'rm -f "$TMPLOG"' EXIT

echo "Running log-watcher tests..."
echo ""

echo "[1] No arguments"
assert_exit "exits 1 with no args" 1 bash "$SCRIPT"

echo "[2] File not found"
assert_exit "exits 1 for missing file" 1 bash "$SCRIPT" /tmp/no-such-file-xyz.log

echo "[3] Invalid -n value"
assert_exit "exits 1 for -n abc" 1 bash "$SCRIPT" -n abc "$TMPLOG"

echo "[4] Missing argument to -p"
assert_exit "exits 1 for bare -p flag" 1 bash "$SCRIPT" -p

echo "[5] Unknown flag"
assert_exit "exits 1 for unknown flag" 1 bash "$SCRIPT" -z "$TMPLOG"

echo "[6] Help flag"
rc=0; bash "$SCRIPT" -h >/dev/null 2>&1 || rc=$?
if [[ "$rc" == "0" ]]; then pass "exits 0 for -h"; else fail "exits 0 for -h (got $rc)"; fi
out=$(bash "$SCRIPT" -h 2>&1 || true)
if [[ "$out" =~ Usage ]]; then pass "-h prints usage"; else fail "-h prints usage"; fi

echo "[7] Pattern match — stdout"
echo "ERROR: something broke" > "$TMPLOG"
out=$(timeout 1s bash "$SCRIPT" -n 1 "$TMPLOG" 2>/dev/null || true)
if [[ "$out" =~ MATCH ]]; then pass "match line printed to stdout"
else fail "match line printed to stdout (got: '$out')"; fi

echo "[8] No match — no MATCH output"
echo "INFO: all good" > "$TMPLOG"
out=$(timeout 1s bash "$SCRIPT" -n 1 -p "ERROR" "$TMPLOG" 2>/dev/null || true)
if [[ ! "$out" =~ MATCH ]]; then
    pass "no MATCH output for non-matching line"
else
    fail "no MATCH output for non-matching line (got: '$out')"
fi

echo "[9] Quiet mode — no stdout"
echo "ERROR: quiet test" > "$TMPLOG"
out=$(timeout 1s bash "$SCRIPT" -q -n 1 "$TMPLOG" 2>/dev/null || true)
if [[ -z "$out" ]]; then pass "quiet mode suppresses stdout"
else fail "quiet mode suppresses stdout (got: '$out')"; fi

echo "[10] -n includes initial matching lines"
printf 'line1\nERROR: line2\nline3\n' > "$TMPLOG"
out=$(timeout 1s bash "$SCRIPT" -n 2 -p "ERROR" "$TMPLOG" 2>/dev/null || true)
if [[ "$out" =~ MATCH ]]; then
    pass "-n 2 includes matching initial line"
else
    fail "-n 2 includes matching initial line (got: '$out')"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
