# Pluris Haven

Pluris Haven is an offline-first app for systems, other collectives,
individuals, and anyone else who finds its tools useful. It is made by systems
and does not assume which words or experiences fit someone.

Made by systems. Designed to welcome everyone without assuming how many are
present, which words they use for themselves, or what their experience looks
like.

The app works locally without an account. Sync, friends, hosted imports, and
other network features are opt-in.

## Targets

- `mobile` - Flutter app targeting Android and iOS.
- `website` - static SvelteKit project site.
- `server` - optional accounts, sessions, friends, and encrypted backup storage.

## What works

- local member, group, note, and front tracking
- mobile navigation and dashboard
- dashboard, theme, and language preferences
- Simply Plural and PluralKit file and live-token import paths
- local export, password-protected recovery, and encrypted server backup upload
- optional server accounts, revocable sessions, encrypted backups, and experimental friends/blocking
- dev and tagged mobile builds through GitHub Actions

Public registration, federation(tbd), browser access to private data, and signed iOS
distribution are not ready.

## Docs

- `docs/release/mobile.md` - mobile dev builds and releases
- `docs/mobile-accessibility.md` - mobile accessibility rules and alpha gate
- `docs/product-goals.md` - product boundaries and inclusive language rules
- `docs/distribution.md` - install channels, Obtainium notes, and funding metadata

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

## Licence

Pluris Haven is source-available for noncommercial use. Commercial use,
including selling builds or hosted access, requires a separate written licence
from EndofTimeWorks. See [LICENSE](LICENSE).
