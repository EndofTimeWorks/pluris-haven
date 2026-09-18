#!/usr/bin/env node

import { execFileSync } from 'node:child_process';

const numericIdentifier = /^(0|[1-9][0-9]*)$/;
const prereleaseIdentifier = /^[0-9A-Za-z-]+$/;

function parseVersion(value) {
  const separator = value.indexOf('-');
  const coreValue = separator === -1 ? value : value.slice(0, separator);
  const prereleaseValue = separator === -1 ? '' : value.slice(separator + 1);
  const coreParts = coreValue.split('.');
  if (
    coreParts.length !== 3 ||
    !coreParts.every((part) => numericIdentifier.test(part)) ||
    (separator !== -1 &&
      (!prereleaseValue ||
        !prereleaseValue.split('.').every((part) => {
          return (
            prereleaseIdentifier.test(part) && (!/^\d+$/.test(part) || numericIdentifier.test(part))
          );
        })))
  ) {
    throw new Error(`Invalid semantic version: ${value}`);
  }
  return {
    core: coreParts.map(Number),
    prerelease: prereleaseValue ? prereleaseValue.split('.') : [],
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
const buildSeparator = candidate.indexOf('+');
if (buildSeparator <= 0 || candidate.indexOf('+', buildSeparator + 1) !== -1) {
  console.error(`Invalid mobile release version: ${candidate}`);
  process.exit(1);
}
const candidateVersionValue = candidate.slice(0, buildSeparator);
const candidateBuildValue = candidate.slice(buildSeparator + 1);
if (!numericIdentifier.test(candidateBuildValue)) {
  console.error(`Invalid mobile release version: ${candidate}`);
  process.exit(1);
}
const candidateVersion = parseVersion(candidateVersionValue);
const candidateBuild = Number(candidateBuildValue);
const tags =
  process.env.PLURIS_MOBILE_RELEASE_TAGS?.split('\n') ??
  execFileSync('git', ['tag', '--list', 'mobile-v*+*'], { encoding: 'utf8' }).split('\n');
const previous = tags
  .filter((tag) => tag && tag !== excludedTag)
  .map((tag) => {
    if (!tag.startsWith('mobile-v')) return null;
    const versionWithBuild = tag.slice('mobile-v'.length);
    const separator = versionWithBuild.indexOf('+');
    if (separator <= 0 || versionWithBuild.indexOf('+', separator + 1) !== -1) return null;
    const build = versionWithBuild.slice(separator + 1);
    return numericIdentifier.test(build)
      ? { tag, version: parseVersion(versionWithBuild.slice(0, separator)), build: Number(build) }
      : null;
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
    `Version ${candidateVersionValue} must be greater than tagged mobile version ${highestVersion.tag.slice('mobile-v'.length).split('+')[0]}.`,
  );
  process.exit(1);
}

console.log(`Mobile release ${candidate} is newer than ${previous.length} prior mobile tag(s).`);
