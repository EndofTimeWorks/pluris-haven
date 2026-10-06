#!/usr/bin/env node
import { fileURLToPath } from 'node:url';

import { parseReleaseMarker } from './release-marker.mjs';

const versionPattern =
  /^(?<core>(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*))(?<prerelease>-[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?\+(?<build>[1-9][0-9]*)$/;

export function debugTag(versionWithBuild, runNumber) {
  const match = versionPattern.exec(versionWithBuild);
  if (!match || !/^[1-9][0-9]*$/.test(String(runNumber))) {
    throw new Error(
      'Expected SemVer mobile version with numeric build metadata and a positive run number.',
    );
  }

  const { core, prerelease = '', build } = match.groups;
  const debugPrerelease = prerelease === '' ? 'debug' : `${prerelease.slice(1)}.debug`;
  return `debug-v${core}-${debugPrerelease}.${runNumber}+${build}`;
}

export function debugReleaseEligibility({
  event,
  conclusion,
  repository,
  headRepository,
  actor,
  headBranch,
  subject,
}) {
  if (event !== 'push') return { eligible: false, reason: 'not-a-push' };
  if (conclusion !== 'success') return { eligible: false, reason: 'ci-not-successful' };
  if (!repository || headRepository !== repository) {
    return { eligible: false, reason: 'different-or-missing-repository' };
  }
  if (actor === 'dependabot[bot]') {
    return { eligible: false, reason: 'dependabot-actor' };
  }
  if (headBranch?.startsWith('dependabot/')) {
    return { eligible: false, reason: 'dependabot-branch' };
  }
  if (headBranch === 'main' && parseReleaseMarker(subject ?? '')) {
    return { eligible: false, reason: 'official-release-marker' };
  }
  if (!headBranch) return { eligible: false, reason: 'missing-head-branch' };
  return { eligible: true, reason: 'eligible' };
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  try {
    if (process.argv[2] === '--eligibility') {
      const [event, conclusion, repository, headRepository, actor, headBranch, subject] =
        process.argv.slice(3);
      const result = debugReleaseEligibility({
        event,
        conclusion,
        repository,
        headRepository,
        actor,
        headBranch,
        subject,
      });
      console.log(`skip=${!result.eligible}`);
      console.log(`reason=${result.reason}`);
      process.exit(0);
    }
    console.log(debugTag(process.argv[2], process.argv[3]));
  } catch (error) {
    console.error(error.message);
    process.exit(1);
  }
}
