import assert from 'node:assert/strict';
import test from 'node:test';

import { debugReleaseEligibility, debugTag } from './debug-release-version.mjs';

const ordinaryPush = {
  event: 'push',
  conclusion: 'success',
  repository: 'EndofTimeWorks/pluris-haven',
  headRepository: 'EndofTimeWorks/pluris-haven',
  actor: 'end-user',
  headBranch: 'fix/archive-safety',
  subject: 'fix(mobile): preserve archives',
};

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

test('permits a successful ordinary development-branch push', () => {
  assert.deepEqual(debugReleaseEligibility(ordinaryPush), {
    eligible: true,
    reason: 'eligible',
  });
});

test('rejects Dependabot as the workflow-run actor', () => {
  assert.deepEqual(debugReleaseEligibility({ ...ordinaryPush, actor: 'dependabot[bot]' }), {
    eligible: false,
    reason: 'dependabot-actor',
  });
});

test('rejects a Dependabot branch even with unusual actor metadata', () => {
  assert.deepEqual(
    debugReleaseEligibility({
      ...ordinaryPush,
      actor: 'repository-maintainer',
      headBranch: 'dependabot/npm_and_yarn/website/tooling-deps-123',
    }),
    { eligible: false, reason: 'dependabot-branch' },
  );
});

test('keeps main debug publication except for official release markers', () => {
  assert.deepEqual(debugReleaseEligibility({ ...ordinaryPush, headBranch: 'main' }), {
    eligible: true,
    reason: 'eligible',
  });
  assert.deepEqual(
    debugReleaseEligibility({
      ...ordinaryPush,
      headBranch: 'main',
      subject: 'release: 0.3.0-pre-alpha.5',
    }),
    { eligible: false, reason: 'official-release-marker' },
  );
});
