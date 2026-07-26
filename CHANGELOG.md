# Changelog

## Unreleased

Android-first alpha target: `0.2.0-pre-alpha.1.dev.9+2007`.

### Tooling

- Added a small root pnpm package for repository-wide checks.
- Prettier covers the website, docs, workflows, and root configuration.
- Husky runs the format check before commits and commitlint on commit messages.
- `pnpm lint` runs Prettier, Svelte check, Ruff, and ShellCheck.
- CI runs the same text and commit-message checks on pull requests.
- Added [CONTRIBUTING.md](CONTRIBUTING.md) with the local commands and commit
  format.

### Mobile import and backup

- ZIP imports now limit the input size, entry count, per-entry expansion, and
  total expansion. Malformed ZIPs are rejected cleanly.
- Remote avatar imports only accept safe HTTP(S) URLs. Private and special-use
  addresses are rejected, DNS results are checked, and redirects are off.
- Encrypted backup snapshots now limit the chunk size, chunk count, ciphertext
  metadata, and total restored plaintext. Chunk order and hashes are checked
  before restore. Bad authentication or base64 data becomes a format error.
- The existing local encrypted archive, restore rehearsal, tamper detection,
  and resumable opaque-chunk design are unchanged. The server never gets the
  archive plaintext or the device key.

### Server and CI

- Register, login, and refresh have configurable per-process rate limits and
  return `Retry-After` when the limit is reached.
- The server container no longer trusts arbitrary forwarded headers. A proxy
  deployment needs an explicit, narrow trusted-proxy configuration.
- Dependabot CI no longer has write access or the ability to approve a pull
  request automatically.
- The crypto subkey derivation remains version `v1`. Changing it needs a
  migration path, so it was not changed as part of this alpha work.

### Checks

- `pnpm lint` passes: Prettier, Svelte check, Ruff format/lint, and ShellCheck.
- `pnpm audit --prod=false` passes for the website after raising the SvelteKit
  and PostCSS floors.
- Recent commits pass commitlint.
- System Dart format and analysis pass for the import and backup changes.
- The accessibility contract test passes all five checks, including status and
  settings-row semantics and both high-contrast theme paths.
- The complete server suite passed: 17 tests in 2.61 seconds, including the
  rate-limit tests.
- The current Android release run passed Dart format, `flutter analyze`, the
  signed universal APK, all three ABI splits, APK signature verification, and
  package inspection. It produced package
  `works.endoftime.plurishaven`, version `0.2.0-pre-alpha.1.dev.9`, build
  `2007`.
- The current full Flutter run passed 146 tests. Two optional local-fixture
  tests were skipped because their fixture paths were not set in this run.
- The Flutter SDK cache used by this checkout is read-only, so the test run used
  writable temporary generated directories; that workaround did not change the
  project files.

### Still open for alpha

- The hosted macOS run reached Xcode but hit a CocoaPods sandbox mismatch. The
  project now keeps Flutter on its existing CocoaPods integration; that fix
  needs a new hosted run before the iOS checkbox can be checked.
- The hosted website run also needs to rerun on the dependency-floor fix. The
  local audit, check, and build are clean.
- TalkBack, VoiceOver, keyboard/switch access, large text, high contrast,
  reduced motion, focus order, and every route/sheet still need device notes.
- Public server launch still needs distributed rate limits, email verification,
  account recovery, HTTPS/proxy operations, moderation, legal pages, and
  monitoring. Registration and friends remain disabled by default.
- The mobile account/session UI and network uploader for encrypted snapshots are
  not finished. Losing the device key is still unrecoverable.
- Sync, portable identity, federation, ActivityPub, and signed iOS release are
  outside this alpha.

### Recent commits

- `dfa6632` - `fix(website): raise audited dependency floors`
- `123fdc4` - `fix(mobile): keep iOS on CocoaPods`
- `aec80a0` - `test(accessibility): cover status semantics`
- `e07cdb8` - `docs(release): correct mobile evidence count`
- `c25e810` - `docs(release): record final mobile test count`
- `4c1ba2f` - `docs(release): record high contrast coverage`
- `8b2e0d6` - `test(accessibility): cover high contrast themes`
- `cb8a077` - `docs(release): record passing server suite`
- `78c2a75` - `docs(release): record current Android build`
- `9d3318c` - `docs(release): record current mobile test evidence`
- `22910be` - `docs(project): make notes more direct`
- `351264a` - `docs(release): record bounded backup manifests`
- `7642d02` - `fix(backup): bound encrypted snapshot resources`
- `30ea105` - `ci(tooling): enforce repository quality gates`
- `696843c` - `chore(tooling): expose platform lint commands`
- `86a6be0` - `docs(website): align alpha changelog status`
- `df1afc8` - `docs(release): restore detailed alpha change record`
- `98253b4` - `chore(tooling): include changelog in format gate`
- `1c790fb` - `feat(server): add auth endpoint rate limits`
- `2f924ee` - `style(format): normalize web and documentation files`
- `dd1791a` - `chore(tooling): add formatting and commit hooks`
- `92550f1` - `fix(server): stop trusting arbitrary proxy headers`
- `e563be9` - `fix(ci): remove automated pull request approval`
- `cf5981a` - `fix(import): harden archive and avatar fetching`
- `077bb91` - `fix(build): guard iOS checks before Flutter setup`
- `09ecb05` - `ci(mobile): gate releases on iOS compilation`
