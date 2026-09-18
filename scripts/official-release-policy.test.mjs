import assert from 'node:assert/strict';
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
const validListing = `sec#:-:255:22:primary::::::::scESC:::#:::23::0:
fpr:::::::::${primary}:
ssb:-:255:22:signing::::::::s::::::23:
fpr:::::::::${signing}:`;

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
    validateSecretKeyListing(validListing.replace('sec#', 'sec'), {
      primaryFingerprint: primary,
      signingFingerprint: signing,
    }),
  );
  assert.throws(() =>
    validateSecretKeyListing(
      `${validListing}\nssb:-:255:22:other::::::::s::::::23:\nfpr:::::::::OTHER:`,
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
