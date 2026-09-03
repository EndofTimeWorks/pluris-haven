# Pluris Haven

Pluris Haven is an offline-first app for systems, other collectives,
individuals, and anyone else who finds its tools useful. It is made by systems
and does not assume which words or experiences fit someone.

Made by systems. Designed to welcome everyone without assuming how many are
present, which words they use for themselves, or what their experience looks
like.

The app works locally without an account. Accounts, encrypted server backups,
friends, and other network features are optional. The long-term sync model is
transport-independent; a central server is infrastructure, not a requirement
for local use.

## Targets

- `mobile` - Flutter app targeting Android and iOS.
- `website` - static SvelteKit project site.
- `server` - optional accounts, sessions, friends, password recovery, and
  encrypted backup storage.

## What works

- local member, group, tag, custom-field, front, note, journal, poll, reminder,
  message, and preference storage
- mobile navigation, dashboard, themes, terminology, and accessibility settings
- tested Simply Plural and PluralKit file/live import paths
- Tupperbox, PluralSpace, and Ampersand file-normalisation paths with checked-in
  mapper coverage
- local export, password-protected portable recovery, and encrypted server
  backup upload/download/restore
- optional server accounts, revocable sessions, one-time-token password
  recovery, encrypted backups, and experimental friends/blocking
- automatic dev prereleases and signed-tag versioned releases through GitHub
  Actions
- Android AAB/APK release artifacts and Play internal-testing automation after a
  canonical GitHub release

OpenPlural import is wanted but currently missing after an earlier history
rewrite. The local API, complete chat/revision product surfaces, Play closed
alpha testing, public registration, federation, browser access to private data,
and signed iOS/TestFlight distribution are not ready yet.

## Docs

- `docs/project-state.md` - current product decisions and implementation state
- `docs/engineering-readiness.md` - current pre-alpha verification and remaining
  release work
- `docs/release/mobile.md` - mobile dev builds and versioned releases
- `docs/mobile-accessibility.md` - mobile accessibility rules and device checks
- `docs/product-goals.md` - product boundaries and inclusive language rules
- `docs/local-data-model.md` - local storage, encryption, and archive boundaries
- `docs/distribution.md` - install channels, Play/GitHub distribution, and
  funding metadata

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

The iOS targets require macOS and Xcode. Current CI can produce an unsigned IPA
that can be re-signed for tester installation with AltStore, SideStore, or
Sideloadly; it is not App Store/TestFlight-ready.

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
