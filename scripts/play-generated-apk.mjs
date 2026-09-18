#!/usr/bin/env node

import { readFileSync } from 'node:fs';

export function selectUniversalApk(response) {
  const candidates = (response.generatedApks ?? [])
    .map((generatedApk) => generatedApk.generatedUniversalApk?.downloadId)
    .filter(Boolean);
  if (candidates.length !== 1) {
    throw new Error('Play must return exactly one generated universal APK for this version code.');
  }
  return candidates[0];
}

export async function waitForUniversalApk(fetchResponse, attempts = 10) {
  let lastError;
  for (let attempt = 0; attempt < attempts; attempt += 1) {
    try {
      return selectUniversalApk(await fetchResponse());
    } catch (error) {
      lastError = error;
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
  if (/^split='/m.test(badging))
    throw new Error('Downloaded Play APK is a device-specific split, not a universal APK.');
  if (!/Verified using v[1-4] scheme \(APK Signature Scheme v[1-4]\): true/m.test(signerOutput)) {
    throw new Error('Downloaded Play APK did not pass APK signature verification.');
  }
  const actual = /Signer #1 certificate SHA-256 digest:\s*([A-Fa-f0-9:]+)/.exec(signerOutput)?.[1];
  const normalise = (value) => value.replaceAll(':', '').toUpperCase();
  if (!actual || normalise(actual) !== normalise(certificateSha256)) {
    throw new Error('Downloaded Play APK has an unexpected app-signing certificate.');
  }
}

if (process.argv[1] && import.meta.url === new URL(`file://${process.argv[1]}`).href) {
  const [command, ...args] = process.argv.slice(2);
  if (command === 'select') {
    process.stdout.write(`${selectUniversalApk(JSON.parse(readFileSync(args[0], 'utf8')))}\n`);
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
