# Product goals

Pluris Haven is a local-first app made by systems, for systems and anyone else who finds its tools
useful. “System”, “member” and “front” are defaults, not labels someone must adopt.

## What the app is for

People should be able to record members, groups, fronts, notes, journals, messages, polls and
reminders without creating an account. Local data should remain usable offline. Import, export and
portable recovery are maintained features, not one-time migration tools.

The app supports Simply Plural and PluralKit import paths. OpenPlural v0.1 has a file import path
with local fixture coverage. Tupperbox, PluralSpace and Ampersand have file mappers, but
representative real exports are still needed before broad compatibility claims. PluralPort Draft
v0.1 file import/export maps systems, members and fronts and retains unsupported records as
encrypted source data. It is separate from live sync and federation. See the
[completion ledger](completion-ledger.md) for the current limits of each path.

Password-protected local archives are the portable recovery route. Optional server snapshots depend
on device-held keys and cannot replace those archives. No local feature should require the server.
Friendship, if used, shares nothing by default and has no browsing directory.

The local database encrypts private text and stored avatar references. It still exposes some
metadata, such as row counts, relationships, timestamps and status flags. Hiding that metadata would
need a separate database design.

## Language and inclusion

Do not assume one identity, name, gender, set of pronouns or mind per body. Do not assume plurality,
switching, amnesia, origin, diagnosis or a particular relationship between members. Use someone's
chosen words and pronouns; use neutral “they” where none have been supplied.

Use **entity** for a portable identity that could belong to a system, collective or individual. Use
**account holder** for ownership and consent, and **person** or **people** when the human or legal
meaning matters. Preserve imported terms without applying them to everyone else. Explain any
feature-specific assumption and allow people to opt out where practical. The app must not ask anyone
to prove or medicalise their identity.

## Boundaries

Accessibility belongs in release work. Privacy controls, import/export and recovery must not depend
on payment. Product and store copy must distinguish implemented behaviour from tested behaviour and
plans.

Before alpha, finish the local paths that are exposed to users, close data integrity and
accessibility gaps, test upgrades and recovery on devices, and verify the release workflow with real
artefacts. The [project state](project-state.md) records decisions; the
[engineering readiness](engineering-readiness.md) page records release checks.

Hosted federation, desktop and private-browser clients, watch clients, plugins, authenticated
PluralSpace API import and full-database encryption are later work. Requiring an account for local
use, a friendship directory, routine scanning of private content, paid tiers for core access and
CLI/TUI clients are not planned.
