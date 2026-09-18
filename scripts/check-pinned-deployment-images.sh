#!/usr/bin/env bash
set -euo pipefail

if rg -n '^\s*image:' server/compose.yml | rg -v '@sha256:'; then
  echo 'Deployment images must be pinned by digest.' >&2
  exit 1
fi
