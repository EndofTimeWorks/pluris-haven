# Mobile releases

There are two automation paths: automatic debug prereleases from successful
ordinary `main` CI, and deliberate versioned releases from an exact validated
release-marker tip on `main`.

Pluris Haven is currently **PRE-ALPHA**. Alpha is next; beta is later. Do not
change maturity merely because a store/testing path exists.

## Debug prerelease

Every successful ordinary `main` push is eligible for an automatic GitHub debug
prerelease after `CI` completes. Pull-request and feature-branch builds remain CI
artefacts only: they never create a GitHub tag or Release, so update clients such
as Obtainium cannot discover them. The trusted publisher workflow runs from the
default branch; this is deliberate privilege separation.

Debug publication reads, but does not modify, `mobile/pubspec.yaml`. For source
version `0.3.0-pre-alpha.4+3004`, CI run 127 creates:

```text
debug-v0.3.0-pre-alpha.4.debug.127+3004
```

Each debug prerelease contains an Android debug APK, an unsigned iOS IPA where
the macOS CI build succeeds, `BUILD.txt`, and `SHA256SUMS.txt`. It states its
source branch, exact commit, source version, CI run number/ID, signing class,
and build time. Current `main` debug APKs are re-signed with a dedicated stable
debug-prerelease key so that later `main` builds can upgrade them. The privileged
signer requires the tested SHA to remain the exact `main` tip and verifies both
the debug package ID and expected certificate fingerprint. Branch builds use
disposable runner certificates but are retained only as CI artefacts. These are
test artefacts: they are never Play/App Store uploads, never official releases,
and the unsigned IPA is not installable or TestFlight evidence.

The first stable-signed `main` debug APK cannot upgrade a previously installed
APK signed by a disposable runner key; uninstall that old debug package once.
Do not reuse the official Android upload key for debug prereleases.

An exact `main` commit subject of `release: <semantic-version>` is reserved for
an official release candidate. It does not make a second public
debug release for that SHA. The trusted post-CI validator checks the exact CI
SHA, source version, changelog, monotonicity, GitHub signature status, and that
the SHA is still the current `origin/main` tip. If `main` moved, it stops with
`ABORT -- release marker is no longer the current main tip.`

Debug tags begin `debug-v*`; `mobile-v*` remains reserved for official mobile
releases. A rerun checks that an existing debug tag peels to the same tested
commit and then leaves it unchanged. It refuses to move a tag targeting another
commit.

## Versioned prerelease

Use this for an explicitly approved named pre-alpha/alpha milestone. Prepare it
on `release/<version>` from protected `main`; do not prepare or tag it from an
ordinary feature branch.

The latest signed tag is `0.3.1-alpha.1+3006`, but it remains unpublished after
an Android archive-save defect was found. Do not move or reuse that tag. The
prepared successor is `0.3.1-alpha.2+3007`; it remains unreleased until every
release gate completes.

1. Set the approved release version in `mobile/pubspec.yaml`. Versioned releases
   must not contain `.dev.N`, and the build after `+` must increase.
2. Move current changelog notes under the approved version/date.
3. Run the local release checks appropriate to the changed tree, including at
   minimum:

   ```sh
   pnpm lint
   pnpm test:server
   pnpm --dir website check
   pnpm --dir website build
   pnpm --dir website check:a11y
   pnpm --dir website check:headers
   cd mobile
   flutter analyze
   flutter test
   cd ..
   actionlint .github/workflows/*.yml
   git diff --check
   ```

4. Generate reviewed deterministic notes from the previous official tag with

   ```sh
   node scripts/generate-release-notes.mjs --from mobile-v<previous> --to HEAD
   ```

   Put the resulting entry in `CHANGELOG.md` before the PR lands.

5. Make the final release-preparation commit exactly:

   ```text
   release: <semantic-version>
   ```

   For the prepared candidate, use:

   ```text
   release: 0.3.1-alpha.2
   ```

6. Review and GPG-sign the release-marker commit, then open and merge a PR to
   protected `main`, with successful GitHub-hosted CI for
   the exact up-to-date merge candidate. Local test parity alone is not enough.
7. The trusted validator checks only the exact successful `main` tip. If a new
   commit lands first, refresh the release branch, regenerate the changelog, and
   make a new final marker; do not tag the older marker.
8. The trusted default-branch workflow rechecks that the marker is still the
   current `main` tip, then creates and verifies the signed immutable tag. It
   explicitly dispatches `Mobile Release`, because tags pushed with
   `GITHUB_TOKEN` do not trigger another workflow's tag-push event.
   `scripts/tag-mobile-release.sh` remains the maintainer's YubiKey-backed
   recovery path if that automation cannot complete.
