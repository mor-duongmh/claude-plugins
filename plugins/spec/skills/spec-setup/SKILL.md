---
name: spec-setup
description: Install the Mor superpowers-driven OpenSpec schema into a specific project. Requires the user to either pass the project path as an argument OR run Claude Code from within the target project directory. Use when setting up a project to use OpenSpec with Superpowers-compatible artifacts.
license: MIT
---

Install the Mor `superpowers-driven` schema into a target project's `openspec/schemas/` directory so OpenSpec artifacts become TDD-ready and consumable by Superpowers (`writing-plans`, `executing-plans`, `subagent-driven-development`).

**CRITICAL SAFETY RULE:** Never install into a path the user did not explicitly specify. The target project MUST be resolved from one of:
1. An explicit path argument the user passed to the skill, OR
2. The current working directory (cwd), confirmed by the user before copying.

If neither condition is met, stop and ask the user to provide a path.

---

**Steps**

1. **Resolve the target project path**

   - If the user provided a path as an argument (e.g. `/mor-openspec-setup /Users/me/projects/foo`), use that.
   - Otherwise, run `pwd` to get cwd.
   - The resolved path MUST be an absolute path — if it is relative, fail with:
     > "Please pass an absolute path, or cd into the target project first."

2. **Confirm the target with the user**

   Use the **AskUserQuestion tool** to confirm:
   > "Install the `superpowers-driven` schema into this project?
   >
   > **Path:** `<resolved-path>`
   >
   > This will create `<resolved-path>/openspec/schemas/superpowers-driven/`."

   Options:
   - "Yes, install here"
   - "No, cancel"

   If the user cancels, stop with a status message.

   **IMPORTANT:** Do NOT skip this confirmation even if a path argument was provided. Copying files into the wrong project is irreversible friction.

3. **Verify OpenSpec is initialized in the target project**

   Check if `<path>/openspec/` exists.
   - If NO: stop and tell the user:
     > "This project is not OpenSpec-initialized. Run `cd <path> && openspec init` first, then retry."

4. **Locate the schema source**

   The schema ships with this plugin at `${CLAUDE_PLUGIN_ROOT}/schemas/superpowers-driven/`.

   ```bash
   ls "$CLAUDE_PLUGIN_ROOT/schemas/superpowers-driven"
   ```

   If the directory is missing, stop with an install error — do not attempt a fallback.

5. **Check for existing schema in the target project**

   If `<path>/openspec/schemas/superpowers-driven/` already exists:
   - Use **AskUserQuestion tool** to confirm overwrite.
   - If the user declines, stop with a status message.

6. **Copy the schema**

   ```bash
   mkdir -p "<path>/openspec/schemas"
   cp -R "$CLAUDE_PLUGIN_ROOT/schemas/superpowers-driven" "<path>/openspec/schemas/"
   ```

7. **Validate the installed schema**

   ```bash
   cd "<path>" && openspec schema validate superpowers-driven
   ```

   If validation fails, report the error and stop — do not claim success.

8. **Offer to set as default schema**

   Use **AskUserQuestion tool** with options:
   - "Yes, set as default" → update `<path>/openspec/config.yaml` → `schema: superpowers-driven`
   - "No, keep current default" → skip

   Never modify `config.yaml` without explicit user confirmation.

9. **Report success**

   ```
   ## Mor OpenSpec Setup Complete

   **Target project:** <path>
   **Schema installed:** <path>/openspec/schemas/superpowers-driven/
   **Default schema:** <superpowers-driven | unchanged>

   You can now create changes with:
   - `/opsx:propose` (uses default schema)
   - `openspec new change <name> --schema superpowers-driven`

   Artifacts will be TDD-ready and compatible with:
   - `superpowers:executing-plans`
   - `superpowers:subagent-driven-development`
   ```

---

**Guardrails**

- **Never guess the target path.** If the user invoked the skill with no argument and cwd is something ambiguous (e.g. `$HOME`, `/tmp`, a parent of multiple projects), ask for an explicit path instead of proceeding.
- Always confirm the resolved path with the user before the first write.
- Never overwrite an existing schema without user confirmation.
- Never edit `openspec/config.yaml` without user confirmation.
- Stop on validation failure — do not pretend success.
- Never run the copy from a SessionStart hook or any automatic trigger; this skill must be invoked intentionally.
