#!/usr/bin/env bash
# test-scope-guard.sh — Tests for the scope guard in the Codex hook.
#
# Tests:
#  SG.1  userpromptsubmit-route.sh emits [ROUTING] when marker is present and enabled
#  SG.2  userpromptsubmit-route.sh is SILENT (no output) when marker is absent
#  SG.3  userpromptsubmit-route.sh is SILENT when marker has enabled:false
#  SG.4  userpromptsubmit-route.sh exits 0 in all scope-guard cases (fail-open)
#  SG.5  .model-routing.json marker file exists at repo root with enabled:true
#  SG.6  hook-handler.cjs exits 0 with no output when CLAUDE_PROJECT_DIR is a dir
#        without a .model-routing.json marker (simulates out-of-scope project)

set -uo pipefail

TEST_NAME="scope-guard"
HELPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HELPER_DIR/test-helper.sh"

PLUGIN_ROOT="$TEST_PLUGIN_ROOT"
REPO_ROOT="$(cd "$PLUGIN_ROOT/../.." && pwd)"
HOOK_SCRIPT="$PLUGIN_ROOT/hooks/userpromptsubmit-route.sh"
HOOK_HANDLER="$REPO_ROOT/.claude/helpers/hook-handler.cjs"
MARKER_FILE="$REPO_ROOT/.model-routing.json"

# Helper: run the hook script with env vars properly inherited into the pipeline.
# Usage: _run_hook_with_env MORKIT_ROOT CLAUDE_ROOT HOOK_PATH PROMPT
_run_hook_with_env() {
    local morkit_root="$1" claude_root="$2" hook_path="$3" prompt_json="$4"
    # Use env(1) to pass vars to a subshell that runs the full pipeline.
    # This ensures env vars apply to BOTH sides of the pipe (unlike var=val cmd).
    (
        export MORKIT_PLUGIN_ROOT="$morkit_root"
        export CLAUDE_PLUGIN_ROOT="$claude_root"
        printf '%s' "$prompt_json" | bash "$hook_path" 2>/dev/null
    ) || true
}

# Helper: build a minimal isolated repo tree in $tmp with marker file optional.
# Copies hook script + all helpers. Pass marker_content="" to skip marker.
_build_tmp_repo() {
    local tmp="$1" marker_content="${2:-}"
    mkdir -p "$tmp/plugins/morkit/hooks"
    cp "$HOOK_SCRIPT" "$tmp/plugins/morkit/hooks/userpromptsubmit-route.sh"
    mkdir -p "$tmp/.claude/helpers"
    cp "$HOOK_HANDLER" "$tmp/.claude/helpers/hook-handler.cjs"
    cp "$REPO_ROOT/.claude/helpers/"*.js  "$tmp/.claude/helpers/" 2>/dev/null || true
    cp "$REPO_ROOT/.claude/helpers/"*.cjs "$tmp/.claude/helpers/" 2>/dev/null || true
    cp -r "$REPO_ROOT/.claude/helpers/embeddings" "$tmp/.claude/helpers/" 2>/dev/null || true
    if [[ -n "$marker_content" ]]; then
        printf '%s' "$marker_content" > "$tmp/.model-routing.json"
    fi
}

# ---------------------------------------------------------------------------
# SG.1 — hook emits [ROUTING] when marker is present and enabled
# ---------------------------------------------------------------------------
case_SG_1() {
    if [[ ! -f "$MARKER_FILE" ]]; then
        _fail "SG.1 skipped — marker file missing (setup problem)"
        return
    fi
    local out
    out=$(_run_hook_with_env "$PLUGIN_ROOT" "$PLUGIN_ROOT" "$HOOK_SCRIPT" \
        '{"prompt":"implement a new feature"}')
    assert_contains "$out" "[ROUTING]" "SG.1 [ROUTING] present when marker enabled"
}

# ---------------------------------------------------------------------------
# SG.2 — hook is SILENT when marker is absent
# ---------------------------------------------------------------------------
case_SG_2() {
    local tmp; tmp="$(mktemp -d)"
    _build_tmp_repo "$tmp" ""  # no marker

    local out
    out=$(_run_hook_with_env "$tmp/plugins/morkit" "$tmp/plugins/morkit" \
        "$tmp/plugins/morkit/hooks/userpromptsubmit-route.sh" \
        '{"prompt":"implement a new feature"}')
    assert_not_contains "$out" "[ROUTING]" "SG.2 no [ROUTING] when marker absent"
    assert_equal "$out" "" "SG.2 output must be empty when scope guard blocks"
    rm -rf "$tmp"
}

