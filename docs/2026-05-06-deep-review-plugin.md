# Deep Review Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a public Claude Code plugin `deep-review` (in `mor-duongmh/claude-plugins` marketplace) that runs an orchestrated multi-agent code review on a PR or git diff, producing a structured Markdown report covering risk, security, design pattern, test coverage, and convention — with `code-review-graph` MCP bundled via `uvx` and project `CLAUDE.md` overriding language profile defaults.

**Architecture:** Plugin lives in `plugins/deep-review/`. A single skill (`deep-review`) orchestrates 5 specialist subagents dispatched in parallel via the Task tool. The skill ingests the diff, loads CLAUDE.md (Tier 1) → language profiles (Tier 2) → universal rules (Tier 3), dispatches subagents, then synthesizes findings into a Markdown matrix. The `code-review-graph` MCP is declared in `.mcp.json` and run on-demand via `uvx`; a `SessionStart` hook runs `setup.sh` once to install `uv`, pre-cache the package, and build the graph.

**Tech Stack:**
- Claude Code Plugin (plugin.json + .mcp.json + skill + agents + commands + hooks)
- `tirth8205/code-review-graph` (PyPI) launched via `uvx`
- Bash for setup/doctor scripts
- Markdown for plan/profiles/agents/skills (declarative)
- `gh` CLI for PR diff retrieval
- GitHub Actions (Phase 3)

**Branch:** `feature/deep-review-plugin` (created from `main` of `mor-duongmh/claude-plugins`)

**Plan locations (both kept in sync):**
- `_bmad-output/plans/2026-05-06-deep-review-plugin.md`
- `claude-plugins/docs/2026-05-06-deep-review-plugin.md`

**Convention priority (CLAUDE.md override):**
1. **Tier 1** — Project `CLAUDE.md` (highest, must be cited explicitly in findings)
2. **Tier 2** — Language profile (`profiles/<lang>.md`)
3. **Tier 3** — Universal rules (SOLID/DRY/KISS/YAGNI)

---

## File Structure

### Phase 1 (MVP)

```
plugins/deep-review/
├── .claude-plugin/plugin.json          # plugin metadata + hooks declaration
├── .mcp.json                           # code-review-graph via uvx
├── README.md                           # install + usage
├── agents/
│   ├── risk-impact-analyst.md          # graph-heavy: blast radius, flows
│   ├── security-auditor.md             # OWASP + secret scan
│   ├── pattern-architecture-critic.md  # SOLID + arch boundaries (CLAUDE.md aware)
│   ├── test-coverage-auditor.md        # tests_for from graph
│   └── convention-checker.md           # CLAUDE.md > profile > universal
├── commands/
│   ├── deep-review.md                  # /deep-review entry
│   └── deep-review-doctor.md           # /deep-review-doctor diagnostic
├── skills/
│   └── deep-review/
│       └── SKILL.md                    # orchestrator (4 phases: ingest/dispatch/synth/output)
├── profiles/
│   ├── typescript.md
│   ├── python.md
│   └── go.md
├── scripts/
│   ├── setup.sh                        # SessionStart one-time setup
│   └── doctor.sh                       # health check
└── templates/
    └── report-template.md              # output skeleton
```

### Phase 2 additions

```
plugins/deep-review/
├── agents/
│   ├── performance-auditor.md
│   └── documentation-auditor.md
├── profiles/
│   ├── java.md
│   ├── rust.md
│   ├── csharp.md
│   ├── php.md
│   └── ruby.md
├── lib/
│   └── severity-calibration.md         # severity matrix doc
└── commands/
    └── deep-review-post.md             # /deep-review-post (publish to gh PR)
```

### Phase 3 additions

```
plugins/deep-review/
├── ci/
│   ├── github-actions.yml              # template for user repo
│   └── pre-commit-hook.sh
├── lib/
│   └── feedback-store.md               # false-positive tracking schema
└── (skill emits JSON when --json flag is passed)
```

### Repo-level changes

- `.claude-plugin/marketplace.json` — append `deep-review` entry (Phase 1)
- `README.md` — append Deep Review section (Phase 1)
- `docs/2026-05-06-deep-review-plugin.md` — this plan

---

# PHASE 1 — MVP

## Task 1: Initialize feature branch and folder skeleton

**Files:**
- Create: `plugins/deep-review/` (directory)
- Create: `plugins/deep-review/.claude-plugin/plugin.json`

- [ ] **Step 1.1: Create feature branch**

```bash
cd /Users/haiduong/Documents/work/claude-plugins
git checkout main
git pull --ff-only
git checkout -b feature/deep-review-plugin
```

Expected: `Switched to a new branch 'feature/deep-review-plugin'`

- [ ] **Step 1.2: Create plugin folder skeleton**

```bash
mkdir -p plugins/deep-review/{.claude-plugin,agents,commands,skills/deep-review,profiles,scripts,templates}
```

- [ ] **Step 1.3: Write `plugin.json`**

Create `plugins/deep-review/.claude-plugin/plugin.json`:

```json
{
  "name": "deep-review",
  "version": "0.1.0",
  "description": "Multi-language deep code review agent: risk, security, design pattern, test coverage, convention — powered by code-review-graph MCP. Honors project CLAUDE.md as the highest source of truth.",
  "author": {
    "name": "Mor (Hai Duong)",
    "email": "duongmh@mor.com.vn"
  },
  "homepage": "https://github.com/mor-duongmh/claude-plugins/tree/main/plugins/deep-review",
  "repository": "https://github.com/mor-duongmh/claude-plugins",
  "license": "MIT",
  "keywords": [
    "code-review",
    "security",
    "design-pattern",
    "risk-analysis",
    "multi-language",
    "code-review-graph"
  ],
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"${CLAUDE_PLUGIN_ROOT}/scripts/setup.sh\"",
            "async": true
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 1.4: Validate JSON**

Run: `python3 -m json.tool plugins/deep-review/.claude-plugin/plugin.json > /dev/null && echo OK`
Expected: `OK`

- [ ] **Step 1.5: Commit**

```bash
git add plugins/deep-review/.claude-plugin/plugin.json
git commit -m "feat(deep-review): scaffold plugin skeleton with plugin.json"
```

---

## Task 2: Declare bundled MCP server (code-review-graph)

**Files:**
- Create: `plugins/deep-review/.mcp.json`

- [ ] **Step 2.1: Write `.mcp.json`**

Create `plugins/deep-review/.mcp.json`:

```json
{
  "mcpServers": {
    "code-review-graph": {
      "command": "uvx",
      "args": ["code-review-graph", "mcp"],
      "env": {}
    }
  }
}
```

- [ ] **Step 2.2: Validate JSON**

Run: `python3 -m json.tool plugins/deep-review/.mcp.json > /dev/null && echo OK`
Expected: `OK`

- [ ] **Step 2.3: Smoke-test uvx command exists (does not download)**

Run: `command -v uvx >/dev/null && echo "uvx present" || echo "uvx will be installed by setup.sh"`
Expected: either branch is fine; setup.sh handles missing uv.

- [ ] **Step 2.4: Commit**

```bash
git add plugins/deep-review/.mcp.json
git commit -m "feat(deep-review): bundle code-review-graph MCP via uvx"
```

---

## Task 3: setup.sh (one-time install) + doctor.sh

**Files:**
- Create: `plugins/deep-review/scripts/setup.sh`
- Create: `plugins/deep-review/scripts/doctor.sh`

- [ ] **Step 3.1: Write `setup.sh`**

Create `plugins/deep-review/scripts/setup.sh`:

```bash
#!/usr/bin/env bash
# Deep Review plugin: one-time setup. Idempotent via marker file.
set -e

MARKER_DIR="${HOME}/.claude/deep-review"
MARKER="${MARKER_DIR}/.setup-done"
mkdir -p "${MARKER_DIR}"

if [ -f "${MARKER}" ]; then
  exit 0
fi

echo "🔧 Deep Review: first-time setup..."

# 1. Ensure uv (provides uvx)
if ! command -v uvx >/dev/null 2>&1; then
  echo "  📦 Installing uv (provides uvx)..."
  curl -LsSf https://astral.sh/uv/install.sh | sh >/dev/null 2>&1 || {
    echo "  ⚠️  uv install failed. Install manually: https://docs.astral.sh/uv/"
    exit 0
  }
  export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"
fi

# 2. Pre-cache code-review-graph (best-effort)
echo "  📥 Pre-caching code-review-graph..."
uvx --quiet code-review-graph --version >/dev/null 2>&1 || true

# 3. Optional dependency notes
command -v gh  >/dev/null 2>&1 || echo "  ℹ️  Recommended: install GitHub CLI (gh) for PR diff fetching."
command -v git >/dev/null 2>&1 || { echo "  ❌ git not found — required."; exit 0; }

# 4. Build graph for current repo if it is a git repo and graph not present
if [ -d ".git" ] && [ ! -d ".code-review-graph" ]; then
  echo "  📊 Building code graph for current repo (one-time)..."
  uvx --quiet code-review-graph build 2>&1 | tail -3 || \
    echo "  ℹ️  Graph not built now; will build on first /deep-review."
