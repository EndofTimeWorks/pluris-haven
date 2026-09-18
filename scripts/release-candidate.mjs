#!/usr/bin/env node

import { parseReleaseMarker } from './release-marker.mjs';

export function releaseEligibility({ subject, releaseSha, mainSha }) {
  const version = parseReleaseMarker(subject);
  if (!version) return { eligible: false, reason: 'not-a-release-marker' };
  if (releaseSha !== mainSha) return { eligible: false, reason: 'stale-main-tip' };
  return { eligible: true, version };
}

if (process.argv[1] && import.meta.url === new URL(`file://${process.argv[1]}`).href) {
  const [subject, releaseSha, mainSha] = process.argv.slice(2);
  const result = releaseEligibility({ subject, releaseSha, mainSha });
  if (result.reason === 'stale-main-tip') {
    console.error('ABORT — release marker is no longer the current main tip.');
    process.exit(1);
  }
  if (!result.eligible) {
    console.error('Current main tip is not a release marker.');
    process.exit(1);
  }
  console.log(result.version);
}
