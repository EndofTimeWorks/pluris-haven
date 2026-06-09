# Pluris Haven

An offline-first home for plural systems.

The project has three targets: Android, iOS, and website. Local app use should work without an account. Online features such as accounts, friends, sync, and hosted import/export are optional.

## Product Direction

- **Android first** - current native app target.
- **iOS later** - native iOS app when the core model is stable.
- **Website alongside apps** - accounts, hosted import/export, project info, and later web access.
- **Offline by default** - core records live on-device and remain usable without a connection.
- **Opt-in online services** - sync, friends, PluralKit, backups, and hosted imports need clear data notices.

## Core Features

- **Logs** - timeline entries for fronts, switches, notable events, and imported history.
- **Chat** - local system chat and optional proxied/connected chat integrations.
- **Archive** - preserve old members, chats, fronts, polls, journals, folders, and imports without deleting them.
- **Journal** - private system and member journals, encrypted before online sync.
- **Polls** - local decision polls with member votes and archived results.
- **Custom fronts** - custom front states beyond a single current member.
- **Custom terms** - configurable system language for members, fronts, roles, and relationship terms.
- **Different languages** - app text and user-defined labels should support multilingual systems.
- **Folders** - organize members, journals, logs, polls, and archive items.
- **Export** - full local export so users can leave or back up their data.
- **SP import** - import Simply Plural exports.
- **PK import** - import PluralKit data.
- **Sticky notification** - Android foreground notification for current front and quick front changes.
- **Friends** - optional trusted sharing for front status, selected profiles, and shared history.
- **Statistics** - local fronting, journal, poll, and activity stats.

## Stack

- **Android:** Kotlin + Jetpack Compose, local-first.
- **iOS:** Swift/SwiftUI, planned.
- **Website:** SvelteKit.
- **Local data:** encrypted device database first; server sync is optional.
- **Server:** add account/sync/import backend when those features start.
- **Hosting:** Coolify.

## Repo Layout

- `android` - native Android app.
- `ios` - future native iOS app.
- `website` - SvelteKit website/app.
- `sp-replacement-schema.md` - local-first data model and sync boundary.

## Privacy Model

Default data stays local. Any online connection must show a plain-language disclaimer before setup:

- what service is being connected
- what data is uploaded or shared
- whether the service can read that data
- how to disconnect it
- what data remains after disconnecting

Online data is split into two tiers:

- **Local/private data** - journals, private notes, custom fields, archives, polls, and detailed logs stay local or are end-to-end encrypted before sync.
- **Integration-readable data** - only the fields required for a connected service, such as front status or proxy metadata, may be readable by the server or third-party service.

## Developing

Website:

```sh
cd website
pnpm install
pnpm dev
```

Android:

```sh
cd android
./gradlew :app:assembleDebug
```

## License

MIT
