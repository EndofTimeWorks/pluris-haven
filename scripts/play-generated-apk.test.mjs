import assert from 'node:assert/strict';
import test from 'node:test';

import {
  selectUniversalApk,
  verifyGeneratedApk,
  waitForUniversalApk,
} from './play-generated-apk.mjs';

const expected = {
  packageName: 'works.endoftime.plurishaven',
  versionCode: '3005',
  versionName: '0.3.0-pre-alpha.5',
  certificateSha256:
    '3F:60:9E:59:A3:9C:F0:0B:66:99:A7:93:6B:7F:01:85:F5:56:63:2B:BF:88:F0:03:9E:B6:2B:A6:4F:AF:03:0D',
};
const badging =
  "package: name='works.endoftime.plurishaven' versionCode='3005' versionName='0.3.0-pre-alpha.5' platformBuildVersionName='15'";
const signer = `Verified using v1 scheme (JAR signing): true
Verified using v2 scheme (APK Signature Scheme v2): true
Signer #1 certificate SHA-256 digest: ${expected.certificateSha256}`;

const generatedUniversalApk = {
  certificateSha256Hash: expected.certificateSha256,
  generatedUniversalApk: { downloadId: 'universal' },
};

test('selects exactly one Play-generated universal APK', () => {
  assert.equal(
    selectUniversalApk({ generatedApks: [generatedUniversalApk] }, expected.certificateSha256),
    'universal',
  );
  assert.throws(() => selectUniversalApk({ generatedApks: [] }));
  assert.throws(() =>
    selectUniversalApk({
      generatedApks: [
        { generatedUniversalApk: { downloadId: 'one' } },
        { generatedUniversalApk: { downloadId: 'two' } },
      ],
    }),
  );
  assert.throws(() =>
    selectUniversalApk(
      { generatedApks: [generatedUniversalApk] },
      `00${expected.certificateSha256}`,
    ),
  );
});

test('retries a pending generated APK response only within its bounded attempt count', async () => {
  let calls = 0;
  const waits = [];
  const response = await waitForUniversalApk(
    async () => {
      calls += 1;
      return calls === 3
        ? { generatedApks: [{ generatedUniversalApk: { downloadId: 'ready' } }] }
        : { generatedApks: [] };
    },
    3,
    async (milliseconds) => waits.push(milliseconds),
  );
  assert.equal(response, 'ready');
  assert.equal(calls, 3);
  assert.deepEqual(waits, [1000, 2000]);
  await assert.rejects(() =>
    waitForUniversalApk(
      async () => ({ generatedApks: [] }),
      2,
      async () => {},
    ),
  );
});

test('rejects an APK with unexpected identity, certificate, or split metadata', () => {
  assert.doesNotThrow(() => verifyGeneratedApk({ badging, signerOutput: signer, ...expected }));
  assert.throws(() =>
    verifyGeneratedApk({
      badging: badging.replace('3005', '3004'),
      signerOutput: signer,
      ...expected,
    }),
  );
  assert.throws(() =>
    verifyGeneratedApk({
      badging: badging.replace('plurishaven', 'other'),
      signerOutput: signer,
      ...expected,
    }),
  );
  assert.throws(() =>
    verifyGeneratedApk({
      badging: `${badging} split='config.x86_64'`,
      signerOutput: signer,
      ...expected,
    }),
  );
  assert.throws(() =>
    verifyGeneratedApk({ badging, signerOutput: signer.replace('3F:60', '00:60'), ...expected }),
  );
});

test('accepts the Play signer label emitted by current Android build tools', () => {
  const currentSigner = signer.replace('Signer #1', 'V3.0 Signer');
  assert.doesNotThrow(() =>
    verifyGeneratedApk({ badging, signerOutput: currentSigner, ...expected }),
  );
});
