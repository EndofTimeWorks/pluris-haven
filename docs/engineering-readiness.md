# Engineering readiness

Internal pre-alpha readiness record, reconciled 2026-09-02.

This document records evidence, not marketing status. Pluris Haven remains
**PRE-ALPHA**; alpha is the next maturity stage after the current completion and
distribution work is ready.

## Current locally verified baseline

- The protected local-text upgrade path migrates supported recent `ph1:` data to
  context-bound `ph2:` data before later readers/migrations, in both foreground
  and background startup.
- App Lock hides private UI while persisted security state is unknown without
  triggering premature OS authentication, and remains fail-closed if device
  credentials disappear.
- Notification permission logic separates explicit prompting from nonprompting
  delivery checks. Reminder/front delivery does not claim notification success
  when permission blocks delivery.
- The complete Flutter test suite and `flutter analyze` passed after the final
  notification/recovery cleanup.
- The full server suite passed with one-time-token password recovery, verifying
  STARTTLS, response-path-independent background email delivery, encrypted
  backups, and queued backup-deletion cleanup covered.
- The static website passes its build, type/check, generated accessibility and
  security-header/CSP checks.
- Release workflows pass static `actionlint` validation. Real GitHub-hosted CI
  and external publication paths must still be checked separately; static YAML
  validation is not an external release verification.

## Release/distribution state

- Android release builds produce signed APKs plus an AAB using the configured
  upload-key path.
- Versioned release automation waits for Android and unsigned-iOS artifacts
  before creating the canonical GitHub Release.
- Play internal-testing automation runs only after that GitHub Release.
- Website release metadata/deployment is independent of Play after GitHub
  publication.
- Play closed testing is wanted for alpha but is not implemented/verified yet.
- Current Play authentication uses a service-account JSON secret through
  `google-github-actions/auth`; WIF/OIDC should be evaluated as release
  hardening if compatible with the real publisher path.
- Current CI can build an unsigned iOS IPA on `macos-26-intel` with Xcode 26.4.1.
  Signed/TestFlight distribution still needs Apple credentials and device
  validation.

## Product work before alpha is called ready

The following are completion targets, not proof that the current build is
broken:

- Restore OpenPlural import through the current import architecture.
- Finish exposed local chat/message/category/channel product paths.
- Finish note/journal/message revision/history/restore behaviour that is already
  decided.
- Implement the scoped/revocable near-term local API before exposing it as an
  alpha feature.
- Finish the already-decided advanced reminder, poll, front-audit and System
  Safety gaps that are exposed in the alpha UI.
- Reconcile customization, terminology, low-cognitive-load and accessibility
  gaps.
- Implement/configure Play closed testing and run real GitHub/Play workflow
  verification.
- Keep documentation/store claims aligned with what has actually been verified.

Full federation, desktop/private-web clients, watch clients, plugins and other
explicitly deferred platform work are not alpha prerequisites.

## Server/hosted-service conditions

The optional server is not ready for public registration.

Accounts, sessions, password changes/recovery, deletion/recovery, encrypted
backup upload/download, and experimental friends/blocking exist. Production
registration remains disabled because verified email and other hosted-service
operational/policy gates are not complete.

Keep registration and friends disabled by default until their explicit gates are
satisfied. Password recovery being implemented does not by itself make public
registration ready.

## Import compatibility evidence

- **Simply Plural:** importer/re-import coverage plus private/local acceptance
  tooling for realistic exports.
- **PluralKit:** file and bounded live-token coverage.
- **Tupperbox:** normalized member-mapper coverage; do not claim broad real-export
  compatibility without representative exports.
- **PluralSpace:** normalized roster/front mapper coverage; authenticated live
  API import remains deferred.
- **Ampersand:** normalized database-export mapper coverage.
- **Prism:** source/plan scaffolding exists, but it is not a verified current
  compatibility claim.
- **OpenPlural:** currently regressed/missing after history rewrite and must be
  restored before claiming current support.

Do not claim real-export compatibility merely because a source shape, parser or
mapper test exists.

## Still needs real environment/device coverage

- Inspect and run the real safe GitHub CI/test workflows against the pushed
  baseline; investigate CI-only failures rather than relying on local parity.
- Perform an actual Play internal upload before marking that external path
  verified, then configure/verify the intended closed-testing path.
- Smoke-test Android upgrade/migration using actual distributed artifacts.
- Sign/install iOS builds and verify notification permission, App Lock,
  screen-capture privacy and upgrade behavior on simulator/physical hardware.
- Perform TalkBack, VoiceOver, keyboard, switch access, large-text, contrast and
  reduced-motion passes on devices.
- Profile large imports and decrypt-heavy screens on representative Android/iOS
  hardware.

## Private test data

- Keep private exports, avatars, tokens, passwords and recovery archives out of
  Git.
- Checked-in fixtures must say where they came from and what they test.
- Add a fixture when it reproduces a real compatibility problem, not merely to
  increase fixture count.

## Release rules

- Local use must not depend on the server.
- The server must not receive plaintext private content by default.
- Device-key snapshots are not portable recovery; password-protected archives
  are the portable path.
- Database migrations need tests using realistic rows from the affected schema.
- An unsigned iOS build is compile evidence, not a signed release.
- `actionlint` is static workflow evidence, not a successful GitHub Actions run.
- Automated accessibility checks do not replace device testing.
- Record the command, CI run, artifact, device test, or external-service result
  behind any readiness change.
