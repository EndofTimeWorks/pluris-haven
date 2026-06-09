# Pluris Haven - Offline-First Data Model

## Product Shape

Pluris Haven is an Android-first offline app with a SvelteKit site/web app. The core product should not require an account, network access, or a hosted server. Online services are optional and must be enabled one at a time with a clear disclaimer.

## Required Modules

- Logs
- Chat
- Archive
- Journal
- Polls
- Custom fronts
- Custom terms
- Different languages
- Folders
- Export
- Simply Plural import
- PluralKit import
- Sticky Android notification
- Friends
- Statistics

## Android Stack

- Kotlin native Android app.
- Jetpack Compose for UI.
- ViewModels/state holders with unidirectional data flow.
- Repository layer over local database and optional remote data sources.
- Local database is the source of truth.
- Android Keystore for key material where possible.
- Foreground notification for current front and quick actions.

## Storage Strategy

### Local Device Store

The Android app owns the primary copy of user data. Local records should be queryable offline for:

- current front and front history
- logs
- chats and messages
- journals
- polls and votes
- members
- folders
- custom terms
- archives
- statistics
- import/export manifests
- service connection settings

Sensitive local fields should be encrypted at rest before real user data is stored. Export should produce a complete portable archive so the user can back up or leave without depending on the hosted service.

### Optional Server Store

The server exists for opt-in features:

- web account access
- encrypted sync
- friends and trusted sharing
- Slack/Plura connection
- PluralKit connection
- hosted backup/export
- long-running import jobs

The server should not be required for normal Android use.

## Online Service Disclaimer

Before connecting any online service, the UI must explain:

- the service name
- what data leaves the device
- whether Pluris Haven can read that data
- whether the third-party service can read that data
- how to disconnect
- what remote data remains after disconnecting

This applies to sync, friends, Slack/Plura, PluralKit, cloud backup, hosted import, and any future integration.

## Privacy Tiers

### Local/private

These stay local by default and are end-to-end encrypted before optional sync:

- journal content
- chat message bodies
- private member fields
- poll questions/options/votes
- detailed logs
- archive notes
- custom fields

### Integration-readable

These may be readable by a server or third-party service only when needed for an enabled integration:

- selected display names
- selected avatar URLs
- selected pronouns
- selected front status
- proxy trigger metadata
- external service IDs

## Server Schema Sketch

The Drizzle schema in `src/lib/server/db/schema.ts` mirrors the optional server-side sync/integration model:

- `users`
- `systems`
- `folders`
- `members`
- `custom_terms`
- `front_states`
- `front_events`
- `logs`
- `chats`
- `chat_messages`
- `journal_entries`
- `polls`
- `poll_votes`
- `friends`
- `service_connections`
- `import_jobs`
- `export_jobs`
- `archives`

Ciphertext columns are used where the hosted service should not read content. Plaintext columns are limited to routing, ordering, integration metadata, and user-visible labels that the user has chosen to share.

## Import/Export

Import/export are part of the app core and must work offline.

### Export

Export must work locally and include:

- system profile
- members
- folders
- logs
- front history
- chats
- journals
- polls and votes
- custom terms
- archive metadata
- import provenance
- service connection metadata, excluding tokens by default

Encrypted export is the default. Plain JSON export can exist for portability, but it must require an explicit warning because it exposes private data.

### SP Import

Simply Plural import should parse exports locally first. Users choose what to import and what, if anything, to later sync online.

### PK Import

PluralKit import should preserve proxy/member/fronting data while keeping private Pluris Haven-only fields local unless the user opts into sync.

## Android Sticky Notification

The Android app should provide a persistent notification for:

- current front display
- quick front switch
- custom front state selection
- pause/clear front
- offline status

This should be local-first and should not require the server.

## Statistics

Stats should be computed locally first:

- fronting time by member/state
- switch frequency
- journal activity
- poll participation
- chat activity
- import totals
- archive totals

Server-side stats can exist only as an opt-in sync convenience.
