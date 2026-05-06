#!/usr/bin/env bash
# Deep Review plugin: health diagnostic.
set -u

ok()  { printf "  ✅ %s\n" "$*"; }
bad() { printf "  ❌ %s\n" "$*"; }
warn(){ printf "  ⚠️  %s\n" "$*"; }
info(){ printf "  ℹ️  %s\n" "$*"; }

echo "Deep Review — Health Check"
echo "=========================="

command -v git    >/dev/null 2>&1 && ok "git: $(git --version)"            || bad "git not found (required)"
command -v uvx    >/dev/null 2>&1 && ok "uvx: $(uvx --version 2>/dev/null)" || bad "uvx not found (required)"
command -v gh     >/dev/null 2>&1 && ok "gh: $(gh --version | head -1)"     || warn "gh not found (recommended for PR diff)"

if command -v uvx >/dev/null 2>&1; then
  CRG_VER=$(uvx --quiet code-review-graph --version 2>/dev/null || echo "")
  [ -n "${CRG_VER}" ] && ok "code-review-graph: ${CRG_VER}" || warn "code-review-graph not yet cached (will fetch on first run)"
fi

# Graph status via shared helper
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -d ".git" ]; then
  ok "current dir is a git repo"
  STATUS_OUT=$("${SCRIPT_DIR}/graph-status.sh" 2>/dev/null || true)
  eval_kv() { echo "$STATUS_OUT" | awk -F= -v k="$1" '$1==k {print $2; exit}'; }
  GRAPH_PRESENT=$(eval_kv graph_present)
  FILE_COUNT=$(eval_kv file_count)
  EST_SEC=$(eval_kv estimated_build_seconds)
  REC=$(eval_kv recommendation)

  if [ "${GRAPH_PRESENT}" = "true" ]; then
    ok "graph built for this repo (${FILE_COUNT} files indexed, incremental updates < 2s)"
  else
    case "${REC}" in
      auto-build)
        warn "graph NOT built — will auto-build on /deep-review (~${EST_SEC}s for ${FILE_COUNT} files)"
        ;;
      prompt-user)
        warn "graph NOT built — /deep-review will prompt before build (${FILE_COUNT} files, ~${EST_SEC}s)"
        ;;
      prompt-user-large)
        warn "graph NOT built — LARGE repo (${FILE_COUNT} files, est. ~${EST_SEC}s). /deep-review will prompt with strong warning."
        ;;
      *)
        info "graph status: ${REC}"
        ;;
    esac
  fi
  [ -f "CLAUDE.md" ] && ok "CLAUDE.md present (Tier-1 conventions will be honored)" || warn "no CLAUDE.md — falling back to language profile + universal rules"
else
  warn "current dir is not a git repo — /deep-review needs git context"
fi

echo
echo "Done."
