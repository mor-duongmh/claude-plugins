---
name: "spec:setup"
description: Install the Mor superpowers-driven OpenSpec schema into a specific project. Requires an absolute path argument OR being inside the target project directory.
category: Setup
tags: [spec, openspec, setup, schema]
---

Invoke the `spec-setup` skill using the Skill tool. Pass through any path argument the user provided.

The skill will:
- Resolve the target project path (from argument or cwd)
- Confirm the path with the user before any write
- Verify OpenSpec is initialized (or offer to init it)
- Copy `schemas/superpowers-driven/` into `<project>/openspec/schemas/`
- Validate the installed schema
- Optionally set it as the project's default schema

**Usage:**
```
/spec:setup                          # uses current working directory
/spec:setup /absolute/path/to/proj   # uses explicit path
```

Never installs silently — always confirms before writing.
