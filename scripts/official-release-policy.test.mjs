import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';

import {
  assertReleaseArtifacts,
  assertRequiredSecret,
  assertTestingTrack,
  tagDisposition,
  validateSecretKeyListing,
} from './official-release-policy.mjs';

const primary = '2C930C47DEED62EC7DAFDFE245FFF54B2D9F031C';
const signing = 'BF89ABFBD583200EB70E43FA46525A21A09A8888';
// Captured from GnuPG 2.4 --with-colons after importing an exported signing
// subkey without its primary secret-key material. The stub marker is field 15,
// not part of the record type.
const validListing = `sec:-:255:22:primary:::::::cSC:::#::ed25519:::0:
fpr:::::::::${primary}:
ssb:-:255:22:signing:::::::s::::::ed25519:::0:
fpr:::::::::${signing}:`;

const releaseWorkflows = [
  '../.github/workflows/create-official-mobile-tag.yml',
  '../.github/workflows/validate-release-marker.yml',
];

function workflowJob(source, name, nextName) {
  const start = source.indexOf(`\n  ${name}:`);
  assert.notEqual(start, -1, `Missing workflow job: ${name}`);
  const end =
    nextName === undefined ? source.length : source.indexOf(`\n  ${nextName}:`, start + 1);
  assert.notEqual(end, -1, `Missing workflow job after ${name}: ${nextName}`);
  return source.slice(start, end);
}

test('accepts only the unavailable expected primary and explicit signing subkey', () => {
  assert.doesNotThrow(() =>
    validateSecretKeyListing(validListing, {
      primaryFingerprint: primary,
      signingFingerprint: signing,
    }),
  );
});

test('rejects incorrect, usable, missing, and unexpected secret key material', () => {
  assert.throws(() =>
    validateSecretKeyListing(validListing, {
      primaryFingerprint: 'wrong',
      signingFingerprint: signing,
    }),
  );
  assert.throws(() =>
    validateSecretKeyListing(validListing, {
      primaryFingerprint: primary,
      signingFingerprint: 'wrong',
    }),
  );
  assert.throws(() =>
    validateSecretKeyListing(validListing.replace(':::#::', ':::::'), {
      primaryFingerprint: primary,
      signingFingerprint: signing,
    }),
  );
  assert.throws(() =>
    validateSecretKeyListing(
      `${validListing}\nssb:-:255:22:other:::::::s::::::ed25519:::0:\nfpr:::::::::OTHER:`,
      { primaryFingerprint: primary, signingFingerprint: signing },
    ),
  );
});

test('requires explicit secrets and safe tag retry behaviour', () => {
  assert.throws(() => assertRequiredSecret('', 'PLURIS_RELEASE_GPG_PRIVATE_KEY'));
  assert.equal(
    tagDisposition({ existingSha: '', expectedSha: 'sha', signerValid: false }),
    'create',
  );
  assert.equal(
    tagDisposition({ existingSha: 'sha', expectedSha: 'sha', signerValid: true }),
    'already-valid',
  );
  assert.throws(() =>
    tagDisposition({ existingSha: 'other', expectedSha: 'sha', signerValid: true }),
  );
  assert.throws(() =>
    tagDisposition({ existingSha: 'sha', expectedSha: 'sha', signerValid: false }),
  );
});

test('requires signed downloadable artefacts and a non-production Play track', () => {
  assert.doesNotThrow(() =>
    assertReleaseArtifacts(['apk', 'apk.asc', 'SHA256SUMS.txt', 'SHA256SUMS.txt.asc', 'BUILD.txt']),
  );
  assert.throws(() => assertReleaseArtifacts(['apk', 'SHA256SUMS.txt', 'BUILD.txt']));
  assert.doesNotThrow(() => assertTestingTrack('internal'));
  assert.doesNotThrow(() => assertTestingTrack('pre-alpha'));
  assert.throws(() => assertTestingTrack('production'));
});

test('release workflows decode changelogs before quiet matching', () => {
  for (const workflow of releaseWorkflows) {
    const source = readFileSync(new URL(workflow, import.meta.url), 'utf8');
    assert.doesNotMatch(source, /base64 --decode \| grep -Fq/);
    assert.match(source, /changelog="\$\(gh api[\s\S]*?base64 --decode\)"/);
    assert.match(source, /grep -Fq "\$\{source_version\}" <<<"\$\{changelog\}"/);
  }
});

test('official tag workflow configures an annotated-tag identity', () => {
  const source = readFileSync(
    new URL('../.github/workflows/create-official-mobile-tag.yml', import.meta.url),
    'utf8',
  );
  assert.match(source, /git config user\.name 'Pluris Haven Release Bot'/);
  assert.match(source, /git config user\.email 'git-bot@endoftime\.works'/);
  assert.ok(source.indexOf('git config user.name') < source.indexOf('tag --sign'));
});

test('official tag signing job retains credentials for the tag push', () => {
  const source = readFileSync(
    new URL('../.github/workflows/create-official-mobile-tag.yml', import.meta.url),
    'utf8',
  );
  const signJob = source.slice(source.indexOf('\n  sign:'));
  assert.match(signJob, /persist-credentials: true/);
});

test('credential-bearing mobile release jobs require the official environment', () => {
  const release = readFileSync(
    new URL('../.github/workflows/mobile-release.yml', import.meta.url),
    'utf8',
  );
  const android = workflowJob(release, 'android', 'play-internal');
  const playInternal = workflowJob(release, 'play-internal', 'publish');
  assert.match(android, /\n    environment: official-release\n/);
  assert.match(android, /secrets\.ANDROID_KEYSTORE_BASE64/);
  assert.match(playInternal, /\n    environment: official-release\n/);
  assert.match(playInternal, /secrets\.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON/);
  assert.match(playInternal, /play-generated-apk\.mjs select[\s\S]*?PLAY_APP_SIGNING_CERT_SHA256/);
  assert.match(playInternal, /:download\?alt=media/);

  const repair = readFileSync(
    new URL('../.github/workflows/publish-play-track.yml', import.meta.url),
    'utf8',
  );
  const repairPublish = workflowJob(repair, 'publish');
  assert.match(repairPublish, /\n    environment: official-release\n/);
  assert.match(repairPublish, /secrets\.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON/);
});

test('stable debug signing is restricted to the exact current main tip', () => {
  const source = readFileSync(
    new URL('../.github/workflows/publish-debug-prerelease.yml', import.meta.url),
    'utf8',
  );
  const signer = workflowJob(source, 'sign-main-android', 'publish');
  const publisher = workflowJob(source, 'publish');

  assert.match(signer, /github\.event\.workflow_run\.head_branch == 'main'/);
  assert.match(signer, /\n    environment: debug-prerelease\n/);
  assert.match(signer, /if \[\[ "\$\{HEAD_SHA\}" != "\$\{main_sha\}" \]\]/);
  assert.match(signer, /works\.endoftime\.plurishaven\.debug/);
  assert.match(signer, /secrets\.DEBUG_KEYSTORE_BASE64/);
  assert.match(signer, /PLURIS_DEBUG_SIGNING_CERT_SHA256/);
  assert.match(signer, /certificate SHA-256 digest/);
  assert.doesNotMatch(publisher, /secrets\.DEBUG_KEY/);
  assert.match(
    publisher,
    /head_branch != 'main' \|\| needs\.sign-main-android\.result == 'success'/,
  );
  assert.match(publisher, /stable main debug-prerelease certificate/);
  assert.match(publisher, /disposable branch debug certificate/);
});
