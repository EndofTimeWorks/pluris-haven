# Distribution

Pluris Haven should be installable and testable without depending on a single
store. GitHub Releases remain a direct distribution path while Google Play is
used for managed Android testing.

## Current release channels

The mobile version at the current pre-alpha baseline is
`0.3.0-pre-alpha.4+3004`.

- Development versions use a `.dev.N` prerelease suffix and are published from
  successful `main` CI only when their build number is newer than existing
  mobile tags.
- Versioned releases use a maintainer-created GPG-signed `mobile-v...` tag.
- The project is still **PRE-ALPHA**. **ALPHA** is next; beta is later.
- Do not use `0.3.0-alpha.1` after `0.3.0-pre-alpha.4`: SemVer would order
  `alpha` before `pre-alpha` at the same core version. A future alpha must use a
  monotonic core/build version; `0.3.1-alpha.1+3005` is the current candidate,
  not a released version.

## Android / GitHub Releases

Package id: `works.endoftime.plurishaven`.

Dev prereleases contain a release-mode Android APK signed with the configured
upload key, an unsigned iOS IPA, `BUILD.txt`, and `SHA256SUMS.txt`.

A versioned mobile release builds:

- a universal release APK;
- split APKs for supported Android ABIs;
- an Android App Bundle (`.aab`);
- an unsigned release-mode iOS IPA;
- `BUILD.txt` and `SHA256SUMS.txt`.

The canonical GitHub Release is created only after the required Android and iOS
artifact jobs succeed.

For Obtainium, use the repository at
`https://github.com/EndofTimeWorks/pluris-haven`. Enable prereleases while
using dev builds and filter to `pluris-haven-dev.apk` for that channel.

Android will not update an app if the package id/signing identity changes. Old
experimental builds used other ids and may require a one-time uninstall before
the current `works.endoftime.plurishaven` package can be installed.

## Google Play

The versioned release workflow contains an Android Publisher path that uploads
the already-published release AAB to Play **internal testing**. Play and website
metadata fan out independently after the canonical GitHub Release, so a Play
failure does not make an existing GitHub release disappear or leave website
metadata blocked behind Play.

Current Play state:

- **IMPLEMENTED:** internal-track upload automation;
- **DECIDED / PENDING:** configurable closed testing for the alpha distribution
  path;
- **NOT YET CLAIMED VERIFIED:** a real Play Console upload/promotion must be
  observed successfully before the external service path is called verified.

The current workflow authenticates through `google-github-actions/auth` using a
Google Play service-account JSON secret and requests an Android Publisher access
token. Credentials must never be committed. Release hardening should evaluate
GitHub OIDC / Google Workload Identity Federation if it cleanly fits the actual
Play publishing path.

Do not overwrite `website/static/.well-known/assetlinks.json` without proving
which Android signing certificate the fingerprint represents.

## iOS

The iOS host target uses bundle id `works.endoftime.plurishaven`, with an Apple
privacy manifest checked in. GitHub-hosted macOS jobs currently build an
unsigned IPA with Xcode 26.4.1. AltStore, SideStore, Sideloadly, or an Apple
Developer-managed device must re-sign it before installation.

Officially signed IPA/TestFlight/App Store distribution still needs Apple
signing credentials plus simulator/physical-device validation. An unsigned IPA
is compile evidence, not an App Store release.

## Store readiness

Before an alpha store rollout is called ready, keep a tracked checklist for:

- Play internal and configured closed-track behavior;
- application signing and Play App Signing assumptions;
- monotonically increasing version codes;
- upgrade/migration smoke tests from supported earlier builds;
- privacy-policy and account-deletion URLs;
- Data Safety/content/age-rating inputs;
- screenshots, icons, feature graphics, tester instructions and other listing
  requirements;
- actual external-service verification separately from local/static workflow
  validation.

Hosted accounts, social features, public profiles, messaging, and younger-user
flows can trigger extra legal/safety requirements in different jurisdictions.
Local-only use should remain available even if a store or hosted service is not.

## Funding

Funding is optional. It must not unlock core data access, imports, exports,
privacy controls, or accessibility features.

Structured funding metadata is served from:

- `https://pluris.endoftime.dev/funding.json`
- `https://pluris.endoftime.dev/.well-known/funding-manifest-urls`
