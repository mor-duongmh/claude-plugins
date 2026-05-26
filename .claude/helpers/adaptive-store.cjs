'use strict';

/**
 * adaptive-store.cjs — JSON-backed store for routing outcome feedback.
 *
 * Records per-(agent, bucket) outcome counters and implements bump-up-only
 * tier adjustment with hysteresis. State is persisted to a small JSON file.
 *
 * Outcome taxonomy:
 *   "success"  — the chosen tier handled the task without complaint
 *   "retry"    — the task had to be retried (model insufficient)
 *   "escalate" — caller explicitly escalated to a higher tier
 *
 * Bump logic (V1: up-only):
 *   When total observations for (agent, bucket) >= minSamples AND
 *   (retry + escalate) > success, bump tier by +1, clamped to 3.
 *
 * Hysteresis: after a bump fires at observation-count N, it will not fire
 *   again until at least (N + hysteresis) total observations have accumulated.
 *   This prevents oscillation if the same bucket keeps accumulating samples.
 *
 * @module adaptive-store
 */

const fs = require('node:fs');
const path = require('node:path');

const DEFAULT_STATE_PATH = path.join(__dirname, '.adaptive-state.json');

/**
 * Load state from disk. Returns an empty object if the file is missing or
 * unreadable (defensive; never throws).
 *
 * @param {string} statePath
 * @returns {object}
 */
function loadState(statePath) {
  try {
    return JSON.parse(fs.readFileSync(statePath, 'utf8'));
  } catch (_) {
    return {};
  }
}

/**
 * Persist state to disk. Never throws.
 *
 * @param {string} statePath
 * @param {object} state
 */
function saveState(statePath, state) {
  try {
    fs.writeFileSync(statePath, JSON.stringify(state, null, 2), 'utf8');
  } catch (_) {}
}

/**
 * Build the state key for a (agent, bucket) pair.
 * Null or undefined bucket falls back to "default".
 *
 * @param {string} agent
 * @param {string|null|undefined} bucket
 * @returns {string}
 */
function stateKey(agent, bucket) {
  return `${agent}:${bucket != null ? bucket : 'default'}`;
}

/**
 * Record a routing outcome for a (agent, bucket) pair.
 *
 * Aggregates counts per key. Initialises missing keys with zero counters.
 * Never throws (defensive).
 *
 * @param {string} agent     - Agent name (e.g. "coder").
 * @param {string|null} bucket - Complexity bucket ("simple"|"medium"|"complex"|null).
 * @param {number} tier      - Tier that was chosen for this routing decision.
 * @param {"success"|"retry"|"escalate"} outcome
 * @param {string} [statePath] - Path to the JSON state file (default: .adaptive-state.json).
 */
function recordOutcome(agent, bucket, tier, outcome, statePath) {
  statePath = statePath || DEFAULT_STATE_PATH;
  const state = loadState(statePath);
  const key = stateKey(agent, bucket);

  if (!(key in state)) {
    state[key] = { tierChosen: tier, success: 0, retry: 0, escalate: 0, lastBumpAt: null };
  }

  const row = state[key];
  // Update tierChosen to the most recent tier seen (informational)
  row.tierChosen = tier;

  if (outcome === 'success') row.success += 1;
  else if (outcome === 'retry') row.retry += 1;
  else if (outcome === 'escalate') row.escalate += 1;
  // Unknown outcomes are silently ignored (defensive)

  saveState(statePath, state);
}

/**
 * Compute total observations for a row.
 *
 * @param {{ success: number, retry: number, escalate: number }} row
 * @returns {number}
 */
function totalObservations(row) {
  return row.success + row.retry + row.escalate;
}

/**
 * Adaptively adjust tier based on accumulated outcome statistics.
 *
 * Pure-ish: reads from the state file but does NOT write to it.
 * The "lastBumpAt" value is recorded by recordOutcome at bump time — callers
 * should call recordOutcome after a bump to advance the observation count for
 * future hysteresis checks. (See design contract.)
 *
 * Semantics (V1, bump-up only):
 *   - If total < minSamples → return tier unchanged.
 *   - If in hysteresis window (total - lastBumpAt < hysteresis) → return tier+1
 *     (the bump already fired; don't fire again yet).
 *   - Actually: hysteresis means "do not set lastBumpAt again"; the actual
 *     returned tier is still bumped if the last bump is still in effect.
 *
 * Revised semantics for clarity:
 *   adaptiveAdjust is called BEFORE recordOutcome for the current decision.
 *   It checks whether a bump should be applied based on past data:
 *     - Eligible to bump: total >= minSamples AND (retry+escalate) > success
 *       AND (lastBumpAt is null OR total - lastBumpAt >= hysteresis)
 *     - If eligible: return Math.min(3, tier + 1) and persist lastBumpAt=total.
 *     - Otherwise: return tier.
 *
 * @param {string} agent
 * @param {string|null} bucket
 * @param {number} tier         - Current base tier to potentially adjust.
 * @param {{ enabled: boolean, minSamples: number, hysteresis: number }} policyAdaptive
 * @param {string} [statePath]
 * @returns {number} Adjusted tier.
 */
function adaptiveAdjust(agent, bucket, tier, policyAdaptive, statePath) {
  statePath = statePath || DEFAULT_STATE_PATH;

  if (!policyAdaptive || !policyAdaptive.enabled) return tier;

  const state = loadState(statePath);
  const key = stateKey(agent, bucket);
  const row = state[key];

  if (!row) return tier;

  const total = totalObservations(row);
  const { minSamples, hysteresis } = policyAdaptive;

  if (total < minSamples) return tier;

  const dominated = (row.retry + row.escalate) > row.success;
  if (!dominated) return tier;

  // Hysteresis: don't bump if we bumped within the last `hysteresis` observations
  if (row.lastBumpAt !== null && (total - row.lastBumpAt) < hysteresis) {
    return tier;
  }

  // Fire the bump — persist lastBumpAt so future calls respect hysteresis
  row.lastBumpAt = total;
  saveState(statePath, state);

  return Math.min(3, tier + 1);
}

module.exports = { recordOutcome, adaptiveAdjust };
