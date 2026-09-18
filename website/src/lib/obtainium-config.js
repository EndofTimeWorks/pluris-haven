const repositoryUrl = 'https://github.com/EndofTimeWorks/pluris-haven';
const packageId = 'works.endoftime.plurishaven';
const canonicalApkPattern =
  '^pluris-haven-[0-9]+\\.[0-9]+\\.[0-9]+(?:-[0-9A-Za-z.-]+)?\\+[1-9][0-9]*\\.apk$';

export const obtainiumConfig = {
  id: packageId,
  url: repositoryUrl,
  author: 'EndofTimeWorks',
  name: 'Pluris Haven',
  preferredApkIndex: 0,
  additionalSettings: JSON.stringify({
    includePrereleases: true,
    fallbackToOlderReleases: true,
    apkFilterRegEx: canonicalApkPattern,
    versionExtractionRegEx: '^mobile-v.*\\+([1-9][0-9]*)$',
    matchGroupToUse: '$1',
    versionDetection: false,
    useVersionCodeAsOSVersion: true,
  }),
  overrideSource: 'GitHub',
};

export const obtainiumDeepLink = `obtainium://app/${encodeURIComponent(JSON.stringify(obtainiumConfig))}`;
export const obtainiumRedirectUrl = `https://apps.obtainium.imranr.dev/redirect?r=${encodeURIComponent(obtainiumDeepLink)}`;
export { canonicalApkPattern, packageId, repositoryUrl };
