# Pluris Haven

An offline-first home for plural systems. Inspired by Simply Plural and PluralKit.

Pluris Haven is built around a local Android app first, with a web app/site for desktop access and project information. The default experience should work without an account, a server, or network access. Online services are optional integrations and must clearly explain what data leaves the device before they are connected.

## Product Direction

- **Android first** - the primary app starts as a local-first mobile experience.
- **Web alongside mobile** - SvelteKit provides the public site and a browser app for desktop workflows.
- **Offline by default** - core records live on-device and remain usable without a connection.
- **Opt-in online services** - sync, friends, Slack/Plura, PluralKit, backups, and imports are explicit connections with privacy disclaimers.
- **Plural-system focused** - language, fronting, identity, logs, and sharing are designed around system workflows rather than generic notes.

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
- **Web/Site:** SvelteKit.
- **Local data:** encrypted device database first; server sync is optional.
- **Server:** PostgreSQL + Drizzle ORM for opt-in sync, integrations, web accounts, and hosted backups.
- **Auth:** better-auth for online accounts only.
- **Async jobs:** future server-side import and integration workers.
- **Hosting:** Coolify.

## Repo Layout

- `apps/pluris-haven-andorid` - native Android app.
- `src/routes` - SvelteKit site/web app.
- `src/lib/server` - optional server-side database and integration code.
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

For the current SvelteKit site:

```sh
pnpm install
pnpm dev
```

The Android app lives under `apps/pluris-haven-andorid`.

## License

MIT
