import assert from 'node:assert/strict';
import test from 'node:test';

import { debugTag } from './debug-release-version.mjs';

test('derives a debug tag from an existing prerelease', () => {
  assert.equal(debugTag('0.3.0-pre-alpha.4+3004', 127), 'debug-v0.3.0-pre-alpha.4.debug.127+3004');
});

test('derives a debug tag from a stable source version', () => {
  assert.equal(debugTag('1.0.0+4000', 127), 'debug-v1.0.0-debug.127+4000');
});

test('preserves an existing beta prerelease', () => {
  assert.equal(debugTag('1.2.0-beta.3+5000', 127), 'debug-v1.2.0-beta.3.debug.127+5000');
});

test('rejects invalid source versions and run numbers', () => {
  assert.throws(() => debugTag('1.0.0', 127));
  assert.throws(() => debugTag('1.0.0+4000', 0));
});