fi

touch "${MARKER}"
echo "✅ Deep Review ready. Try: /deep-review <PR-number-or-diff>"
```

- [ ] **Step 3.2: Write `doctor.sh`**

Create `plugins/deep-review/scripts/doctor.sh`:

```bash
#!/usr/bin/env bash
# Deep Review plugin: health diagnostic.
set -u

ok()  { printf "  ✅ %s\n" "$*"; }
bad() { printf "  ❌ %s\n" "$*"; }
warn(){ printf "  ⚠️  %s\n" "$*"; }

echo "Deep Review — Health Check"
echo "=========================="

command -v git    >/dev/null 2>&1 && ok "git: $(git --version)"            || bad "git not found (required)"
command -v uvx    >/dev/null 2>&1 && ok "uvx: $(uvx --version 2>/dev/null)" || bad "uvx not found (required)"
command -v gh     >/dev/null 2>&1 && ok "gh: $(gh --version | head -1)"     || warn "gh not found (recommended for PR diff)"

if command -v uvx >/dev/null 2>&1; then
  CRG_VER=$(uvx --quiet code-review-graph --version 2>/dev/null || echo "")
  [ -n "${CRG_VER}" ] && ok "code-review-graph: ${CRG_VER}" || warn "code-review-graph not yet cached (will fetch on first run)"
fi

if [ -d ".git" ]; then
  ok "current dir is a git repo"
  [ -d ".code-review-graph" ] && ok "graph already built for this repo" || warn "graph not built — first /deep-review will trigger build"
  [ -f "CLAUDE.md" ] && ok "CLAUDE.md present (Tier-1 conventions will be honored)" || warn "no CLAUDE.md — falling back to language profile + universal rules"
else
  warn "current dir is not a git repo — /deep-review needs git context"
fi

echo
echo "Done."
```

- [ ] **Step 3.3: Make executable**

```bash
chmod +x plugins/deep-review/scripts/setup.sh plugins/deep-review/scripts/doctor.sh
```

- [ ] **Step 3.4: Smoke-test doctor.sh**

Run: `bash plugins/deep-review/scripts/doctor.sh`
Expected: prints check report, exit 0.

- [ ] **Step 3.5: Smoke-test setup.sh idempotency**

Run twice:
```bash
bash plugins/deep-review/scripts/setup.sh
bash plugins/deep-review/scripts/setup.sh
```
Expected: first run sets up; second run exits silently (marker present).

- [ ] **Step 3.6: Commit**

```bash
git add plugins/deep-review/scripts/
git commit -m "feat(deep-review): add setup.sh (one-time) and doctor.sh (diagnostic)"
```

---

## Task 4: Skill orchestrator (`skills/deep-review/SKILL.md`)

**Files:**
- Create: `plugins/deep-review/skills/deep-review/SKILL.md`

- [ ] **Step 4.1: Write SKILL.md**

Create `plugins/deep-review/skills/deep-review/SKILL.md`:

````markdown
---
name: deep-review
description: Run a deep multi-agent code review on a PR or git diff. Dispatches 5 specialist subagents (risk, security, pattern, tests, convention) in parallel and synthesizes a Markdown matrix report. Honors project CLAUDE.md as the highest source of truth.
license: MIT
---

# Deep Review Orchestrator

Run a four-phase deep code review and emit a Markdown report.

## Inputs

The user invokes via `/deep-review <target>` where `<target>` is one of:
- `#<number>` or `<number>` → GitHub PR number (uses `gh pr diff <n>`)
- `--diff` → uses `git diff` (working tree vs HEAD)
- `--diff <ref>` → uses `git diff <ref>...HEAD`
- (empty) → defaults to `--diff`

## Phase 1 — Ingest

1. Resolve target → produce a unified diff string.
   - PR: `gh pr diff <n>` (fail with clear message if `gh` missing or unauthenticated).
   - Diff: `git diff` or `git diff <ref>...HEAD`.
2. Parse diff to derive:
   - Changed file list.
   - Languages present (by extension): `.ts`/`.tsx`, `.py`, `.go`, `.java`, `.rs`, `.cs`, `.php`, `.rb`, `.js`/`.jsx`, etc.
3. Load **convention sources** in priority order:
   - **Tier 1**: project `CLAUDE.md` (read full content; if absent, mark "no CLAUDE.md").
   - **Tier 2**: matching `profiles/<lang>.md` files for each detected language (read from `${CLAUDE_PLUGIN_ROOT}/profiles/`).
   - **Tier 3**: universal rules (SOLID/DRY/KISS/YAGNI) — embedded below.
4. Verify graph availability via `mcp__code-review-graph__list_graph_stats_tool`. If unavailable, run `mcp__code-review-graph__build_or_update_graph_tool` first.

## Phase 2 — Dispatch Specialists (PARALLEL)

Dispatch all 5 subagents in **a single message with multiple Agent tool calls** (parallel). Each subagent receives:
- The diff string
- The list of changed files
- The detected languages
- The Tier-1/Tier-2/Tier-3 convention bundle
- Instruction to cite **CLAUDE.md line numbers** when CLAUDE.md is the basis for a finding

| Subagent | `subagent_type` | Primary tools |
|----------|----------------|---------------|
| Risk & Impact Analyst | `general-purpose` (use Agent definition: `risk-impact-analyst`) | `code-review-graph: detect_changes_tool, get_impact_radius_tool, get_affected_flows_tool, get_bridge_nodes_tool, query_graph_tool` |
| Security Auditor | `risk-impact-analyst` style → `security-auditor` | `code-review-graph: semantic_search_nodes_tool, query_graph_tool, get_minimal_context_tool` + Read/Grep |
| Pattern & Architecture Critic | `pattern-architecture-critic` | `code-review-graph: get_architecture_overview_tool, list_communities_tool, get_hub_nodes_tool, find_large_functions_tool, get_surprising_connections_tool` |
| Test Coverage Auditor | `test-coverage-auditor` | `code-review-graph: query_graph_tool (tests_for), get_knowledge_gaps_tool` |
| Convention Checker | `convention-checker` | Read (CLAUDE.md + profile), Grep |

**Each subagent returns a JSON-like Markdown block:**

```yaml
findings:
  - id: <S1|R1|P1|T1|C1>-<n>
    category: Security|Risk|Pattern|Tests|Convention
    severity: Critical|High|Medium|Low|Info
    file: path/to/file.ts
    line: 42
    title: short description
    detail: longer explanation
    source: "CLAUDE.md:L<line>" | "profile:typescript" | "universal:SOLID-S" | "graph:impact_radius"
    suggested_fix: code or text
    confidence: 0-100
```

## Phase 3 — Synthesize

1. Merge findings from all 5 subagents.
2. Deduplicate (same file:line + same title).
3. Compute severity score per finding: severity_weight × confidence × impact_factor (impact_factor from graph if available).
4. Rank: Critical first, then High, Medium, Low, Info.
5. Build executive summary:
   - Overall Risk: highest individual severity (capped at HIGH unless ≥2 Critical → CRITICAL).
   - Decision: BLOCK if any Critical; APPROVE WITH CHANGES if any High; APPROVE otherwise.
   - Confidence: weighted average.

## Phase 4 — Output

1. Render `templates/report-template.md` with computed values.
2. **Print full report directly to chat.**
3. Save to `_deep-review-output/deep-review-<timestamp>-<target>.md` if writable; otherwise skip silently.

## Universal Rules (Tier 3, embedded)

- **SOLID**: Single-responsibility, Open/closed, Liskov, Interface-segregation, Dependency-inversion violations are findings.
- **DRY**: Three or more near-identical blocks → finding.
- **KISS / YAGNI**: Speculative abstraction, dead branches, unused parameters → finding.
- **Cyclomatic complexity** > 10 in changed functions → finding.
- **Magic numbers** (non-0/1/-1) without named constant → finding.
- **Long methods** > 60 lines (changed) → finding.
- **Error swallowing** (empty catch / `pass` on except / `_ = err`) → finding.
- **Resource leaks** (no `defer`/`finally`/`with`) → finding.

## Tier-1 Override Rule (CRITICAL)

If CLAUDE.md states a convention that conflicts with the language profile, **CLAUDE.md wins**. Cite the CLAUDE.md line in `source`. Findings derived from a profile rule that is contradicted by CLAUDE.md MUST be suppressed and instead recorded as `Info`-level note "profile rule overridden by CLAUDE.md:L<n>".

## Failure Modes

| Condition | Behavior |
|-----------|----------|
| `gh` missing for PR target | Fail with: "Install GitHub CLI: brew install gh && gh auth login" |
| Graph build fails | Continue in degraded mode; subagents fall back to Read/Grep; report header notes "⚠️ Degraded mode (no graph)" |
| Empty diff | Print "No changes to review." and exit |
| Subagent timeout | Skip that subagent; report header notes which categories were skipped |

