---
name: "spec:apply"
description: Implement tasks from an OpenSpec change. Works through pending tasks and marks them complete as you go.
category: Workflow
tags: [spec, openspec, apply, implement]
---

Invoke the `openspec-apply-change` skill using the Skill tool. Pass through any arguments (change name) the user provided.

The skill will:
- Select the change (from argument, context, or prompt user)
- Read proposal/design/specs/tasks for full context
- Work through pending `- [ ]` tasks in order
- Mark each checkbox complete as it finishes
- Pause on blockers or unclear requirements

For richer implementation workflows (TDD + parallel agents), consider using:
- `/superpowers:executing-plans`
- `/superpowers:subagent-driven-development`

directly on the `tasks.md` file instead.
