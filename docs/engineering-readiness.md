# Engineering Readiness

Internal release decision record. This is not a public checklist or product
overview.

Last reviewed: 2026-07-24

## Current decision

| Area                    | Status                   | Evidence                                                                                                                   | Remaining work                                                                                                |
| ----------------------- | ------------------------ | -------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| Android alpha build     | Conditional go           | Fresh release APK and ABI splits built locally; signing and package checks passed.                                         | Do a device smoke pass on the release artifact.                                                               |
| Import and local backup | Go for alpha             | Import, encryption, restore, and malformed-input tests pass.                                                               | Keep adding fixtures when a real compatibility problem is found.                                              |
| Accessibility           | Conditional go           | Widget checks cover semantics, progress, high contrast, and reduced motion.                                                | Test routes and sheets with TalkBack, VoiceOver, keyboard, switch access, and large text.                     |
| iOS compilation         | Conditional go           | Hosted CI compiles the unsigned iOS target on the pinned macOS runner.                                                     | Validate on a device and decide signing/distribution.                                                         |
| iOS distribution        | No-go                    | No signed IPA or TestFlight workflow.                                                                                      | Apple signing, provisioning, and physical-device validation.                                                  |
| Optional server         | No-go for public use     | Authentication, sessions, sharing, backup storage, quotas, and account deletion exist behind disabled-by-default settings. | Email verification, recovery, distributed limits, HTTPS operations, monitoring, moderation, and legal policy. |
| Website                 | Go for the current scope | Website checks and production build pass.                                                                                  | Keep status pages consistent with the actual mobile release.                                                  |

## Release rules

- Do not describe the hosted server as public-ready while any server item above
  is `No-go`.
- An unsigned iOS compile is build evidence, not an iOS release.
- Widget coverage does not replace device accessibility testing.
- Keep local import fixtures and private exports out of Git.
- Record the command, CI run, artifact, or test that supports a status change.

## Evidence to refresh

When this document changes, update only the rows affected by new evidence:

- mobile build version and artifact checks;
- Flutter and server test counts;
- hosted CI run and uploaded artifacts;
- device accessibility coverage;
- server deployment and recovery checks.

If a row has no current evidence, mark it `No-go` or `Blocked` instead of
guessing.
