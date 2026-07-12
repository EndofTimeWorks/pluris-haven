# Distribution

Pluris Haven should be installable without depending on a single store.

## Android

Primary pre-alpha builds are GitHub Releases APKs.

- Repository: `https://github.com/EndofTimeWorks/pluris-haven`
- Package id: `works.endoftime.plurishaven`
- Dev APK asset: `pluris-haven-dev.apk`
- Dev tags: `mobile-v0.2.0-pre-alpha.1.dev.N+BUILD`
- Versioned tags: `mobile-v0.2.0-pre-alpha.1+BUILD`

For Obtainium:

1. Add `https://github.com/EndofTimeWorks/pluris-haven`.
2. Enable prereleases while testing dev builds.
3. Filter APK assets to `pluris-haven-dev.apk` for the dev channel.
4. Use GitHub Releases sorting by date.

Android will not update an app if the package id changes. Experimental builds
used older ids. If Android reports a package conflict, uninstall the older test
build once, then install the current `works.endoftime.plurishaven` build.

## iOS

The iOS host target exists and uses bundle id `works.endoftime.plurishaven`,
with an Apple privacy manifest checked in. It is not a supported release channel
yet because signed IPA/TestFlight builds still need macOS/Xcode CI validation.

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
