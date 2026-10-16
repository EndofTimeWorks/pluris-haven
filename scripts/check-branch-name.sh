#!/usr/bin/env bash
set -euo pipefail

branch="${1:-}"
pattern='^(feat|fix|security|perf|refactor|test|docs|chore|build|ci|release|hotfix|style|revert)/[a-z0-9]([a-z0-9-]*[a-z0-9])?(/[a-z0-9]([a-z0-9-]*[a-z0-9])?)*$'
release_pattern='^release/(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?$'

if [[ -z "${branch}" ]]; then
  echo 'Usage: scripts/check-branch-name.sh <branch-name>' >&2
  exit 2
fi

if [[ "${branch}" == 'main' || "${branch}" == dependabot/** || "${branch}" =~ ${release_pattern} ]]; then
  exit 0
fi

if [[ ! "${branch}" =~ ${pattern} ]]; then
  echo "Invalid branch name: ${branch}" >&2
  echo 'Use <type>/<lowercase-kebab-description>, for example: fix/archive-purge-resurrection.' >&2
  echo 'Release branches may use a semantic version, for example: release/0.3.1-alpha.1.' >&2
  echo 'Allowed types: feat fix security perf refactor test docs chore build ci release hotfix style revert.' >&2
  exit 1
fi
