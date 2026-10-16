#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${project_root}"

node_version="$(awk -F '"' '/^node = / { print $2; exit }' .mise.toml)"
if [[ -z "${node_version}" ]]; then
  echo 'Node version is missing from .mise.toml.' >&2
  exit 1
fi
export PATH="${HOME}/.local/node-v${node_version}/bin:${PATH}"

echo '==> toolchain'
node --version
corepack install
pnpm --version

echo '==> pnpm install --frozen-lockfile'
pnpm --dir website install --frozen-lockfile

echo '==> pnpm build'
pnpm --dir website build

echo '==> verify'
http_code="$(curl -sS -o /dev/null -w '%{http_code}' http://localhost:8083/)"
if [[ "${http_code}" != 200 ]]; then
  echo "Deploy failed (HTTP ${http_code})." >&2
  exit 1
fi
echo "Deploy OK (HTTP ${http_code})."
