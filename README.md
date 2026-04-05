# Pluris Haven

A home for plural systems. Inspired by Simply Plural (sunsetting) and PluralKit.

Built by and for plural systems. Privacy-first, with tiered encryption so your private data stays yours.

## Features

- **Member management** — profiles, avatars, pronouns, colors
- **Fronting tracker** — log and view front history
- **Journal** — system and member journals, fully E2E encrypted
- **Partner access** — share front status or member info with trusted partners
- **Slack integration** — message proxying via [Plura](https://github.com/Suya1671/plura)
- **Import** — bring your data from Simply Plural or PluralKit
- **Mobile** — Flutter app for iOS and Android
- **Web** — full SvelteKit web app

## Stack

- **Backend/Web:** SvelteKit (SSR for Tier 1 data, app shell for Tier 2)
- **DB:** PostgreSQL + Drizzle ORM
- **Auth:** better-auth (Google + Apple OAuth)
- **Async jobs:** pg-boss
- **Mobile:** Flutter
- **Hosting:** Coolify

## Privacy Model

Data is split into two tiers:

- **Tier 1** (display names, fronting status, triggers) — server-readable, needed for Slack bot and PK sync
- **Tier 2** (journal, private notes, custom fields) — true E2E, AES-256-GCM encrypted client-side before upload. Server sees ciphertext only.

Key derivation: `OAuth sub → HKDF(sub + server_pepper) → Master Key → Symmetric Key`

Recovery via Google OAuth, Apple OAuth, or a 24-word BIP39 mnemonic.

## Developing

```sh
pnpm install
pnpm dev
```

## License

MIT
