# Mobile releases

There are two automation paths: automatic debug prereleases from successful
internal branch CI (including `main`), and deliberate versioned releases from a
maintainer-created GPG-signed tag on `main`.

Pluris Haven is currently **PRE-ALPHA**. Alpha is next; beta is later. Do not
change maturity merely because a store/testing path exists.

## Debug prerelease

Every successful push to an internal branch, including `main`, is eligible for
an automatic GitHub debug prerelease after `CI` completes. The trusted publisher
workflow runs from the default branch; this is deliberate privilege separation.
The first governance PR does not receive this publication until that workflow
has been merged to `main` once.

Debug publication reads, but does not modify, `mobile/pubspec.yaml`. For source
version `0.3.0-pre-alpha.4+3004`, CI run 127 creates:

```text
debug-v0.3.0-pre-alpha.4.debug.127+3004
```

Each debug prerelease contains an Android debug APK, an unsigned iOS IPA where
the macOS CI build succeeds, `BUILD.txt`, and `SHA256SUMS.txt`. It states its
source branch, exact commit, source version, CI run number/ID, and build time.
These are test artifacts: they are never Play/App Store uploads, never official
releases, and the unsigned IPA is not installable or TestFlight evidence.

Debug tags begin `debug-v*`; `mobile-v*` remains reserved for official mobile
releases. A rerun checks that an existing debug tag peels to the same tested
commit and then leaves it unchanged. It refuses to move a tag targeting another
commit.

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
5. Open and merge a PR to protected `main`, with successful GitHub-hosted CI for
   the exact up-to-date merge candidate. Local test parity alone is not enough.
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

1. verifies the pushed tag and its GPG signature;
2. fetches `origin/main` and rejects a tag whose target commit is not contained
   in `main`;
3. validates tag/version/build consistency and rejects `.dev.N`;
4. builds Android release APKs and the release AAB;
5. builds an unsigned iOS IPA on `macos-26-intel` with Xcode 26.4.1;
6. writes build metadata and SHA-256 checksums;
7. creates/updates the canonical GitHub prerelease;
8. proposes website metadata through a normal PR when a change is needed.

A Play failure does not invalidate an existing GitHub Release. Website metadata
is not pushed directly to `main` or deployed by release automation: its PR must
pass the normal CI and Rulesets. These independent targets need explicit
retry/repair behavior rather than pretending to be transactionally atomic.

Current Play automation covers **internal testing**. Closed testing is decided
for the alpha distribution path. Use the manually dispatched `Publish existing
mobile release to Google Play track` workflow after the canonical GitHub
Release exists, supplying the exact configured Console track identifier. The
workflow verifies the signed tag, that its target is in `main`, and the release AAB checksum, does not
recreate GitHub artifacts, and exits successfully when that version is already
on the requested track. Console configuration and real external verification
remain required.

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
