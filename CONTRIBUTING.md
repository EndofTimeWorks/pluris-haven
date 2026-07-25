# Contributing

Pluris Haven is an offline-first project with separate mobile, server, and
website toolchains. Keep changes reviewable and preserve the repository's
actual provenance.

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

Commit timestamps, authorship, and history should remain truthful. Do not
rewrite or fabricate timestamps to make work appear manually authored or to
hide tool assistance. AI-assisted changes are acceptable when the contributor
understands, reviews, tests, and documents the resulting behavior.
