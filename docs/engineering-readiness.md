# Engineering readiness

Internal release notes, last reviewed 2026-08-16.

## Ready for alpha testing

- Android release builds and ABI splits build with the configured signing key.
- Local data, import, export, encrypted recovery, and migration tests pass.
- Simply Plural import has a private local acceptance path. PluralKit has file
  and bounded live-token tests.
- The static website builds and has generated-page accessibility and security
  header checks.

These are engineering checks, not a claim that every real export or device has
been tested.

## Still conditional

- Android needs a smoke test using the actual published release artefact.
- iOS compiles unsigned in CI, but still needs signing, installation, and
  physical-device testing.
- Accessibility has widget and page checks, but still needs TalkBack,
  VoiceOver, keyboard, switch access, large text, contrast, and reduced-motion
  passes on devices.
- Large imports and decrypt-heavy screens still need profiling on representative
  Android and iOS hardware.

The optional server is not ready for public registration. Accounts, sessions,
password changes, deletion, encrypted backup upload, and experimental friends
exist, but verified email, recovery, moderation, policy, and production
operations are not complete.

Keep registration and friends disabled by default.

## Compatibility claims

- **Simply Plural:** import and re-import tests, plus a local private fixture.
- **PluralKit:** file and live-token tests.
- **Tupperbox, PluralSpace, and Prism:** checked-in shape and mapper tests only.

Do not claim real-export compatibility unless that export has been tested.

## Private test data

- Keep private exports, avatars, tokens, passwords, and recovery archives out of
  Git.
- Checked-in fixtures must say where they came from and what they test.
- Add a fixture when it reproduces a real compatibility problem, not merely to
  increase the fixture count.

## Release rules

- Local use must not depend on the server.
- The server must not receive plaintext private content.
- Device-key snapshots are not portable recovery. Password-protected archives
  are.
- Database migrations need tests using real rows from the affected schema.
- An unsigned iOS build is compile evidence, not a release.
- Automated accessibility checks do not replace device testing.
- Record the command, CI run, artefact, or test behind any readiness change.
