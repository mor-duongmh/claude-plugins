#!/usr/bin/env node
/**
 * Claude Flow Agent Router
 * Routes tasks to optimal agents based on learned patterns
 */

'use strict';

const fs = require('node:fs');
const path = require('node:path');

const DEFAULT_POLICY_PATH = path.join(__dirname, 'model-policy.json');

const REQUIRED_KEYS = ['schemaVersion', 'agentBase', 'escalators', 'tierModel', 'complexity', 'adaptive'];

/**
 * Load and validate the model routing policy file.
 *
 * @param {string} [policyPath] - Path to the policy JSON file. Defaults to model-policy.json
 *   in the same directory as this module.
 * @returns {object|null} Parsed policy object, or null if the file is missing,
 *   unparseable, or fails validation.
 */
function loadPolicy(policyPath) {
  const filePath = policyPath || DEFAULT_POLICY_PATH;

  let raw;
  try {
    raw = fs.readFileSync(filePath, 'utf8');
  } catch (_err) {
    return null;
  }

  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch (_err) {
    return null;
  }

  // Validate required top-level keys
  for (const key of REQUIRED_KEYS) {
    if (!(key in parsed)) {
      return null;
    }
  }

  // Validate schemaVersion === 1
  if (parsed.schemaVersion !== 1) {
    return null;
  }

  return parsed;
}

const AGENT_CAPABILITIES = {
  coder: ['code-generation', 'refactoring', 'debugging', 'implementation'],
  tester: ['unit-testing', 'integration-testing', 'coverage', 'test-generation'],
  reviewer: ['code-review', 'security-audit', 'quality-check', 'best-practices'],
  researcher: ['web-search', 'documentation', 'analysis', 'summarization'],
  architect: ['system-design', 'architecture', 'patterns', 'scalability'],
  'backend-dev': ['api', 'database', 'server', 'authentication'],
  'frontend-dev': ['ui', 'react', 'css', 'components'],
  devops: ['ci-cd', 'docker', 'deployment', 'infrastructure'],
};

const TASK_PATTERNS = {
  // Code patterns
  'implement|create|build|add|write code': 'coder',
  'test|spec|coverage|unit test|integration': 'tester',
  'review|audit|check|validate|security': 'reviewer',
  'research|find|search|documentation|explore': 'researcher',
  'design|architect|structure|plan': 'architect',

  // Domain patterns
  'api|endpoint|server|backend|database': 'backend-dev',
  'ui|frontend|component|react|css|style': 'frontend-dev',
  'deploy|docker|ci|cd|pipeline|infrastructure': 'devops',
};

function routeTask(task) {
  const taskLower = task.toLowerCase();

  // Check patterns
  for (const [pattern, agent] of Object.entries(TASK_PATTERNS)) {
    const regex = new RegExp(pattern, 'i');
    if (regex.test(taskLower)) {
      return {
        agent,
        confidence: 0.8,
        reason: `Matched pattern: ${pattern}`,
      };
    }
  }

  // Default to coder for unknown tasks
  return {
    agent: 'coder',
    confidence: 0.5,
    reason: 'Default routing - no specific pattern matched',
  };
}

// CLI
const task = process.argv.slice(2).join(' ');

if (task) {
  const result = routeTask(task);
  console.log(JSON.stringify(result, null, 2));
} else {
  console.log('Usage: router.js <task description>');
  console.log('\nAvailable agents:', Object.keys(AGENT_CAPABILITIES).join(', '));
}

module.exports = { routeTask, loadPolicy, AGENT_CAPABILITIES, TASK_PATTERNS };
