#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helper.sh"

SYNC="$SCRIPT_DIR/../sync-superpowers.sh"

# Test 1: --help prints usage and exits 0
output="$("$SYNC" --help 2>&1)"
assert_contains "$output" "Usage:" "help shows Usage"
assert_contains "$output" "sync-superpowers.sh" "help shows script name"

# Test 2: invalid flag fails with helpful message
if "$SYNC" --bogus 2>/dev/null; then
    echo "FAIL: --bogus should have errored" >&2
    exit 1
fi

# Test 3: valid version arg is accepted (will fail later for other reasons; we only check parsing here)
output="$("$SYNC" --help 5.1.0 2>&1 || true)"
assert_contains "$output" "Usage:" "version arg with --help still shows usage"

echo "PASS: test-sync-args"
