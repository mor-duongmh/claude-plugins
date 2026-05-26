#!/usr/bin/env bash
# test-model-routing-codex.sh — Tests for Codex advisory enforcement (Task 7).
#
# Tests:
#  C.1  userpromptsubmit-route.sh emits [ROUTING] line with a codex model name
#  C.2  userpromptsubmit-route.sh emits harness=codex model (gpt-5.4-mini/gpt-5.4/gpt-5.5), not claude model
#  C.3  userpromptsubmit-route.sh exits 0 on empty stdin (fail-open)
#  C.4  userpromptsubmit-route.sh exits 0 when node is unavailable (fail-open, simulated)
#  C.5  custom agent TOMLs exist for every agent in agentBase
#  C.6  each custom agent TOML pins model ∈ codex tier models
#  C.7  each custom agent model matches the agent's base tier (tester/researcher → mini, coder etc → gpt-5.4, architect/reviewer → gpt-5.5)
#  C.8  hooks.json has UserPromptSubmit entry
#  C.9  hooks.json has Stop entry
#  C.10 hooks.json does NOT have SubagentStart
#  C.11 hooks.json does NOT have SubagentStop
#  C.12 hooks.json is valid JSON
#  C.13 hook-handler.cjs route --harness codex emits codex model, not claude model

set -uo pipefail

TEST_NAME="model-routing-codex"
HELPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HELPER_DIR/test-helper.sh"

# Resolve paths
PLUGIN_ROOT="$TEST_PLUGIN_ROOT"
REPO_ROOT="$(cd "$PLUGIN_ROOT/../.." && pwd)"
HOOK_SCRIPT="$PLUGIN_ROOT/hooks/userpromptsubmit-route.sh"
HOOK_HANDLER="$REPO_ROOT/.claude/helpers/hook-handler.cjs"
HOOKS_JSON="$PLUGIN_ROOT/hooks/hooks.json"
POLICY_JSON="$REPO_ROOT/.claude/helpers/model-policy.json"
CODEX_AGENTS_DIR="$REPO_ROOT/.codex/agents"

# Known codex tier models (from policy.tierModel.codex)
CODEX_T1="gpt-5.4-mini"
CODEX_T2="gpt-5.4"
CODEX_T3="gpt-5.5"

# ---------------------------------------------------------------------------
# C.1 — hook emits [ROUTING] line with codex model on a typical prompt
# ---------------------------------------------------------------------------
case_C_1() {
    local input='{"prompt":"implement a new feature"}'
    local out
    out=$(MORKIT_PLUGIN_ROOT="$PLUGIN_ROOT" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
        printf '%s' "$input" | bash "$HOOK_SCRIPT" 2>/dev/null || true)
    assert_contains "$out" "[ROUTING]" "C.1 [ROUTING] prefix present"
}

# ---------------------------------------------------------------------------
# C.2 — hook emits a codex model name (not a claude model like haiku/sonnet/opus)
# ---------------------------------------------------------------------------
case_C_2() {
    local input='{"prompt":"implement a new feature"}'
    local out
    out=$(MORKIT_PLUGIN_ROOT="$PLUGIN_ROOT" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
        printf '%s' "$input" | bash "$HOOK_SCRIPT" 2>/dev/null || true)
    # Must contain one of the three codex model names
    local has_codex=0
    [[ "$out" == *"$CODEX_T1"* || "$out" == *"$CODEX_T2"* || "$out" == *"$CODEX_T3"* ]] && has_codex=1
    [[ "$has_codex" -eq 1 ]] \
        && _pass "C.2 output contains a codex model name" \
        || _fail "C.2 output must contain a codex model name; got: $out"

    # Must NOT contain claude model names
    assert_not_contains "$out" "model=haiku"  "C.2 output must not contain haiku"
    assert_not_contains "$out" "model=sonnet" "C.2 output must not contain sonnet"
    assert_not_contains "$out" "model=opus"   "C.2 output must not contain opus"
}

