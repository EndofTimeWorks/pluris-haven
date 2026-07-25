# Changelog

This is the detailed release record for Pluris Haven. It explains user and
operator impact, security and compatibility consequences, verification, and
remaining blockers. Commit messages provide source traceability; they are not
a substitute for these release notes.

## Unreleased

Current target: Android-first alpha, mobile version
`0.2.0-pre-alpha.1.dev.9+2007`.

### Added: repository quality gates

- The repository now has a root pnpm tooling package with Prettier 3 and the
  Svelte formatter plugin for tracked web, workflow, documentation, and
  configuration files.
- Husky installs `pre-commit` and `commit-msg` hooks. The pre-commit hook
  checks the repository's supported text surface with Prettier; the commit-msg
  hook enforces Conventional Commits with commitlint.
- Existing platform checks remain authoritative for their code: Svelte check
  for the website, Ruff format/lint for the server, and Flutter format/analyze/
  test/build gates for mobile.

### Changed: import and backup safety

- Imported ZIP files are bounded before decompression: input size, entry count,
  per-entry expansion, and total relevant expansion are capped. Malformed ZIP
  input is rejected as an unreadable import instead of escaping to the UI as an
  exception.
- Imported remote avatar URLs must use HTTP(S), default web ports, no embedded
  credentials, and DNS results outside private, loopback, link-local,
  multicast, documentation, carrier-grade NAT, and metadata address ranges.
  Redirects are disabled so a public avatar URL cannot redirect into a local
  network. Avatar bytes retain their existing 10 MiB response limit.
- Encrypted local data, resumable encrypted backup chunks, restore rehearsal,
  tamper rejection, and private fixture-backed import acceptance remain local-
  first. The server still receives opaque ciphertext rather than archive
  plaintext or a device master key.

### Changed: server and CI security defaults

- Login, registration, and refresh endpoints now have a configurable
  per-process rate limiter with `Retry-After` responses. This is defense in
  depth; public or multi-process deployments still require distributed or
  reverse-proxy limits.
- The container no longer trusts forwarded headers from arbitrary sources.
  Operators who place it behind a proxy must configure a narrowly trusted
  proxy boundary rather than restoring `--forwarded-allow-ips=*`.
- The Dependabot-only CI path no longer has write permissions or the ability to
  approve pull requests automatically. Passing checks remain evidence for a
  human review decision.
- The standard crypto subkey derivation remains version `v1`. Replacing its
  domain-separated construction would require a versioned migration and
  compatibility plan; it is recorded as review debt, not changed silently.

### Verification evidence

- Prettier check - pass for the tracked web, workflow, documentation, and
  configuration surface.
- Svelte check - pass with zero errors and zero warnings.
- Ruff format and lint - pass for the server, including the rate limiter.
- commitlint - pass for the recent Conventional Commit history; the hooks
  also reject new non-conforming messages locally.
- Mobile import hardening - system Dart format and analysis pass; focused
  Flutter tests were added for malformed ZIPs, declared ZIP expansion limits,
  and unsafe avatar URL classes.
- Prior full fixture-backed mobile suite - 140 tests passed with no skips
  before the current import-hardening tests were added. A fresh Flutter run is
  still pending because this Linux checkout's Flutter SDK cache is read-only.
- Android release evidence remains: Java 17/Flutter 3.44.4 signed universal
  and split APKs, package identity `works.endoftime.plurishaven`, build
  `2007`, and passing local checksum assembly.
- The server rate-limiter unit test passes. The local FastAPI TestClient hangs
  during application lifespan startup before the first request, so the full
  server integration suite is not claimed green from this environment.

### Known limitations and alpha blockers

- Hosted macOS iOS compilation has not run from this checkout. The release
  workflow now gates Android publication on that unsigned iOS build, but the
  checkbox remains open until a hosted run succeeds.
- TalkBack, VoiceOver, keyboard/switch access, large text, high contrast,
  reduced motion, focus order, and route-by-route semantics still need manual
  device evidence.
- Public server launch still requires distributed rate limits, email
  verification, recovery, HTTPS/proxy policy, moderation, privacy/terms, and
  operational monitoring. Registration and friends remain disabled by default.
- Account/session UI and a mobile network uploader for encrypted snapshots are
  not finished. Losing the device encryption key remains unrecoverable.
- Bidirectional sync, portable identity, federation, ActivityPub, and signed
  iOS distribution remain outside this alpha.

### Audit trail

Recent implementation commits are listed for source-level traceability:

- `1c790fb` - `feat(server): add auth endpoint rate limits`
- `92550f1` - `fix(server): stop trusting arbitrary proxy headers`
- `e563be9` - `fix(ci): remove automated pull request approval`
- `cf5981a` - `fix(import): harden archive and avatar fetching`
- `077bb91` - `fix(build): guard iOS checks before Flutter setup`
- `09ecb05` - `ci(mobile): gate releases on iOS compilation`
- `2f924ee` - `style(format): normalize web and documentation files`
- `dd1791a` - `chore(tooling): add formatting and commit hooks`
- `30ea105` - `ci(tooling): enforce repository quality gates`
- `696843c` - `chore(tooling): expose platform lint commands`
- `86a6be0` - `docs(website): align alpha changelog status`
- `df1afc8` - `docs(release): restore detailed alpha change record`
- `98253b4` - `chore(tooling): include changelog in format gate`

## Changelog rules

Each coherent implementation change gets its own Conventional Commit and a
matching release-note update. Notes should answer, where applicable:

- What can a user or operator do now?
- What changed in storage, network behavior, security, or privacy?
- What migration, compatibility, recovery, or versioning consequence exists?
- What evidence verifies it, and what evidence is still missing?
- What remains deliberately unavailable for the target release?
