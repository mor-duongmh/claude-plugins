# Overlay — Mor customizations on top of vendored Superpowers

This folder contains Mor-specific customizations layered on top of the vendored Superpowers content. The sync script applies overlay AFTER copying the vendored layer.

## How overlay works

For each path under `overlay/`, the sync script does:

1. Compute target = `<plugin-root>/<same-relative-path>` (i.e., remove the leading `overlay/`).
2. If target exists → REPLACE it with the overlay file (full replacement).
3. If target does not exist → ADD the overlay file as a new entry.

## Three use cases

| Use case | Overlay path | Effect |
|----------|-------------|--------|
| Override a skill from upstream | `overlay/skills/test-driven-development/SKILL.md` | Replaces vendored after sync |
| Add a Mor-only skill | `overlay/skills/mor-code-style/SKILL.md` | New skill, no upstream collision |
| Override an agent | `overlay/agents/code-reviewer.md` | Replaces vendored agent |

## Start a new overlay

Use the helper:

```bash
./scripts/start-overlay.sh skills/test-driven-development
```

It copies the live vendored skill into `overlay/...` and creates a `.overlay-meta.json` with the base version, so future drift detection (planned for v2) can warn when upstream changes the same file.

## Limitations (v1)

- **Replace mode only.** No append/patch mode — overlay file always replaces the entire target.
- **No automatic drift detection.** When you sync upstream to a newer version that touches an overlaid file, you must manually diff and reconcile.
