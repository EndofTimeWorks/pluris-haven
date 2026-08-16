# Product goals

Pluris Haven is a local-first app made by systems. It is for systems, other
collectives, individuals, and anyone else who finds the tools useful.

No one has to use words such as “system”, “member”, or “front”. Those are useful
defaults, not requirements.

## What works now

The mobile app stores members, groups, tags, custom fields, fronts, notes,
journals, messages, polls, reminders, and preferences locally. It does not need
an account.

It imports Simply Plural and PluralKit data, previews changes before applying
them, and keeps source information that it does not understand yet.

Password-protected archives are the portable recovery path. Server snapshots
use the device key, upload in checked chunks, and cannot yet be restored by the
mobile client.

Accounts and friends are optional. Friends are experimental and disabled by
default.

## Rules for the product

- Local features must keep working without an account or network connection.
- Private content must not leave the device as plaintext by default.
- Import and export are maintained features, not one-off migration tools.
- Self-hosted servers use the same public protocol as the official server.
- Accessibility is part of release work.
- The app must not ask anyone to prove or medicalise their identity.

Local text is encrypted with a device key. The SQLite file still exposes some
metadata, including row counts, relationships, timestamps, and status flags.
Reducing that exposure would need a separate full-database encryption design.

## Language and inclusion

- Do not assume one identity, name, gender, set of pronouns, or mind per body or
  account.
- Do not assume plurality, singlet identity, switching, amnesia, origin,
  diagnosis, or relationships between members.
- Use chosen names, pronouns, and terms.
- Use neutral “they” unless someone has supplied different language.
- Use **entity** for a portable identity that may belong to a system,
  collective, or individual.
- Use **account holder** when discussing ownership or consent. Use **person** or
  **people** when the bodily, human, or legal meaning matters.
- Keep assumptions local to the feature that needs them. Explain them and let
  people opt out where possible.
- Preserve an imported tool's terms and data without applying those terms to
  everyone else.

## Next

- Add verified email and account recovery before public registration.
- Add download and restore for server snapshots without presenting them as a
  replacement for portable recovery archives.
- Finish abuse controls and device accessibility testing for friends.
- Test TalkBack, VoiceOver, switch access, keyboard navigation, large text,
  contrast, and reduced motion on real devices.
- Finish signed iOS distribution and physical-device testing.
- Split the local repository by feature as those areas are changed.

## Later

- Portable identity and server federation.
- Desktop and browser clients.
- A permission-based local API for integrations.
- An optional design that also encrypts local database metadata.

## Not planned

- Requiring an account for local features.
- Copying another plurality app screen for screen.
- A public directory without explicit opt-in.
- Routine scanning of private content.
- Paid feature tiers on the official server.
