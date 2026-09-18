#!/usr/bin/env node
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

if (import.meta.url === `file://${process.argv[1]}`) {
  try {
    console.log(debugTag(process.argv[2], process.argv[3]));
  } catch (error) {
    console.error(error.message);
    process.exit(1);
  }
}
