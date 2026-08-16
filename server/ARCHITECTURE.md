# Server architecture

The server is optional. The mobile app and its local history must keep working
when the server is unavailable or disconnected.

## Current server

The implemented server provides:

- password accounts and revocable device sessions;
- password change and account deletion;
- encrypted backup upload, download, listing, and deletion;
- friend requests and blocking behind a disabled-by-default flag;
- a small user-visible security event history; and
- a public descriptor at `/.well-known/pluris-haven`.

The mobile app encrypts backup content before upload. The server stores opaque
chunks and account metadata. It does not receive the device master key or local
archive plaintext.

Accepting a friend request does not share local content. Sharing grants,
messaging, content sync, federation, portable identity, passkeys, and public
directories are not implemented.

## Trust boundaries

- Logging out or disconnecting a server must not erase local data.
- Each backup, session, friendship, and block query is scoped to the signed-in
  account.
- Clients check the server descriptor before authentication.
- Production uses PostgreSQL, HTTPS through a reverse proxy, explicit trusted
  hosts, and a narrow proxy-header boundary.
- Self-hosted and official servers use the same API and data format.

## Authentication

Passwords use Argon2. Access tokens are short-lived and checked against the
live device session. Refresh tokens rotate once; unexpected reuse revokes the
session. A nonce allows one narrow retry when the first refresh response is
lost.

Authentication and friend-request limits are stored in the database. The
production PostgreSQL path locks each rate-limit bucket during updates.

## Backups

Backup chunks are immutable, size-limited, digest-checked, and owned by one
account. Snapshot count and byte quotas are configurable. Blob deletion happens
after the database transaction and is retried from a durable cleanup queue.

Device-key snapshots are not portable by themselves. Password-protected local
archives remain the new-device recovery path.

## Public launch

Registration and friends stay disabled until the project has:

- verified email and account recovery;
- production HTTPS, monitoring, backups, and restore rehearsals;
- abuse reporting, moderation, privacy, terms, and minor-safety policies; and
- physical-device testing of the account and friend flows.

Future identity, sync, and federation work needs its own reviewed protocol and
migration plan. It is not implied by the current friends API.

## Deployment

The supported production path is PostgreSQL with systemd behind a local reverse
proxy. Rootless containers remain available for self-hosting and testing.
Operators are responsible for email delivery, abuse response, host backups,
restore tests, and local law and policy requirements.
