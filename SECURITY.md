# Security

## Reporting a vulnerability

Please do not put exploit details in a public issue. Send a report to
`security@endoftime.works` with `[security]` in the subject.

Useful reports include:

- the affected route, screen, or file;
- a short description of the impact;
- reproduction steps or a minimal proof of concept; and
- the version or commit where it was observed.

Please allow time for confirmation before publishing details. Do not include
real user exports, passwords, tokens, or private avatars in a report.

## Current boundaries

- Registration and friend connections are disabled by default.
- Backup snapshots are client-encrypted, but the optional server stores their
  opaque chunks and applies per-user snapshot-count and byte quotas.
- Device-key snapshots cannot be restored without the original device key. The
  user-facing password-protected archive is a separate portable recovery path:
  import it on a new device with its passphrase and the app will encrypt the
  restored local data with that device's new key.
- Authentication and friend-request limits are stored in the database. The
  production PostgreSQL path locks each bucket while it updates the count.
- The mobile app exposes account, session, password-change, deletion, backup,
  and experimental friend controls. Public accounts are still not ready: email
  verification, recovery, moderation, policy, and deployment checks remain.
