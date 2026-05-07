---
name: generate-api-docs
description: "Generate or update REST API documentation. Init mode renders api-docs.md from ProjectModel; update mode applies a Delta to existing docs; sync is a 2-step propose→apply that scans the codebase and asks the user to pick which discoveries to apply."
category: documentation
keywords: [api-docs, rest, openapi, codebase-sync]
argument-hint: "init|update|sync|apply-sync [options]"
metadata:
  author: docs-hero
  version: "1.0.0"
---

# Generate API Docs Skill

Sub-skill that owns `docs/api-docs.md`. Single-language output (JP / EN / VN).

## Modes

| Mode | Purpose |
|---|---|
| `init` | Render `docs/api-docs.md` from a ProjectModel JSON |
| `update` | Apply Delta filtered for API scope (ENDPOINT/ERROR_CODE/WEBHOOK/AUTH/RATE_LIMIT) |
| `sync` | Scan codebase, write a human-readable proposal — DOES NOT touch docs |
| `apply-sync` | Read proposal (with user-checked boxes) → convert to Delta → apply |

## Init Workflow

```bash
python scripts/render_api_docs.py \
  --project-model {path}.json \
  --language JP|EN|VN \
  --output docs/api-docs.md
```

Resource grouping: endpoints whose path shares a first segment go in one section (e.g. `/users`, `/users/{id}` → "Users Resource").

Section IDs (stable for diff engine):

```
ENDPOINT-GET-users
ENDPOINT-GET-users-by-id
ENDPOINT-POST-users
ENDPOINT-DELETE-users-by-id
ERR-USER_NOT_FOUND
WEBHOOK-users-created
```

## Update Workflow

The orchestrator pre-filters Delta to API scope, then runs the standard diff-engine flow:

```bash
python {orchestrator}/detect_manual_edits.py --doc docs/api-docs.md --meta {meta} --output edits.json
python {orchestrator}/compute_diff.py --delta api-delta.json --doc docs/api-docs.md --manual-edits edits.json --output plan.json
python {orchestrator}/apply_patch.py --plan plan.json --doc docs/api-docs.md --meta {meta}
```

## Sync Workflow (2-step, report before add)

### Step 1: propose

```bash
python scripts/api_sync_propose.py \
  --codebase-paths "src/api,src/routes" \
  --existing-doc docs/api-docs.md \
  --output .tmp/api-sync-proposal.md
```

Generates a markdown proposal with `[ ]` / `[x]` checkboxes for ADD / UPDATE / DEPRECATE candidates. **No doc changes.** User edits the file, ticks checkboxes, then runs apply-sync.

### Step 2: apply-sync

```bash
python scripts/api_sync_apply.py \
  --proposal .tmp/api-sync-proposal.md \
  --output .tmp/api-delta.json
```

Parses the proposal, extracts checked items, emits a Delta JSON. The orchestrator then runs the standard update flow with that Delta.

## File Ownership

This skill owns:
- `docs/api-docs.md`

It does **not** modify:
- `docs/srs.md`
- `docs/database-design.md`

## References

- `templates/api-docs-template.md` — full structure reference
- `references/api-docs-conventions.md` — REST patterns + error code conventions
