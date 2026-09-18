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
    '6B:EE:34:24:F3:EC:AF:0D:5A:20:F1:F6:7F:65:9A:3F:BE:E9:21:24:B1:8D:DA:86:C9:32:AC:E8:23:B6:BA:C4',
};
const badging =
  "package: name='works.endoftime.plurishaven' versionCode='3005' versionName='0.3.0-pre-alpha.5'";
const signer = `Verified using v1 scheme (APK Signature Scheme v1): true
Verified using v2 scheme (APK Signature Scheme v2): true
Signer #1 certificate SHA-256 digest: ${expected.certificateSha256}`;

test('selects exactly one Play-generated universal APK', () => {
  assert.equal(
    selectUniversalApk({ generatedApks: [{ generatedUniversalApk: { downloadId: 'universal' } }] }),
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
});

test('retries a pending generated APK response only within its bounded attempt count', async () => {
  let calls = 0;
  const response = await waitForUniversalApk(async () => {
    calls += 1;
    return calls === 3
      ? { generatedApks: [{ generatedUniversalApk: { downloadId: 'ready' } }] }
      : { generatedApks: [] };
  }, 3);
  assert.equal(response, 'ready');
  assert.equal(calls, 3);
  await assert.rejects(() => waitForUniversalApk(async () => ({ generatedApks: [] }), 2));
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
      badging: `${badging}\nsplit='x86_64'`,
      signerOutput: signer,
      ...expected,
    }),
  );
  assert.throws(() =>
    verifyGeneratedApk({ badging, signerOutput: signer.replace('6B:EE', '00:EE'), ...expected }),
  );
});