9. Watch `Mobile Release` through completion and inspect failed job logs rather
   than treating static workflow validation as a release test.

## Version rules

- Debug publication adds `.debug.<CI-run-number>` to the source prerelease (or
  `-debug.<CI-run-number>` when the source has no prerelease); it does not alter
  the source version.
- Versioned tags may use the intended prerelease channels `pre-alpha`, `alpha`,
  and later `beta`.
- A versioned release must not use `.dev.N`.
- The number after `+` is Android's version code/build number and iOS's bundle
  version.
- Core/prerelease ordering and the build number must both move forward relative
  to the releases being upgraded.
- The Android package ID is `works.endoftime.plurishaven`.

Old experimental Android builds used other package ids/signing states and may
need a one-time uninstall before the current package can be installed.

## What the versioned workflow does

`Mobile Release`:

1. verifies the selected tag and its trusted GPG signature;
2. fetches `origin/main` and rejects a tag whose target commit is not contained
   in `main`;
3. validates tag/version/build consistency and rejects `.dev.N`;
4. builds Android release APKs and the release AAB;
5. builds an unsigned iOS IPA on `macos-26-intel` with Xcode 26.4.1;
6. uploads the AAB only to Play internal testing, then obtains the Play-generated
   universal APK for direct distribution;
7. writes build metadata, SHA-256 checksums, and detached OpenPGP signatures;
8. creates the immutable canonical GitHub prerelease;
9. proposes website metadata through a normal PR when a change is needed.

A Play failure prevents the official GitHub Release from being created. Website
metadata is not pushed directly to `main` or deployed by release automation:
its PR must pass the normal CI and Rulesets. These targets are independent, so
each needs an explicit retry and repair path.

Current official Play automation covers **internal testing** only and fails
closed for `production`. The manually dispatched repair workflow also rejects
`production`, verifies the trusted tag, `main` ancestry, and AAB checksum, and
does not recreate GitHub artefacts. Console configuration and real external
verification remain required.

## Signing boundaries

Official tags use the CI signing subkey beneath the active Git identity. The
maintainer's YubiKey signing subkey remains the manual recovery path. Downloaded
artefacts carry detached OpenPGP signatures from the separate Apps/release
identity. Android APK/AAB package signatures are separate again: the direct APK
is generated by Play App Signing after the AAB reaches internal testing.
The `PLURIS_PLAY_APP_SIGNING_CERT_SHA256` variable pins the expected Play
app-signing certificate; the release stops if the generated APK differs.

The Android upload keystore and passwords belong only in `official-release`
environment secrets. Both Android release-building jobs and Play publication
jobs must reference that environment; do not keep duplicate Android signing or
Play credentials as repository-wide secrets. The stable debug-prerelease key is
separate, belongs only in the `debug-prerelease` environment, and is exposed
only to the exact-current-`main` signing job. Keep owner-held backups of both
keystores outside the repository with mode `0600` or stronger protection.

## Google Play authentication

The current internal-upload job uses `google-github-actions/auth` with the
configured Google Play service-account JSON secret to obtain an Android
Publisher access token.

Never commit credentials. Release hardening should evaluate GitHub OIDC / Google
Workload Identity Federation if it fits the actual publisher path cleanly; do
not replace a working path with brittle custom authentication merely for the
label.

## iOS support

- Deployment target for new builds: iOS 15, required by `sentry_flutter` 10.
- GitHub build runner: `macos-26-intel`.
- Workflow-selected Xcode: 26.4.1.
- Building with a newer SDK does not change the declared iOS 15 deployment
  target. Previously published builds retain their own deployment target.
- Unsigned CI IPA output is compile/package evidence, not TestFlight/App Store
  verification.

Real-device/simulator work still includes notification permission timing,
App Lock/passcode behaviour, screen-capture privacy, accessibility and upgrade
smoke tests.

## Local import acceptance

Large Simply Plural exports can exercise import, deduplication, encrypted
backup rehearsal, and clean restore without adding private source data to Git:

```sh
cd mobile
PLURIS_SP_EXPORT=/absolute/path/to/export.json \
PLURIS_SP_AVATARS=/absolute/path/to/avatars.zip \
flutter test test/local_import_acceptance_test.dart --reporter expanded
```

The test uses temporary/in-memory state and checks import, re-import, encryption,
restore rehearsal and clean restore. Device-key server snapshots are not
portable to a new device; use the password-protected archive export for portable
recovery.
