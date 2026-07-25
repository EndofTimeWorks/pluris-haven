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

Keep commit timestamps, authorship, and history truthful. Do not rewrite old
commits to make new work look older. If code comes from a generator or another
tool, read it, test it, and make sure the commit explains the behavior it adds.
