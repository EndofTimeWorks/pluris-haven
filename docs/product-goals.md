# Product Goals

Pluris Haven is a local-first replacement for Simply Plural. It should feel
familiar, but it does not need to copy SP screen-for-screen.

## Principles

- Local use must not require an account.
- Import/export is core, not an afterthought.
- Sync and sharing are opt-in.
- Privacy rules belong in the data model.
- Mobile comes before web/admin/watch work.

## MVP

Build enough to be useful before adding server-heavy features:

- members
- groups and subsystems
- tags
- custom fields
- custom fronts and named fronts
- front history
- notes
- basic journals
- Simply Plural import
- PluralKit file import
- PluralKit live import shape
- local backup and restore
- basic analytics
- theme, dashboard, and language preferences

## Importers

Target import sources:

- Simply Plural
- PluralKit file
- PluralKit live via `pk;token`
- Tupperbox
- PluralSpace
- Prism `.prism`

Re-imports should dedupe against the existing roster. External IDs win. Names
are only a fallback.

## Privacy And Safety

Use plain visibility terms:

- private
- trusted
- shared
- public

Needed later:

- field-level encryption for sensitive text
- per-field and per-member visibility overrides
- friend/trust rules
- destructive-action grace periods
- optional re-auth before destructive actions
- revision history and pinning for journals/bios

## Sync

Sync should be self-hostable and optional.

Long-term sync work:

- encrypted sync server
- friends and cross-system visibility
- PluralKit bidirectional sync
- scoped API keys
- front-change notifications
- webhooks, ntfy, Pushover, FCM, APNs
- quiet hours and payload sensitivity

## Later

These matter, but not before the mobile app and importers work:

- React web app
- CLI
- Wear OS and watchOS companions
- admin UI
- Docker Compose
- Terraform
- S3-compatible storage
- metrics
- verifiable builds

## Not Now

- server-required mobile use
- billing tiers in the local app
- exact SP cloning
- admin tools before sync exists
- watch apps before front tracking works well
