#!/usr/bin/env node

import { execFileSync } from 'node:child_process';

const tagPattern = /^mobile-v(.+)\+([1-9][0-9]*)$/;
const semverPattern =
  /^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(?:-((?:0|[1-9][0-9]*|[0-9A-Za-z-]*[A-Za-z-][0-9A-Za-z-]*)(?:\.(?:0|[1-9][0-9]*|[0-9A-Za-z-]*[A-Za-z-][0-9A-Za-z-]*))*))?$/;

function parseVersion(value) {
  const match = semverPattern.exec(value);
  if (!match) throw new Error(`Invalid semantic version: ${value}`);
  return {
    core: match.slice(1, 4).map(Number),
    prerelease: match[4]?.split('.') ?? [],
  };
}

function compareSemver(left, right) {
  for (let index = 0; index < left.core.length; index += 1) {
    if (left.core[index] !== right.core[index]) {
      return left.core[index] < right.core[index] ? -1 : 1;
    }
  }
  if (left.prerelease.length === 0 || right.prerelease.length === 0) {
    if (left.prerelease.length === right.prerelease.length) return 0;
    return left.prerelease.length === 0 ? 1 : -1;
  }
  const length = Math.max(left.prerelease.length, right.prerelease.length);
  for (let index = 0; index < length; index += 1) {
    const leftId = left.prerelease[index];
    const rightId = right.prerelease[index];
    if (leftId === undefined) return -1;
    if (rightId === undefined) return 1;
    if (leftId === rightId) continue;
    const leftNumeric = /^\d+$/.test(leftId);
    const rightNumeric = /^\d+$/.test(rightId);
    if (leftNumeric && rightNumeric) return Number(leftId) < Number(rightId) ? -1 : 1;
    if (leftNumeric !== rightNumeric) return leftNumeric ? -1 : 1;
    return leftId < rightId ? -1 : 1;
  }
  return 0;
}

const [candidate, excludedTag] = process.argv.slice(2);
if (!candidate) {
  console.error('Usage: check-mobile-release-version.mjs <version+build> [exclude-tag]');
  process.exit(2);
}
const candidateMatch = /^(.+)\+([1-9][0-9]*)$/.exec(candidate);
if (!candidateMatch) {
  console.error(`Invalid mobile release version: ${candidate}`);
  process.exit(1);
}
const candidateVersion = parseVersion(candidateMatch[1]);
const candidateBuild = Number(candidateMatch[2]);
const tags =
  process.env.PLURIS_MOBILE_RELEASE_TAGS?.split('\n') ??
  execFileSync('git', ['tag', '--list', 'mobile-v*+*'], { encoding: 'utf8' }).split('\n');
const previous = tags
  .filter((tag) => tag && tag !== excludedTag)
  .map((tag) => {
    const match = tagPattern.exec(tag);
    return match ? { tag, version: parseVersion(match[1]), build: Number(match[2]) } : null;
  })
  .filter(Boolean);

const highestBuild = previous.reduce((maximum, tag) => Math.max(maximum, tag.build), 0);
if (candidateBuild <= highestBuild) {
  console.error(
    `Build ${candidateBuild} must be greater than the highest tagged mobile build ${highestBuild}.`,
  );
  process.exit(1);
}
const highestVersion = previous.reduce(
  (maximum, tag) => (!maximum || compareSemver(tag.version, maximum.version) > 0 ? tag : maximum),
  null,
);
if (highestVersion && compareSemver(candidateVersion, highestVersion.version) <= 0) {
  console.error(
    `Version ${candidateMatch[1]} must be greater than tagged mobile version ${highestVersion.tag.slice('mobile-v'.length).split('+')[0]}.`,
  );
  process.exit(1);
}

console.log(`Mobile release ${candidate} is newer than ${previous.length} prior mobile tag(s).`);
