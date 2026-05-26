#!/usr/bin/env bash
# userpromptsubmit-route.sh — Codex UserPromptSubmit hook (advisory routing).
#
# Reads the user prompt from hook stdin JSON, invokes the shared router with
# harness=codex, and emits a [ROUTING] line to stdout → Codex picks it up as
# additionalContext injected into the model context.
#
# Advisory: Codex has no SubagentStart/SubagentStop events (v0.130.0), so this
# hook cannot enforce model selection at spawn time. The [ROUTING] line is a
# suggestion in context; model-baked custom agents (.codex/agents/*.toml) are the
# robust enforcement mechanism.
#
# Path assumption: the shared router lives at .claude/helpers/hook-handler.cjs
# relative to the repo root (i.e. parent of plugins/morkit). This script resolves
# that path via MORKIT_PLUGIN_ROOT / CLAUDE_PLUGIN_ROOT (pointing to plugins/morkit)
# → repo root is two levels up. If neither env var is set, the script derives the
# repo root from its own filesystem location.
#
# Safety contract:
#   - Never hangs: relies on hook-handler.cjs's 5 s global timer + 500 ms stdin timer.
#   - Never fails the prompt: all error paths exit 0.
#   - Emits nothing (silent) on jq-missing or malformed stdin; Codex proceeds normally.

set -uo pipefail

# Resolve repo root. MORKIT_PLUGIN_ROOT / CLAUDE_PLUGIN_ROOT both point to
# plugins/morkit — repo root is two dirs up.
if [[ -n "${MORKIT_PLUGIN_ROOT:-}" ]]; then
    REPO_ROOT="$(cd "${MORKIT_PLUGIN_ROOT}/../.." && pwd -P)"
elif [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
    REPO_ROOT="$(cd "${CLAUDE_PLUGIN_ROOT}/../.." && pwd -P)"
else
    # Fallback: derive from this script's own location
    # This script is at <repo>/plugins/morkit/hooks/userpromptsubmit-route.sh
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd -P)"
fi

HOOK_HANDLER="$REPO_ROOT/.claude/helpers/hook-handler.cjs"

# Fail-open: if node or the handler is not available, exit silently.
if ! command -v node >/dev/null 2>&1; then
    exit 0
fi
if [[ ! -f "$HOOK_HANDLER" ]]; then
    exit 0
fi

# Read stdin (Codex passes hook payload as JSON on stdin). Codex UserPromptSubmit
# payload: { "prompt": "<user text>" } (or similar — we pass the raw JSON through
# to hook-handler.cjs which extracts .prompt / .command).
input="$(cat || true)"
[[ -n "$input" ]] || exit 0

# Invoke the shared router with harness=codex. The handler reads the prompt from
# the piped stdin JSON and prints the [ROUTING] line to stdout.
printf '%s' "$input" | node "$HOOK_HANDLER" route --harness codex 2>/dev/null || true
