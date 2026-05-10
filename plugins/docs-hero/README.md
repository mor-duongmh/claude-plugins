# docs-hero

> BrSE document generation suite (SRS + API + DB) cho ITO Japan offshore. Conflict-minimal updates from OpenSpec/plan, codebase sync với human-gated approval.

## Cài đặt

```
/plugin add marketplace github:mor-duongmh/claude-plugins
/plugin install docs-hero@mor-duongmh
/docs-hero:setup
```

Yêu cầu: Python ≥ 3.9, ~50 MB disk cho venv, ~30-60s lần đầu setup.

Optional: `mmdc` (mermaid CLI) cho QA agent validate Mermaid syntax — nếu thiếu, agent fallback sang sanity check.

## What it does

3 deliverables, 1 single-language output (JP / EN / VN):

| Document | Standard | Owner skill |
|----------|----------|-------------|
| `docs/srs.md` (+ `docs/screen-specs/SCREEN-*.md`) | BrSE template ITO Japan: 13 sections + 2 appendices, IPA-6 NFR | `generate-srs` |
| `docs/api-docs.md` | REST endpoints with cURL, error codes, webhooks | `generate-api-docs` |
| `docs/database-design.md` | Tables + indexes + Mermaid ERD | `generate-db-design` |

Plus a QA agent (`docs-hero`, model `haiku`) that validates cross-references and BrSE-standard quality after every init/update.

## 3 Modes

### `/docs-hero:init`
Render fresh docs from a `ProjectModel` JSON (Pydantic schema in `lib/normalized_schema.py`, ~40 entity types: FR, NFR, UseCase, Screen, DataItem, ExternalInterface, Report, Table, Endpoint, ...).

Before rendering, the orchestrator runs two gates:
1. **Doc-type selection** — pick which of SRS / API docs / DB design to generate.
2. **Gap & Risk analysis** — Claude inspects the parsed inputs, writes `.tmp/docs-plan.md` (§0 Project Overview / §1 per-doc plan / §2 severity-tagged gaps / §3 risks / §4 implementation status snapshot / §5 recommended action per gap: ask / placeholder / drop / assumption) and asks for approval before any doc is written. Unresolved gaps surface in the aggregate report and the QA agent verifies each one is either resolved or carried forward as a `<TBD: …>` placeholder.

**Implementation Status tracking in SRS** — every FR carries an `impl_status` (`NotStarted` ⬜ / `InProgress` 🟡 / `Done` 🟢 / `Verified` 🔵 / `Blocked` 🔴) auto-detected from `openspec/changes`, codebase scan (FR-ID references in source + git log), and test files. SRS §3 renders a dashboard (counts + %) plus an "Impl Status" column in the FR list and an Evidence row in each FR detail — so BrSE/PM see at a glance which functions are done vs still on paper. Manual override in `project-model.json` wins over auto-detect.

### `/docs-hero:update`
Apply Delta from OpenSpec change OR brainstorm plan, **preserving manual edits**. The diff engine:
1. Detect manual edits → preserve those regions
2. Compute patch plan against new Delta
3. Apply atomically with backup

### `/docs-hero:sync` + `/docs-hero:apply-sync`
2-step codebase ↔ docs reconciliation:
1. Scan ORM models + REST routes → write proposal markdown with `[ ]` checkboxes
2. **User reviews + ticks** what to apply
3. `apply-sync` parses ticks → Delta → runs update flow

SRS sync intentionally not supported (requirements ≠ code).

## Synergy với `spec` plugin

```
/spec:propose "feature-X"                          # creates openspec/changes/feature-X/
# (review-checklist gate per Mor workflow)
/spec:apply feature-X                              # implements code
/docs-hero:update --from-openspec feature-X        # syncs SRS/API/DB to match
```

Mor's spec-driven workflow now closes the loop: spec → code → docs.

## Slash Commands

| Command | Purpose |
|---------|---------|
| `/docs-hero:setup` | Bootstrap venv (one-time) |
| `/docs-hero:init` | Fresh docs from ProjectModel JSON |
| `/docs-hero:update` | Apply Delta from OpenSpec or plan |
| `/docs-hero:sync` | Propose codebase changes (read-only) |
| `/docs-hero:apply-sync` | Apply ticked sync proposal |
| `/docs-hero:doctor` | Health check |

## File ownership (in your project)

```
docs/
├── srs.md                          ← generate-srs owns
├── screen-specs/SCREEN-*.md        ← generate-srs owns
├── api-docs.md                     ← generate-api-docs owns
└── database-design.md              ← generate-db-design owns
.docs-hero-meta.json                ← orchestrator owns (gitignored)
.docs-hero.lock                     ← transient (gitignored)
.tmp/                               ← scratch (gitignored)
assets/screens/SCREEN-*-annotated.png  ← generate-srs owns (Pillow + vision)
```

## Troubleshooting

- **`venv: MISSING`** → `/docs-hero:setup`
- **`Python: FAIL`** → Install Python 3.9+
- **`schema: FAIL`** → re-run `/docs-hero:setup` to reinstall pydantic
- **Manual edits lost on update** → File a bug. The diff engine should preserve them; report which file/section.

## Architecture pointers

- Pydantic schema (single source of truth): `skills/docs-hero-orchestrator/scripts/lib/normalized_schema.py` (~803 lines, 40+ entities)
- Diff engine: `compute_diff.py` + `apply_patch.py`
- QA agent: `agents/docs-hero.md` (haiku model, read-only validation)

## License

MIT
