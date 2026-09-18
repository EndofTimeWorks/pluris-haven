import assert from 'node:assert/strict';
import test from 'node:test';

import { parseReleaseMarker } from './release-marker.mjs';

test('accepts exact semantic release markers', () => {
  for (const marker of ['release: 0.3.0-pre-alpha.5', 'release: 1.0.0-beta.2', 'release: 1.0.0']) {
    assert.ok(parseReleaseMarker(marker));
  }
});

test('rejects vague and malformed release markers', () => {
  for (const marker of [
    'Release: 0.3.0',
    'release pls',
    'release:',
    'release 0.3.0',
    'release: banana',
    'release: 0.3',
    'release: 1.0.0+4',
  ]) {
    assert.equal(parseReleaseMarker(marker), null);
  }
});
