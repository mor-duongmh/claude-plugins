# Mor Claude Plugins

Mor team's Claude Code plugin marketplace. Contains customized workflows for spec-driven development with TDD.

## Plugins

| Plugin | Purpose |
|--------|---------|
| [`mor-openspec`](./plugins/mor-openspec) | OpenSpec skills + `superpowers-driven` schema. Produces `proposal.md`, `design.md`, and TDD-ready `tasks.md` that plug directly into Superpowers `executing-plans` / `subagent-driven-development`. |

> Future: `mor-superpowers` with Mor-specific coding standards and review rules.

## Installation

### 1. Add the marketplace

In Claude Code:

```
/plugin add marketplace github:mor-duongmh/claude-plugins
```

### 2. Install plugins

```
/plugin install mor-openspec@mor-duongmh
```

### 3. Install the schema into your project (one-time per project)

Requires the [OpenSpec CLI](https://github.com/Fission-AI/OpenSpec):

```bash
npm install -g @fission-ai/openspec
openspec init     # if not already initialized
```

Then in Claude Code, invoke the setup skill:

```
/mor-openspec-setup
```

This copies `schemas/superpowers-driven/` into your project's `openspec/schemas/` and (optionally) sets it as the default schema.

## Workflow

```
/opsx:propose         → creates proposal.md, design.md, tasks.md
                        (tasks.md has Superpowers header + TDD steps)
       ↓
/superpowers:executing-plans         (or)
/superpowers:subagent-driven-development
```

## What's different from upstream OpenSpec?

The `superpowers-driven` schema (forked from `spec-driven`) adds:

- **Superpowers header** in `tasks.md`: Goal, Architecture, Tech Stack
- **Tech Stack section** required in `design.md`
- **TDD step structure** in each task group: write failing test → verify fails → implement → verify passes → commit
- **Files block** per task group: explicit Create/Modify/Test paths

## License

MIT
