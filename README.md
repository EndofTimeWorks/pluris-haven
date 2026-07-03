# Pluris Haven

Offline-first app for tracking systems, members, groups, notes, and fronting.

The app works locally without an account. Sync, friends, hosted imports, and
other network features are opt-in.

## Targets

- `mobile` - Flutter app for Android now, iOS next.
- `website` - SvelteKit site/app shell.
- server/sync - later, once the local app and importers are solid.

## Current Focus

- local member, group, note, and front tracking
- mobile navigation and dashboard
- dashboard, theme, and language preferences
- Simply Plural and PluralKit import paths
- local export and backup
- dev and tagged mobile builds through GitHub Actions

## Docs

- `docs/release/mobile.md` - mobile dev builds and releases
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
