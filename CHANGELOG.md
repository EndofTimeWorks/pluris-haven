# Changelog

## Unreleased

Android-first alpha work: `0.2.0-pre-alpha.1.dev.9+2007`.

### Tooling

- Added a root pnpm package for repository-wide checks.
- Prettier covers the website, docs, workflows, and root configuration.
- Husky runs the format check before commits and commitlint on commit messages.
- `pnpm lint` runs Prettier, Svelte check, Ruff, and ShellCheck.
- CI runs the same text and commit-message checks on pull requests.
- Added [CONTRIBUTING.md](CONTRIBUTING.md) with the local commands and commit
  format.

### Mobile import and backup

- ZIP imports now limit the input size, entry count, per-entry expansion, and
  total expansion. Malformed ZIPs are rejected cleanly.
- Remote avatar imports only accept safe HTTPS URLs. Private and special-use
  addresses are rejected, DNS results are checked, redirects are off, and
  plaintext HTTP is rejected.
- Encrypted backup snapshots now limit chunk size, chunk count, ciphertext
  metadata, and total restored plaintext. Restore checks chunk order and hashes
  before touching the archive. Bad authentication and malformed base64 are
  reported as format errors.
- Local encrypted archives still support restore rehearsal, tamper detection,
  and resumable opaque chunks. The server never sees the archive plaintext or
  the device key.

### Server and CI

- Register, login, and refresh have configurable per-process rate limits and
  return `Retry-After` when the limit is reached.
- The server container no longer trusts arbitrary forwarded headers. A proxy
  deployment needs an explicit, narrow trusted-proxy configuration.
- Dependabot CI no longer has write access or the ability to approve a pull
  request automatically.
- Backup snapshot creation reserves a configurable per-user snapshot count and
  total byte quota before accepting a manifest.
- An authenticated account can now be deleted after confirming its current
  password. This removes its sessions, friend data, snapshots, and opaque
  backup files. The mobile app does not expose this yet.
- A declined friend request cannot be immediately sent again; the cooldown is
  configurable and returns `Retry-After`.
- Friend-request creation is also limited by both client IP and account, so a
  single user cannot flood the endpoint through one or many addresses.
- Crypto subkey derivation stays at `v1`; changing it needs a migration path.

### Checks

- `pnpm lint` passes: Prettier, Svelte check, Ruff format/lint, and ShellCheck.
- The website audit, check, and production build pass. Commitlint passes too.
- The accessibility contract test passes all five checks, including status,
  settings-row, avatar, high-contrast, and import/restore progress semantics.
- The server suite passes: 21 tests, including account deletion, rate-limit,
  and quota tests.
- A fresh local Flutter 3.44.4 release build produced a signed universal APK
  for package `works.endoftime.plurishaven`, build `2007`, plus arm64-v8a,
  armeabi-v7a, and x86_64 splits. `apksigner` v2 verification and `aapt2`
  package/ABI checks pass; Flutter assigns the splits version codes `4007`,
  `3007`, and `6007` respectively.
- Flutter passed 147 tests. Two optional fixture tests were skipped because
  their fixture paths were not set.
- Hosted CI run `30185733204` passed the website, mobile, server, repository,
  iOS, and CodeQL jobs. The iOS job uploaded `pluris-haven-ios-unsigned`.
- That hosted run predates the unpushed local commits listed here. No new
  Android or iOS release artifact has been published for this local delta.
- The local Flutter cache is read-only, so tests used temporary generated
  directories. No project files were changed by that workaround.
- `SECURITY.md` now explains private reporting and calls out the remaining
  account-lifecycle and multi-process rate-limit limits.

### Not done yet

- The hosted iOS evidence is unsigned compilation only. Signed iOS
  distribution remains outside this alpha.
- TalkBack, VoiceOver, keyboard/switch access, large text, high contrast,
  reduced motion, focus order, and every route/sheet still need device notes.
- Public server launch still needs distributed rate limits, email verification,
  account recovery and deletion, HTTPS/proxy operations, moderation, legal
  pages, and monitoring. Registration and friends remain disabled by default.
- The mobile account/session UI and network uploader for encrypted snapshots are
  not finished. Losing the device key is still unrecoverable.
- Sync, portable identity, federation, ActivityPub, and signed iOS releases are
  outside this alpha.
