const releaseBase =
  'https://github.com/EndofTimeWorks/pluris-haven/releases/download/mobile-v0.2.0-pre-alpha.2%2B2008';

export const mobileRelease = {
  version: '0.2.0-pre-alpha.2+2008',
  tag: 'mobile-v0.2.0-pre-alpha.2+2008',
  published: '10 August 2026',
  releaseUrl:
    'https://github.com/EndofTimeWorks/pluris-haven/releases/tag/mobile-v0.2.0-pre-alpha.2%2B2008',
  universalApk: {
    name: 'pluris-haven-0.2.0-pre-alpha.2+2008-universal.apk',
    size: '66 MB',
    sha256: '06879ed599203a9c53a36579d4fa5670fe630aed82761110271a4c3e0d8519bd',
    url: `${releaseBase}/pluris-haven-0.2.0-pre-alpha.2%2B2008-universal.apk`,
  },
  arm64Apk: {
    name: 'pluris-haven-0.2.0-pre-alpha.2+2008-arm64-v8a.apk',
    size: '23 MB',
    url: `${releaseBase}/pluris-haven-0.2.0-pre-alpha.2%2B2008-arm64-v8a.apk`,
  },
  checksumsUrl: `${releaseBase}/SHA256SUMS.txt`,
  buildMetadataUrl: `${releaseBase}/BUILD.txt`,
  unsignedIpaUrl: `${releaseBase}/pluris-haven-0.2.0-pre-alpha.2%2B2008-unsigned.ipa`,
} as const;
