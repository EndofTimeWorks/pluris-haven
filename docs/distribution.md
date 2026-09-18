# Distribution

Pluris Haven should be installable and testable without depending on a single
store. GitHub Releases remain a direct distribution path while Google Play is
used for managed Android testing.

## Current release channels

The mobile version at the current pre-alpha baseline is
`0.3.0-pre-alpha.4+3004`.

- Successful internal branch CI, including ordinary `main` CI, publishes a
  clearly labelled `debug-v...` GitHub prerelease with debug/test artifacts.
- Versioned releases use an immutable GPG-signed `mobile-v...` tag only after
  an exact `release: <semantic-version>` marker at the current `main` tip has
  passed hosted CI. The protected release job creates the normal CI-signed tag;
  the maintainer's YubiKey path remains a recovery option.
- The project is still **PRE-ALPHA**. **ALPHA** is next; beta is later.
- Do not use `0.3.0-alpha.1` after `0.3.0-pre-alpha.4`: SemVer would order
  `alpha` before `pre-alpha` at the same core version. The proposed next named
  pre-alpha is `0.3.0-pre-alpha.5+3005`; it is not a released version.

## Android / GitHub Releases

Package id: `works.endoftime.plurishaven`.

Debug prereleases contain an Android debug APK, an unsigned iOS IPA where the
macOS build succeeds, `BUILD.txt`, deterministic release notes, and
`SHA256SUMS.txt`. They are not signed-store artifacts, Play uploads, App Store
uploads, or TestFlight evidence.

A versioned mobile release builds:

- a universal release APK;
- split APKs for supported Android ABIs;
- an Android App Bundle (`.aab`);
- an unsigned release-mode iOS IPA;
- `BUILD.txt`, `SHA256SUMS.txt`, and detached OpenPGP signatures.

The canonical GitHub Release is created only after the required Android and iOS
artifact jobs succeed and the AAB has reached the configured Play testing track.
Its direct universal APK is obtained through Play App Signing; this is distinct
from the project's Android upload-key signature and from the OpenPGP signatures.
The release workflow verifies its package id, version, universal shape, APK
signature, and the `PLURIS_PLAY_APP_SIGNING_CERT_SHA256` certificate pin before
GitHub Release publication.

For Obtainium, use the repository at
`https://github.com/EndofTimeWorks/pluris-haven`. Enable prereleases while
using dev builds and filter to `pluris-haven-dev.apk` for that channel.

Android will not update an app if the package id/signing identity changes. Old
experimental builds used other ids and may require a one-time uninstall before
the current `works.endoftime.plurishaven` package can be installed.

## Google Play

The versioned release workflow uploads the AAB only to Play **internal testing**
and rejects `production`. It retrieves Play's generated universal APK before
creating the canonical GitHub Release. Play App Signing, the Android upload key,
and detached OpenPGP artefact signatures are separate systems.

Current Play state:

- **IMPLEMENTED:** internal-track upload automation;
- **IMPLEMENTED (local/static):** a manually dispatched existing-release path
  for any explicitly supplied Play Console track, including the intended closed
  alpha track. It verifies the release AAB checksum and treats an already
  present version as a no-op; it never recreates GitHub release artifacts.
- **BLOCKED-EXTERNAL:** configure the actual closed track in Play Console and
  observe a real upload/promotion;
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
