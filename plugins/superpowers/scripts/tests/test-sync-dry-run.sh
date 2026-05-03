#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helper.sh"

SYNC="$SCRIPT_DIR/../sync-superpowers.sh"
PLUGIN_ROOT="$SCRIPT_DIR/../.."

# Snapshot manifest contents before running
manifest_before="$(cat "$PLUGIN_ROOT/.vendor-manifest.json")"

# Run dry-run with explicit version
output="$("$SYNC" --dry-run 5.0.7 2>&1)"

assert_contains "$output" "DRY RUN" "dry-run banner"
assert_contains "$output" "5.0.7" "target version shown"
assert_contains "$output" "would download" "download action listed"
assert_contains "$output" "would extract" "extract action listed"

# Manifest must be unchanged
manifest_after="$(cat "$PLUGIN_ROOT/.vendor-manifest.json")"
assert_equal "$manifest_after" "$manifest_before" "manifest unchanged after dry-run"

echo "PASS: test-sync-dry-run"
