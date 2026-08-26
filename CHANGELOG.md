# Changelog

## 0.3.0-pre-alpha.4 - 2026-08-25

Security release: `0.3.0-pre-alpha.4+3004`.

### Security and release hardening

- Empty encrypted values are now authenticated like every other protected
  field. Existing local records migrate before the stricter check is enabled,
  so optional blank values remain intact while tampered empty ciphertext fails
  closed.
- The container smoke test now supplies isolated CI-only secrets, matching the
  server's fail-loud startup requirements.

## 0.3.0-pre-alpha.3 - 2026-08-24

Beta hardening and import performance: `0.3.0-pre-alpha.3+3003`.

### Mobile privacy and recovery

- Local avatar files are encrypted at rest and legacy plaintext avatar files
  migrate in place. A missing device encryption key now fails closed instead of
  silently replacing the key and making existing data unrecoverable.
- Local records use opaque identifiers rather than creation timestamps.
- Account deletion now has a 30-day grace window. Password reset links can
  recover a deletion-scheduled account; login no longer restores it silently.
- Remote backup restore validates metadata and enforces the declared byte total
  while downloading.

### Import and performance

- Simply Plural imports recognise avatar ZIPs and can repair prior remote-avatar
  references through the configured rescue endpoint.
- Member, custom-front, and front-history views decrypt and construct only the
  records they need. Profile member/front lists are virtualised, and front
  history loads older entries when the end of the page is reached.
- Debug builds now use a separate Android package and label, so they can remain
  installed beside the release app without a signing conflict.

### Server and release hardening

- Auth and non-chunk API requests have request-size limits. Backup snapshots
  and cleanup jobs enforce bounded storage, incomplete-upload expiry, and
  resilient scheduled deletion cleanup.
- The server distinguishes recovery from ordinary login, hides
  deletion-scheduled accounts from social flows, and requires explicit proxy
  trust in Compose deployments.
- CI now audits Python dependencies, verifies PostgreSQL migrations, bounds job
  duration, and checks the website CSP header.

## 0.3.0-pre-alpha.2 - 2026-08-21

Privacy follow-up and repository maintenance: `0.3.0-pre-alpha.2+3002`.

### Mobile privacy and security

- iOS now hides app content before the system captures an app-switcher preview.
- Startup refreshes now clear local server sessions only when the server
  explicitly rejects the refresh token, while transient network failures keep
  offline sessions available.

### Maintenance

- Continued splitting the local repository implementation into focused store
  parts without changing its public interface.

## 0.3.0-pre-alpha.1 - 2026-08-18

Android privacy hardening: `0.3.0-pre-alpha.1+3001`.

### Mobile privacy and security

- Screenshots and screen recordings of the app now show a black rectangle on
  Android instead of member, front, or journal content.
- Added an optional app lock: the app can require the device's own screen
  lock (biometric, PIN, pattern, or password) before it opens, and re-locks
  whenever the app is backgrounded. No separate app-specific secret is
  stored.
- Copying the local archive JSON to the clipboard now marks it sensitive on
  Android 13+, so the system clipboard preview shows a masked placeholder
  instead of the plaintext content.
- The Android fronting-status notification gained two off-by-default
  settings: whether it shows on the lock screen at all, and whether it names
  the fronting member or just says the app is active.
- Avatar photos are now excluded from iOS iCloud/iTunes backups, matching
  Android's existing full backup exclusion.

### Mobile UI

- Fixed dashboard shortcut tiles overflowing at large system text-scale
  settings.
- The User Report screen can now open a prefilled GitHub bug report
  alongside the existing local-report copy button.

### Repository

- Added GitHub issue templates for bug reports and feature requests.

## 0.2.0-pre-alpha.2 - 2026-08-10

Android-first alpha release: `0.2.0-pre-alpha.2+2008`.

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
- PluralKit live import now fetches bounded account data without storing or
  logging the token.
- The release workflow packages the unsigned iOS device build as an IPA for
  re-signing with AltStore, SideStore, or Sideloadly.
- Dev prereleases reuse the signed release-mode APK already built by CI instead
  of running a second Flutter test and build job.

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
- The optional mobile server surface now supports accounts, revocable sessions,
  encrypted backup upload and deletion, friend requests, grants, and blocking.
- Server account, import, backup, friend, and reminder surfaces use the typed
  localisation catalogue.
- Versioned releases now validate metadata once, build Android and iOS in
  parallel, and grant repository write access only to the publishing job.

### Checks

- `pnpm lint` passes: Prettier, Svelte check, Ruff format/lint, and ShellCheck.
- The website audit, check, and production build pass. Commitlint passes too.
- The accessibility contract test passes seven checks, including every drawer
  route, status, settings-row, avatar, high-contrast, and import/restore
  progress semantics.
- The server suite passes: 24 tests, including account deletion, rate-limit,
  and quota tests.
- A fresh local Flutter 3.44.4 release build produced a signed universal APK
  for package `works.endoftime.plurishaven`, build `2007`, plus arm64-v8a,
  armeabi-v7a, and x86_64 splits. `apksigner` v2 verification and `aapt2`
  package/ABI checks pass; Flutter assigns the splits version codes `4007`,
  `3007`, and `6007` respectively.
- The iOS CI gate now runs on GitHub's Intel Tahoe image with Xcode 26.4.1.
  The deployment target remains iOS 14; this only moves the build check to the
  current SDK line.
- Flutter passed 162 tests. Two optional fixture tests were skipped because
  their fixture paths were not set.
- Hosted CI run `30185996637` passed the website, mobile, server, repository,
  iOS, and CodeQL jobs. The iOS job uploaded `pluris-haven-ios-unsigned`.
- The next hosted release will publish the unsigned iOS IPA alongside the
  Android APKs and include both in the checksum manifest.
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
  account recovery, HTTPS/proxy operations, moderation, legal pages, and
  monitoring. Registration and friends remain disabled by default.
- The password-protected archive remains the portable local recovery path:
  import it on a new device with its passphrase to create new device-key
  encryption there.
- Sync, portable identity, federation, ActivityPub, and signed iOS releases are
  outside this alpha.
