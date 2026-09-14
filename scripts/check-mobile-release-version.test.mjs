import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import test from 'node:test';

const script = new URL('./check-mobile-release-version.mjs', import.meta.url);

function check(candidate, tags) {
  return spawnSync(process.execPath, [script.pathname, candidate], {
    encoding: 'utf8',
    env: { ...process.env, PLURIS_MOBILE_RELEASE_TAGS: tags.join('\n') },
  });
}

test('accepts a strictly newer build and semantic version', () => {
  const result = check('1.2.0+43', ['mobile-v1.1.9+42']);
  assert.equal(result.status, 0, result.stderr);
});

test('rejects an equal Android versionCode', () => {
  const result = check('1.2.0+42', ['mobile-v1.1.9+42']);
  assert.equal(result.status, 1);
});

test('rejects a lower or equal semantic version even with a higher build', () => {
  const result = check('1.1.9+43', ['mobile-v1.1.9+42']);
  assert.equal(result.status, 1);
});

test('orders prereleases according to SemVer precedence', () => {
  const result = check('1.0.0-alpha.10+43', ['mobile-v1.0.0-alpha.9+42']);
  assert.equal(result.status, 0, result.stderr);
});
