'use strict';

/**
 * scope-guard.cjs — Repo-scope guard for the model-routing-harness.
 *
 * The model-routing feature must apply ONLY within the claude-plugins repo.
 * Detection mechanism: presence of a `.model-routing.json` file with
 * `{ "enabled": true }` at the repo root (or any ancestor of the given dir).
 *
 * Choosing an explicit opt-in marker file over structural detection
 * (checking for .claude-plugin/marketplace.json + plugins/morkit/) gives:
 *   - Clear intent: one file to create/delete to toggle the feature
 *   - No false matches on similarly structured repos
 *   - Easy to disable without touching code
 *
 * Safety contract (fail-open-to-noop):
 *   - Any I/O error or parse error → return false (noop, never block)
 *   - Walks up the directory tree until the marker is found OR the filesystem
 *     root is reached (prevents infinite loop)
 *   - Never throws
 */

const fs = require('node:fs');
const path = require('node:path');

const MARKER_FILE = '.model-routing.json';

/**
 * Check whether the given directory (or its ancestors) is the claude-plugins
 * repo with model-routing enabled.
 *
 * Walks up from `startDir` looking for `.model-routing.json` with
 * `{ "enabled": true }`. Returns true on first match, false if the root is
 * reached without a match or any error occurs.
 *
 * @param {string} [startDir] - Directory to start the search from.
 *   Defaults to CLAUDE_PROJECT_DIR env var, then process.cwd().
 * @returns {boolean}
 */
function isClaudePluginsRepo(startDir) {
  try {
    const start = startDir
      || process.env.CLAUDE_PROJECT_DIR
      || process.cwd();

    let current = path.resolve(start);

    // Walk up the directory tree
    // eslint-disable-next-line no-constant-condition
    while (true) {
      const markerPath = path.join(current, MARKER_FILE);
      try {
        const raw = fs.readFileSync(markerPath, 'utf8');
        let parsed;
        try {
          parsed = JSON.parse(raw);
        } catch (_) {
          // Invalid JSON in marker → treat as disabled, keep walking up
          parsed = null;
        }
        if (parsed && parsed.enabled === true) {
          return true;
        }
        // Marker present but not enabled — still check ancestors
        // (unusual, but someone could have a disabled marker in a subdir
        // and an enabled one higher up; walk up regardless)
      } catch (e) {
        if (e.code !== 'ENOENT') {
          // Unexpected I/O error (permissions, etc.) → treat as absent, keep walking
        }
        // ENOENT: marker absent in this dir → walk up
      }

      const parent = path.dirname(current);
      if (parent === current) {
        // Reached filesystem root
        break;
      }
      current = parent;
    }

    return false;
  } catch (_) {
    // Any unexpected error → fail-open-to-noop
    return false;
  }
}

module.exports = { isClaudePluginsRepo };
