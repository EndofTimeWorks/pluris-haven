# Contributing

Pluris Haven is an offline-first project with separate mobile, server, and
website toolchains. Keep changes reviewable and preserve the repository's
actual provenance.

## Inclusion

Pluris Haven is made by systems and welcomes systems, other collectives,
individuals, and anyone else who finds the project useful.

Respect each contributor's and account holder's chosen name, pronouns,
terminology, identity, and boundaries. Do not require anyone to disclose or
justify their gender, orientation, plurality, origin, diagnosis, disability,
body, culture, or spiritual framework. Do not assume one mind, one identity, or
one set of pronouns per body or account.

Product-facing changes must follow the language rules in
[`docs/product-goals.md`](docs/product-goals.md). If a technical or legal context
requires a narrower term, explain why and keep that assumption local.

## Checks

From the repository root:

```sh
pnpm ci:local
```

This is the normal local CI entry point. It reports the macOS/iOS and
GitHub-hosted-only checks as `NOT RUN`; it does not replace hosted CI.

## Branches and pull requests

Create normal work on a typed, lowercase kebab-case branch. Allowed prefixes
are `feat/`, `fix/`, `security/`, `perf/`, `refactor/`, `test/`, `docs/`,
`chore/`, `build/`, `ci/`, `release/`, `hotfix/`, `style/`, and `revert/`.
For example:

```text
feat/groups-custom-fields
fix/archive-purge-resurrection
ci/enforce-repository-governance
```

`dependabot/**` is allowed for GitHub-managed dependency branches. Check a name
locally with `scripts/check-branch-name.sh <branch>`.

GitHub currently rejects repository branch-name metadata Rulesets for this
repository (`branch_name_pattern` returns HTTP 422), so GitHub cannot block an
invalid branch at creation time here. The same canonical script runs in the
required `Branch policy` CI job and is enforced by the required `CI gate` before
anything can merge to `main`.

The permanent path is:

```text
typed branch → pnpm ci:local → push → hosted CI → debug prerelease → PR
→ CI gate → merge to protected main
```

Open a PR for every `main` change. `main` requires the stable `CI gate` check,
verified signed commits, and resolved conversations. Do not push ordinary work
directly to it.

## Commits

Use a Conventional Commit subject, for example:

```text
fix(import): reject oversized archive entries
```

Husky runs Prettier before a commit and commitlint against the commit message.
Keep unrelated local fixtures, exports, archives, generated files, and private
handoff material out of commits.

Keep commit timestamps, authorship, and history truthful. Do not rewrite old
commits to make new work look older. If code comes from a generator or another
tool, read it, test it, and make sure the commit explains the behavior it adds.

## Translations

See [TRANSLATING.md](TRANSLATING.md) if you want to add or fix a language.
