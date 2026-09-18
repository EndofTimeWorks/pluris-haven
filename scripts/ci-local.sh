#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${root}"

failed=0
ci_tmp_dir="${HOME}/tmp/pluris-haven/ci-local"

run_group() {
  local name="$1"
  shift
  printf '\n== %s ==\n' "${name}"
  if "$@"; then
    printf 'PASS — %s\n' "${name}"
  else
    printf 'FAIL — %s\n' "${name}" >&2
    failed=1
  fi
}

run_group 'Install repository tooling' pnpm install --frozen-lockfile
run_group 'Install website tooling' pnpm --dir website install --frozen-lockfile
run_group 'Install server tooling' bash -c 'cd server && uv sync --frozen --dev'
run_group 'Branch policy' scripts/check-branch-name.sh "$(git branch --show-current)"
run_group 'Repository quality gates' pnpm format:check
run_group 'GitHub Actions workflow syntax' mise exec actionlint -- actionlint
run_group 'Pinned deployment images' scripts/check-pinned-deployment-images.sh
run_group 'Localisation catalogues' pnpm check:l10n
run_group 'Mobile UI localisation policy' pnpm check:ui-l10n
run_group 'Shell scripts' shellcheck scripts/*.sh server/deploy/*.sh
run_group 'Website check, audit, build, and generated-page contracts' bash -c 'pnpm --dir website audit --prod=false && pnpm --dir website check && pnpm --dir website build && pnpm --dir website check:a11y && pnpm --dir website check:headers'
run_group 'Mobile analysis, tests, and debug APK' bash -c 'cd mobile && dart format --set-exit-if-changed lib test && flutter analyze && flutter test && cd .. && scripts/build-mobile.sh android-debug'
# shellcheck disable=SC2016 # The command is deliberately evaluated by its child Bash process.
run_group 'Server lint, audit, tests, and SQLite migration' bash -c 'mkdir -p "$1" && cd server && uv run ruff format --check . && uv run ruff check . && uv run --with pyright pyright pluris_server && uv run pytest -q && uv run --with pip-audit pip-audit --local && PLURIS_ENVIRONMENT=test PLURIS_DATABASE_URL="sqlite+aiosqlite:///$1/pluris-local-ci-migration.db" uv run alembic upgrade head && PLURIS_ENVIRONMENT=test PLURIS_DATABASE_URL="sqlite+aiosqlite:///$1/pluris-local-ci-migration.db" uv run alembic check' bash "${ci_tmp_dir}"

printf '\nNOT RUN — requires macOS/hosted CI: unsigned iOS build\n'
printf 'NOT RUN — requires GitHub-hosted CI: PostgreSQL migration, server-container smoke test, CodeQL matrix, workflow permissions, artefact flow, Rulesets\n'

exit "${failed}"
