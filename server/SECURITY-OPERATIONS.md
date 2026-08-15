# Security operations

This is the minimum operator runbook for the optional Pluris Haven server. It
does not make public accounts ready by itself. Registration must remain disabled
until verified email, recovery, moderation, policy, and external monitoring are
also ready.

## Signals

The server writes small JSON security signals to the `pluris.security` logger.
Each signal contains only `event`, `operation`, and `reason`. It deliberately
does not contain an email address, user ID, IP address, device name, token,
request body, or arbitrary exception text.

Current events are:

- `security.auth.rejected`: an explicit login, refresh, registration, password,
  or deletion check was rejected.
- `security.auth.rate_limited`: an authentication endpoint reached its shared
  database-backed limit.
- `security.capacity.rejected`: a backup request exceeded its configured count,
  byte, manifest, or chunk limit.
- `security.readiness.failed`: the readiness probe could not query PostgreSQL.

These operator signals are separate from the user-visible security history.
Missing bearer tokens are intentionally not logged because an unauthenticated
probe could otherwise amplify logs without reaching a rate-limited endpoint.

On the systemd deployment, inspect and count recent signals with:

```sh
sudo journalctl -u pluris-haven-server --since "15 minutes ago" -o cat \
  | rg 'security\.(auth|capacity|readiness)\.'

sudo journalctl -u pluris-haven-server --since "15 minutes ago" -o cat \
  | rg -o '\{"event":"security\.[^}]+\}' \
  | sort | uniq -c
```

Feed the same stable fields into the operator's existing log collector. Do not
add request bodies or identity fields when translating them into metrics.

## Initial alerts

Start with these conservative alerts, then tune them using a private-instance
baseline:

- any `security.readiness.failed` event;
- any repeated `security.capacity.rejected` event for five minutes;
- five `security.auth.rate_limited` events in five minutes;
- twenty `security.auth.rejected` events for one operation in five minutes;
- PostgreSQL volume or backup-object volume at 80% used, critical at 90%;
- PostgreSQL connection use at 80% of `max_connections`;
- failed backup service, failed restore rehearsal, or a backup older than the
  expected schedule.

The HTTP probes are:

```sh
curl --fail --silent --show-error http://127.0.0.1:8000/health
curl --fail --silent --show-error http://127.0.0.1:8000/ready
```

Monitor database and object-store capacity from outside the application. At a
minimum, collect `pg_database_size(current_database())`, active connections,
filesystem free space for `PLURIS_BACKUP_OBJECT_DIR`, and the most recent
successful backup and restore-rehearsal timestamps. A quota rejection protects
one account; it is not an early warning that the host volume is almost full.

## Incident response

1. Contain the public route. Stop the reverse proxy route or stop
   `pluris-haven-server` if requests may still be harmful. Keep registration and
   friends disabled while investigating.
2. Preserve the relevant journal range, reverse-proxy logs, database backup,
   deployment revision, and configuration names. Redact secrets before sharing
   any evidence.
3. Identify whether the signal is credential abuse, refresh-token replay,
   storage pressure, database failure, or a deployment regression. Do not infer
   an affected identity from the aggregate signal alone.
4. For a session or signing-secret compromise, revoke affected database
   sessions and refresh tokens before restoring access. Rotating the JWT secret
   alone does not revoke a stolen refresh token.
5. For database or storage failure, keep writes closed until a backup restore
   rehearsal and consistency checks succeed. Do not delete queued backup cleanup
   rows to make a capacity alarm disappear.
6. Restore service gradually, watch the signals and readiness probe, and record
   the exact containment and recovery times.
7. Notify affected people and the appropriate authorities when policy or law
   requires it. The aggregate operator log is not a substitute for a breach
   assessment.

After an incident, add a regression test or an operational check for the actual
failure mode. Do not lower a limit or silence a signal solely to clear an alert.
