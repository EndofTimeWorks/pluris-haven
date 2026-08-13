# Product goals

Pluris Haven is a local-first application made by systems for systems,
collectives, individuals, and anyone else who finds its tools useful. It is an
offline-capable home for members, identities, fronting, journals, and day-to-day
life, with an optional online layer for sync, backup, and connection. None of
those concepts is required simply to use the app.

## What it is today

The mobile app is the primary product. It works entirely offline: members, groups and subsystems, tags, custom fields, custom fronts, front history with overlapping and co-fronting intervals, notes, journals, message boards, polls, reminders, dashboard customisation, and theming all run locally with no account required.

Import is a first-class feature, not an afterthought. Simply Plural and PluralKit archives import with preview-then-publish behaviour, source-ID-based deduplication, and preserved provenance for anything the mapper doesn't yet understand. Local backup and restore is encrypted end to end, with resumable, hash-verified restore.

An optional account layer exists for backup, and friends are in early development behind a disabled-by-default flag. Neither is required for the app to be useful.

## Principles

- Local use never requires an account, a server, or a network connection.
- Anything that leaves the device is encrypted end to end by default. The server routes and stores ciphertext; it does not read private content.
- Local private text is encrypted with the device key, but the current
  field-level design leaves database structure visible to someone who obtains
  the raw SQLite file: row counts, relationships, timestamps, and status
  flags. It is not a substitute for device encryption or a full-database
  encryption design.
- Import and export are core functionality, maintained to the same standard as everything else, not a one-time migration tool.
- Self-hosting is a first-class path, not a downgraded one. Self-hosters get the same protocol, migration rights, and encryption guarantees as the official server.
- Accessibility is a release requirement, not a follow-up task.
- The app welcomes every gender, orientation, culture, body, ability, origin,
  spiritual framework, diagnostic status, and understanding of self. It does
  not ask anyone to prove or medicalise their identity.

## Inclusion and language

Pluris Haven is made by systems. That informs the care put into plurality
features; it does not make the app exclusive to systems.

Product copy, schemas, protocols, and moderation rules must follow these rules:

- Do not assume one mind, one identity, one name, one gender, or one set of
  pronouns per body or account.
- Do not assume plurality, singlet identity, fronting, switching, amnesia,
  communication, origin, diagnosis, or a particular relationship between
  members.
- Let an entity choose its own collective and individual terminology. “System”,
  “member”, “front”, and similar words are defaults, not labels imposed on
  everyone.
- Store and display chosen names and pronouns. Avoid legal names and gendered
  language unless they are specifically required and clearly explained.
- Never use singular grammar to imply that an entity must be an individual.
  Neutral “they” is the default in natural-language copy.
- Use **entity** for the portable identity represented by the app. An entity may
  be a plural system, another collective, or an individual.
- Use **account holder** for account ownership and consent. Use **user** only
  when describing interaction with software. Use **person** or **people** when a
  legal, bodily, or human context genuinely requires it.
- Accessibility, localisation, safety, and privacy needs are part of inclusion,
  not separate polish.
- Compatibility with another plurality tool must preserve source terminology
  and data without forcing that tool's worldview onto every entity.

When a feature cannot remain neutral, its UI must explain the assumption, make
the feature optional where possible, and provide a way to correct or decline it.

## Identity and connection

A Pluris Haven identity is portable: held by the entity, not owned by whichever
server it is registered on. Friends, sharing, and messaging work the same way
whether both entities are on the official server, a self-hosted server, or
different servers entirely, over a purpose-built protocol designed for this
rather than adapted from something else. Moving to a new server is a real
migration, not a fresh start, and works even if the old server has gone
permanently offline.

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
- An optional full-database encryption design for people who need to reduce
  local metadata exposure as well as content exposure, with a clear migration,
  performance, and portability plan.

## Deliberately not doing

- Requiring a server or account for any local, single-user feature.
- Matching Simply Plural or PluralKit screen-for-screen. Import compatibility does not mean interface cloning.
- A public user directory beyond an explicit opt-in listing.
- Scanning private content for moderation. Moderation acts on public content and evidence a user chooses to submit.
- Paid feature tiers on the official server, or for-profit hosting by other operators.
