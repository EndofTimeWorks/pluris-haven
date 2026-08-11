# Distribution

Pluris Haven should be installable without depending on a single store.

## Android

Primary pre-alpha builds are GitHub Releases APKs.

- Repository: `https://github.com/EndofTimeWorks/pluris-haven`
- Package id: `works.endoftime.plurishaven`
- Dev APK asset: `pluris-haven-dev.apk`
- Dev tags: `mobile-v0.2.0-pre-alpha.N.dev.N+BUILD`
- Versioned tags: `mobile-v0.2.0-pre-alpha.N+BUILD`

Dev prereleases are published automatically after the mobile CI job succeeds.
They are release-mode APKs signed with the same Android upload key as versioned
builds, so Obtainium can update them without exposing Flutter's debug service.
Versioned releases require a maintainer-pushed GPG-signed tag; GitHub then
builds and publishes the Android and iOS artifacts automatically.

For Obtainium:

1. Add `https://github.com/EndofTimeWorks/pluris-haven`.
2. Enable prereleases while testing dev builds.
3. Filter APK assets to `pluris-haven-dev.apk` for the dev channel.
4. Use GitHub Releases sorting by date.

Android will not update an app if the package id changes. Experimental builds
used older ids. If Android reports a package conflict, uninstall the older test
build once, then install the current `works.endoftime.plurishaven` build.

## iOS

The iOS host target uses bundle id `works.endoftime.plurishaven`, with an Apple
privacy manifest checked in. Versioned releases include an unsigned IPA built
on macOS. AltStore, SideStore, or Sideloadly must re-sign it before installation.
Officially signed IPA and TestFlight builds still need Apple signing credentials
and physical-device validation.

When the iOS client is ready, prefer a SideStore/AltStore source before assuming
App Store availability.

## Store Policy

Hosted accounts, social features, public profiles, messaging, and younger-user
flows can trigger extra legal and safety work in different places. The app
should keep local-only use available even if a store or hosted service is not
available somewhere.

## Funding

Funding is optional. It must not unlock core data access, imports, exports,
privacy controls, or accessibility features.

Structured funding metadata is served from:

- `https://pluris.endoftime.works/funding.json`
- `https://pluris.endoftime.works/.well-known/funding-manifest-urls`
