# deep-review

> Multi-language deep code review agent for Claude Code. Risk · Security · Design Pattern · Test Coverage · Convention. Powered by [code-review-graph](https://github.com/tirth8205/code-review-graph). Honors project `CLAUDE.md` as the highest source of truth.

## Install

```
/plugin marketplace add mor-duongmh/claude-plugins
/plugin install deep-review@mor-duongmh
```

On first session start, the plugin runs `scripts/setup.sh` once to:
- install `uv` (provides `uvx`) if missing
- pre-cache the `code-review-graph` Python package
- build the code graph for the current repo (if it is a git repo)

## Usage

```
/deep-review 123          # review PR #123
/deep-review --diff       # review working tree vs HEAD
/deep-review --diff main  # review HEAD vs main
/deep-review --json       # CI mode: emit JSON instead of Markdown
/deep-review-doctor       # diagnose setup
```

The skill orchestrates 5 parallel subagents and prints a structured Markdown report directly to chat.

## First-time on a repo (no graph yet)

The skill auto-detects whether the current repo has a code graph and decides what to do based on size:

| Repo size | Behavior |
|-----------|----------|
| < 1500 files | Build silently with a one-line progress (~10–40s) |
| 1500–8000 files | Prompt: `Build now? (y/N/skip)` |
| > 8000 files | Strong warning + prompt — build is 1-time, incremental updates < 2s |

If you decline (or build fails), the skill runs in **degraded mode** — graph-dependent findings fall back to `grep`/`Read` with reduced confidence; Security/Convention/Universal checks remain unaffected. The report header always notes the mode.

Use `/deep-review-doctor` any time to see graph status, file count, and estimated build time.

## Convention priority

1. **Project `CLAUDE.md`** (Tier 1) — always wins.
2. **Language profile** (`profiles/<lang>.md`) — when CLAUDE.md is silent.
3. **Universal rules** (SOLID/DRY/KISS/YAGNI) — baseline.

## Subagents

| Subagent | Focus |
|----------|-------|
| `risk-impact-analyst` | Blast radius, critical flow, bridge-node detection |
| `security-auditor` | OWASP Top 10, secrets, injection, deserialization |
| `pattern-architecture-critic` | SOLID, anti-patterns, layer boundaries |
| `test-coverage-auditor` | New/changed funcs without tests |
| `convention-checker` | Naming/style — CLAUDE.md > profile > universal |
| `performance-auditor` (Phase 2) | N+1, sync-in-async, hot-path allocation |
| `documentation-auditor` (Phase 2) | Public-API docs, README sync, migration notes |

## Languages

**Phase 1 (this release):** TypeScript/TSX · Python · Go (universal rules apply to all 23 languages supported by code-review-graph).

**Phase 2:** Java · Rust · C# · PHP · Ruby.

## Optional: pre-commit hook

```bash
cp plugins/deep-review/ci/pre-commit-hook.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

The hook is **warn-only** — it never blocks a commit.

## CI/CD integration

See `ci/github-actions.yml` for a workflow template that posts the review as a PR comment.

## Roadmap

- **Phase 1 (MVP)** ✅ — 5 subagents, 3 profiles, slash commands, marketplace registration
- **Phase 2** — Java/Rust/C#/PHP/Ruby profiles, severity calibration, `gh pr review` posting, performance & docs auditors
- **Phase 3** — GitHub Actions template, pre-commit hook, JSON output mode, false-positive feedback loop

## License

MIT
