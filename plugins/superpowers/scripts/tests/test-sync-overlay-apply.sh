#!/usr/bin/env bash
# Test that overlay/<path>/<file> replaces vendored <path>/<file> after sync.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helper.sh"

SYNC="$SCRIPT_DIR/../sync-superpowers.sh"
PLUGIN_ROOT="$SCRIPT_DIR/../.."
TEST_VERSION="5.0.7"

# Backup state
backup="$(mktemp -d)"
for d in skills commands agents LICENSE overlay; do
    [[ -e "$PLUGIN_ROOT/$d" ]] && cp -R "$PLUGIN_ROOT/$d" "$backup/$d"
done
manifest_backup="$(cat "$PLUGIN_ROOT/.vendor-manifest.json")"
# Clear manifest version so sync runs (avoid idempotent skip)
jq '.version = null | .tarball_sha256 = null' "$PLUGIN_ROOT/.vendor-manifest.json" > "$PLUGIN_ROOT/.vendor-manifest.json.tmp"
mv "$PLUGIN_ROOT/.vendor-manifest.json.tmp" "$PLUGIN_ROOT/.vendor-manifest.json"

cleanup() {
    rm -rf "$PLUGIN_ROOT/skills" "$PLUGIN_ROOT/commands" "$PLUGIN_ROOT/agents" "$PLUGIN_ROOT/LICENSE" "$PLUGIN_ROOT/overlay"
    for d in skills commands agents LICENSE overlay; do
        [[ -e "$backup/$d" ]] && cp -R "$backup/$d" "$PLUGIN_ROOT/$d"
    done
    echo "$manifest_backup" > "$PLUGIN_ROOT/.vendor-manifest.json"
    rm -rf "$backup"
}
trap cleanup EXIT

# Setup overlay: create a file that will replace a known vendored skill
mkdir -p "$PLUGIN_ROOT/overlay/skills/brainstorming"
echo "MOR-OVERLAY-MARKER" > "$PLUGIN_ROOT/overlay/skills/brainstorming/SKILL.md"

# Run sync
echo "y" | "$SYNC" "$TEST_VERSION" >/dev/null

# After sync, the overlay file should have replaced the vendored one
content="$(cat "$PLUGIN_ROOT/skills/brainstorming/SKILL.md")"
assert_equal "$content" "MOR-OVERLAY-MARKER" "overlay replaced vendored SKILL.md"

echo "PASS: test-sync-overlay-apply"
