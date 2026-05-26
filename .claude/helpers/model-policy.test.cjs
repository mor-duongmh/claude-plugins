'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');
const fs = require('node:fs');

const { loadPolicy, routeTask } = require('./router.js');

const HELPERS_DIR = path.join(__dirname);
const VALID_POLICY_PATH = path.join(HELPERS_DIR, 'model-policy.json');

// ── Test 1: loader parses model-policy.json and exposes required fields ───────
test('loadPolicy parses model-policy.json and exposes required top-level fields', () => {
  const policy = loadPolicy(VALID_POLICY_PATH);

  assert.notEqual(policy, null, 'policy must not be null for a valid file');

  // schemaVersion
  assert.equal(policy.schemaVersion, 1, 'schemaVersion must be 1');

  // agentBase: object with known agents
  assert.equal(typeof policy.agentBase, 'object', 'agentBase must be an object');
  assert.ok(!Array.isArray(policy.agentBase), 'agentBase must not be an array');
  assert.ok('tester' in policy.agentBase, 'agentBase must contain tester');
  assert.ok('coder' in policy.agentBase, 'agentBase must contain coder');

  // escalators: object with up/down arrays
  assert.equal(typeof policy.escalators, 'object', 'escalators must be an object');
  assert.ok(Array.isArray(policy.escalators.up), 'escalators.up must be an array');
  assert.ok(Array.isArray(policy.escalators.down), 'escalators.down must be an array');

  // tierModel: object with at least one harness key, each harness has numeric string keys
  assert.equal(typeof policy.tierModel, 'object', 'tierModel must be an object');
  const harnessKeys = Object.keys(policy.tierModel);
  assert.ok(harnessKeys.length > 0, 'tierModel must have at least one harness entry');
  // spot-check the "claude" harness
  assert.ok('claude' in policy.tierModel, 'tierModel must contain "claude" harness');
  assert.equal(typeof policy.tierModel.claude, 'object', 'tierModel.claude must be an object');

  // complexity: object with enabled boolean
  assert.equal(typeof policy.complexity, 'object', 'complexity must be an object');
  assert.equal(typeof policy.complexity.enabled, 'boolean', 'complexity.enabled must be boolean');

  // adaptive: object with enabled boolean
  assert.equal(typeof policy.adaptive, 'object', 'adaptive must be an object');
  assert.equal(typeof policy.adaptive.enabled, 'boolean', 'adaptive.enabled must be boolean');
});

// ── Test 2a: missing policy file ⇒ null ───────────────────────────────────────
test('loadPolicy returns null when policy file does not exist', () => {
  const result = loadPolicy(path.join(HELPERS_DIR, 'nonexistent-policy.json'));
  assert.equal(result, null, 'must return null for a missing file');
});

// ── Test 2b: invalid JSON ⇒ null ──────────────────────────────────────────────
test('loadPolicy returns null when policy file contains invalid JSON', (t) => {
  const tmpPath = path.join(HELPERS_DIR, '__tmp_bad_policy.json');
  fs.writeFileSync(tmpPath, '{ not valid json %%% }');
  try {
    const result = loadPolicy(tmpPath);
    assert.equal(result, null, 'must return null for invalid JSON');
  } finally {
    fs.unlinkSync(tmpPath);
  }
});

// ── Test 2c: missing required key ⇒ null ─────────────────────────────────────
test('loadPolicy returns null when a required top-level key is missing', (t) => {
  const tmpPath = path.join(HELPERS_DIR, '__tmp_partial_policy.json');
  // Valid JSON but missing "adaptive"
  const partial = {
    schemaVersion: 1,
    agentBase: { coder: 2 },
    escalators: { up: [], down: [] },
    tierModel: { claude: { '1': 'haiku' } },
    complexity: { enabled: true },
    // adaptive is absent
  };
  fs.writeFileSync(tmpPath, JSON.stringify(partial));
  try {
    const result = loadPolicy(tmpPath);
    assert.equal(result, null, 'must return null when a required key is missing');
  } finally {
    fs.unlinkSync(tmpPath);
  }
});

// ── Test 2d: wrong schemaVersion ⇒ null ──────────────────────────────────────
test('loadPolicy returns null when schemaVersion !== 1', (t) => {
  const tmpPath = path.join(HELPERS_DIR, '__tmp_version_policy.json');
  const bad = {
    schemaVersion: 99,
    agentBase: { coder: 2 },
    escalators: { up: [], down: [] },
    tierModel: { claude: { '1': 'haiku' } },
    complexity: { enabled: true },
    adaptive: { enabled: false },
  };
  fs.writeFileSync(tmpPath, JSON.stringify(bad));
  try {
    const result = loadPolicy(tmpPath);
    assert.equal(result, null, 'must return null when schemaVersion is not 1');
  } finally {
    fs.unlinkSync(tmpPath);
  }
});

// ── Test 3: routeTask still works (agent-only fallback) when policy is absent ─
test('routeTask returns valid agent routing regardless of policy availability', () => {
  // routeTask should always work — it does not depend on a loaded policy
  const result = routeTask('implement a new feature');
  assert.equal(typeof result, 'object', 'routeTask must return an object');
  assert.equal(typeof result.agent, 'string', 'result.agent must be a string');
  assert.equal(typeof result.confidence, 'number', 'result.confidence must be a number');
  assert.equal(typeof result.reason, 'string', 'result.reason must be a string');
});
