---
name: "spec:propose"
description: Propose a new change - create the change and generate all artifacts (proposal, design, TDD-ready tasks) in one step.
category: Workflow
tags: [spec, openspec, propose, superpowers]
---

Invoke the `openspec-propose` skill using the Skill tool. Pass through any arguments the user provided.

The skill will:
- Create a new OpenSpec change folder
- Generate `proposal.md` (what & why)
- Generate `design.md` (how, including Tech Stack)
- Generate `tasks.md` with Superpowers header + TDD steps

When all artifacts are ready, the user can implement via:
- `/spec:apply` (OpenSpec's built-in task runner), or
- `/superpowers:executing-plans`, or
- `/superpowers:subagent-driven-development`
