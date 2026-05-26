'use strict';

/**
 * hook-handler.cjs — Minimal hook handler for the model-routing harness.
 *
 * Provides named handler functions that can be invoked from hook scripts.
 * Handlers are defensive: they never throw, always complete within the
 * 5-second safety-timeout budget, and log errors to stderr silently.
 *
 * Supported handlers:
 *   "record-outcome" — persists a routing outcome via adaptive-store.
 *     Expected JSON input fields:
 *       agent    {string}   — agent name (e.g. "coder")
 *       bucket   {string}   — complexity bucket ("simple"|"medium"|"complex") or omitted
 *       tier     {number}   — tier that was used
 *       outcome  {string}   — "success"|"retry"|"escalate"
 *       statePath {string}  — optional override for the state file path (used in tests)
 *       event    {string}   — optional event name (e.g. "Stop", "PostToolUse") — informational
 *
 * Claude Code and Codex both emit Stop/PostToolUse (Codex v0.130.0 has no SubagentStop).
 * The handler accepts either event shape without special branching.
 *
 * Hook registration in settings.json/hooks.json is handled in Tasks 6/7.
 * This module only provides the callable handler.
 */

const { recordOutcome } = require('./adaptive-store.cjs');

/**
 * Handle a "record-outcome" event from stdin JSON.
 *
 * @param {string} inputJson - Raw JSON string from the hook invocation.
 * @returns {void}
 */
function handleRecordOutcome(inputJson) {
  try {
    const data = JSON.parse(inputJson);

    const agent = typeof data.agent === 'string' ? data.agent : null;
    const bucket = typeof data.bucket === 'string' ? data.bucket : null;
    const tier = typeof data.tier === 'number' ? data.tier : 2;
    const outcome = typeof data.outcome === 'string' ? data.outcome : 'success';
    const statePath = typeof data.statePath === 'string' ? data.statePath : undefined;

    // Ignore events with no agent (malformed input)
    if (!agent) return;

    recordOutcome(agent, bucket, tier, outcome, statePath);
  } catch (_) {
    // Never throw — hook handlers must always exit cleanly
  }
}

module.exports = {
  'record-outcome': handleRecordOutcome,
};
