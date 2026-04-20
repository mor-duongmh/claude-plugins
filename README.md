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

1. **Spec skills** — `propose`, `apply`, `explore`, `archive` for spec-driven change management.
2. **A custom `superpowers-driven` schema** — generated artifacts plug directly into Superpowers (`writing-plans`, `executing-plans`, `subagent-driven-development`) without any bridging work.
3. **Namespaced slash commands** under `/spec:` to avoid conflicts with upstream commands.
4. **Zero external install** — the underlying CLI is invoked via `npx`; the user does not need to run `npm install -g` first.
5. **Auto-prompt** — when a project has an `openspec/` folder but no schema yet, the plugin politely suggests running `/spec:setup` on the first session. Nothing is copied without confirmation.

---

## Plugins

| Plugin | Version | Purpose |
|--------|---------|---------|
| [`spec`](./plugins/spec) | `0.3.0` | Spec skills + `superpowers-driven` schema. Artifacts are TDD-ready and consumable by Superpowers. |

> **Roadmap:** A second plugin `mor-superpowers` with Mor-specific coding standards and review rules is planned — see [Roadmap](#roadmap).

---

## Quick start

### Prerequisites

- [Claude Code](https://docs.anthropic.com/claude/docs/claude-code) installed
- Node.js ≥ 18 on `PATH` (needed so `npx` can run the spec CLI on demand)

No global `npm install` required.

### 1. Add the marketplace (once per machine)

In Claude Code:

```
/plugin add marketplace github:mor-duongmh/claude-plugins
```

### 2. Install the `spec` plugin (once per machine)

```
/plugin install spec@mor-duongmh
```

That's it. When you open a project the plugin will detect whether the spec workflow is set up:

- **New project (no `openspec/`):** run `/spec:setup` when you want to start using the workflow. The command will offer to initialize OpenSpec and install the schema.
- **Existing project with `openspec/` but no schema yet:** the plugin auto-prompts on session start, asking whether you want to install the schema. Reply "skip" (or create `openspec/.spec-setup-skip`) to mute the prompt for that project.
- **Fully set-up project:** nothing happens — just start using `/spec:propose` etc.

`/spec:setup` always confirms the resolved path before writing; it never copies files silently.

---

## Slash commands

All commands are namespaced under `/spec:`.

| Command | Arguments | Purpose |
|---------|-----------|---------|
| `/spec:setup` | `[path]` (optional absolute path) | Initialize the workflow in a project: offer `openspec init` if needed, install the `superpowers-driven` schema, optionally set it as default |
| `/spec:explore` | — | Thinking-partner mode — investigate, ask questions, don't implement |
| `/spec:propose` | `[description]` (optional) | Create a new change with proposal + design + TDD-ready tasks |
| `/spec:apply` | `[change-name]` (optional) | Walk through pending tasks and implement (native runner) |
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

Forked from the upstream default schema and modified in 3 places:

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

### The auto-prompt keeps appearing on a project I don't want to set up

Create an empty file to mute it:

```bash
touch openspec/.spec-setup-skip
```

### `schema validate superpowers-driven` fails

The schema may have been partially copied. Delete `openspec/schemas/superpowers-driven/` and re-run `/spec:setup`.

### Commands appear as `/mor-openspec:*` instead of `/spec:*`

You're on an older cached copy of the plugin. Update and reinstall:

```
/plugin update spec@mor-duongmh
```

### Conflicts with `/opsx:*` commands

No conflict — `/spec:*` and `/opsx:*` are independent namespaces and can coexist. The `spec` plugin wraps the same underlying skills, so you can use either.

### `npx` is slow on first run

The first `/spec:setup` downloads `@fission-ai/openspec` into the local npm cache. Subsequent runs are instant.

---

## Roadmap

- [ ] `mor-superpowers` plugin — forked Superpowers skills customized for Mor's coding standards, review rules, and commit conventions.
- [ ] CI validation on every push (`schema validate superpowers-driven`).
- [ ] Optional telemetry to track schema adoption across Mor projects.

---

## License

[MIT](LICENSE) © Mor
