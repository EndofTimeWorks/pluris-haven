# Local data model

The mobile app owns the main copy of a person's data. Local features do not
depend on an account, network connection, or Pluris Haven server.

The current Drift database uses schema version 17. Its tables cover:

- the system profile, members, groups, tags, and privacy buckets;
- custom fields and named fronts;
- front sessions, their members, and front audit events;
- notes, journals, revisions, messages, channels, and categories;
- polls, options, votes, and vote events;
- reminders, notifications, pending actions, and preferences; and
- import records and optional retained source payloads.

The table definitions and migrations in
`mobile/lib/data/local/app_database.dart` are authoritative. This document is a
summary, not a second schema definition.

## Encryption boundary

Private text and stored avatar references are encrypted with a key held by the
device. Relationship columns, timestamps, row counts, status flags, and other
metadata needed for local queries remain visible in the SQLite file.

The device key is not a portable recovery secret. A password-protected recovery
archive is needed when moving data to a new device.

## Local archive

`buildLocalArchiveJson()` exports a versioned `pluris_haven.local_archive`
document. It includes the system profile, content records, relationships,
preferences, import history, and portable avatar assets that belong to the
local system.

Plain JSON exposes the exported content and must be treated as private. The
password-protected archive wraps that JSON for portable recovery. A restore
rehearsal can test an archive in a clean temporary database without changing
the live one.

The archive writer in `mobile/lib/data/local/haven_repository.dart` is the
authoritative list of exported collections.

## Optional server

The server currently provides accounts, revocable sessions, encrypted backup
storage, friend requests, and blocking. The mobile app encrypts backup chunks
before upload, so the server does not receive archive plaintext or the device
master key.

Server snapshot restore, bidirectional content sync, sharing grants, messaging,
and federation are not implemented. None of them is required for local use.