## Output Mode Flag (Phase 3 of plan)

If invocation includes `--json`, emit a JSON object instead of Markdown (Phase-3 deliverable). Default = Markdown.
````

- [ ] **Step 4.2: Validate frontmatter**

Run: `python3 -c "import re,sys; t=open('plugins/deep-review/skills/deep-review/SKILL.md').read(); m=re.match(r'---\n(.*?)\n---', t, re.S); assert m and 'name:' in m.group(1) and 'description:' in m.group(1); print('OK')"`
Expected: `OK`

- [ ] **Step 4.3: Commit**

```bash
git add plugins/deep-review/skills/deep-review/SKILL.md
git commit -m "feat(deep-review): add orchestrator SKILL with 4-phase flow + CLAUDE.md priority"
```

---

## Task 5: Subagent — Risk & Impact Analyst

**Files:**
- Create: `plugins/deep-review/agents/risk-impact-analyst.md`

- [ ] **Step 5.1: Write agent file**

Create `plugins/deep-review/agents/risk-impact-analyst.md`:

```markdown
---
name: risk-impact-analyst
description: Specialist subagent. Computes blast radius and risk for a code diff using code-review-graph. Returns YAML-Markdown findings.
tools: Bash, Read, Grep, Glob
---

You are the **Risk & Impact Analyst**. Inputs: a diff, changed files list, languages, convention bundle.

## Procedure (graph-first)

1. Call `mcp__code-review-graph__detect_changes_tool` with the changed files. Capture risk-scored nodes.
2. For each top-risk symbol, call `mcp__code-review-graph__get_impact_radius_tool`. Record callers/dependents/tests counts.
3. Call `mcp__code-review-graph__get_affected_flows_tool` to identify execution paths touched. Mark any whose name matches /auth|payment|billing|admin|secret|crypt/ as **critical flow**.
4. Call `mcp__code-review-graph__get_bridge_nodes_tool`. If a changed symbol IS a bridge node, raise severity by one level.
5. If graph is unavailable, fall back: grep for symbol references across the repo (lower confidence; mark `confidence ≤ 60`).

## Heuristics

- impact_radius ≥ 20 → severity High
- impact_radius ≥ 50 → severity Critical
- bridge node touched → +1 severity, append "bridge node" to detail
- removed public symbol with N callers → Critical if N > 0
- new circular import → High

## Output

Emit findings in the YAML-Markdown schema defined in the orchestrator SKILL. Use IDs `R1`, `R2`, …. Always populate `source: "graph:<tool>"` or `source: "fallback:grep"`.

If no findings: emit `findings: []` with a one-line note.
```

- [ ] **Step 5.2: Commit**

```bash
git add plugins/deep-review/agents/risk-impact-analyst.md
git commit -m "feat(deep-review): add risk-impact-analyst subagent"
```

---

## Task 6: Subagent — Security Auditor

**Files:**
- Create: `plugins/deep-review/agents/security-auditor.md`

- [ ] **Step 6.1: Write agent file**

Create `plugins/deep-review/agents/security-auditor.md`:

```markdown
---
name: security-auditor
description: Specialist subagent. Audits a diff for OWASP Top 10, secret leakage, unsafe deserialization, SSRF, and injection. Returns YAML-Markdown findings.
tools: Bash, Read, Grep, Glob
---

You are the **Security Auditor**. Inputs: diff, changed files, languages, convention bundle.

## Checklist (run all that apply to the languages in the diff)

### Universal
- **A01 Broken Access Control**: missing authz check on new endpoints/handlers.
- **A02 Crypto Failures**: hardcoded keys, MD5/SHA1 for security, weak random (`Math.random`, `random.random` for tokens).
- **A03 Injection**:
  - SQL: string concatenation/interpolation in queries → finding.
  - Command: `exec`, `system`, `Runtime.exec`, `subprocess.*shell=True` with user input.
  - LDAP/XPath: similar patterns.
- **A04 Insecure Design**: trust boundaries crossed without validation.
- **A05 Security Misconfiguration**: CORS `*`, debug=True, default credentials, exposed admin routes.
- **A06 Vulnerable Components**: new deps in lockfile/manifest? (read-only flag, no fetch).
- **A07 Auth Failures**: token compared with `==`, no rate limit on login, jwt `none` alg.
- **A08 Integrity Failures**: unsigned deserialization (`pickle.load`, `yaml.load` w/o SafeLoader, `unserialize`).
- **A09 Logging Failures**: secrets logged, PII logged.
- **A10 SSRF**: user-controlled URL passed to `fetch`/`requests`/`http.Get` without allowlist.

### Secrets scan
- Grep diff for: `AKIA[0-9A-Z]{16}`, `sk_live_`, `xoxb-`, `ghp_`, `-----BEGIN .* PRIVATE KEY-----`, high-entropy strings ≥ 32 chars in quotes.

### Language-specific quick hits
- TS/JS: `dangerouslySetInnerHTML` with non-sanitized input; `eval`, `Function()`.
- Python: `pickle.load`, `yaml.load` (without SafeLoader), `subprocess(..., shell=True)`.
- Go: `fmt.Sprintf` into SQL, `exec.Command("sh","-c", ...)` with input.
- Java: `Runtime.exec(String)`, `XMLDecoder`, `ObjectInputStream` on user input.

## Graph use

- `mcp__code-review-graph__semantic_search_nodes_tool` to find sanitizers and trust boundaries; cross-check whether tainted input reaches sinks unsanitized.
- `mcp__code-review-graph__get_minimal_context_tool` to fetch the minimal slice of code needed to confirm a finding without reading entire files.

## Output

Use IDs `S1`, `S2`, …. For each finding, populate:
- `source: "OWASP:A0X"` or `source: "secrets-scan"` or `source: "graph:semantic_search"`
- `confidence`: 95+ if pattern is unambiguous; 70-90 if heuristic; lower if speculative.

Critical-severity defaults: SQL injection, command injection, hardcoded secret, unsafe deserialization. Do not downgrade these.
```

- [ ] **Step 6.2: Commit**

```bash
git add plugins/deep-review/agents/security-auditor.md
git commit -m "feat(deep-review): add security-auditor subagent (OWASP + secrets)"
```

---

## Task 7: Subagent — Pattern & Architecture Critic

**Files:**
- Create: `plugins/deep-review/agents/pattern-architecture-critic.md`

- [ ] **Step 7.1: Write agent file**

Create `plugins/deep-review/agents/pattern-architecture-critic.md`:

```markdown
---
name: pattern-architecture-critic
description: Specialist subagent. Reviews diff for design pattern violations, anti-patterns, and architectural-boundary breaches. Honors CLAUDE.md (Tier 1) over language profile (Tier 2).
tools: Bash, Read, Grep, Glob
---

You are the **Pattern & Architecture Critic**. Inputs: diff, changed files, languages, **convention bundle (Tier-1 CLAUDE.md, Tier-2 profile, Tier-3 universal)**.

## CRITICAL: Tier resolution

Before producing any finding, resolve the relevant rule:
1. Search CLAUDE.md for guidance on the topic (e.g., "no inheritance", "use functional core / imperative shell", "all DB access via repository pattern"). If found, **cite the line** and use it as authority.
2. Otherwise, use the loaded language profile.
3. Otherwise, fall back to universal SOLID/DRY/etc.

If a profile rule **contradicts** an explicit CLAUDE.md rule, the CLAUDE.md rule wins. Suppress the profile-based finding and emit an `Info` finding noting the override.

## Checks

### L1 Universal (always)
- SOLID violations on changed classes/modules.
- God object: changed file > 500 LOC AND > 7 public methods added.
- Long method: changed function > 60 lines.
- Magic numbers (non-0/1/-1) without const.
- Cyclomatic complexity > 10 (estimate from branching).
- Dead code: unreferenced new symbols (verify via graph).

### L2 Paradigm/profile
- For each language present, apply rules from `profiles/<lang>.md`.

### L3 Architecture
- `mcp__code-review-graph__get_architecture_overview_tool` → identify layers/communities.
- `mcp__code-review-graph__list_communities_tool` + `get_community_tool` → detect cross-boundary calls (e.g., presentation → DB direct).
- `mcp__code-review-graph__get_hub_nodes_tool` → flag if change adds dependency on a hub.
- `mcp__code-review-graph__find_large_functions_tool` → flag newly-added large functions.
- `mcp__code-review-graph__get_surprising_connections_tool` → flag unusual coupling.

## Output

Use IDs `P1`, `P2`, …. Populate `source` precisely:
- `"CLAUDE.md:L<line>"` when CLAUDE.md authoritative
- `"profile:<lang>"` when profile authoritative
- `"universal:<rule-name>"` when universal
- `"graph:<tool>"` when architectural

Confidence ≥ 80 for explicit CLAUDE.md/profile matches; 60-80 for universal heuristics.
```

- [ ] **Step 7.2: Commit**

