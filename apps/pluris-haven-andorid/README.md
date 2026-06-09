# Pluris Haven Android

Native Android is the first real app target. The app must be useful without an account, without network access, and without the hosted server.

## Stack Decision

- **Language:** Kotlin
- **UI:** Jetpack Compose
- **Architecture:** unidirectional data flow, ViewModels/state holders, repositories
- **Local database:** Room/SQLite, with encryption selected before storing real user data
- **Secrets:** Android Keystore
- **Background UX:** foreground service notification for current front and quick actions
- **Network:** disabled by default; only used after opt-in service setup

## Development Prerequisites

- Android Studio or Android SDK installed locally.
- SDK Platform 36 installed.
- `ANDROID_HOME` set, or `local.properties` containing `sdk.dir=/path/to/Android/Sdk`.
- Gradle 9.x or Android Studio's bundled Gradle.

The current repository does not include a Gradle wrapper yet. Add one after the Android SDK is installed and the project syncs cleanly.

## Source Of Truth

The local encrypted device database is the source of truth for:

- systems
- members
- custom fronts
- logs
- chat
- journals
- polls
- folders
- archive
- custom terms
- statistics inputs
- import/export manifests
- service connection settings

The server must never be required to open the app, edit local data, import, export, or view history.

## Security Requirements

- Require no account for local use.
- Encrypt sensitive data at rest before real user data is stored.
- Store key material in Android Keystore where possible.
- Support app lock with device credential or biometrics.
- Do not write plaintext private data to logs, crash reports, backups, or analytics.
- Do not add analytics by default.
- Treat online sync, friends, PK, Slack/Plura, and hosted backup as explicit service connections.
- Show a per-service disclaimer before any data leaves the device.

## Import And Export

Import/export are core offline features, not admin tools.

Export should support:

- encrypted `.pluris` backup by default
- optional plain JSON export only after warning
- all members, fronts, logs, chats, journals, polls, folders, terms, archives, and stats inputs
- import provenance and app/schema version
- no service tokens by default

Import should support:

- Simply Plural export files
- PluralKit data
- Pluris Haven backups
- local preview before commit
- conflict handling before overwriting existing data

## Friends

Friends are optional online E2EE sharing.

- Friend setup requires an online identity and public key.
- Sharing is per friend and per data type.
- Default share level is front status only.
- Journals, private chat, detailed logs, polls, and archives are never shared by default.
- Shared private content should be encrypted on-device for the recipient.

## First Implementation Milestones

1. Scaffold Kotlin/Compose app.
2. Add locked local database shell and schema migrations.
3. Build member list and current front screen.
4. Add sticky front notification with quick actions.
5. Add local logs and front history.
6. Add encrypted export/import format.
7. Add SP import.
8. Add PK import.
9. Add optional online identity and friends.
