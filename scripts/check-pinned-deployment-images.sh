#!/usr/bin/env bash
set -euo pipefail

command -v grep >/dev/null 2>&1 || {
  echo 'grep is required to check deployment image digests.' >&2
  exit 1
}

images="$(grep -En '^\s*image:' server/compose.yml)"
if grep -Ev '@sha256:' <<<"${images}"; then
  echo 'Deployment images must be pinned by digest.' >&2
  exit 1
fi
