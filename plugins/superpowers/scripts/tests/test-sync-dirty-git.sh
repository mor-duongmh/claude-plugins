#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helper.sh"

SYNC="$SCRIPT_DIR/../sync-superpowers.sh"
PLUGIN_ROOT="$SCRIPT_DIR/../.."

# Setup: create a dirty vendored file
mkdir -p "$PLUGIN_ROOT/skills/dummy"
echo "uncommitted" > "$PLUGIN_ROOT/skills/dummy/SKILL.md"

cleanup() {
    rm -rf "$PLUGIN_ROOT/skills/dummy"
}
trap cleanup EXIT

# Try real sync (not dry-run) — should abort due to dirty state
if output="$(echo n | "$SYNC" 5.0.7 2>&1)"; then
    echo "FAIL: sync should have aborted on dirty git state" >&2
    echo "Output was: $output" >&2
    exit 1
fi

assert_contains "$output" "uncommitted changes" "abort message mentions uncommitted"

echo "PASS: test-sync-dirty-git"
