# Product goals

Pluris Haven is a local-first application for plural systems: an offline-capable home for members, fronting, journals, and the rest of day-to-day system life, with an optional online layer for sync, backup, and connecting with other people.

## What it is today

The mobile app is the primary product. It works entirely offline: members, groups and subsystems, tags, custom fields, custom fronts, front history with overlapping and co-fronting intervals, notes, journals, message boards, polls, reminders, dashboard customisation, and theming all run locally with no account required.

Import is a first-class feature, not an afterthought. Simply Plural and PluralKit archives import with preview-then-publish behaviour, source-ID-based deduplication, and preserved provenance for anything the mapper doesn't yet understand. Local backup and restore is encrypted end to end, with resumable, hash-verified restore.

An optional account layer exists for backup, and friends are in early development behind a disabled-by-default flag. Neither is required for the app to be useful.

## Principles

- Local use never requires an account, a server, or a network connection.
- Anything that leaves the device is encrypted end to end by default. The server routes and stores ciphertext; it does not read private content.
- Import and export are core functionality, maintained to the same standard as everything else, not a one-time migration tool.
- Self-hosting is a first-class path, not a downgraded one. Self-hosters get the same protocol, migration rights, and encryption guarantees as the official server.
- Accessibility is a release requirement, not a follow-up task.

## Identity and connection

A Pluris Haven identity is portable: held by the person, not owned by whichever server they registered on. Friends, sharing, and messaging work the same way whether both people are on the official server, a self-hosted server, or different servers entirely, over a purpose-built protocol designed for this rather than adapted from something else. Moving to a new server is a real migration, not a fresh start, and works even if the old server has gone permanently offline.

## Near-term goals

- Finish the account/session UI and the network uploader for encrypted backup snapshots, so backup works end to end without a manual archive export.
- Bring the friends feature out from behind its feature flag: rate limiting, abuse handling, and a real accessibility pass across the whole flow.
- Signed release builds for Android and a working iOS signing and distribution path; iOS currently only compiles.
- A genuine accessibility pass: screen readers, keyboard and switch navigation, reduced motion, high contrast, and large text, tested on real devices rather than assumed from code review.
- Schema-migration regression tests, so upgrading the local database is verified rather than assumed safe.

## Longer-term goals

- Federation between servers, and the portable-identity migration path it depends on.
- A desktop client and a browser client sharing the same core logic. Browser access to private data requires JavaScript or WebAssembly, since decryption has to happen on the client; public pages work without it.
- A scoped local API for third-party integrations and automations, with explicit permissions and revocation.
- An optional stronger-privacy transport mode for people who want to obscure metadata patterns as well as content, at a cost in battery and latency.

## Deliberately not doing

- Requiring a server or account for any local, single-user feature.
- Matching Simply Plural or PluralKit screen-for-screen. Import compatibility does not mean interface cloning.
- A public user directory beyond an explicit opt-in listing.
- Scanning private content for moderation. Moderation acts on public content and evidence a user chooses to submit.
- Paid feature tiers on the official server, or for-profit hosting by other operators.
