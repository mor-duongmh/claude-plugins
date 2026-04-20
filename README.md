# Mor Claude Plugins

Mor team's Claude Code plugin marketplace. Contains customized workflows for spec-driven development with TDD.

## Plugins

| Plugin | Purpose |
|--------|---------|
| [`spec`](./plugins/spec) | Spec-driven workflow: OpenSpec skills + `superpowers-driven` schema. Produces `proposal.md`, `design.md`, and TDD-ready `tasks.md` that plug directly into Superpowers `executing-plans` / `subagent-driven-development`. |

> Future: `mor-superpowers` with Mor-specific coding standards and review rules.

## Installation

### 1. Add the marketplace

In Claude Code:

```
/plugin add marketplace github:mor-duongmh/claude-plugins
```

### 2. Install the `spec` plugin

```
/plugin install spec@mor-duongmh
```

### 3. Install the schema into your project (one-time per project)

Requires the [OpenSpec CLI](https://github.com/Fission-AI/OpenSpec):

```bash
npm install -g @fission-ai/openspec
openspec init     # if not already initialized
```

Then in Claude Code, invoke the setup command **from inside the target project** OR pass the project path explicitly:

```
# Option A: cd into the target project, then run
/spec:setup

# Option B: pass the absolute path
/spec:setup /absolute/path/to/project
```

The setup command always confirms the resolved path with you before writing. It copies `schemas/superpowers-driven/` into the project's `openspec/schemas/` and (optionally) sets it as the default schema.

## Slash commands

All commands are namespaced under `/spec:`.

| Command | Purpose |
|---------|---------|
| `/spec:setup [path]` | Install the `superpowers-driven` schema into a project |
| `/spec:explore` | Thinking-partner mode: explore ideas, investigate before committing to a change |
| `/spec:propose` | Create a new change with proposal + design + TDD-ready tasks |
| `/spec:apply [change]` | Walk through the tasks and implement them (OpenSpec-native) |
| `/spec:archive [change]` | Archive a completed change and sync specs |

## Workflow

```
/spec:propose         → creates proposal.md, design.md, tasks.md
                        (tasks.md has Superpowers header + TDD steps)
       ↓
/spec:apply                          (OpenSpec-native implementation)
    or
/superpowers:executing-plans         (TDD discipline)
    or
/superpowers:subagent-driven-development   (parallel agents)
       ↓
/spec:archive         → archive + sync specs when done
```

## What's different from upstream OpenSpec?

The `superpowers-driven` schema (forked from `spec-driven`) adds:

- **Superpowers header** in `tasks.md`: Goal, Architecture, Tech Stack
- **Tech Stack section** required in `design.md`
- **TDD step structure** in each task group: write failing test → verify fails → implement → verify passes → commit
- **Files block** per task group: explicit Create/Modify/Test paths

## License

MIT
