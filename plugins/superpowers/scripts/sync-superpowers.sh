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

main() {
    parse_args "$@"
    echo "(stub) DRY_RUN=$DRY_RUN TARGET_VERSION=${TARGET_VERSION:-<from manifest>}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
