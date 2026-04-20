---
name: mor-openspec-setup
description: Install the Mor superpowers-driven OpenSpec schema into the current project. Use when setting up a new project to use OpenSpec with Superpowers-compatible artifacts, or when the user asks to install the Mor OpenSpec schema.
license: MIT
---

Install the Mor `superpowers-driven` schema into the current project's `openspec/schemas/` directory so OpenSpec artifacts are ready to be consumed by Superpowers skills (`writing-plans`, `executing-plans`, `subagent-driven-development`).

**Input**: None required.

**Steps**

1. **Verify OpenSpec is initialized**

   Check if `openspec/` exists in the project root.
   - If NO: tell the user to run `openspec init` first and stop.
   - If YES: continue.

2. **Locate the schema source**

   The schema is bundled with this plugin at `${CLAUDE_PLUGIN_ROOT}/schemas/superpowers-driven/`.

   Use Bash to resolve the path:
   ```bash
   echo "$CLAUDE_PLUGIN_ROOT/schemas/superpowers-driven"
   ```

3. **Check for existing schema**

   If `openspec/schemas/superpowers-driven/` already exists:
   - Use **AskUserQuestion tool** to confirm overwrite
   - If user declines, stop with a status message.

4. **Copy the schema**

   ```bash
   mkdir -p openspec/schemas
   cp -R "$CLAUDE_PLUGIN_ROOT/schemas/superpowers-driven" openspec/schemas/
   ```

5. **Validate the installed schema**

   ```bash
   openspec schema validate superpowers-driven
   ```

   If validation fails, report the error and stop.

6. **Offer to set as default schema**

   Use **AskUserQuestion tool** with options:
   - "Yes, set as default" → update `openspec/config.yaml` to `schema: superpowers-driven`
   - "No, keep current default" → stop

7. **Report success**

   ```
   ## Mor OpenSpec Setup Complete

   **Schema installed:** openspec/schemas/superpowers-driven/
   **Default schema:** <superpowers-driven | unchanged>

   You can now create changes with:
   - `/opsx:propose` (uses default schema)
   - `openspec new change <name> --schema superpowers-driven`

   Artifacts will be TDD-ready and compatible with:
   - `superpowers:executing-plans`
   - `superpowers:subagent-driven-development`
   ```

**Guardrails**
- Never overwrite existing schema without user confirmation
- Never modify `openspec/config.yaml` without user confirmation
- Stop on validation failure — do not pretend success
