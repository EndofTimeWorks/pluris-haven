import assert from 'node:assert/strict';
import test from 'node:test';

import {
  canonicalApkPattern,
  obtainiumConfig,
  obtainiumDeepLink,
  obtainiumRedirectUrl,
  packageId,
  repositoryUrl,
} from '../website/src/lib/obtainium-config.js';

test('produces an Obtainium GitHub Releases configuration for the canonical APK only', () => {
  assert.equal(obtainiumConfig.id, packageId);
  assert.equal(obtainiumConfig.url, repositoryUrl);
  assert.equal(obtainiumConfig.overrideSource, 'GitHub');
  assert.equal(obtainiumConfig.preferredApkIndex, 0);
  const settings = JSON.parse(obtainiumConfig.additionalSettings);
  assert.equal(settings.includePrereleases, true);
  assert.equal(settings.fallbackToOlderReleases, true);
  assert.equal(settings.useVersionCodeAsOSVersion, true);
  assert.equal(
    new RegExp(settings.versionExtractionRegEx).exec('mobile-v0.3.0-pre-alpha.5+3005')?.[1],
    '3005',
  );

  const apk = new RegExp(canonicalApkPattern);
  assert.match('pluris-haven-0.3.0-pre-alpha.5+3005.apk', apk);
  for (const excluded of [
    'pluris-haven-0.3.0-pre-alpha.5+3005-universal.apk',
    'pluris-haven-0.3.0-pre-alpha.5+3005.apk.asc',
    'pluris-haven-0.3.0-pre-alpha.5+3005.aab',
    'debug-v0.3.0-pre-alpha.5.debug.9+3005.apk',
    'SHA256SUMS.txt',
  ]) {
    assert.doesNotMatch(excluded, apk);
  }
});

test('encodes the full Obtainium configuration for direct and HTTPS links', () => {
  assert.match(obtainiumDeepLink, /^obtainium:\/\/app\/%7B/);
  const decoded = JSON.parse(
    decodeURIComponent(obtainiumDeepLink.slice('obtainium://app/'.length)),
  );
  assert.deepEqual(decoded, obtainiumConfig);
  const redirect = new URL(obtainiumRedirectUrl);
  assert.equal(redirect.origin, 'https://apps.obtainium.imranr.dev');
  assert.equal(redirect.pathname, '/redirect');
  assert.equal(redirect.searchParams.get('r'), obtainiumDeepLink);
});
