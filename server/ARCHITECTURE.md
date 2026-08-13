# Server architecture

This defines the architecture and policy for the first public-server release. Changing any of it requires a migration plan for existing accounts and clients.

## Product boundary

- The app remains local-first. An account is optional.
- Losing access to a server never removes local systems or local history.
- Logging out removes server credentials, not local data. "Lock app," "disconnect this server," "remove this device," and "erase local data" are separate actions.
- The official server is the default. Custom servers are an advanced option with identical protocol rights, migration rights, and encryption guarantees.
- Self-hosters and the official server run the same protocol. Official-only extras are support and convenience, never protocol features.

## Identity

- An entity holds one portable cryptographic identity, recognised across servers. No server owns it.
- Human-readable handles use a `name@server` style; the underlying identity stays stable if the handle changes.
- Passkeys are the primary sign-in method. Password, Google/Apple sign-in, TOTP, hardware keys, and recovery codes are also supported. Google/Apple sign-in is convenience only and cannot itself decrypt private data.
- SMS is never required, not even as a fallback.
- Each device gets its own revocable key. Adding a device always requires approval from an existing trusted device or configured recovery material.
- A revoked device can return later as a new, untrusted device, re-approved from scratch.

## Server identity

- The official API URL is `https://api.plurishaven.endoftime.works`.
- Every server has a stable identity and publishes `/.well-known/pluris-haven`, identifying the operator, policies, support address, enabled capabilities, and protocol version.
- The client shows this identity before creating an account on a custom server.
- Servers are untrusted routing and storage infrastructure, not identity or data authorities. Clients fail closed if a server can't prove required security capabilities.

## Friends and federation

- Friends, sharing, and messaging work the same way whether both entities are on the same server or different servers, over a purpose-built Pluris protocol. This is not Mastodon, ActivityPub, or the Fediverse.
- The proposed wire protocol, trust model, state machines, and rollout gates are specified in [`docs/protocol/federation-v1.md`](../docs/protocol/federation-v1.md). It is a design contract, not a claim that federation is currently implemented.
- ActivityPub support is deferred until the private protocol is designed; if it's ever added, it covers deliberately public content only.
- Accepting a friend request grants no access by itself. Sharing grants are directional and revocable independently.
- Blocking removes the friendship and every grant in both directions immediately.
- There is no default public directory. Users may opt into a searchable public listing if they want to be discoverable.

## Migration

- Migrating to a new server is a complete, cryptographically signed transfer. It works even if the old server is permanently offline.
- The root-signed portable identity is the authority for migration, not any device or server by itself.
- If an old server comes back online with divergent data from after a migration, that data is quarantined and reviewed rather than silently merged or discarded.
- Automatic standby replication is on by default for the official server. Self-hosters choose their own standby or opt out.

## Data and encryption

- Server-local account identity, device-session records, friend relationships, blocks, and grants are server data.
- Passwords use Argon2 hashes. Refresh tokens are one-time records; replay revokes the device session.
- All non-public synchronised or shared content is end-to-end encrypted. The server stores and routes ciphertext for member profiles, fronts, notes, messages, polls, and journals, never plaintext.
- A feature may request one plaintext value from a user with explicit, specific, opt-in consent and a clear warning that it breaks encryption for that value. This is never silent or blanket.
- No custom cryptographic primitives. Established, reviewed algorithms and libraries only; any protocol composition gets review before a stable release.
- Server exports and account deletion must be implemented before public registration opens.

## Metadata and privacy

- The server retains only what auth, routing, delivery, and abuse prevention require.
- Crash reports and performance metrics are collected by default and are configurable or opt-out where technically possible.
- An optional stronger-privacy mode (padding, batching, relay routing) is available for people who want to obscure who-talks-to-whom patterns, at a battery and latency cost. It is not the default.

## Public launch

- Registration starts closed and opens gradually after email verification, recovery, rate limits, reporting, and moderation tools exist.
- There is no public account directory beyond the opt-in listing above, and no stranger messaging or cross-server search at launch.
- Direct messages are not included in the first friends release.
- The service is for people aged 13 and older. Jurisdictions with a higher digital-consent age require separate handling; qualified legal review covers this before public registration opens.
- Account deletion uses immediate deactivation followed by a 30-day recovery period before permanent removal.
- Moderation acts on public content and evidence a user chooses to submit. There is no routine scanning of private content.

## Hosting

- The official server uses PostgreSQL, systemd, and a local reverse proxy connection.
- Rootless containers are the recommended packaged option for self-hosters. Native systemd installation remains supported for experienced self-hosters.
- Operators are responsible for their own policies, email delivery, abuse response, backups, and restore rehearsals.
- A custom-server warning tells users that its operator controls account metadata and any data intentionally sent to it.
- Official hosting is donation-funded with no paid feature tiers. For-profit hosting by other operators is not permitted under the current licence; community servers may recover their own actual, itemised costs without that being commercial use.

## Compatibility

- Clients check the descriptor before authentication.
- Unknown protocol versions or missing required capabilities fail closed.
- New optional capabilities can be added without breaking older clients.
- Servers publish a compatibility window and support older clients on a best-effort basis beyond it.
- Encrypted sync requires a later protocol revision; it is not implied by the current friends API.
