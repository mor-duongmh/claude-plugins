# Mor Claude Plugins

> Mor team's Claude Code plugin marketplace — spec-driven development with TDD, wired to work seamlessly with Superpowers.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Plugin-orange.svg)](https://docs.anthropic.com/claude/docs/claude-code)

---

## Table of contents

- [Overview](#overview)
- [Plugins](#plugins)
- [Quick start](#quick-start)
- [Slash commands](#slash-commands)
- [Workflow](#workflow)
- [What's inside the `superpowers-driven` schema?](#whats-inside-the-superpowers-driven-schema)
- [Troubleshooting](#troubleshooting)
- [Roadmap](#roadmap)
- [License](#license)

---

## Overview

This marketplace ships a single plugin — **`spec`** — that bundles:

1. **OpenSpec skills** — `propose`, `apply`, `explore`, `archive` for spec-driven change management.
2. **A custom `superpowers-driven` schema** — a fork of OpenSpec's default `spec-driven` schema, tuned so every generated artifact plugs directly into Superpowers (`writing-plans`, `executing-plans`, `subagent-driven-development`) without any bridging work.
3. **Namespaced slash commands** under `/spec:` so there are no conflicts with the upstream `/opsx:` commands.

---

## Plugins

| Plugin | Version | Purpose |
|--------|---------|---------|
| [`spec`](./plugins/spec) | `0.2.0` | OpenSpec skills + `superpowers-driven` schema. Artifacts are TDD-ready and consumable by Superpowers. |

> **Roadmap:** A second plugin `mor-superpowers` with Mor-specific coding standards and review rules is planned — see [Roadmap](#roadmap).

---

## Quick start

### Prerequisites

- [Claude Code](https://docs.anthropic.com/claude/docs/claude-code) installed
- Node.js ≥ 18 (for the OpenSpec CLI)
- [OpenSpec CLI](https://github.com/Fission-AI/OpenSpec) installed globally:
  ```bash
  npm install -g @fission-ai/openspec
  ```

### 1. Add the marketplace (once per machine)

In Claude Code:

```
/plugin add marketplace github:mor-duongmh/claude-plugins
```

### 2. Install the `spec` plugin (once per machine)

```
/plugin install spec@mor-duongmh
```

### 3. Set up a project (once per project)

Initialize OpenSpec in your project if you haven't:

```bash
cd /path/to/your-project
openspec init
```

Then install the `superpowers-driven` schema. You can either:

**Option A — run from inside the target project:**
```
/spec:setup
```

**Option B — pass an absolute path:**
```
/spec:setup /Users/you/projects/your-project
```

The setup command **always confirms the resolved path before writing**. Nothing is copied silently.

---

## Slash commands

All commands are namespaced under `/spec:` to avoid conflicts with OpenSpec's built-in `/opsx:` commands.

| Command | Arguments | Purpose |
|---------|-----------|---------|
| `/spec:setup` | `[path]` (optional absolute path) | Install the `superpowers-driven` schema into a project |
| `/spec:explore` | — | Thinking-partner mode — investigate, ask questions, don't implement |
| `/spec:propose` | `[description]` (optional) | Create a new change with proposal + design + TDD-ready tasks |
| `/spec:apply` | `[change-name]` (optional) | Walk through pending tasks and implement (OpenSpec-native) |
| `/spec:archive` | `[change-name]` (optional) | Archive a completed change and sync delta specs |

---

## Workflow

```
┌──────────────────────────────────────────────────────────────┐
│  /spec:explore          (optional — think before committing) │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────┐
│  /spec:propose                                                │
│    Generates:                                                 │
│      • proposal.md   (what & why)                             │
│      • design.md     (how + Tech Stack)                       │
│      • tasks.md      (Superpowers header + TDD steps)         │
└──────────────────────────────────────────────────────────────┘
                              │
          ┌───────────────────┼───────────────────┐
          ▼                   ▼                   ▼
  ┌──────────────┐   ┌──────────────────┐   ┌────────────────────┐
  │ /spec:apply  │   │ /superpowers:    │   │ /superpowers:      │
  │ (native)     │   │ executing-plans  │   │ subagent-driven-   │
  │              │   │ (TDD discipline) │   │ development        │
  └──────────────┘   └──────────────────┘   │ (parallel agents)  │
                                             └────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────┐
│  /spec:archive      (once implementation + merge complete)    │
└──────────────────────────────────────────────────────────────┘
```

Because `tasks.md` already contains the Superpowers header (Goal, Architecture, Tech Stack) and per-task TDD steps with explicit file paths, you can hand it straight to `/superpowers:executing-plans` with **no manual rewriting**.

---

## What's inside the `superpowers-driven` schema?

Forked from OpenSpec's default `spec-driven` and modified in 3 places:

### 1. `design.md` gains a `## Tech Stack` section

Needed so the downstream `tasks.md` header can reference a real tech stack without the AI guessing.

### 2. `tasks.md` template starts with the Superpowers header

```markdown
> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** <one sentence>
**Architecture:** <2-3 sentences>
**Tech Stack:** <pulled from design.md>
```

### 3. Each task group follows TDD structure

```markdown
## 1. <group name>

**Files:**
- Create: `path/to/new/file`
- Modify: `path/to/existing/file`
- Test:   `path/to/test/file`

- [ ] 1.1 Write failing test for <behavior>
- [ ] 1.2 Run test — verify it fails
- [ ] 1.3 Implement <minimal code>
- [ ] 1.4 Run tests — verify passing
- [ ] 1.5 Commit
```

The matching `schema.yaml` instructions enforce these rules so AI-generated artifacts stay consistent across every change.

---

## Troubleshooting

### `/spec:setup` says "OpenSpec is not initialized"

Run `openspec init` in the target project first, then retry.

### `openspec schema validate superpowers-driven` fails

The schema may have been partially copied. Delete `openspec/schemas/superpowers-driven/` and re-run `/spec:setup`.

### Commands appear as `/mor-openspec:*` instead of `/spec:*`

You're on an older cached copy of the plugin. Update the marketplace and reinstall:

```
/plugin update spec@mor-duongmh
```

### Conflicts with `/opsx:*` commands

No conflict — `/spec:*` and `/opsx:*` are independent namespaces and can coexist. The `spec` plugin wraps the same underlying OpenSpec skills, so you can use either.

---

## Roadmap

- [ ] `mor-superpowers` plugin — forked Superpowers skills customized for Mor's coding standards, review rules, and commit conventions.
- [ ] Optional `SessionStart` hook in `spec` to auto-prompt schema installation when opening an OpenSpec project without the schema.
- [ ] Replace global `openspec` install with bundled `npx @fission-ai/openspec` calls so the plugin requires zero external installs.
- [ ] CI validation on every push (`openspec schema validate superpowers-driven`).

---

## License

[MIT](LICENSE) © Mor
