# Mobile releases

There are two automation paths: development prereleases from `main`, and
versioned releases from a maintainer-created GPG-signed tag.

Pluris Haven is currently **PRE-ALPHA**. Alpha is next; beta is later. Do not
change maturity merely because a store/testing path exists.

## Dev prerelease

Use a dev build for routine testing between versioned releases.

1. Set a newer `.dev.N` version/build in `mobile/pubspec.yaml`, for example after
   the current `0.3.0-pre-alpha.4+3004` baseline:

   ```yaml
   version: 0.3.0-pre-alpha.4.dev.1+3005
   ```

2. Commit and push `main`.
3. Wait for the `CI` workflow.
4. When the version/build is newer than published mobile tags, the dev
   prerelease contains:
   - `pluris-haven-dev.apk`
   - `pluris-haven-dev-unsigned.ipa`
   - `BUILD.txt`
   - `SHA256SUMS.txt`

The dev APK is release-mode and uses the configured Android upload key. The IPA
is unsigned and can be re-signed with AltStore, SideStore, Sideloadly, or a
Developer-managed device. A non-dev version or non-monotonic build number is not
automatically published as a dev prerelease.

## Versioned prerelease

Use this for an explicitly approved named pre-alpha/alpha milestone.

The current released/tagged baseline is `0.3.0-pre-alpha.4+3004`. Do not move to
`0.3.0-alpha.1`: SemVer orders `alpha` before `pre-alpha` at the same core
version. The current candidate for a future monotonic first alpha is
`0.3.1-alpha.1+3005`, but it must not be set/tagged/released without explicit
approval.

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

4. Review and GPG-sign the release-preparation commit.
5. Push `main` and require successful GitHub-hosted CI for the exact commit.
   Local test parity alone is not enough.
6. Create the checked GPG-signed release tag:

   ```sh
   scripts/tag-mobile-release.sh
   ```

7. Review the exact tag push command printed by the script, then push the tag
   only when release publication is authorized.
8. Watch `Mobile Release` through completion and inspect failed job logs rather
   than treating static workflow validation as a release test.

The manual tag remains intentional: the maintainer GPG private key does not
belong in GitHub Secrets.

## Version rules

- `.dev.N` means an automatic release-mode development prerelease.
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

1. verifies the pushed tag and its GPG signature;
2. validates tag/version/build consistency and rejects `.dev.N`;
3. builds Android release APKs and the release AAB;
4. builds an unsigned iOS IPA on `macos-26-intel` with Xcode 26.4.1;
5. writes build metadata and SHA-256 checksums;
6. creates/updates the canonical GitHub prerelease;
7. after GitHub publication, independently:
   - uploads the AAB to Play internal testing; and
   - updates/validates/deploys website release metadata.

A Play failure does not invalidate an existing GitHub Release or block website
metadata. A website-metadata failure does not recreate release artifacts. These
independent targets need explicit retry/repair behavior rather than pretending
to be transactionally atomic.

Current Play automation covers **internal testing**. Closed testing is decided
for the alpha distribution path but still needs implementation/configuration and
real external verification.

## Google Play authentication

The current internal-upload job uses `google-github-actions/auth` with the
configured Google Play service-account JSON secret to obtain an Android
Publisher access token.

Never commit credentials. Release hardening should evaluate GitHub OIDC / Google
Workload Identity Federation if it fits the actual publisher path cleanly; do
not replace a working path with brittle custom authentication merely for the
label.

## iOS support

- Deployment target: iOS 14.
- GitHub build runner: `macos-26-intel`.
- Workflow-selected Xcode: 26.4.1.
- Building with a newer SDK does not change the iOS 14 deployment target.
- Features that require a newer iOS version need an iOS 14 fallback.
- Unsigned CI IPA output is compile/package evidence, not TestFlight/App Store
  verification.

Real-device/simulator work still includes notification permission timing,
App Lock/passcode behavior, screen-capture privacy, accessibility and upgrade
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
