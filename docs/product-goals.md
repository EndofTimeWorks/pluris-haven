# Pluris Haven Product Goals

Pluris Haven is an offline-first plural system manager with optional self-hosted
sync, strong import/export, and privacy controls. It should feel familiar to
Simply Plural users without copying every screen or carrying over weak product
decisions.

The app should be useful without an account. Server features exist for sync,
sharing, administration, and integrations, not as a requirement for basic use.

## Product Pillars

### 1. Local System Manager

The local app is the source of truth. Core records must work offline first:

- members and system profiles
- groups and nested subsystems
- tags
- custom fields
- custom fronts and named fronts
- front sessions, cofronting, and status notes
- notes and journals
- analytics
- themes and app customization

### 2. Import and Export Hub

Import/export is a core feature, not a migration afterthought.

Supported importers should include:

- Simply Plural export
- PluralKit export file
- PluralKit live import with `pk;token`
- Tupperbox
- PluralSpace
- Prism encrypted `.prism` exports

Importers must deduplicate against the existing roster on re-import. Stable
external IDs should win when available. Name-based matching is only a fallback.

Exports should include:

- a portable JSON export
- a full backup zip with image bytes
- round-trip restore of Pluris Haven backups
- clear warnings for unencrypted exports

### 3. Privacy and Safety

Privacy needs to be built into the data model instead of bolted onto sharing.

Required privacy and safety goals:

- local-first storage
- field-level encryption for sensitive text
- member, group, and per-field privacy controls
- per-field-per-member privacy overrides
- friend and trust visibility rules
- destructive-action grace periods
- optional re-authentication for destructive actions
- revision history and pinning for important edited content

Use clear visibility language instead of vague "privacy buckets":

- private
- trusted
- shared
- public

Overrides should exist at the base, group, and member level.

### 4. Optional Sync and Sharing

Sync should be optional and self-hostable. The server syncs data; it should not
own the app experience.

Long-term sync and sharing goals:

- self-hosted sync server
- friends and cross-system trust controls
- PluralKit bidirectional sync
- scoped API keys for scripts and integrations
- front-change notifications
- web push
- FCM and APNs
- webhooks for JSON, Discord, Slack, and plaintext
- ntfy
- Pushover
- debounce and quiet hours
- payload sensitivity controls

### 5. Clients and Deployment

Mobile comes first. Other clients should use the public API and archive formats.

Target clients:

- Flutter Android app
- Flutter iOS app
- React web app
- CLI similar to `simplyplural-cli`
- Wear OS companion and complication
- watchOS companion and complication

Deployment and operations are later-stage goals:

- Docker Compose
- Terraform module
- S3-compatible file storage
- signed image URLs
- Prometheus-compatible `/metrics`
- multi-replica background coordination
- verifiable builds with cosign and frontend SRI

## MVP Scope

The first real product milestone should prove the offline app. Build this before
server-heavy features:

- members
- groups and subsystems
- tags
- custom fronts
- named fronts
- front history
- notes
- basic journals
- import/export shell
- Simply Plural import
- PluralKit file import
- PluralKit live import shape
- local backup and restore
- basic analytics
- theme and dashboard customization

This is enough to be a useful replacement app without needing hosted accounts.

## Better Than the Pasted List

Some pasted goals are right, but should be reshaped.

### Polls

Start with internal system decisions. Cross-system voting can come later because
it brings more privacy, trust, and audit complexity.

Initial polls:

- single-choice and multi-choice
- current-fronter attribution
- deadline
- optional hidden results
- audit log

### Messages

Start with boards and walls:

- global system board
- per-member wall
- reply chains
- soft delete

Edit history can come after the base message model works.

### Notes and Journals

Keep these separate.

Notes are quick scratchpads with no revision history by default. Journals are
longer markdown entries with versioned edit history.

### System Safety

Start with simple undo and grace periods. Add password, TOTP, and WebAuthn
step-up later.

### Tiers

Do not build artificial free/plus/self-hosted tiers into the local app. If a
hosted service exists later, server admins can define their own tiers and quotas.

### Admin UI

Admin features are useful but should not block the app. Add them after accounts,
sync, and server storage exist.

## Later Goals

These should exist eventually, but they should not distract from the offline app
or importer work:

- WebAuthn and YubiKey
- email OTP fallback
- AWS Secrets Manager
- Vault
- storage quotas
- orphaned file cleanup
- admin dashboard
- emergency support tools
- soft-ban with auto-restore
- forced API key rotation
- session termination
- S3 presign support
- Terraform module
- Prometheus metrics
- leader election for background workers
- verifiable Docker and frontend builds

## Explicit Non-Goals for Now

Avoid these until the core app is solid:

- server-required mobile use
- exact Simply Plural UI copying
- hosted-service billing tiers
- admin tooling before user data sync exists
- complex deployment automation before Docker Compose works
- watch apps before mobile front tracking is reliable
- cross-system social features before local privacy rules are correct

## Internal Data Model Direction

Use one internal model. Do not keep one model per importer.

Importers should map into:

- `System`
- `Member`
- `Group`
- `Tag`
- `CustomField`
- `FrontSession`
- `NamedFront`
- `CustomFront`
- `Note`
- `JournalEntry`
- `ExternalIdentity`
- `ImportRecord`

Deduplication should prefer:

1. known external IDs
2. source-specific stable IDs
3. normalized name plus strong profile hints
4. manual review

Weak automatic matches should be presented for review instead of silently
merging records.

## Recommended Build Order

1. Finish local customization and app shell.
2. Add importer source models and import records.
3. Implement Simply Plural import.
4. Implement PluralKit file import.
5. Implement PluralKit live import with token authentication.
6. Add member/group/tag CRUD.
7. Add named fronts and searchable start-front dialog.
8. Add local analytics.
9. Add round-trip backup and restore.
10. Add encrypted notes and journals.
11. Add optional sync server.
12. Add friends, trust, API keys, and notifications.
13. Add web, CLI, wearables, admin, metrics, and deployment automation.
