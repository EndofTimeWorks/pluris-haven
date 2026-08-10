# Engineering Readiness

Internal release decision record. This is not a public checklist or product
overview.

Last reviewed: 2026-08-09

## Current decision

| Area                    | Status                   | Evidence                                                                                                                                                          | Remaining work                                                                                                |
| ----------------------- | ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| Android alpha build     | Conditional go           | Fresh release APK and ABI splits built locally; signing and package checks passed.                                                                                | Do a device smoke pass on the release artifact.                                                               |
| Import and local backup | Go for alpha             | Import, encryption, restore, live PluralKit fetching, and malformed-input tests pass.                                                                             | Keep adding fixtures when a real compatibility problem is found.                                              |
| Accessibility           | Conditional go           | Widget checks cover semantics, progress, high contrast, and reduced motion.                                                                                       | Test routes and sheets with TalkBack, VoiceOver, keyboard, switch access, and large text.                     |
| iOS compilation         | Conditional go           | Hosted CI compiles the unsigned iOS target on the pinned macOS runner.                                                                                            | Validate on a device and decide signing/distribution.                                                         |
| iOS distribution        | No-go                    | No signed IPA or TestFlight workflow.                                                                                                                             | Apple signing, provisioning, and physical-device validation.                                                  |
| Optional server         | No-go for public use     | Mobile and server support accounts, sessions, friends, blocks, sharing grants, encrypted backup upload, quotas, and deletion behind disabled-by-default settings. | Email verification, recovery, distributed limits, HTTPS operations, monitoring, moderation, and legal policy. |
| Website                 | Go for the current scope | Website checks and production build pass.                                                                                                                         | Keep status pages consistent with the actual mobile release.                                                  |

## Compatibility scope

| Source                | Current claim                   | Evidence                                        |
| --------------------- | ------------------------------- | ----------------------------------------------- |
| Simply Plural         | Import and re-import support    | Import tests and the local acceptance fixture.  |
| PluralKit             | File and live-token import      | Checked-in mapper and bounded API-client tests. |
| Tupperbox             | Contract-level importer support | Checked-in source-shape tests.                  |
| PluralSpace and Prism | Contract-level importer support | Checked-in source-shape tests.                  |

No private real-world export is claimed for a source unless it is listed in the
local test record.

## Fixture and data rules

- Private exports, avatar archives, and local backup archives stay untracked.
- Checked-in fixtures must state where they came from and what behavior they
  cover.
- Do not add private names, tokens, passwords, avatars, or account data to a
  fixture.
- A compatibility claim needs an import test, an acceptance run, or both.

## Architecture boundaries

- The mobile app remains usable without an account or server.
- Local encrypted storage is the primary copy of user data.
- The optional server must not receive plaintext system content.
- Bidirectional sync, federation, portable identity, and ActivityPub are out of
  scope for this alpha.
- Public registration and friends stay disabled until the server launch gates
  are complete.

## Recovery and migration requirements

- Database migrations must fail closed when they cannot preserve the data.
- Encrypted backup restore must be tested with a clean destination.
- Backup format changes need a compatibility or migration plan before release.
- A device-key snapshot is not a portable recovery path; the password-protected
  archive is the portable path.

## Release rules

- Do not describe the hosted server as public-ready while any server item above
  is `No-go`.
- An unsigned iOS compile is build evidence, not an iOS release.
- Widget coverage does not replace device accessibility testing.
- Keep local import fixtures and private exports out of Git.
- Record the command, CI run, artifact, or test that supports a status change.

## Evidence update

For each status change, record:

- last reviewed date;
- what changed;
- the command, test, CI run, or artifact used as evidence; and
- the remaining work or follow-up.

## Evidence to refresh

When this document changes, update only the rows affected by new evidence:

- mobile build version and artifact checks;
- Flutter and server test counts;
- hosted CI run and uploaded artifacts;
- device accessibility coverage;
- server deployment and recovery checks.

If a row has no current evidence, mark it `No-go` or `Blocked` instead of
guessing.
