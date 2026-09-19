import assert from 'node:assert/strict';
import test from 'node:test';

import { releaseEligibility } from './release-candidate.mjs';

test('makes only an exact current release-marker tip eligible', () => {
  assert.deepEqual(
    releaseEligibility({
      subject: 'release: 0.3.0-pre-alpha.5',
      releaseSha: 'a'.repeat(40),
      mainSha: 'a'.repeat(40),
    }),
    { eligible: true, version: '0.3.0-pre-alpha.5' },
  );
  assert.deepEqual(
    releaseEligibility({
      subject: 'release: 0.3.0-pre-alpha.5',
      releaseSha: 'b'.repeat(40),
      mainSha: 'c'.repeat(40),
    }),
    { eligible: false, reason: 'stale-main-tip' },
  );
});

test('does not scan backwards for a release marker in a multi-commit push', () => {
  assert.deepEqual(
    releaseEligibility({
      subject: 'fix: follow-up after marker',
      releaseSha: 'a'.repeat(40),
      mainSha: 'a'.repeat(40),
    }),
    { eligible: false, reason: 'not-a-release-marker' },
  );
});

test('fails closed when GitHub metadata is absent or malformed', () => {
  for (const [releaseSha, mainSha] of [
    ['', ''],
    ['a'.repeat(40), ''],
    ['not-a-sha', 'a'.repeat(40)],
  ]) {
    assert.deepEqual(
      releaseEligibility({
        subject: 'release: 0.3.0-pre-alpha.5',
        releaseSha,
        mainSha,
      }),
      { eligible: false, reason: 'missing-or-invalid-commit-sha' },
    );
  }
});
