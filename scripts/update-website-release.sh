#!/usr/bin/env bash
set -euo pipefail

: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
: "${RELEASE_TAG:?RELEASE_TAG is required}"

release_json="$(gh api "repos/${GITHUB_REPOSITORY}/releases/tags/${RELEASE_TAG}")"
version="$(jq -r '.tag_name | sub("^mobile-v"; "")' <<<"${release_json}")"
published="$(jq -r '.published_at' <<<"${release_json}")"
published_label="$(date -u -d "${published}" '+%-d %B %Y')"

asset_url() {
  jq -r --arg name "$1" '.assets[] | select(.name == $name) | .browser_download_url' <<<"${release_json}"
}

asset_size() {
  jq -r --arg name "$1" '.assets[] | select(.name == $name) | .size' <<<"${release_json}" |
    awk '{ printf "%.0f MB", $1 / 1024 / 1024 }'
}

universal_name="pluris-haven-${version}-universal.apk"
arm64_name="pluris-haven-${version}-arm64-v8a.apk"
ipa_name="pluris-haven-${version}-unsigned.ipa"
checksums_url="$(asset_url SHA256SUMS.txt)"
build_metadata_url="$(asset_url BUILD.txt)"

universal_url="$(asset_url "${universal_name}")"
arm64_url="$(asset_url "${arm64_name}")"
ipa_url="$(asset_url "${ipa_name}")"

for value in "${checksums_url}" "${build_metadata_url}" "${universal_url}" "${arm64_url}" "${ipa_url}"; do
  test -n "${value}" || { echo "Missing release asset metadata." >&2; exit 1; }
done

cat > website/src/lib/release.ts <<EOF
export const mobileRelease = {
  version: '${version}',
  tag: '${RELEASE_TAG}',
  published: '${published_label}',
  releaseUrl:
    'https://github.com/${GITHUB_REPOSITORY}/releases/tag/${RELEASE_TAG}',
  universalApk: {
    name: '${universal_name}',
    size: '$(asset_size "${universal_name}")',
    url: '${universal_url}',
  },
  arm64Apk: {
    name: '${arm64_name}',
    size: '$(asset_size "${arm64_name}")',
    url: '${arm64_url}',
  },
  checksumsUrl: '${checksums_url}',
  buildMetadataUrl: '${build_metadata_url}',
  unsignedIpaUrl: '${ipa_url}',
} as const;
EOF
