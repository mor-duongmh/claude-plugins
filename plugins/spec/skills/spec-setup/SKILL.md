---
name: spec-setup
description: Set up the Mor spec-driven workflow in a specific project. Auto-initializes OpenSpec if needed and installs the superpowers-driven schema. Requires the user to either pass the project path as an argument OR run Claude Code from within the target project directory.
license: MIT
---

Set up the Mor spec-driven workflow in a target project in a single step:

1. Run `openspec init` if the project isn't already initialized.
2. Install the `superpowers-driven` schema into `openspec/schemas/`.
3. Optionally set it as the project's default schema.

All OpenSpec commands are invoked via `npx -y @fission-ai/openspec@latest` — the user does NOT need `@fission-ai/openspec` installed globally.

---

**CRITICAL SAFETY RULES**

- Never write into a path the user did not explicitly specify. The target MUST come from:
  1. An explicit path argument the user passed to the skill, OR
  2. The current working directory (cwd), confirmed by the user before any write.
- Always confirm the resolved path with the user before the FIRST write, even if a path argument was provided.
- Never run any OpenSpec command, file copy, or config edit automatically from a hook. This skill only runs when invoked intentionally.

---

**Steps**

1. **Resolve the target project path**

   - If the user provided a path argument (e.g. `/spec:setup /Users/me/projects/foo`), use that.
   - Otherwise, run `pwd` to get cwd.
   - The resolved path MUST be absolute. If relative, fail with:
     > "Please pass an absolute path, or cd into the target project first."
   - If cwd is a clearly ambiguous location (`$HOME`, `/tmp`, `/`), ask for an explicit path instead of proceeding.

2. **Confirm the target with the user**

   Use the **AskUserQuestion tool**:
   > "Set up Mor's spec-driven workflow in this project?
   >
   > **Path:** `<resolved-path>`
   >
   > This may create `<resolved-path>/openspec/` (if not initialized) and will create `<resolved-path>/openspec/schemas/superpowers-driven/`."

   Options:
   - "Yes, set up here"
   - "No, cancel"

   If the user cancels, stop with a status message.

3. **Initialize OpenSpec if needed**

   Check if `<path>/openspec/` exists.

   **If NO:**
   - Use **AskUserQuestion tool**:
     > "OpenSpec is not initialized in this project. Run `openspec init` now?"
   - Options:
     - "Yes, initialize"
     - "No, cancel"
   - If confirmed, run:
     ```bash
     cd "<path>" && npx -y @fission-ai/openspec@latest init
     ```
   - First run downloads the CLI via npx; subsequent runs use the local npm cache.

4. **Locate the schema source**

   The schema ships with this plugin at `${CLAUDE_PLUGIN_ROOT}/schemas/superpowers-driven/`.

   ```bash
   ls "$CLAUDE_PLUGIN_ROOT/schemas/superpowers-driven"
   ```

   If missing, stop with an install error — do not attempt a fallback.

5. **Check for existing schema**

   If `<path>/openspec/schemas/superpowers-driven/` already exists:
   - Use **AskUserQuestion tool** to confirm overwrite.
   - If declined, stop with a status message.

6. **Copy the schema**

   ```bash
   mkdir -p "<path>/openspec/schemas"
   cp -R "$CLAUDE_PLUGIN_ROOT/schemas/superpowers-driven" "<path>/openspec/schemas/"
   ```

7. **Validate the installed schema**

   ```bash
   cd "<path>" && npx -y @fission-ai/openspec@latest schema validate superpowers-driven
   ```

   If validation fails, report the error and stop — do not claim success.

8. **Offer to set as default schema**

   Use **AskUserQuestion tool**:
   - "Yes, set as default" → update `<path>/openspec/config.yaml` → `schema: superpowers-driven`
   - "No, keep current default" → skip

   Never modify `config.yaml` without explicit user confirmation.

9. **Report success**

   ```
   ## Mor Spec Setup Complete

   **Target project:** <path>
   **OpenSpec:** <already initialized | initialized now>
   **Schema installed:** <path>/openspec/schemas/superpowers-driven/
   **Default schema:** <superpowers-driven | unchanged>

   You can now:
   - `/spec:propose` — create a new change
   - `/spec:explore` — think before committing
   - `/spec:apply`   — implement tasks
   - `/spec:archive` — finalize when done

   Artifacts are TDD-ready and compatible with Superpowers.
   ```

---

**Guardrails**

- Never guess the target path. Ask if cwd is ambiguous.
- Always confirm the resolved path before the first write.
- Never overwrite an existing schema without user confirmation.
- Never edit `openspec/config.yaml` without user confirmation.
- Stop on validation failure — do not pretend success.
- Never run automatically from any hook; the user must invoke this skill intentionally.
- All OpenSpec CLI calls MUST go through `npx -y @fission-ai/openspec@latest` — do not assume a global `openspec` binary exists.