```bash
git add plugins/deep-review/agents/pattern-architecture-critic.md
git commit -m "feat(deep-review): add pattern-architecture-critic subagent (CLAUDE.md priority)"
```

---

## Task 8: Subagent — Test Coverage Auditor

**Files:**
- Create: `plugins/deep-review/agents/test-coverage-auditor.md`

- [ ] **Step 8.1: Write agent file**

Create `plugins/deep-review/agents/test-coverage-auditor.md`:

```markdown
---
name: test-coverage-auditor
description: Specialist subagent. Detects untested new/changed functions and missing test cases via code-review-graph tests_for relations.
tools: Bash, Read, Grep, Glob
---

You are the **Test Coverage Auditor**. Inputs: diff, changed files, languages, convention bundle.

## Procedure

1. From the diff, extract every NEW or MODIFIED function/method.
2. For each, query `mcp__code-review-graph__query_graph_tool` with `pattern="tests_for"` (or equivalent) to get the list of tests linked to that symbol.
3. Bucket each symbol:
   - 0 tests → severity **High** (blocker if function is in critical flow per Risk Analyst convention).
   - 1 test → severity **Medium** (warn: only happy-path likely).
   - ≥ 2 tests → no finding.
4. Use `mcp__code-review-graph__get_knowledge_gaps_tool` to identify modules with chronically low coverage; if the diff lands in such a module, add a contextual `Info` finding.
5. If graph is unavailable, fall back: grep for `<symbol-name>` in `**/*test*` paths.

## Output

Use IDs `T1`, `T2`, …. Populate:
- `source: "graph:tests_for"` (preferred) or `"fallback:grep"`
- `detail` includes the count: e.g., "0 tests reference this function (graph)".
- `suggested_fix` references the file that conventionally houses tests for this symbol.

If CLAUDE.md states a testing rule (e.g., "every public function must have at least 2 tests"), apply it and cite.
```

- [ ] **Step 8.2: Commit**

```bash
git add plugins/deep-review/agents/test-coverage-auditor.md
git commit -m "feat(deep-review): add test-coverage-auditor subagent"
```

---

## Task 9: Subagent — Convention Checker

**Files:**
- Create: `plugins/deep-review/agents/convention-checker.md`

- [ ] **Step 9.1: Write agent file**

Create `plugins/deep-review/agents/convention-checker.md`:

```markdown
---
name: convention-checker
description: Specialist subagent. Verifies naming, structure, and style conventions, with project CLAUDE.md taking strict priority over language profile.
tools: Bash, Read, Grep, Glob
---

You are the **Convention Checker**. Inputs: diff, changed files, languages, convention bundle.

## Tier resolution (STRICT)

For every potential finding:
1. **Tier 1 — CLAUDE.md**: scan for keywords (`naming`, `convention`, `style`, `format`, `import`, `prefix`, `suffix`, `case`, language names). If a rule applies, use it as the source of truth and cite the line.
2. **Tier 2 — profile**: only if CLAUDE.md says nothing about the topic.
3. **Tier 3 — universal**: only if neither CLAUDE.md nor profile cover it.

If CLAUDE.md says, for example, "use snake_case in TypeScript files" and the profile says camelCase, **CLAUDE.md wins**. Profile-based findings on that topic are suppressed.

## Checks

For each language present, apply the rules listed in `profiles/<lang>.md` (Tier 2). Examples:
- File naming convention.
- Identifier casing (functions, classes, constants).
- Import order/grouping.
- Module structure (e.g., one default export per file in TS).
- Specific anti-patterns the profile lists.

## Output

Use IDs `C1`, `C2`, …. Populate `source` precisely. Confidence ≥ 90 for direct rule match.

If a project-wide CLAUDE.md rule is violated, severity Medium minimum.
```

- [ ] **Step 9.2: Commit**

```bash
git add plugins/deep-review/agents/convention-checker.md
git commit -m "feat(deep-review): add convention-checker subagent (CLAUDE.md strict priority)"
```

---

## Task 10: Slash command `/deep-review`

**Files:**
- Create: `plugins/deep-review/commands/deep-review.md`

- [ ] **Step 10.1: Write command**

Create `plugins/deep-review/commands/deep-review.md`:

```markdown
---
name: "deep-review"
description: Run a deep multi-agent code review on a PR or git diff. Produces a Markdown matrix report with risk, security, design pattern, test coverage, and convention findings.
category: Code Review
tags: [code-review, security, risk, pattern, tests]
---

Invoke the `deep-review` skill via the Skill tool. Pass through any arguments the user provided as `<target>`:

- `/deep-review 123` → review PR #123
- `/deep-review #123` → review PR #123
- `/deep-review --diff` → review uncommitted changes vs HEAD
- `/deep-review --diff main` → review HEAD vs main
- `/deep-review` → defaults to `--diff`

The skill orchestrates 5 parallel subagents and prints a full Markdown report directly to chat. It also saves a copy under `_deep-review-output/` if the directory is writable.

If `gh` is missing for a PR target, the skill exits with installation instructions.
If the code-review-graph MCP is unavailable, the skill runs in degraded mode and notes this in the report header.
```

- [ ] **Step 10.2: Commit**

```bash
git add plugins/deep-review/commands/deep-review.md
git commit -m "feat(deep-review): add /deep-review slash command"
```

---

## Task 11: Slash command `/deep-review-doctor`

**Files:**
- Create: `plugins/deep-review/commands/deep-review-doctor.md`

- [ ] **Step 11.1: Write command**

Create `plugins/deep-review/commands/deep-review-doctor.md`:

```markdown
---
name: "deep-review-doctor"
description: Diagnose Deep Review installation health (uvx, code-review-graph, gh, git, graph build, CLAUDE.md presence).
category: Code Review
tags: [diagnostic, doctor, health-check]
---

Run the bundled `${CLAUDE_PLUGIN_ROOT}/scripts/doctor.sh` via Bash and stream its output to chat. Then summarize:
- Required components (git, uvx) — ok/missing
- Recommended (gh) — ok/missing
- Code graph status for current repo
- Whether a project CLAUDE.md is present (Tier-1 conventions)

If anything required is missing, propose the exact install command.
```

- [ ] **Step 11.2: Commit**

```bash
git add plugins/deep-review/commands/deep-review-doctor.md
git commit -m "feat(deep-review): add /deep-review-doctor diagnostic command"
```

---

## Task 12: Report template

**Files:**
- Create: `plugins/deep-review/templates/report-template.md`

- [ ] **Step 12.1: Write template**

Create `plugins/deep-review/templates/report-template.md`:

```markdown
# Deep Review Report — {{TARGET}}

**Generated:** {{TIMESTAMP}}
**Mode:** {{MODE: full | degraded-no-graph | degraded-no-gh}}
**Convention sources:** {{TIER1_PRESENT}} CLAUDE.md, {{TIER2_LANGS}} profile(s), universal

## 🎯 Executive Summary

| | |
|--|--|
| **Overall Risk** | {{RISK: 🔴 CRITICAL / 🟠 HIGH / 🟡 MEDIUM / 🟢 LOW}} |
| **Decision** | {{DECISION: ❌ BLOCK / ⚠️ APPROVE WITH CHANGES / ✅ APPROVE}} |
| **Confidence** | {{CONF}}% |
| **Files changed** | {{N_FILES}} |
| **Languages** | {{LANGS}} |

## 📋 Findings Matrix

| ID | Category | Severity | File:Line | Issue | Source | Confidence |
|----|----------|----------|-----------|-------|--------|------------|
{{FINDINGS_TABLE}}

## 🔬 Deep Dive

{{FOREACH FINDING}}
### {{ID}} — {{TITLE}} ({{SEVERITY}})

**File:** `{{FILE}}:{{LINE}}`
**Source:** {{SOURCE}}
**Confidence:** {{CONFIDENCE}}%

{{DETAIL}}

**Suggested Fix:**
```{{LANG}}
{{SUGGESTED_FIX}}
```
{{/FOREACH}}

## ✅ What's Good

{{POSITIVES}}

## 🚦 Required Actions Before Merge

{{ACTIONS}}

---

_Generated by [deep-review](https://github.com/mor-duongmh/claude-plugins/tree/main/plugins/deep-review) plugin._
```

- [ ] **Step 12.2: Commit**

```bash
git add plugins/deep-review/templates/report-template.md
git commit -m "feat(deep-review): add report template"
```

---

## Task 13: Language profile — TypeScript

**Files:**
- Create: `plugins/deep-review/profiles/typescript.md`

- [ ] **Step 13.1: Write profile**

Create `plugins/deep-review/profiles/typescript.md`:

```markdown
# TypeScript / TSX Convention Profile (Tier 2)

> CLAUDE.md (Tier 1) overrides every rule here. If CLAUDE.md is silent on a topic, this profile applies.

## Naming
- Files: `kebab-case.ts` for utilities; `PascalCase.tsx` for React components.
- Variables/functions: `camelCase`.
- Types/interfaces/classes: `PascalCase`.
- Constants (module-level immutable): `SCREAMING_SNAKE_CASE`.
- Booleans: prefix with `is`, `has`, `should`, `can`.

## Idioms
- Prefer `const` over `let`; never `var`.
- Strict null checks: prefer `Foo | undefined` explicit; avoid `any`.
- Use `unknown` for unknown input; narrow before use.
- Prefer named exports; one default export at most per file.
- `async/await` over chained `.then` for new code.
- Replace `enum` with `as const` literal unions when applicable.
- React: hooks at top of component, no conditional hooks.

## Anti-patterns (findings)
- `any` introduced in new code → Medium.
- `// @ts-ignore` without comment justifying → Medium.
- `dangerouslySetInnerHTML` with non-sanitized input → Critical (Security overlap).
- Empty catch `{}` → High.
- Floating promises (no `await`, no `.catch`, no `void`) → High.
- Mutable exported `let` → Medium.
- React: `useEffect` without dependency array, or with all-deps disabled → Medium.

## Resource handling
- `fetch` without timeout/abort signal → Low.
- File handles or streams not closed in error path → High.
```

- [ ] **Step 13.2: Commit**

```bash
git add plugins/deep-review/profiles/typescript.md
git commit -m "feat(deep-review): add TypeScript language profile"
```

---

## Task 14: Language profile — Python

**Files:**
- Create: `plugins/deep-review/profiles/python.md`

- [ ] **Step 14.1: Write profile**

Create `plugins/deep-review/profiles/python.md`:

```markdown
# Python Convention Profile (Tier 2)

> CLAUDE.md (Tier 1) overrides every rule here.

## Naming (PEP 8)
- Modules: `snake_case`.
- Classes: `PascalCase`.
- Functions/variables: `snake_case`.
- Constants: `SCREAMING_SNAKE_CASE`.
- Private: leading single underscore.

## Idioms
- Prefer f-strings over `%` and `.format`.
- Use context managers (`with`) for files/locks/transactions.
- Type hints on public APIs (Python 3.10+).
- Use `dataclasses` or `pydantic` instead of dict-as-record.
- Iterators/generators for streaming; avoid building giant lists.

## Anti-patterns (findings)
- Mutable default argument (`def f(x=[])`) → High.
- `except:` or `except Exception: pass` → High.
- `eval` / `exec` on dynamic input → Critical (Security overlap).
- `pickle.load` on external data → Critical (Security overlap).
- `yaml.load` without `Loader=SafeLoader` → Critical.
- Bare `assert` for runtime validation (stripped under `-O`) → Medium.
- `subprocess.*` with `shell=True` and string interpolation → Critical.
- Globals mutated from inside functions without `global` declaration → Medium.

## Resource / concurrency
- Open file without `with` → Medium.
- `requests` without `timeout=` → Low.
- `asyncio` blocking call (`time.sleep`, sync I/O) inside coroutine → High.
- Threading shared mutable state without `Lock`/`Queue` → High.

## Tests
- Use `pytest` style; avoid `unittest.TestCase` in new code unless project uses it.
- Test functions named `test_<unit>_<scenario>`.
```

- [ ] **Step 14.2: Commit**

```bash
git add plugins/deep-review/profiles/python.md
git commit -m "feat(deep-review): add Python language profile"
```

---

## Task 15: Language profile — Go

**Files:**
- Create: `plugins/deep-review/profiles/go.md`

- [ ] **Step 15.1: Write profile**

Create `plugins/deep-review/profiles/go.md`:

```markdown
# Go Convention Profile (Tier 2)

> CLAUDE.md (Tier 1) overrides every rule here.

## Naming
- Packages: lowercase, no underscores, short.
- Exported: `PascalCase`. Unexported: `camelCase`.
- Acronyms: keep case (e.g., `URL`, `HTTPClient`, `userID`).
- Errors: variables `ErrFoo`, types `FooError`.

## Idioms
- Return `error` last; check `if err != nil` immediately.
- Wrap with `fmt.Errorf("...: %w", err)`.
- Use `context.Context` as first param of long-running funcs.
- Prefer interfaces accepted, structs returned (consumer-driven).
- Use `defer` for cleanup right after acquiring resource.

## Anti-patterns (findings)
- `_ = err` (silently dropping error) → High.
- `panic` outside `init`/CLI bootstrap → High.
- Goroutine started without lifecycle/cancellation plan → High.
- Channel never closed leading to goroutine leak → High.
- Package-level mutable variables (without sync) → Medium.
- `fmt.Sprintf` into SQL → Critical (Security overlap).
- `exec.Command("sh","-c", input)` → Critical.
- `interface{}` (or `any`) in new APIs without justification → Medium.

## Resource / concurrency
- Open file/conn without `defer Close()` → High.
- `sync.Mutex` copied (passed by value) → High.
- Unbounded goroutine fan-out (no semaphore/worker pool) → Medium.
- `time.Now()` in business logic without injection (testability) → Low.

## Tests
- Use table-driven tests with `t.Run(name, ...)`.
- Use `t.Helper()` in helpers.
- No `time.Sleep` in tests; use `eventually` patterns.
```

- [ ] **Step 15.2: Commit**

```bash
git add plugins/deep-review/profiles/go.md
git commit -m "feat(deep-review): add Go language profile"
```

---

## Task 16: Plugin README

**Files:**
- Create: `plugins/deep-review/README.md`

- [ ] **Step 16.1: Write README**

Create `plugins/deep-review/README.md`:

```markdown
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
/deep-review-doctor       # diagnose setup
```

The skill orchestrates 5 parallel subagents and prints a structured Markdown report directly to chat.

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

## Languages (Phase 1 MVP)

TypeScript/TSX · Python · Go (universal rules apply to all 23 langs supported by code-review-graph)

## Roadmap

- **Phase 2** — Java/Rust/C#/PHP/Ruby profiles, severity calibration, `gh pr review` posting, performance & docs auditors
- **Phase 3** — GitHub Actions template, pre-commit hook, JSON output mode, false-positive feedback loop

## License

MIT
```

- [ ] **Step 16.2: Commit**

```bash
git add plugins/deep-review/README.md
git commit -m "docs(deep-review): add plugin README"
```

---

## Task 17: Register plugin in marketplace.json

**Files:**
- Modify: `.claude-plugin/marketplace.json`

- [ ] **Step 17.1: Append entry**

Open `.claude-plugin/marketplace.json` and add a third object to the `plugins` array. The full file becomes:

```json
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "mor-duongmh",
  "description": "Mor's Claude Code plugin marketplace — spec-driven workflows + vendored Superpowers + deep code review.",
  "owner": {
    "name": "duongmh",
    "email": "duongmh@mor.com.vn"
  },
  "plugins": [
    {
      "name": "spec",
      "description": "Mor's spec-driven workflow with superpowers-driven schema. Artifacts are TDD-ready and consumable by Superpowers executing-plans and subagent-driven-development.",
      "source": "./plugins/spec",
      "category": "development",
      "author": { "name": "Mor" },
      "homepage": "https://github.com/mor-duongmh/claude-plugins/tree/main/plugins/spec"
    },
    {
      "name": "superpowers",
      "description": "Mor's vendored fork of obra/superpowers — same skills as upstream, pinned and synced via script. Replaces upstream superpowers@obra in this marketplace.",
      "source": "./plugins/superpowers",
      "category": "development",
      "author": {
        "name": "Jesse Vincent (upstream) / Mor (vendoring)",
        "email": "duongmh@mor.com.vn"
      },
      "homepage": "https://github.com/mor-duongmh/claude-plugins/tree/main/plugins/superpowers"
    },
    {
      "name": "deep-review",
      "description": "Multi-language deep code review agent: risk · security · design pattern · test coverage · convention. Powered by code-review-graph MCP. Honors project CLAUDE.md as the highest source of truth.",
      "source": "./plugins/deep-review",
      "category": "code-review",
      "author": {
        "name": "Mor (Hai Duong)",
        "email": "duongmh@mor.com.vn"
      },
      "homepage": "https://github.com/mor-duongmh/claude-plugins/tree/main/plugins/deep-review"
    }
  ]
}
```

- [ ] **Step 17.2: Validate JSON**

Run: `python3 -m json.tool .claude-plugin/marketplace.json > /dev/null && echo OK`
Expected: `OK`

- [ ] **Step 17.3: Commit**

```bash
git add .claude-plugin/marketplace.json
git commit -m "feat(marketplace): register deep-review plugin"
```

---

## Task 18: Update repo README

**Files:**
- Modify: `README.md`

- [ ] **Step 18.1: Add Deep Review section**

Open `README.md` and add — under the existing plugin list — a new section:

```markdown
### deep-review

Multi-language deep code review agent. Runs 5 specialist subagents in parallel against a PR or git diff and emits a structured Markdown matrix covering risk, security, design pattern, test coverage, and convention. Powered by [code-review-graph](https://github.com/tirth8205/code-review-graph). Honors project `CLAUDE.md` as the highest source of truth.

```bash
/plugin install deep-review@mor-duongmh
/deep-review 123
```

See [`plugins/deep-review/README.md`](plugins/deep-review/README.md) for details.
```

- [ ] **Step 18.2: Commit**

```bash
git add README.md
git commit -m "docs: announce deep-review plugin in repo README"
```

---

## Task 19: End-to-end verification

- [ ] **Step 19.1: Validate file presence**

Run:
```bash
test -f plugins/deep-review/.claude-plugin/plugin.json && \
test -f plugins/deep-review/.mcp.json && \
test -f plugins/deep-review/skills/deep-review/SKILL.md && \
test -f plugins/deep-review/agents/risk-impact-analyst.md && \
test -f plugins/deep-review/agents/security-auditor.md && \
test -f plugins/deep-review/agents/pattern-architecture-critic.md && \
test -f plugins/deep-review/agents/test-coverage-auditor.md && \
test -f plugins/deep-review/agents/convention-checker.md && \
test -f plugins/deep-review/commands/deep-review.md && \
test -f plugins/deep-review/commands/deep-review-doctor.md && \
test -f plugins/deep-review/profiles/typescript.md && \
test -f plugins/deep-review/profiles/python.md && \
test -f plugins/deep-review/profiles/go.md && \
test -x plugins/deep-review/scripts/setup.sh && \
test -x plugins/deep-review/scripts/doctor.sh && \
test -f plugins/deep-review/templates/report-template.md && \
test -f plugins/deep-review/README.md && \
echo ALL_PRESENT
```
Expected: `ALL_PRESENT`

- [ ] **Step 19.2: Validate all JSON**

Run:
```bash
for f in plugins/deep-review/.claude-plugin/plugin.json plugins/deep-review/.mcp.json .claude-plugin/marketplace.json; do
  python3 -m json.tool "$f" > /dev/null && echo "OK: $f" || echo "FAIL: $f"
done
```
Expected: three `OK:` lines.

- [ ] **Step 19.3: Validate markdown frontmatter on agents/commands/skill**

Run:
```bash
for f in plugins/deep-review/agents/*.md plugins/deep-review/commands/*.md plugins/deep-review/skills/deep-review/SKILL.md; do
  head -1 "$f" | grep -q '^---$' && grep -q '^name:' "$f" && grep -q '^description:' "$f" && echo "OK: $f" || echo "FAIL: $f"
done
```
Expected: every line `OK:`.

- [ ] **Step 19.4: Run doctor.sh smoke test**

Run: `bash plugins/deep-review/scripts/doctor.sh`
Expected: prints check report (some warnings ok), exit 0.

- [ ] **Step 19.5: Push branch + open PR**

```bash
git push -u origin feature/deep-review-plugin
gh pr create --title "feat: add deep-review plugin (Phase 1 MVP)" --body "$(cat <<'EOF'
## Summary
- Adds `plugins/deep-review/` — multi-language deep code review agent
- 5 specialist subagents dispatched in parallel by an orchestrator skill
- Bundles `code-review-graph` MCP via `uvx` (no global install required)
- Honors project `CLAUDE.md` (Tier 1) over language profile (Tier 2) over universal rules (Tier 3)
- Slash commands: `/deep-review`, `/deep-review-doctor`
- Language profiles: TypeScript, Python, Go
- Registered in `.claude-plugin/marketplace.json` as `deep-review`

## Test plan
- [ ] Fresh machine: `/plugin marketplace add mor-duongmh/claude-plugins` then `/plugin install deep-review@mor-duongmh` succeeds
- [ ] `/deep-review-doctor` reports green on a machine with git, uv, gh
- [ ] `/deep-review --diff` produces a Markdown report on a sample diff in a TS repo
- [ ] `/deep-review --diff` honors a CLAUDE.md rule that contradicts `profiles/typescript.md`
- [ ] Degraded mode: with the MCP unavailable, the skill still produces a report and notes "no graph"
EOF
)"
```

Expected: PR URL printed.

---

# PHASE 2 — Expansion

## Task 20: Java profile

**Files:**
- Create: `plugins/deep-review/profiles/java.md`

- [ ] **Step 20.1: Write profile**

Create `plugins/deep-review/profiles/java.md`:

```markdown
# Java Convention Profile (Tier 2)

> CLAUDE.md (Tier 1) overrides every rule here.

## Naming
- Packages: lowercase, dot-separated.
- Classes/Interfaces: `PascalCase`.
- Methods/fields: `camelCase`.
- Constants: `SCREAMING_SNAKE_CASE`.

## Idioms
- Use `Optional<T>` for "may-be-absent" return types; never for fields/parameters.
- Prefer immutability: `final` fields, defensive copies.
- Use try-with-resources for `AutoCloseable`.
- Prefer streams for collection transforms — but avoid side-effects inside.

## Anti-patterns (findings)
- `catch (Exception e) {}` → High.
- `Runtime.exec(String)` with user input → Critical.
- `XMLDecoder` / `ObjectInputStream` on user input → Critical.
- Public mutable fields → Medium.
- `Date` / `Calendar` in new code (use `java.time`) → Low.
- `null` returned where `Optional` would fit → Medium.
- Static singletons holding mutable state → Medium.

## Resource / concurrency
- Stream/connection without try-with-resources → High.
- `synchronized` on `String` literal / boxed primitive → High.
- `ExecutorService` not shut down → Medium.
```

- [ ] **Step 20.2: Commit**

```bash
git add plugins/deep-review/profiles/java.md
git commit -m "feat(deep-review): add Java language profile"
```

---

## Task 21: Rust profile

**Files:**
- Create: `plugins/deep-review/profiles/rust.md`

- [ ] **Step 21.1: Write profile**

Create `plugins/deep-review/profiles/rust.md`:

```markdown
# Rust Convention Profile (Tier 2)

> CLAUDE.md (Tier 1) overrides every rule here.

## Naming
- Modules/files: `snake_case`.
- Types/traits/enums: `PascalCase`.
- Functions/vars: `snake_case`.
- Consts/statics: `SCREAMING_SNAKE_CASE`.

## Idioms
- Return `Result<T, E>`; use `?` for propagation.
- Prefer `&str` parameters over `String` when ownership not needed.
- Use `thiserror` for library errors, `anyhow` for application errors.
- Use `Cow<'_, str>` to avoid allocation when possible.

## Anti-patterns (findings)
- `unwrap()` / `expect("...")` in non-test code → High (unless invariant proved in comment).
- `panic!` outside startup/CLI → High.
- `unsafe` block without `// SAFETY:` comment → High.
- `clone()` on large struct in hot path → Medium.
- `Arc<Mutex<...>>` copy-pasted without justification → Medium.
- `as` numeric cast that may truncate without check → Medium.

## Resource / concurrency
- Blocking call inside `async fn` → High.
- `tokio::spawn` without lifecycle management → Medium.
- Drop order assumptions across threads → Medium.
```

- [ ] **Step 21.2: Commit**

```bash
git add plugins/deep-review/profiles/rust.md
git commit -m "feat(deep-review): add Rust language profile"
```

---

## Task 22: C# / PHP / Ruby profiles

**Files:**
- Create: `plugins/deep-review/profiles/csharp.md`
- Create: `plugins/deep-review/profiles/php.md`
- Create: `plugins/deep-review/profiles/ruby.md`

- [ ] **Step 22.1: Write csharp.md**

Create `plugins/deep-review/profiles/csharp.md`:

```markdown
# C# Convention Profile (Tier 2)

> CLAUDE.md (Tier 1) overrides every rule here.

## Naming
- Types/methods/properties: `PascalCase`.
- Local vars/parameters: `camelCase`.
- Private fields: `_camelCase`.
- Interfaces: `IPascalCase`.
- Constants: `PascalCase` (Microsoft style) unless project uses SCREAMING_SNAKE.

## Idioms
- Use `async`/`await`; suffix async methods with `Async`.
- Use `using`/`using var` for `IDisposable`.
- Records for immutable data; classes for behavior.
- Prefer `IEnumerable<T>` parameters; concrete returns OK.

## Anti-patterns (findings)
- `async void` (except event handlers) → High.
- Blocking on async (`.Result`, `.Wait()`) → High.
- `catch (Exception) {}` empty → High.
- LINQ in hot path with multiple enumerations → Medium.
- Dynamic SQL via `string.Format`/interpolation → Critical.
- `HttpClient` instantiated per call instead of injected → Medium.

## Resource / concurrency
- `IDisposable` not in `using` → High.
- `lock` on `this` or `typeof(...)` → High.
```

- [ ] **Step 22.2: Write php.md**

Create `plugins/deep-review/profiles/php.md`:

```markdown
# PHP Convention Profile (Tier 2)

> CLAUDE.md (Tier 1) overrides every rule here.

## Naming (PSR-12)
- Classes: `PascalCase`.
- Methods/properties: `camelCase`.
- Constants: `SCREAMING_SNAKE_CASE`.
- Files (classes): `PascalCase.php` matching class name (PSR-4).

## Idioms
- Use strict types: `declare(strict_types=1);` at top of file.
- Type-hint parameters and returns; use union types (`int|string`) when justified.
- Prefer constructor property promotion (PHP 8+).
- Use enums (PHP 8.1+) over class constants.

## Anti-patterns (findings)
- `unserialize` on user input → Critical.
- `eval(...)` → Critical.
- SQL via string concatenation → Critical.
- `extract($_GET)` / `extract($_POST)` → Critical.
- `@` error suppression → Medium.
- Mixed return types without `mixed` declaration → Medium.

## Resource
- File handles via `fopen` not closed → High.
- `curl_init` without `curl_close` → Medium.
```

- [ ] **Step 22.3: Write ruby.md**

Create `plugins/deep-review/profiles/ruby.md`:

```markdown
# Ruby Convention Profile (Tier 2)

> CLAUDE.md (Tier 1) overrides every rule here.

## Naming
- Classes/modules: `PascalCase`.
- Methods/vars: `snake_case`. Predicate methods end with `?`. Bang methods end with `!`.
- Constants: `SCREAMING_SNAKE_CASE`.

## Idioms
- Use blocks/iterators (`each`, `map`, `select`) over manual loops.
- Prefer `&:method_name` symbol-to-proc.
- Keep methods short; favor early returns.

## Anti-patterns (findings)
- `eval(input)` → Critical.
- `system("sh -c #{input}")` / backticks with input → Critical.
- `Marshal.load` on external data → Critical.
- `rescue` without exception class → High.
- Monkey-patching core classes in app code → Medium.
- Long methods > 30 lines → Medium.

## Rails-specific (if Rails detected)
- N+1 query suspicion (loop over records calling AR) → High.
- Mass assignment without strong params → Critical.
- `html_safe` on user input → Critical.
```

- [ ] **Step 22.4: Commit**

```bash
git add plugins/deep-review/profiles/csharp.md plugins/deep-review/profiles/php.md plugins/deep-review/profiles/ruby.md
git commit -m "feat(deep-review): add C#/PHP/Ruby language profiles"
```

---

## Task 23: Severity calibration framework

**Files:**
- Create: `plugins/deep-review/lib/severity-calibration.md`

- [ ] **Step 23.1: Write calibration doc**

Create `plugins/deep-review/lib/severity-calibration.md`:

```markdown
# Severity Calibration Matrix

Subagents emit `severity: Critical|High|Medium|Low|Info`. The orchestrator may **adjust** severity using this matrix at synthesis time.

## Severity weights

| Severity | Weight |
|----------|-------:|
| Critical | 100 |
| High     | 60 |
| Medium   | 30 |
| Low      | 10 |
| Info     | 1 |

## Modifiers (applied multiplicatively, capped 0.5x to 2.0x)

| Modifier | Factor |
|----------|-------:|
| Finding inside critical flow (auth/payment/admin/crypt) | ×1.5 |
| Bridge node touched | ×1.3 |
| Impact radius ≥ 50 | ×1.4 |
| Impact radius ≥ 20 | ×1.2 |
| Symbol has 0 tests | ×1.2 |
| Confidence ≥ 90 | ×1.1 |
| Confidence ≤ 50 | ×0.7 |
| Already covered by lint/typecheck (assume project enforces) | ×0.5 |

## Overall risk

`overall_score = max(finding_score)` — but if ≥ 2 Critical findings, escalate one rank.

| Score | Overall risk |
|------:|--------------|
| ≥ 100 | CRITICAL |
| ≥ 60 | HIGH |
| ≥ 30 | MEDIUM |
| ≥ 10 | LOW |
| < 10 | INFO |

## Decision

- Any **Critical** after modifiers → BLOCK
- Any **High** after modifiers → APPROVE WITH CHANGES
- Otherwise → APPROVE
```

The orchestrator's Phase 3 must read this file and apply.

- [ ] **Step 23.2: Update orchestrator SKILL.md**

Append a section to `plugins/deep-review/skills/deep-review/SKILL.md`:

```markdown
## Severity calibration

Apply the matrix in `${CLAUDE_PLUGIN_ROOT}/lib/severity-calibration.md` during Phase 3 (Synthesize). Multiply base weight by modifiers; recompute overall risk and decision per the matrix.
```

- [ ] **Step 23.3: Commit**

```bash
git add plugins/deep-review/lib/severity-calibration.md plugins/deep-review/skills/deep-review/SKILL.md
git commit -m "feat(deep-review): add severity calibration matrix"
```

---

## Task 24: `gh pr review` integration — `/deep-review-post`

**Files:**
- Create: `plugins/deep-review/commands/deep-review-post.md`

- [ ] **Step 24.1: Write command**

Create `plugins/deep-review/commands/deep-review-post.md`:

```markdown
---
name: "deep-review-post"
description: Post the latest deep-review report as a PR comment via `gh pr comment` (does not request changes; user retains decision).
category: Code Review
tags: [post, gh, pr]
---

Behavior:

1. Resolve target PR: argument `<pr-number>` or auto-detect from current branch via `gh pr view --json number -q .number`.
2. Locate the latest report under `_deep-review-output/deep-review-<timestamp>-<target>.md`. If multiple, prefer matching `<target>`.
3. Show the user the first 30 lines of the report and ask: **"Post this report to PR #<n>? (y/N)"**.
4. On `y`, run:
   ```bash
   gh pr comment <n> --body-file _deep-review-output/<file>.md
   ```
5. Print the resulting comment URL.

Never use `gh pr review --request-changes` or `--approve`. The plugin only **comments**; the human decides.
```

- [ ] **Step 24.2: Commit**

```bash
git add plugins/deep-review/commands/deep-review-post.md
git commit -m "feat(deep-review): add /deep-review-post (comment-only PR posting)"
```

---

## Task 25: Performance Auditor subagent

**Files:**
- Create: `plugins/deep-review/agents/performance-auditor.md`

- [ ] **Step 25.1: Write agent**

Create `plugins/deep-review/agents/performance-auditor.md`:

```markdown
---
name: performance-auditor
description: Specialist subagent. Detects performance smells in changed code (N+1, sync I/O in hot path, unbounded loops, allocation in tight loops).
tools: Bash, Read, Grep, Glob
---

You are the **Performance Auditor**. Inputs: diff, files, languages, conventions.

## Heuristics

- **N+1**: loop over collection containing DB/HTTP/cache call inside body → High.
- **Unbounded loop**: `while True:` / `for(;;)` without break/timeout → Medium.
- **Quadratic on input size**: nested loop both proportional to N → Medium-High.
- **Sync inside async**: blocking call in coroutine (per language profile rule) → High.
- **Per-call allocation**: object created in hot path (logged or annotated as hot) → Medium.
- **Missing pagination** on list endpoints → High.
- **Missing index hint** when adding query on a column not in known index list (Tier 1 CLAUDE.md may say so) → Medium.
- **Cache stampede**: cache write without lock/single-flight on hot key → High.

## Graph use

`mcp__code-review-graph__get_hub_nodes_tool` to identify hot symbols; weight findings on hubs higher.

## Output

Use IDs `Pf1`, `Pf2`, …. Confidence rarely exceeds 80 (heuristic by nature).
```

- [ ] **Step 25.2: Update orchestrator dispatch table**

Append `performance-auditor` to the table in `skills/deep-review/SKILL.md`. Update Phase 2 dispatch to send the diff to it as well. Findings prefix `Pf`.

- [ ] **Step 25.3: Commit**

```bash
git add plugins/deep-review/agents/performance-auditor.md plugins/deep-review/skills/deep-review/SKILL.md
git commit -m "feat(deep-review): add performance-auditor subagent"
```

---

## Task 26: Documentation Auditor subagent

**Files:**
- Create: `plugins/deep-review/agents/documentation-auditor.md`

- [ ] **Step 26.1: Write agent**

Create `plugins/deep-review/agents/documentation-auditor.md`:

```markdown
---
name: documentation-auditor
description: Specialist subagent. Verifies docstrings/comments, README updates, and migration notes for changed public APIs.
tools: Bash, Read, Grep, Glob
---

You are the **Documentation Auditor**. Inputs: diff, files, languages, conventions.

## Checks

- New public function/class without docstring (per language profile) → Medium.
- Public API signature changed but README/docs not updated → Medium.
- New env var introduced without README mention → Medium.
- New CLI flag without `--help` text → Low.
- New migration without rollback notes → Medium.
- Removed public symbol without deprecation note → High.
- TODO/FIXME added without ticket reference → Low.

## Tier 1 awareness

If CLAUDE.md mandates documentation rules (e.g., "every public exported function must have a JSDoc with `@example`"), apply strictly and cite.

## Output

Use IDs `D1`, `D2`, ….
```

- [ ] **Step 26.2: Update orchestrator (add to dispatch)**

Append `documentation-auditor` to the dispatch table in `skills/deep-review/SKILL.md`. Findings prefix `D`.

- [ ] **Step 26.3: Commit**

```bash
git add plugins/deep-review/agents/documentation-auditor.md plugins/deep-review/skills/deep-review/SKILL.md
git commit -m "feat(deep-review): add documentation-auditor subagent"
```

---

## Task 27: Phase 2 verification + PR

- [ ] **Step 27.1: Validate new files**

Run:
```bash
for f in profiles/java.md profiles/rust.md profiles/csharp.md profiles/php.md profiles/ruby.md \
         lib/severity-calibration.md commands/deep-review-post.md \
         agents/performance-auditor.md agents/documentation-auditor.md; do
  test -f "plugins/deep-review/$f" && echo "OK: $f" || echo "FAIL: $f"
done
```
Expected: every line `OK:`.

- [ ] **Step 27.2: Frontmatter check**

Run the Step 19.3 loop again over the new agent/command files. Expected: every line `OK:`.

- [ ] **Step 27.3: Commit any remaining doc updates and push**

```bash
git push
```

- [ ] **Step 27.4: Update plan progress in PR description (Phase 2 complete)**

Comment on the PR: "Phase 2 complete: 5 new profiles, severity calibration, gh post command, performance & docs auditors."

---

# PHASE 3 — Automation

## Task 28: GitHub Actions workflow template

**Files:**
- Create: `plugins/deep-review/ci/github-actions.yml`

- [ ] **Step 28.1: Write workflow**

Create `plugins/deep-review/ci/github-actions.yml`:

```yaml
# Reusable template for projects that want deep-review on every PR.
# Copy to `.github/workflows/deep-review.yml` in your repo and adjust.
name: Deep Review

on:
  pull_request:
    types: [opened, synchronize, reopened]

permissions:
  contents: read
  pull-requests: write

jobs:
  deep-review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Install uv
        run: curl -LsSf https://astral.sh/uv/install.sh | sh

      - name: Build code graph
        run: uvx code-review-graph build

      - name: Run deep review
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          # Headless invocation example via Claude Code CLI:
          #   claude --print "/deep-review --diff origin/${{ github.base_ref }} --json" \
          #     > deep-review.json
          # JSON mode (Phase 3 of plan) emits structured data for CI parsing.
          echo "Stub — replace with your headless CC invocation."

      - name: Comment on PR
        if: hashFiles('deep-review.md') != ''
        run: gh pr comment ${{ github.event.pull_request.number }} --body-file deep-review.md
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

- [ ] **Step 28.2: Commit**

```bash
mkdir -p plugins/deep-review/ci
git add plugins/deep-review/ci/github-actions.yml
git commit -m "feat(deep-review): add GitHub Actions workflow template"
```

---

## Task 29: Pre-commit hook template

**Files:**
- Create: `plugins/deep-review/ci/pre-commit-hook.sh`

- [ ] **Step 29.1: Write hook**

Create `plugins/deep-review/ci/pre-commit-hook.sh`:

```bash
#!/usr/bin/env bash
# Optional: install as .git/hooks/pre-commit to run deep-review on staged diff.
# This hook is OPT-IN and only warns; it never blocks the commit.
set -e

if ! command -v claude >/dev/null 2>&1; then
  exit 0
fi

DIFF=$(git diff --cached)
if [ -z "$DIFF" ]; then
  exit 0
fi

echo "🔍 Running deep-review on staged changes (warn-only)..."
echo "$DIFF" | claude --print "/deep-review --diff" || true
```

- [ ] **Step 29.2: Add install instructions**

Append to `plugins/deep-review/README.md` under a new `## Optional: pre-commit hook` heading:

```markdown
## Optional: pre-commit hook

```bash
cp plugins/deep-review/ci/pre-commit-hook.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

The hook is **warn-only** — it never blocks a commit.
```

- [ ] **Step 29.3: Commit**

```bash
chmod +x plugins/deep-review/ci/pre-commit-hook.sh
git add plugins/deep-review/ci/pre-commit-hook.sh plugins/deep-review/README.md
git commit -m "feat(deep-review): add opt-in pre-commit hook (warn-only)"
```

---

## Task 30: JSON output mode

**Files:**
- Modify: `plugins/deep-review/skills/deep-review/SKILL.md`

- [ ] **Step 30.1: Append JSON spec**

Append the following section to `plugins/deep-review/skills/deep-review/SKILL.md`:

```markdown
## JSON output mode

When the invocation includes the `--json` flag, Phase 4 emits a JSON object instead of Markdown:

```json
{
  "schema_version": 1,
  "target": "<PR# or diff ref>",
  "timestamp": "<ISO 8601>",
  "mode": "full | degraded-no-graph | degraded-no-gh",
  "overall": {
    "risk": "CRITICAL|HIGH|MEDIUM|LOW|INFO",
    "decision": "BLOCK|APPROVE_WITH_CHANGES|APPROVE",
    "confidence": 0
  },
  "convention_sources": {
    "claude_md_present": true,
    "language_profiles": ["typescript", "python"]
  },
  "findings": [
    {
      "id": "S1",
      "category": "Security",
      "severity": "Critical",
      "file": "src/auth.ts",
      "line": 42,
      "title": "...",
      "detail": "...",
      "source": "OWASP:A03",
      "suggested_fix": "...",
      "confidence": 95,
      "score": 110
    }
  ],
  "positives": ["..."],
  "actions": ["..."]
}
```

JSON mode is intended for CI/CD pipelines. Save to `deep-review.json` instead of `_deep-review-output/*.md` when `--json` is set.
```

- [ ] **Step 30.2: Commit**

```bash
git add plugins/deep-review/skills/deep-review/SKILL.md
git commit -m "feat(deep-review): add --json output mode for CI"
```

---

## Task 31: False-positive feedback store schema

**Files:**
- Create: `plugins/deep-review/lib/feedback-store.md`

- [ ] **Step 31.1: Write spec**

Create `plugins/deep-review/lib/feedback-store.md`:

```markdown
# False-Positive Feedback Store

Local, opt-in. Lives at `${HOME}/.claude/deep-review/feedback.jsonl` (JSON-lines).

## Record schema

```json
{
  "ts": "<ISO 8601>",
  "finding_id": "S1",
  "rule_source": "OWASP:A03",
  "file": "src/auth.ts",
  "line": 42,
  "verdict": "false-positive | true-positive | wont-fix",
  "note": "free text"
}
```

## CLI

A new slash command `/deep-review-feedback` (out of scope for this phase but reserved):
- `dismiss <finding-id> <reason>` — mark as false-positive
- `list` — show last N entries
- `stats` — aggregate by `rule_source`

## Use at synthesis time

The orchestrator MAY downweight findings whose `rule_source` matches an entry with `verdict=false-positive` for the same file (last 90 days). This is heuristic, not authoritative.

Privacy: no upload. Local file only. Users may delete at any time.
```

- [ ] **Step 31.2: Commit**

```bash
git add plugins/deep-review/lib/feedback-store.md
git commit -m "feat(deep-review): spec local false-positive feedback store"
```

---

## Task 32: Phase 3 verification + final PR update

- [ ] **Step 32.1: Validate**

Run:
```bash
for f in ci/github-actions.yml ci/pre-commit-hook.sh lib/feedback-store.md; do
  test -f "plugins/deep-review/$f" && echo "OK: $f" || echo "FAIL: $f"
done
test -x plugins/deep-review/ci/pre-commit-hook.sh && echo "OK: pre-commit-hook executable" || echo "FAIL"
grep -q "JSON output mode" plugins/deep-review/skills/deep-review/SKILL.md && echo "OK: JSON spec present" || echo "FAIL"
```
Expected: every line `OK:` or `OK: ...`.

- [ ] **Step 32.2: Push final commits**

```bash
git push
```

- [ ] **Step 32.3: Comment on PR**

"Phase 3 complete: GitHub Actions template, opt-in pre-commit hook, JSON output mode, feedback store schema. Plugin ready for review."

- [ ] **Step 32.4: Wait for human review and merge**

Do NOT merge. Wait for human approval per the marketplace's PR policy.

---

## Self-Review Checklist (run after writing the plan)

- [ ] Spec coverage: every requirement of the brainstorm (5 sub-agents, CLAUDE.md priority, multi-language, MCP bundling, marketplace registration, slash commands, 3 phases) maps to at least one task.
- [ ] No placeholders: every step has actual content (file path + code/command/expected output).
- [ ] Type/name consistency: subagent IDs (R, S, P, T, C, Pf, D), severity values, marker file paths, and skill file paths are identical across tasks.
- [ ] Branch naming consistent: `feature/deep-review-plugin` everywhere.
- [ ] Marketplace entry name consistent: `deep-review` everywhere.
- [ ] CLAUDE.md priority appears in: orchestrator SKILL, pattern-architecture-critic, convention-checker, documentation-auditor, profiles' headers, and severity-calibration not contradicting it.
