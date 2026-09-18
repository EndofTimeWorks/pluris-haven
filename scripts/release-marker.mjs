#!/usr/bin/env node

const releasePrefix = 'release: ';

function isNumericIdentifier(value) {
  return /^(0|[1-9][0-9]*)$/.test(value);
}

function isPrereleaseIdentifier(value) {
  return (
    /^[0-9A-Za-z-]+$/.test(value) &&
    !(value.length > 1 && value.startsWith('0') && /^[0-9]+$/.test(value))
  );
}

export function isSemanticVersion(value) {
  const separator = value.indexOf('-');
  const core = separator === -1 ? value : value.slice(0, separator);
  const prerelease = separator === -1 ? undefined : value.slice(separator + 1);
  if (!core || value.includes('+')) return false;

  const coreParts = core.split('.');
  if (coreParts.length !== 3 || !coreParts.every(isNumericIdentifier)) return false;

  return (
    prerelease === undefined ||
    (prerelease.length > 0 && prerelease.split('.').every(isPrereleaseIdentifier))
  );
}

export function parseReleaseMarker(subject) {
  if (!subject.startsWith(releasePrefix)) return null;

  const version = subject.slice(releasePrefix.length);
  return isSemanticVersion(version) ? version : null;
}

if (process.argv[1] && import.meta.url === new URL(`file://${process.argv[1]}`).href) {
  const subject = process.argv.slice(2).join(' ');
  const version = parseReleaseMarker(subject);
  if (!version) {
    console.error('Expected exact release marker: release: <semantic-version>');
    process.exit(1);
  }
  console.log(version);
}
