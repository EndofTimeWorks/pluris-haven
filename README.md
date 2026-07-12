# Pluris Haven

Offline-first plural system app.

The goal is a familiar Simply Plural-style workflow without requiring an
account. The app should work locally first. Sync, friends, hosted imports, and
other network features are opt-in.

## Targets

- `mobile` - Flutter app targeting Android and iOS.
- `website` - SvelteKit site/app shell.
- server/sync - later, once the local app and importers are solid.

## Current Focus

- local member, group, note, and front tracking
- familiar mobile navigation and dashboard
- dashboard/theme/language preferences
- Simply Plural and PluralKit import paths
- local export/backup shape
- dev and tagged mobile builds through GitHub Actions

## Docs

- `docs/product-goals.md` - product scope and milestone order
- `docs/release/mobile.md` - mobile dev builds and releases
- `docs/distribution.md` - install channels, Obtainium notes, and funding metadata
- `sp-replacement-schema.md` - local data model notes

## CI

- `Mobile CI` checks mobile changes, uploads a debug APK, and compiles an
  unsigned iOS app on macOS.
- `Mobile Dev Release` updates the `mobile-dev` prerelease from `main`.
- `Mobile Release` builds tagged APK releases.
- `Website CI` audits, checks, and builds the website.

## Mobile

```sh
mise trust
mise install
cd mobile
flutter analyze
flutter test
flutter run
```

Android Studio should open `mobile/` as the Flutter project.

Reusable build targets are available from the repository root:

```sh
scripts/build-mobile.sh android-debug
scripts/build-mobile.sh android-release
scripts/build-mobile.sh android-split
scripts/build-mobile.sh ios-check
scripts/build-mobile.sh ios-debug
```

The iOS targets require macOS and Xcode. They compile without code signing and
do not produce an installable or App Store-ready IPA.

## Website

```sh
cd website
pnpm install
pnpm dev
```

## Privacy

Local data stays local by default. Any online connection must say:

- what service is being connected
- what data leaves the device
- who can read it
- how to disconnect
- what remains after disconnecting

Pluris Haven is a personal tracking and journaling tool. It is not medical
care, medical advice, crisis support, or a replacement for professional help.

## License

Pluris Haven is source-available for noncommercial use. Commercial use,
including selling builds or hosted access, requires a separate written license
from EndofTimeWorks. See [LICENSE](LICENSE).
