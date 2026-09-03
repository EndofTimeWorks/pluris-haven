# Product goals

Pluris Haven is a local-first app made by systems. It is for systems, other
collectives, individuals, and anyone else who finds the tools useful.

No one has to use words such as “system”, “member”, or “front”. Those are useful
defaults, not requirements.

## What works now

The mobile app stores the main local system data without requiring an account,
including members, groups, tags, custom fields, fronts, notes, journals,
messages, polls, reminders, preferences, import history and recovery data.

Simply Plural and PluralKit have tested import paths. Tupperbox, PluralSpace and
Ampersand have current file-normalisation paths with checked-in mapper coverage.
OpenPlural import is wanted but currently missing after an earlier history
rewrite; restoring it is current product work. Do not advertise a source as
fully compatible merely because a parser or mapper exists.

Password-protected archives are the portable recovery path. Encrypted server
snapshots use device-held key material, upload in checked chunks, and can be
downloaded/restored by a client that still has the required key. Server
snapshots do not replace portable recovery archives.

Accounts and friends are optional. Friends remain experimental and disabled by
default. There is no friendship directory; discovery should be deliberate
through exact handles, rotating codes, links or QR.

Hosted password recovery uses a one-time emailed token. Public registration
remains disabled until its remaining safety gates, including verified email,
are actually implemented.

## Rules for the product

- Local features must keep working without an account or network connection.
- Private content must not leave the device as plaintext by default.
- Sync must be transport-independent; a central server is optional
  infrastructure rather than the owner of the data model.
- Import and export are maintained features, not one-off migration tools.
- Self-hosted servers use the same public protocol as the official server where
  that protocol is implemented.
- Accessibility is part of release work.
- The app must not ask anyone to prove or medicalise their identity.
- Friendship and collaboration are separate; friendship shares nothing by
  default.
- Product/docs/store claims must distinguish implemented, verified and merely
  planned functionality.

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

## Current completion direction

- Restore and verify OpenPlural import through the current import framework.
- Finish local chats/messages/categories/channels already represented in the
  data model and product decisions.
- Finish Markdown revision/history/restore flows for notes and journals, plus
  message history where designed.
- Build the scoped, revocable, permission-based local API as a near-term
  integration surface; it must not expose ambient decrypted-vault access.
- Finish the already-decided advanced reminder, poll, front-audit and System
  Safety paths.
- Finish low-cognitive-load, terminology, customization and accessibility gaps.
- Prepare Play closed alpha testing in addition to the existing internal-test
  release path, and verify the real CI/release workflows.
- Complete remaining real-device accessibility and Apple signing/runtime tests.
- Keep registration disabled until verified email and other production gates are
  genuinely ready.

Trusted recovery contacts are wanted, but their exact cryptographic share and
threshold scheme remains unresolved. Do not invent that cryptography simply to
mark the feature complete.

## Later / deferred

- Full portable-identity and federation protocol implementation.
- Desktop and private browser clients.
- Watch clients and plugin ecosystems.
- Authenticated PluralSpace API import.
- Optional full-database encryption that also hides local metadata.
- Other platform work explicitly recorded as deferred in `docs/project-state.md`.

## Not planned

- Requiring an account for local features.
- Copying another plurality app screen for screen.
- A friendship browsing/search directory.
- Routine scanning of private content.
- Paid feature tiers on the official server.
- CLI/TUI clients.