# ---------------------------------------------------------------------------
# SG.3 — hook is SILENT when marker has enabled:false
# ---------------------------------------------------------------------------
case_SG_3() {
    local tmp; tmp="$(mktemp -d)"
    _build_tmp_repo "$tmp" '{"enabled":false}'

    local out
    out=$(_run_hook_with_env "$tmp/plugins/morkit" "$tmp/plugins/morkit" \
        "$tmp/plugins/morkit/hooks/userpromptsubmit-route.sh" \
        '{"prompt":"implement a new feature"}')
    assert_not_contains "$out" "[ROUTING]" "SG.3 no [ROUTING] when enabled:false"
    assert_equal "$out" "" "SG.3 output must be empty when enabled:false"
    rm -rf "$tmp"
}

# ---------------------------------------------------------------------------
# SG.4 — hook exits 0 in all scope-guard cases (fail-open)
# ---------------------------------------------------------------------------
case_SG_4() {
    local tmp; tmp="$(mktemp -d)"
    mkdir -p "$tmp/plugins/morkit/hooks"
    cp "$HOOK_SCRIPT" "$tmp/plugins/morkit/hooks/userpromptsubmit-route.sh"
    # No handler, no helpers, no marker — most hostile environment

    local rc=0
    (
        export MORKIT_PLUGIN_ROOT="$tmp/plugins/morkit"
        export CLAUDE_PLUGIN_ROOT="$tmp/plugins/morkit"
        printf '{"prompt":"implement a new feature"}' | \
            bash "$tmp/plugins/morkit/hooks/userpromptsubmit-route.sh"
    ) >/dev/null 2>&1 || rc=$?
    assert_equal "$rc" 0 "SG.4 exit 0 even with no marker and no handler"
    rm -rf "$tmp"
}

# ---------------------------------------------------------------------------
# SG.5 — .model-routing.json exists at repo root with enabled:true
# ---------------------------------------------------------------------------
case_SG_5() {
    assert_file_exists "$MARKER_FILE" "SG.5 .model-routing.json exists at repo root"
    if [[ -f "$MARKER_FILE" ]]; then
        if command -v jq >/dev/null 2>&1; then
            local enabled
            enabled=$(jq -r '.enabled // false' "$MARKER_FILE" 2>/dev/null || echo "false")
            assert_equal "$enabled" "true" "SG.5 .model-routing.json has enabled:true (jq)"
        elif command -v node >/dev/null 2>&1; then
            local enabled
            enabled=$(node -e \
                "try{var m=JSON.parse(require('fs').readFileSync('$MARKER_FILE','utf8'));console.log(m.enabled===true?'true':'false')}catch(_){console.log('false')}" \
                2>/dev/null || echo "false")
            assert_equal "$enabled" "true" "SG.5 .model-routing.json has enabled:true (node)"
        else
            _pass "SG.5 .model-routing.json exists (content check skipped: no jq/node)"
        fi
    fi
}

# ---------------------------------------------------------------------------
# SG.6 — hook-handler.cjs exits 0 with no output when CLAUDE_PROJECT_DIR is a
#         directory without a .model-routing.json marker (out-of-scope project)
# ---------------------------------------------------------------------------
case_SG_6() {
    if ! command -v node >/dev/null 2>&1; then
        _pass "SG.6 skipped (node missing)"
        return
    fi
    local tmp; tmp="$(mktemp -d)"
    # tmp has no .model-routing.json anywhere — simulates an out-of-scope project

    local out rc=0
    out=$(
        export CLAUDE_PROJECT_DIR="$tmp"
        printf '{"prompt":"implement a new feature"}' | \
            node "$HOOK_HANDLER" route 2>/dev/null
    ) || rc=$?
    assert_equal "$rc" 0 "SG.6 hook-handler exits 0 in out-of-scope dir"
    assert_equal "$out" "" "SG.6 hook-handler emits nothing in out-of-scope dir"
    rm -rf "$tmp"
}

case_SG_1
case_SG_2
case_SG_3
case_SG_4
case_SG_5
case_SG_6

exit_with_status