# ---------------------------------------------------------------------------
# C.3 — hook exits 0 on empty stdin (fail-open)
# ---------------------------------------------------------------------------
case_C_3() {
    local rc=0
    MORKIT_PLUGIN_ROOT="$PLUGIN_ROOT" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
        printf '' | bash "$HOOK_SCRIPT" >/dev/null 2>&1 || rc=$?
    assert_equal "$rc" 0 "C.3 exit 0 on empty stdin"
}

# ---------------------------------------------------------------------------
# C.4 — hook exits 0 when hook-handler is missing (fail-open)
# ---------------------------------------------------------------------------
case_C_4() {
    local tmp; tmp="$(mktemp -d)"
    # Point to a non-existent repo root by setting env to a tmpdir that has no handler
    local rc=0
    MORKIT_PLUGIN_ROOT="$tmp" CLAUDE_PLUGIN_ROOT="$tmp" \
        printf '{"prompt":"test"}' | bash "$HOOK_SCRIPT" >/dev/null 2>&1 || rc=$?
    assert_equal "$rc" 0 "C.4 exit 0 when hook-handler missing"
    rm -rf "$tmp"
}

# ---------------------------------------------------------------------------
# C.5 — custom agent TOMLs exist for every agent in agentBase
# ---------------------------------------------------------------------------
case_C_5() {
    if ! command -v jq >/dev/null 2>&1; then
        _pass "C.5 skipped (jq missing)"
        return
    fi
    local agents
    agents=$(jq -r '.agentBase | keys[]' "$POLICY_JSON" 2>/dev/null)
    local missing=0
    while IFS= read -r agent; do
        local toml="$CODEX_AGENTS_DIR/${agent}.toml"
        if [[ ! -f "$toml" ]]; then
            _fail "C.5 missing TOML for agent '$agent' at $toml"
            missing=$((missing + 1))
        fi
    done <<< "$agents"
    [[ "$missing" -eq 0 ]] && _pass "C.5 all agentBase agents have a TOML file"
}

