# Engineering readiness

Pluris Haven is **pre-alpha**. This page lists what still needs evidence before an alpha release. It
is not a claim that the current branch or a locally built APK is ready to publish.
[Distribution](distribution.md) describes the release workflow; the
[completion ledger](completion-ledger.md) records local fixes and their tests.

## Release path

The repository has separate CI paths for development builds and deliberate versioned releases.
Android release jobs produce APKs and an AAB. The macOS CI path can build an unsigned iOS IPA. The
versioned workflow is designed to wait for required artefacts before publishing the canonical GitHub
Release.

Play internal-track upload automation and a manually dispatched existing-release path for a
configured testing track are present. Neither a successful local workflow check nor source code
proves a Play Console upload. Closed-track configuration, a real upload or promotion, and retry
behaviour still need external verification. Signed iOS installation and TestFlight/App Store
distribution need Apple credentials and device testing.

The server prototype is optional. Public registration remains disabled; it is not a prerequisite for
local alpha use. Device-key snapshots are not portable recovery. Password-protected local archives
are the recovery path to test across devices.

## Evidence still needed

- Run the final Flutter, migration, localisation and website checks at the exact release commit.
  Investigate hosted CI failures instead of substituting earlier local results.
- Install a signed Android artefact over supported earlier builds, then check local data,
  encryption-key availability, archives, reminders and front history after restart.
- Restore an encrypted local archive into a separate fresh installation and verify its
  relationships, votes, reminders, history and assets.
- Build and install on iOS, then test App Lock, backup exclusion, key loss, notification permission
  and delivery, screen capture, file dialogs and upgrade behaviour. An unsigned IPA build is compile
  evidence only.
- Use TalkBack and VoiceOver on representative screens. Check keyboard and switch access, large
  text, focus return, contrast and reduced motion. Widget semantics tests do not establish device
  behaviour.
- Test representative real exports for each advertised import source. A source-shaped fixture proves
  only the cases in that fixture. In particular, independent PluralPort Draft v0.1 files and real
  OpenPlural exports are needed before broad compatibility claims.
- Verify the exact GitHub Actions trigger and artefact chain, tag signature, checksums, Play signing
  identity, website metadata update and failure recovery. A static workflow check is not a hosted
  run.
- Complete Play Console listing, Data Safety, age rating, tester instructions and signing
  configuration before store publication.

Keep private exports, avatars, tokens, passwords and recovery archives out of Git. Checked-in
fixtures should state their source and the behaviour they test. Do not add fixtures solely to
increase a test count.

The most recent local commands and results are in the [completion ledger](completion-ledger.md).
Physical-device, store and live service checks remain open until their own evidence is recorded.
