# SP Replacement - DB Schema

## Stack
- **Backend:** SvelteKit (SSR web UI + `/api` routes for Flutter/Slack)
- **DB:** PostgreSQL + Drizzle ORM
- **Auth:** better-auth (Google + Apple OAuth)
- **Async jobs:** pg-boss (runs on same Postgres, no extra service)
- **Mobile:** Flutter (iOS + Android)
- **Hosting:** Coolify (self-hosted, migrate to Railway/Fly.io if needed)
- **Encryption:** Tiered - Tier 1 server-readable (at rest), Tier 2 true E2E (client-side AES-256-GCM)

### How SvelteKit is used
- **Tier 1 data** (display names, fronting status) - SSR `load()` → Drizzle → Postgres directly (no API hop)
- **Tier 2 data** (journal, private notes) - SvelteKit serves the app shell only, browser decrypts via Web Crypto API (requires JS)
- `/api` routes expose REST endpoints for Flutter and Slack webhooks
- Both share the same Drizzle schema and types

---

## Encryption Model

```
Google/Apple OAuth → HKDF(sub + server_pepper) → Master Key (never stored)
Master Key → unwraps → Symmetric Key (AES-256-GCM, stored wrapped on server)
Symmetric Key → encrypts → all private data before upload
```

Recovery options (any one unlocks the symmetric key):
- Google OAuth
- Apple OAuth
- 24-word BIP39 recovery mnemonic (shown once on signup)

---

## Key Management

```sql
users
  id          uuid        PK
  email       text        UNIQUE
  created_at  timestamptz

-- Each linked Google/Apple account
oauth_providers
  id            uuid        PK
  user_id       uuid        FK users
  provider      text        -- 'google' | 'apple'
  provider_sub  text        -- stable ID from provider
  wrapped_key   bytea       -- symmetric key wrapped with HKDF(sub + server_pepper)
  created_at    timestamptz

-- Recovery mnemonic path
recovery_keys
  id           uuid   PK
  user_id      uuid   FK users
  wrapped_key  bytea  -- symmetric key wrapped with key derived from recovery mnemonic
  key_hint     text   -- first 4 words only, for identification

-- For receiving encrypted keys from other users (partner access)
partner_public_keys
  id          uuid   PK
  user_id     uuid   FK users
  public_key  bytea
```

---

## Tier 1 - Server-readable (encrypted at rest, not E2E)

> Server can read these fields. Required by the Slack bot (plura) for message proxying,
> PluralKit sync, and partner front view. E2E is impossible here by design - the bot
> needs plaintext to function. Encrypted at rest in Postgres, tokens encrypted at app level.

```sql
systems
  id                              uuid        PK
  user_id                         uuid        FK users UNIQUE
  display_name                    text
  slack_workspace_id              text
  slack_user_id                   text
  slack_oauth_token               text        -- app-level encrypted (not E2E)
  currently_fronting_member_id    uuid        FK members NULLABLE
  created_at                      timestamptz

members
  id           uuid        PK
  system_id    uuid        FK systems
  display_name text
  avatar_url   text        NULLABLE
  pronouns     text        NULLABLE
  color        text        NULLABLE  -- hex
  enabled      boolean     DEFAULT true
  created_at   timestamptz

aliases
  id         uuid  PK
  member_id  uuid  FK members
  system_id  uuid  FK systems
  alias      text

triggers
  id         uuid  PK
  member_id  uuid  FK members
  system_id  uuid  FK systems
  type       text  -- 'prefix' | 'suffix' | 'contains' etc.
  text       text
```

---

## Tier 2 - True E2E (server sees ciphertext only)

> Flutter encrypts before upload. In browser, Web Crypto API encrypts client-side (requires JS).
> SvelteKit serves the app shell only - never reads plaintext Tier 2 content.
> These fields are never needed by the bot or PK sync.

```sql
-- 1:1 with members, holds all sensitive member data
member_private_data
  id              uuid   PK
  member_id       uuid   FK members UNIQUE
  encrypted_data  bytea  -- JSON: { description, notes, birthday, custom_fields: {...} }
  iv              bytea

-- Timestamps plaintext (needed for ordering/querying), notes encrypted
front_history
  id              uuid        PK
  system_id       uuid        FK systems
  member_id       uuid        FK members NULLABLE  -- null = unknown/headspace
  started_at      timestamptz
  ended_at        timestamptz NULLABLE
  encrypted_note  bytea       NULLABLE
  note_iv         bytea       NULLABLE

-- member_id null = system-wide journal entry
journal_entries
  id                 uuid        PK
  system_id          uuid        FK systems
  member_id          uuid        FK members NULLABLE
  created_at         timestamptz  -- plaintext for ordering
  encrypted_content  bytea
  iv                 bytea
```

---

## Partner Access

```sql
partner_access
  id                  uuid        PK
  system_id           uuid        FK systems   -- system being shared
  partner_user_id     uuid        FK users     -- who has access
  access_level        text        -- 'front_only' | 'members' | 'full'
  wrapped_system_key  bytea       -- system symmetric key encrypted with partner's public key
  created_at          timestamptz

-- To revoke: delete partner's wrapped_system_key row. Lazy re-encryption of Tier 2 data via pg-boss if desired.
```

---

## Notes

- **Timestamps are always plaintext** - required for ordering front history and "who's fronting now" queries
- **Partner front access** - reads `systems.currently_fronting_member_id` joined with `members.display_name` (both plaintext)
- **Partner journal/private access** - uses `wrapped_system_key` to decrypt journal entries client-side
- **Slack bot** - only ever touches plaintext tables (systems, members, aliases, triggers)
- **SP import** - parse export JSON client-side in Flutter, encrypt private fields, upload. Avatars re-hosted to S3/R2
- **PluralKit import** - same flow, already prototyped in plura (Rust) for reference
- **Key revocation** - remove partner's `wrapped_system_key` from `partner_access`. Lazy re-encryption on next access via pg-boss job
