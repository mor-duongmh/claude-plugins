---
name: generate-srs
description: "Generate or update Software Requirements Specification (SRS) following BrSE standards for ITO Japan. Renders the BrSE template-updated structure (13 sections + 2 appendices: Doc Control, Overview, Business Flow with UC detail, FR detail, Business Rules, Roles & Permissions, NFR with IPA-6 categories + Security/PII, Data Items with retention, External Interfaces, Reports, Acceptance/UAT, Traceability, Open Q&A, Constraints/Assumptions/Risks, Screen Index, Glossary). Init mode generates srs.md + per-screen specs from ProjectModel JSON; update mode applies a Delta to existing docs preserving manual edits."
category: documentation
keywords: [srs, brse, requirements, japanese-ito, screen-design, ipa-nfr, traceability, acceptance-criteria]
argument-hint: "init|update [options]"
metadata:
  author: docs-hero
  version: "2.0.0"
---

# Generate SRS Skill

Sub-skill for generating SRS + per-screen design specs. Owns `docs/srs.md` and
`docs/screen-specs/SCREEN-*.md`. Single-language output (JP / EN / VN).

## Output Structure (template-updated)

13 numbered sections + 2 appendices:

| § | Section | Entities |
|---|---------|---------|
| 0 | Document Control Rules | (status & priority definitions) |
| 1 | Overview | TargetRelease, Reference (REF), OpenQuestion (Q), Stakeholder |
| 2 | Current State & Business Flow | Issue (ISSUE), UseCase (UC) with detail |
| 3 | Functional Requirements | FunctionalRequirement (FR) with validation/permission/audit/AC/test viewpoints |
| 4 | Business Rules | BusinessRule (BR) |
| 5 | Roles & Permissions | Role (ROLE), PermissionEntry matrix |
| 6 | Non-Functional Requirements | NFR (IPA-6 categories), SecurityPiiItem |
| 7 | Data Items | EntityDef (ENT), DataItem (DATA), DataRetention |
| 8 | External Interfaces | ExternalInterface (INT) + file-interface detail |
| 9 | Reports & Files | Report (RPT), ReportItem |
| 10 | Acceptance Criteria & UAT | AcceptanceCriterion (AC), UatCriterion |
| 11 | Traceability Matrix | TraceabilityRow (auto-derived from FR if absent) |
| 12 | Open Issues & Q&A | OpenQuestion (Q) |
| 13 | Constraints, Assumptions & Risks | Constraint (CONS), Assumption (ASM), Risk (RISK) |
| A | Screen Index | Screen (SCREEN) |
| B | Glossary | GlossaryEntry |

## Modes

## Modes

| Mode | Purpose |
|---|---|
| `init` | Render SRS + screen specs from a ProjectModel JSON |
| `update` | Apply Delta filtered for SRS scope (FR/NFR/SCREEN/DATA/INT/UC/BR/ROLE/RPT/AC/Q/CONS/ASM/ENT/REF/RISK/ISSUE) |

## Init Workflow

```bash
python scripts/render_srs.py \
  --project-model {path}.json \
  --template templates/srs-template.md \
  --language JP|EN|VN \
  --output docs/srs.md

# Per screen:
python scripts/render_screen_spec.py \
  --project-model {path}.json \
  --screen-id SCREEN-001 \
  --template templates/screen-spec-template.md \
  --language JP \
  --output docs/screen-specs/SCREEN-001-{slug}.md

# If user provided mockup image at assets/screens/SCREEN-001-{slug}.png:
#   1. Use Read tool on the image (Claude vision native)
#   2. Apply prompt from references/screen-vision-prompt.md
#   3. Save vision JSON to .tmp/mockup-SCREEN-001.json
#   4. Run annotate_mockup.py to draw numbered circles
python scripts/annotate_mockup.py \
  --image assets/screens/SCREEN-001-login.png \
  --items .tmp/mockup-SCREEN-001.json \
  --output assets/screens/SCREEN-001-login-annotated.png
```

## Update Workflow

The orchestrator pre-filters the Delta to SRS-relevant entity types
(FR, NFR, SCREEN, DATA, INT) and runs the standard diff-engine flow:

```bash
python {orchestrator}/detect_manual_edits.py --doc docs/srs.md --meta {meta} --output edits.json
python {orchestrator}/compute_diff.py --delta srs-delta.json --doc docs/srs.md --manual-edits edits.json --output plan.json
python {orchestrator}/apply_patch.py --plan plan.json --doc docs/srs.md --meta {meta}
```

Sub-skill responsibility on update: re-resolve mockups for any new/changed
screens, then re-run `render_screen_spec.py` for those screens.

## Sync Mode

**Not supported.** Requirements cannot be inferred from code — only init + update.

## File Ownership

This skill owns:
- `docs/srs.md`
- `docs/screen-specs/SCREEN-*.md`
- `assets/screens/*-annotated.png`

It does **not** modify:
- `docs/api-docs.md`
- `docs/database-design.md`
- Original mockup images at `assets/screens/SCREEN-*.{png,jpg,webp}`

## References

- `templates/srs-template.md` — full SRS structure (BrSE standard)
- `templates/screen-spec-template.md` — per-screen detail with numbered items
- `references/brse-srs-standard.md` — IPA non-functional categories + numbering
- `references/screen-vision-prompt.md` — Claude vision prompt for mockup analysis