# ---------------------------------------------------------------------------
# C.6 — each TOML pins model ∈ {gpt-5.4-mini, gpt-5.4, gpt-5.5}
# ---------------------------------------------------------------------------
case_C_6() {
    local all_ok=1
    for toml in "$CODEX_AGENTS_DIR"/*.toml; do
        [[ -f "$toml" ]] || continue
        local model_line
        model_line=$(grep '^model' "$toml" | head -1 || true)
        local ok=0
        [[ "$model_line" == *"$CODEX_T1"* || "$model_line" == *"$CODEX_T2"* || "$model_line" == *"$CODEX_T3"* ]] && ok=1
        if [[ "$ok" -eq 0 ]]; then
            _fail "C.6 $(basename "$toml"): model not in codex tier set; got: $model_line"
            all_ok=0
        fi
    done
    [[ "$all_ok" -eq 1 ]] && _pass "C.6 all TOMLs pin a codex tier model"
}

# ---------------------------------------------------------------------------
# C.7 — each TOML's model matches the agent's expected base tier
# ---------------------------------------------------------------------------
case_C_7() {
    if ! command -v jq >/dev/null 2>&1; then
        _pass "C.7 skipped (jq missing)"
        return
    fi
    local all_ok=1
    while IFS= read -r agent; do
        local base_tier
        base_tier=$(jq -r ".agentBase[\"$agent\"]" "$POLICY_JSON" 2>/dev/null)
        # Clamp: codex has no tier 0 — min effective tier is 1
        [[ "$base_tier" -lt 1 ]] && base_tier=1
        local expected_model
        expected_model=$(jq -r ".tierModel.codex[\"$base_tier\"]" "$POLICY_JSON" 2>/dev/null)

        local toml="$CODEX_AGENTS_DIR/${agent}.toml"
        [[ -f "$toml" ]] || continue
        local model_line
        model_line=$(grep '^model' "$toml" | head -1 || true)

        if [[ "$model_line" != *"$expected_model"* ]]; then
            _fail "C.7 agent=$agent tier=$base_tier: expected model '$expected_model'; got: $model_line"
            all_ok=0
        fi
    done < <(jq -r '.agentBase | keys[]' "$POLICY_JSON" 2>/dev/null)
    [[ "$all_ok" -eq 1 ]] && _pass "C.7 all TOMLs match their agent's base tier model"
}

# ---------------------------------------------------------------------------
# C.8 — hooks.json has UserPromptSubmit entry
# ---------------------------------------------------------------------------
case_C_8() {
    if ! command -v jq >/dev/null 2>&1; then
        assert_contains "$(cat "$HOOKS_JSON")" "UserPromptSubmit" "C.8 UserPromptSubmit in hooks.json (grep)"
        return
    fi
    local val
    val=$(jq -e '.hooks.UserPromptSubmit' "$HOOKS_JSON" 2>/dev/null && echo "found" || echo "missing")
    assert_contains "$val" "found" "C.8 hooks.json has UserPromptSubmit key"
}

# ---------------------------------------------------------------------------
# C.9 — hooks.json has Stop entry
# ---------------------------------------------------------------------------
case_C_9() {
    if ! command -v jq >/dev/null 2>&1; then
        assert_contains "$(cat "$HOOKS_JSON")" '"Stop"' "C.9 Stop in hooks.json (grep)"
        return
    fi
    local val
    val=$(jq -e '.hooks.Stop' "$HOOKS_JSON" 2>/dev/null && echo "found" || echo "missing")
    assert_contains "$val" "found" "C.9 hooks.json has Stop key"
}

# ---------------------------------------------------------------------------
# C.10 — hooks.json does NOT have SubagentStart
# ---------------------------------------------------------------------------
case_C_10() {
    local content
    content=$(cat "$HOOKS_JSON")
    assert_not_contains "$content" "SubagentStart" "C.10 hooks.json has no SubagentStart"
}

# ---------------------------------------------------------------------------
# C.11 — hooks.json does NOT have SubagentStop
# ---------------------------------------------------------------------------
case_C_11() {
    local content
    content=$(cat "$HOOKS_JSON")
    assert_not_contains "$content" "SubagentStop" "C.11 hooks.json has no SubagentStop"
}

# ---------------------------------------------------------------------------
# C.12 — hooks.json is valid JSON
# ---------------------------------------------------------------------------
case_C_12() {
    if command -v jq >/dev/null 2>&1; then
        jq . "$HOOKS_JSON" >/dev/null 2>&1
        assert_equal "$?" 0 "C.12 hooks.json parses as valid JSON"
    else
        # Fallback: node
        node -e "JSON.parse(require('fs').readFileSync('$HOOKS_JSON','utf8'))" 2>/dev/null
        assert_equal "$?" 0 "C.12 hooks.json parses as valid JSON (node)"
    fi
}

# ---------------------------------------------------------------------------
# C.13 — hook-handler.cjs route --harness codex emits codex model, not claude model
# ---------------------------------------------------------------------------
case_C_13() {
    if ! command -v node >/dev/null 2>&1; then
        _pass "C.13 skipped (node missing)"
        return
    fi
    local input='{"prompt":"implement a new feature"}'
    local out
    out=$(printf '%s' "$input" | node "$HOOK_HANDLER" route --harness codex 2>/dev/null || true)
    assert_contains "$out" "[ROUTING]" "C.13 [ROUTING] prefix present"
    local has_codex=0
    [[ "$out" == *"$CODEX_T1"* || "$out" == *"$CODEX_T2"* || "$out" == *"$CODEX_T3"* ]] && has_codex=1
    [[ "$has_codex" -eq 1 ]] \
        && _pass "C.13 handler with --harness codex emits codex model" \
        || _fail "C.13 expected codex model; got: $out"
    assert_not_contains "$out" "model=haiku"  "C.13 no haiku in codex output"
    assert_not_contains "$out" "model=sonnet" "C.13 no sonnet in codex output"
    assert_not_contains "$out" "model=opus"   "C.13 no opus in codex output"
}

case_C_1
case_C_2
case_C_3
case_C_4
case_C_5
case_C_6
case_C_7
case_C_8
case_C_9
case_C_10
case_C_11
case_C_12
case_C_13

exit_with_status
