# Local Data Model

The mobile app owns the primary copy of user data. The server, when it exists,
is for optional sync, sharing, imports, and web access.

## Core Records

- system profile
- members
- groups and nested subsystems
- tags
- custom fields
- custom fronts
- named fronts
- front sessions
- notes
- journals
- polls
- local app events
- import records
- export manifests

## Local Storage

Local data must be usable offline:

- current front
- front history
- members and groups
- notes and journals
- polls and votes
- import/export state
- app preferences

Sensitive fields should be encrypted before real user data is stored long-term.

## Import Shape

The app has not shipped, so the internal archive can still change. Compatibility
targets are external imports, especially Simply Plural and PluralKit.

Current local archive areas:

- `members`
- `groups`
- `customFields`
- `notes`
- `frontHistory`
- `currentFrontMemberIds`
- `currentFrontStartedAt`
- `logs`

## Export

Export should eventually support:

- portable JSON
- encrypted backup
- full backup with image bytes
- round-trip restore

Plain JSON exports need a clear warning because they expose private data.

## Optional Server

Server-side storage can come later for:

- accounts
- encrypted sync
- friends/trust
- hosted imports
- hosted backups
- API keys
- notifications

The server should not be required for normal mobile use.
