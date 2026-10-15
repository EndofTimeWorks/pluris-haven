#!/usr/bin/env node

import { readFileSync } from 'node:fs';

const normaliseCertificateHash = (value) => value.replaceAll(':', '').toUpperCase();

export function selectUniversalApk(response, certificateSha256) {
  const candidates = (response.generatedApks ?? [])
    .filter((generatedApk) => generatedApk.generatedUniversalApk?.downloadId)
    .map((generatedApk) => ({
      certificateSha256: generatedApk.certificateSha256Hash,
      downloadId: generatedApk.generatedUniversalApk.downloadId,
    }));
  if (candidates.length !== 1) {
    throw new Error('Play must return exactly one generated universal APK for this version code.');
  }
  if (
    certificateSha256 &&
    (!candidates[0].certificateSha256 ||
      normaliseCertificateHash(candidates[0].certificateSha256) !==
        normaliseCertificateHash(certificateSha256))
  ) {
    throw new Error('Play metadata has an unexpected app-signing certificate.');
  }
  return candidates[0].downloadId;
}

export async function waitForUniversalApk(
  fetchResponse,
  attempts = 10,
  wait = (milliseconds) => new Promise((resolve) => setTimeout(resolve, milliseconds)),
) {
  let lastError;
  for (let attempt = 0; attempt < attempts; attempt += 1) {
    try {
      return selectUniversalApk(await fetchResponse());
    } catch (error) {
      lastError = error;
      if (attempt + 1 < attempts) await wait((attempt + 1) * 1000);
    }
  }
  throw new Error(`Play did not provide a generated universal APK after ${attempts} attempts.`, {
    cause: lastError,
  });
}

export function verifyGeneratedApk({
  badging,
  signerOutput,
  packageName,
  versionCode,
  versionName,
  certificateSha256,
}) {
  const packageMatch = /^package: name='([^']+)' versionCode='([^']+)' versionName='([^']+)'/m.exec(
    badging,
  );
  if (!packageMatch) throw new Error('Downloaded Play APK has no readable package metadata.');
  if (packageMatch[1] !== packageName)
    throw new Error('Downloaded Play APK has an unexpected package name.');
  if (packageMatch[2] !== String(versionCode))
    throw new Error('Downloaded Play APK has an unexpected version code.');
  if (packageMatch[3] !== versionName)
    throw new Error('Downloaded Play APK has an unexpected version name.');
  if (/^package:.*\bsplit='/m.test(badging))
    throw new Error('Downloaded Play APK is a device-specific split, not a universal APK.');
  if (
    !/Verified using v[1-4] scheme \((?:JAR signing|APK Signature Scheme v[1-4])\): true/m.test(
      signerOutput,
    )
  ) {
    throw new Error('Downloaded Play APK did not pass APK signature verification.');
  }
  const signerCertificates = [
    ...signerOutput.matchAll(
      /^(?:Signer #\d+|V3\.0 Signer):? certificate SHA-256 digest:\s*([A-Fa-f0-9:]+)/gm,
    ),
  ].map((match) => normaliseCertificateHash(match[1]));
  if (!signerCertificates.includes(normaliseCertificateHash(certificateSha256))) {
    throw new Error('Downloaded Play APK has an unexpected app-signing certificate.');
  }
}

if (process.argv[1] && import.meta.url === new URL(`file://${process.argv[1]}`).href) {
  const [command, ...args] = process.argv.slice(2);
  if (command === 'select') {
    process.stdout.write(
      `${selectUniversalApk(JSON.parse(readFileSync(args[0], 'utf8')), args[1])}\n`,
    );
  } else if (command === 'verify') {
    const [badgingPath, signerPath, packageName, versionCode, versionName, certificateSha256] =
      args;
    verifyGeneratedApk({
      badging: readFileSync(badgingPath, 'utf8'),
      signerOutput: readFileSync(signerPath, 'utf8'),
      packageName,
      versionCode,
      versionName,
      certificateSha256,
    });
  } else {
    console.error('Usage: play-generated-apk.mjs <select|verify> ...');
    process.exit(1);
  }
}
