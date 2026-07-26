# Security

## Reporting a vulnerability

Please do not put exploit details in a public issue. Send a report to
`support@endoftime.works` with `[security]` in the subject, or use a private
GitHub security report if that option is available for the repository.

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
- Authentication and friend-request rate limits are in-memory and apply per
  process. Running multiple workers or replicas requires a shared limiter
  before treating them as global controls.
- The server provides password-confirmed account deletion and removes the
  account's opaque backup files with it. The mobile app does not expose the
  account/session flow yet. Keep public account features disabled until account
  recovery, client flows, and legal requirements are complete.
