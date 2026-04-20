---
name: "spec:archive"
description: Archive a completed OpenSpec change after implementation is complete. Syncs delta specs into main specs and moves the change folder to archive.
category: Workflow
tags: [spec, openspec, archive, finalize]
---

Invoke the `openspec-archive-change` skill using the Skill tool. Pass through any arguments (change name) the user provided.

The skill will:
- Prompt the user to select a change (or use argument)
- Verify artifact + task completion
- Compare delta specs with main specs and offer to sync
- Move the change folder to `openspec/changes/archive/YYYY-MM-DD-<name>/`

Run this once a change is fully implemented and merged.
