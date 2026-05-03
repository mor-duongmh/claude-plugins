#!/usr/bin/env bash
# verify-vendor.sh — verify the vendored layer matches the manifest's recorded SHA256.
# Re-downloads the upstream tarball and compares its hash to .vendor-manifest.json.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

main() {
    local plugin_root_dir
    plugin_root_dir="$(plugin_root)"
    require_commands curl jq
    local manifest="$plugin_root_dir/.vendor-manifest.json"
    local version url expected_sha
    version="$(manifest_get "$manifest" version)"
    url="$(manifest_get "$manifest" tarball_url)"
    expected_sha="$(manifest_get "$manifest" tarball_sha256)"

    if [[ "$version" == "null" || "$url" == "null" || "$expected_sha" == "null" ]]; then
        echo "Manifest is incomplete — run sync-superpowers.sh first." >&2
        exit 1
    fi

    VERIFY_TMP="$(mktemp -d)"
    trap 'rm -rf "${VERIFY_TMP:-}"' EXIT
    local tarball="$VERIFY_TMP/superpowers-v$version.tar.gz"

    echo "Verifying vendored Superpowers v$version"
    echo "  URL: $url"

    if ! curl -fsSL "$url" -o "$tarball"; then
        echo "Download failed for $url" >&2
        exit 2
    fi

    local actual_sha
    actual_sha="$(compute_sha256 "$tarball")"
    if [[ "$actual_sha" != "$expected_sha" ]]; then
        echo "MISMATCH" >&2
        echo "  expected: $expected_sha" >&2
        echo "  actual:   $actual_sha" >&2
        exit 3
    fi

    echo "OK — upstream tarball SHA256 matches manifest for v$version"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
