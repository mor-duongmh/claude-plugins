#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helper.sh"

VERIFY="$SCRIPT_DIR/../verify-vendor.sh"

# Assumes Task 8 already populated manifest with version + sha
output="$("$VERIFY" 2>&1)"
assert_contains "$output" "OK" "verify reports OK"
assert_contains "$output" "$(jq -r .version "$SCRIPT_DIR/../../.vendor-manifest.json")" "verify shows version"

echo "PASS: test-verify-vendor"
