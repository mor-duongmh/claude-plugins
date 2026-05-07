---
name: docs-hero
description: "Generate or update full project documentation suite (SRS + API Docs + DB Design) following BrSE standards for ITO Japan. Single entry point orchestrating 3 sub-skills with conflict-minimal updates from OpenSpec changes or brainstorm plans. Supports init / update / sync."
category: documentation
keywords: [docs, srs, api, database, brse, openspec, ito, japan]
argument-hint: "init|update|sync|apply-sync|rebuild-meta [options]"
metadata:
  author: docs-hero
  version: "1.0.0"
---

# Docs Hero Orchestrator

Single entry point for the documentation generation pipeline. Coordinates three
sub-skills (`generate-srs`, `generate-api-docs`, `generate-db-design`) with shared
parsers, the diff engine, atomic write, and a session lock.

## Operations

| Command | Purpose |
|---|---|
| `/docs-hero init` | Create docs from inputs (PDF/Excel/Docx/OpenSpec + codebase) |
| `/docs-hero update --from-plan {path}` | Apply changes from a brainstorm plan.md |
| `/docs-hero update --from-openspec [name]` | Apply 1 OpenSpec change |
| `/docs-hero sync` | Generate sync proposals (codebase → docs) — read-only |
| `/docs-hero apply-sync --proposal {path}` | Apply approved sync proposal |
| `/docs-hero rebuild-meta` | Bootstrap `.docs-hero-meta.json` from existing docs |

## Routing Logic

Parse first arg:
- `init` → init flow (collect inputs → parse → render all 3 docs)
- `update` → parse `--from-{plan,openspec}` → Delta → diff engine → apply
- `sync` → fan out to sub-skills' `*_sync_propose.py` (no doc mutation)
- `apply-sync` → call sub-skill's `*_sync_apply.py` to convert proposal → Delta → run update
- `rebuild-meta` → meta-manager rebuild
- empty → AskUserQuestion (5 operations)

## Init Flow

```bash
# 1. Collect inputs (AskUserQuestion when interactive)
#    - outputs: [SRS, API, DB] (multi-select)
#    - language: JP|EN|VN (single)
#    - codebase paths (optional)
#    - input docs path

# 2. Parse inputs → ProjectModel JSON
python scripts/parse_inputs.py --inputs {dir} --output .tmp/raw-bundle.json
# (apply OpenSpec / plan parsers here if applicable)

# 3. Dispatch to sub-skills (parallel or serial)
python scripts/dispatch_coordinator.py init \
  --project-model .tmp/project-model.json \
  --language EN \
  --outputs srs,api,db \
  --docs-dir docs/

# 4. Aggregate report
python scripts/aggregate_report.py --docs-dir docs/ --output .tmp/init-report.md

# 5. Spawn docs-hero agent for QA review
```

## Update Flow

```bash
# 1. Parse delta source
python scripts/parse_plan.py     --plan {plan.md}      --output .tmp/delta.json
# OR
python scripts/parse_openspec.py --change-dir {path}   --output .tmp/delta.json

# 2. For each affected doc (filter Delta by entity_type):
python scripts/detect_manual_edits.py --doc {doc} --meta {meta} --output edits.json
python scripts/compute_diff.py --delta .tmp/delta.json --doc {doc} \
                               --manual-edits edits.json --output plan.json
python scripts/apply_patch.py --plan plan.json --doc {doc} --meta {meta}

# 3. Aggregate + spawn docs-hero agent
```

The `dispatch_coordinator.py` automates the per-doc filter + diff + apply chain.

## Sync Flow (2-step)

Step 1 — propose:
```bash
python ../generate-api-docs/scripts/api_sync_propose.py ...
python ../generate-db-design/scripts/db_sync_propose.py ...
# SRS sync not supported (requirements cannot be inferred from code)
```

Step 2 — apply (after user ticks checkboxes):
```bash
python ../generate-api-docs/scripts/api_sync_apply.py ... → delta.json → standard update flow
```

## Lock Acquisition (mutating ops only)

Before any mutate:
1. `python scripts/lock_manager.py acquire`
2. If lock exists + valid (PID alive, < 1h) → exit
3. If stale → cleanup + acquire
4. On exit → release

Read-only ops (sync propose, rebuild-meta verify) skip the lock.

## File Ownership

The orchestrator owns:
- `.docs-hero-meta.json` (sidecar, gitignored)
- `.docs-hero.lock` (transient, gitignored)
- Coordination scripts in `scripts/`

Sub-skills own their respective doc files (see each `SKILL.md`).

## References

- Templates: each sub-skill's `templates/`
- Phase specs: `plans/260503-2222-generate-prd-skill/phase-*.md`
- Schema: `scripts/lib/normalized_schema.py` (Pydantic single source of truth)
- Diff engine: `scripts/compute_diff.py` + `scripts/apply_patch.py`
