---
name: "deep-review"
description: Run a deep multi-agent code review on a PR or git diff. Produces a Markdown matrix report with risk, security, design pattern, test coverage, and convention findings.
category: Code Review
tags: [code-review, security, risk, pattern, tests]
---

Invoke the `deep-review` skill via the Skill tool. Pass through any arguments the user provided as `<target>`:

- `/deep-review 123` → review PR #123
- `/deep-review #123` → review PR #123
- `/deep-review --diff` → review uncommitted changes vs HEAD
- `/deep-review --diff main` → review HEAD vs main
- `/deep-review` → defaults to `--diff`
- `/deep-review --json` → emit JSON instead of Markdown (CI/CD mode)

The skill orchestrates 5 parallel subagents and prints a full Markdown report directly to chat. It also saves a copy under `_deep-review-output/` if the directory is writable.

If `gh` is missing for a PR target, the skill exits with installation instructions.
If the code-review-graph MCP is unavailable, the skill runs in degraded mode and notes this in the report header.
