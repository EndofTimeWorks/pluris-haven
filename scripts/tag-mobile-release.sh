#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

if [[ "$(git branch --show-current)" != "main" ]]; then
  echo "Mobile releases must be tagged from main." >&2
  exit 1
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Commit the tracked changes before tagging a release." >&2
  exit 1
fi

head_sha="$(git rev-parse HEAD)"
origin_sha="$(git rev-parse origin/main)"
if [[ "${head_sha}" != "${origin_sha}" ]]; then
  echo "Push main and wait for CI to pass before tagging the release." >&2
  exit 1
fi

signature="$(git log -1 --format=%G?)"
if [[ "${signature}" != "G" && "${signature}" != "U" ]]; then
  echo "HEAD does not have a valid GPG signature." >&2
  exit 1
fi

version_with_build="$(awk '/^version:/ {print $2}' mobile/pubspec.yaml)"
version="${version_with_build%%+*}"
build="${version_with_build##*+}"
semver_regex='^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-((0|[1-9][0-9]*|[0-9A-Za-z-]*[A-Za-z-][0-9A-Za-z-]*)(\.(0|[1-9][0-9]*|[0-9A-Za-z-]*[A-Za-z-][0-9A-Za-z-]*))*))?$'

if [[ -z "${version_with_build}" || "${version_with_build}" == "${version}" ]]; then
  echo "mobile/pubspec.yaml must contain version: <semver>+<build>." >&2
  exit 1
fi
if [[ ! "${version}" =~ ${semver_regex} ]]; then
  echo "Invalid release version: ${version}" >&2
  exit 1
fi
if [[ "${version}" == *.dev.* ]]; then
  echo "Versioned releases cannot use a .dev.N version." >&2
  exit 1
fi
if [[ ! "${build}" =~ ^[1-9][0-9]*$ ]]; then
  echo "Invalid mobile build number: ${build}" >&2
  exit 1
fi
if ! grep -Fq "${version_with_build}" CHANGELOG.md; then
  echo "CHANGELOG.md does not mention ${version_with_build}." >&2
  exit 1
fi

tag="mobile-v${version_with_build}"
if git rev-parse -q --verify "refs/tags/${tag}" >/dev/null; then
  echo "Local tag already exists: ${tag}" >&2
  exit 1
fi
if git ls-remote --exit-code --tags origin "refs/tags/${tag}" >/dev/null 2>&1; then
  echo "Remote tag already exists: ${tag}" >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI is required to confirm the CI run." >&2
  exit 1
fi

test_state="$(
  gh run list \
    --workflow CI \
    --commit "${head_sha}" \
    --event push \
    --limit 1 \
    --json status,conclusion \
    --jq '.[0] | "\(.status) \(.conclusion)"'
)"
if [[ "${test_state}" != "completed success" ]]; then
  echo "CI has not passed for ${head_sha}: ${test_state:-no run found}" >&2
  exit 1
fi

git tag -s "${tag}" -m "Pluris Haven Mobile ${version_with_build}"
git verify-tag "${tag}"

cat <<EOF
Created and verified ${tag}.

Publish it with:
  git push origin refs/tags/${tag}

That tag starts the Mobile Release workflow.
EOF
