#!/usr/bin/env bash
# sync-superpowers.sh — refresh the vendored Superpowers layer from upstream.
# Usage:
#   ./sync-superpowers.sh                    Use version pinned in .vendor-manifest.json
#   ./sync-superpowers.sh <version>          Bump to specific upstream tag (e.g. 5.1.0)
#   ./sync-superpowers.sh --dry-run [<ver>]  Show what would change without writing
#   ./sync-superpowers.sh --help             Show this help

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

DRY_RUN=0
TARGET_VERSION=""

print_usage() {
    cat <<'EOF'
Usage: sync-superpowers.sh [--dry-run] [--help] [<version>]

Refresh the vendored Superpowers layer from obra/superpowers.

Options:
  --dry-run    Print actions without writing files
  --help       Show this help

Arguments:
  <version>    Upstream tag to sync (e.g. 5.1.0). If omitted, the version
               pinned in .vendor-manifest.json is used.

Examples:
  sync-superpowers.sh                  # use pinned version
  sync-superpowers.sh 5.1.0            # bump to 5.1.0
  sync-superpowers.sh --dry-run 5.1.0  # preview only
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                print_usage
                exit 0
                ;;
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            -*)
                echo "Unknown option: $1" >&2
                print_usage >&2
                exit 2
                ;;
            *)
                if [[ -z "$TARGET_VERSION" ]]; then
                    TARGET_VERSION="$1"
                    shift
                else
                    echo "Unexpected extra argument: $1" >&2
                    exit 2
                fi
                ;;
        esac
    done
}

resolve_version() {
    local manifest="$PLUGIN_ROOT/.vendor-manifest.json"
    if [[ -n "$TARGET_VERSION" ]]; then
        echo "$TARGET_VERSION"
        return
    fi
    local pinned
    pinned="$(manifest_get "$manifest" version)"
    if [[ "$pinned" == "null" ]]; then
        echo "No version pinned in manifest. Pass version explicitly: ./sync-superpowers.sh <version>" >&2
        exit 1
    fi
    echo "$pinned"
}

print_dry_run_plan() {
    local version="$1"
    cat <<EOF
=== DRY RUN ===
Target version: $version
Tarball URL:    https://github.com/obra/superpowers/archive/refs/tags/v$version.tar.gz

Plan:
  1. would download tarball to /tmp
  2. would compute SHA256 and verify against manifest (or store if first sync)
  3. would extract to a tempdir
  4. would wipe: \$PLUGIN_ROOT/skills \$PLUGIN_ROOT/commands \$PLUGIN_ROOT/agents \$PLUGIN_ROOT/LICENSE
  5. would copy from extracted tree
  6. would apply overlay/ on top
  7. would update .vendor-manifest.json

No files were written.
EOF
}

main() {
    parse_args "$@"
    PLUGIN_ROOT="$(plugin_root)"
    require_commands curl tar jq git

    local version
    version="$(resolve_version)"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        print_dry_run_plan "$version"
        exit 0
    fi

    echo "(real sync not yet implemented — see Task 5+)"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
