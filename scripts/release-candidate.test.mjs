import assert from 'node:assert/strict';
import test from 'node:test';

import { releaseEligibility } from './release-candidate.mjs';

test('makes only an exact current release-marker tip eligible', () => {
  assert.deepEqual(
    releaseEligibility({
      subject: 'release: 0.3.0-pre-alpha.5',
      releaseSha: 'same',
      mainSha: 'same',
    }),
    { eligible: true, version: '0.3.0-pre-alpha.5' },
  );
  assert.deepEqual(
    releaseEligibility({
      subject: 'release: 0.3.0-pre-alpha.5',
      releaseSha: 'older',
      mainSha: 'newer',
    }),
    { eligible: false, reason: 'stale-main-tip' },
  );
});

test('does not scan backwards for a release marker in a multi-commit push', () => {
  assert.deepEqual(
    releaseEligibility({
      subject: 'fix: follow-up after marker',
      releaseSha: 'tip',
      mainSha: 'tip',
    }),
    { eligible: false, reason: 'not-a-release-marker' },
  );
});
