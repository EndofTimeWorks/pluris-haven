# Mobile Releases

There are two release types. Dev builds are automatic. Versioned releases use a
GPG-signed tag created on your machine.

## Dev prerelease

Use a dev build for routine testing between versioned releases.

1. Set a new version in `mobile/pubspec.yaml`:

   ```yaml
   version: 0.2.0-pre-alpha.2.dev.1+2009
   ```

2. Commit and push `main`.
3. Wait for the `CI` workflow.
4. Open GitHub Releases and check that the new prerelease contains:
   - `pluris-haven-dev.apk`
   - `BUILD.txt`
   - `SHA256SUMS.txt`

Nothing else is needed. On pushes to `main`, `CI` builds a release-mode APK with
the configured Android upload key. The publish job reuses that signed artefact.
If the version is not a `.dev.N` version, or its build number is not newer than
the existing tags, publishing is skipped.

## Versioned prerelease

Use this for a named alpha milestone such as `0.2.0-pre-alpha.2+2008`.

1. Set the release version in `mobile/pubspec.yaml`. Remove `.dev.N` and increase
   the number after `+`.
2. Move the current changelog notes under a heading for that version and date.
3. The website release metadata is updated automatically after GitHub publishes
   the release.
4. Run the release checks:

   ```sh
   pnpm lint
   pnpm test:server
   pnpm --dir website build
   cd mobile
   flutter analyze
   flutter test
   cd ..
   ```

5. Review and commit the release files with GPG signing:

   ```sh
   git diff --check
   git diff
   git add mobile/pubspec.yaml CHANGELOG.md \
     website/src/routes/changelog/+page.svelte \
     website/src/routes/distribution/+page.svelte \
     website/src/routes/download/+page.svelte
   git commit -S -m "chore(release): mobile VERSION+BUILD"
   ```

6. Push `main`:

   ```sh
   git push origin main
   ```

   Wait for `CI` to pass. The next command refuses to continue until the exact
   commit at `HEAD` has a successful CI run.

7. Create the checked, GPG-signed tag:

   ```sh
   scripts/tag-mobile-release.sh
   ```

8. Run the exact `git push origin refs/tags/...` command printed by the script.
9. Wait for `Mobile Release` to pass.
10. Open the GitHub prerelease and check for:
    - universal APK
    - arm64-v8a, armeabi-v7a and x86_64 APKs
    - unsigned IPA
    - `BUILD.txt`
    - `SHA256SUMS.txt`

The tag push is intentionally manual. CI cannot create your GPG signature
without a copy of your private key, and that key does not belong in GitHub
Secrets.

## Version rules

- `.dev.N` means an automatic release-mode dev prerelease.
- A version without `.dev.N` means a signed, versioned release.
- The number after `+` is Android's build number and iOS's bundle version.
- Increase both the prerelease version and the build number. Do not publish a
  second release with the same values.
- Keep build numbers above `2000`; older builds already used that range.

The Android package ID is `works.endoftime.plurishaven`. Old experimental builds
used `support.plurishaven` and must be uninstalled once before upgrading.

## What CI does

`Mobile Release` reads the version from the tag, then builds Android and iOS in
parallel. Android APKs are release-signed. The IPA is unsigned and must be
re-signed with AltStore, SideStore or Sideloadly. The final job creates the
checksums and GitHub prerelease; it is the only release job with write access.

## iOS support

- Deployment target: iOS 14.
- Build runner: macOS Tahoe with Xcode 26.4.1.
- Building with a newer SDK does not change the iOS 14 deployment target.
- iOS 12 and earlier are not supported by the current Flutter line.
- Features that require a newer iOS version must have an iOS 14 fallback.

## Local Import Acceptance

Large Simply Plural exports can exercise import, deduplication, encrypted
backup rehearsal, and clean restore without adding the source data to Git:

```sh
cd mobile
PLURIS_SP_EXPORT=/absolute/path/to/export.json \
PLURIS_SP_AVATARS=/absolute/path/to/avatars.zip \
flutter test test/local_import_acceptance_test.dart --reporter expanded
```

The test uses in-memory databases and checks import, re-import, encryption,
restore rehearsal and clean restore. Device-key snapshots are not portable to a
new device. Use the password-protected archive export for that.
