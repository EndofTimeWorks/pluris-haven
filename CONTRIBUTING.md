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
pnpm install
pnpm format:check
pnpm lint:website
pnpm lint:server:format
pnpm lint:server
```

For mobile changes, also run the pinned Flutter checks from `mobile/`:

```sh
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

The Android and iOS release workflows provide the platform-specific build
gates. Do not claim iOS evidence from Linux; it requires macOS and Xcode.

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
