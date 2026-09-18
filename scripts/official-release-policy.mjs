#!/usr/bin/env node

import { readFileSync } from 'node:fs';
import { readdirSync } from 'node:fs';

function keyRecords(listing) {
  const records = listing
    .trim()
    .split('\n')
    .filter(Boolean)
    .map((line) => line.split(':'));

  return records.flatMap((record, index) => {
    if (!['sec', 'sec#', 'ssb', 'ssb#'].includes(record[0])) return [];
    const fingerprint = records.slice(index + 1).find((next) => next[0] === 'fpr')?.[9];
    return [{ type: record[0], fingerprint, capabilities: record[12] ?? '' }];
  });
}

export function validateSecretKeyListing(listing, { primaryFingerprint, signingFingerprint }) {
  const records = keyRecords(listing);
  const primary = records.find((record) => record.type === 'sec#');
  const usablePrimary = records.find((record) => record.type === 'sec');
  const signing = records.find(
    (record) => record.type === 'ssb' && record.fingerprint === signingFingerprint,
  );
  const unexpected = records.filter(
    (record) =>
      !(
        (record.type === 'sec#' && record.fingerprint === primaryFingerprint) ||
        (record.type === 'ssb' && record.fingerprint === signingFingerprint)
      ),
  );

  if (!primary || primary.fingerprint !== primaryFingerprint) {
    throw new Error(
      'Release primary fingerprint does not match the expected unavailable primary key.',
    );
  }
  if (usablePrimary) throw new Error('Unexpected usable primary secret key material is present.');
  if (!signing || !signing.capabilities.toLowerCase().includes('s')) {
    throw new Error('Expected signing subkey is missing or cannot sign.');
  }
  if (unexpected.length > 0)
    throw new Error('Unexpected usable or secret subkey material is present.');
}

export function tagDisposition({ existingSha, expectedSha, signerValid }) {
  if (!existingSha) return 'create';
  if (existingSha !== expectedSha)
    throw new Error('Official tag already targets a different commit.');
  if (!signerValid)
    throw new Error('Existing official tag has an invalid or unexpected signing identity.');
  return 'already-valid';
}

export function assertRequiredSecret(value, name) {
  if (!value) throw new Error(`${name} is not configured.`);
}

export function assertReleaseArtifacts(files) {
  const required = ['apk', 'apk.asc', 'SHA256SUMS.txt', 'SHA256SUMS.txt.asc', 'BUILD.txt'];
  for (const file of required) {
    if (!files.includes(file)) throw new Error(`Required release artefact is missing: ${file}.`);
  }
}

export function assertTestingTrack(track) {
  if (!/^[A-Za-z0-9][A-Za-z0-9_-]*$/.test(track) || track.toLowerCase() === 'production') {
    throw new Error(
      'Official automation may publish only to a configured non-production testing track.',
    );
  }
}

if (process.argv[1] && import.meta.url === new URL(`file://${process.argv[1]}`).href) {
  const [command, ...args] = process.argv.slice(2);
  if (command === 'validate-secret-key') {
    const [listingPath, primaryFingerprint, signingFingerprint] = args;
    if (!listingPath || !primaryFingerprint || !signingFingerprint) {
      console.error(
        'Usage: official-release-policy.mjs validate-secret-key <listing> <primary> <signing-subkey>',
      );
      process.exit(1);
    }
    validateSecretKeyListing(readFileSync(listingPath, 'utf8'), {
      primaryFingerprint,
      signingFingerprint,
    });
  } else if (command === 'validate-release-artifacts') {
    const [directory] = args;
    if (!directory) {
      console.error('Usage: official-release-policy.mjs validate-release-artifacts <directory>');
      process.exit(1);
    }
    const names = readdirSync(directory);
    assertReleaseArtifacts([
      names.some((name) => name.endsWith('.apk')) ? 'apk' : '',
      names.some((name) => name.endsWith('.apk.asc')) ? 'apk.asc' : '',
      ...names,
    ]);
  } else {
    console.error(
      'Usage: official-release-policy.mjs <validate-secret-key|validate-release-artifacts> ...',
    );
    process.exit(1);
  }
}
