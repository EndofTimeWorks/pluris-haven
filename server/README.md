# Pluris Haven server

This service is optional. The mobile app remains usable without an account or a
server.

The server handles accounts, revocable device sessions, encrypted backups,
friend requests, and blocking. Friends are experimental and do not share local
content. Sharing grants and bidirectional sync are not implemented.

The mobile app encrypts backups before uploading them. The server stores opaque,
immutable chunks and never receives archive plaintext or the device master key.
The mobile client can resume a matching partial upload, list snapshots, delete
them, and restore a completed snapshot after validating its declared chunk and
byte limits. Device-key snapshots are not portable recovery archives.

Set `PLURIS_BACKUP_OBJECT_DIR` to a private filesystem location with enough
space for user-configured snapshot retention. The application creates the
directory only when a store is used; operators must include it in their
backup and access-control plan. Snapshot retention remains user-controlled:
clients create versioned snapshots and explicitly delete them. The server does
not silently expire recovery points.

The authenticated endpoints are `POST /v1/backups/snapshots`, `GET
/v1/backups/snapshots`, `PUT /v1/backups/snapshots/{snapshot_id}/chunks/{index}`,
`GET` for the same chunk path, and `DELETE /v1/backups/snapshots/{snapshot_id}`.
Chunk requests require `X-Content-SHA256`; only the owning authenticated user
can access a snapshot.

`GET /v1/auth/security-events` returns the signed-in user's privacy-minimised
security history in newest-first order. Events contain only a type, timestamp,
and cursor ID. They never contain IP addresses, email addresses, device names,
tokens, snapshot names, or archive content. Account deletion immediately
revokes server sessions and schedules the account, friend data, and encrypted
backups for permanent deletion after 30 days. The account holder can recover it
during that window by completing a password-reset link sent to that email. Final
deletion unlinks its security event from the deleted user, leaving only an
anonymous operational count.

## Local development

```sh
cd server
uv sync --dev
PLURIS_REGISTRATION_ENABLED=true PLURIS_FRIENDS_ENABLED=true \
  uv run uvicorn pluris_server.main:app --reload
```

Development uses SQLite in `server/data/`. API documentation is at `http://127.0.0.1:8000/docs`.

## Native Debian deployment

Install PostgreSQL, Python, and `uv`, then create an unprivileged service account:

```sh
sudo apt install postgresql python3
sudo useradd --system --home /opt/pluris-haven --create-home --shell /usr/sbin/nologin pluris-haven
sudo install -d -o pluris-haven -g pluris-haven /opt/pluris-haven
```

Create the database with a unique password:

```sql
CREATE ROLE pluris LOGIN PASSWORD 'replace-this';
CREATE DATABASE pluris OWNER pluris;
```

Place the checkout at `/opt/pluris-haven`, then install the locked dependencies:

```sh
cd /opt/pluris-haven/server
sudo -u pluris-haven uv sync --frozen --no-dev
```

Install the environment and service templates:

```sh
sudo install -d -m 0750 /etc/pluris-haven
sudo install -m 0640 -o root -g pluris-haven deploy/server.env.example /etc/pluris-haven/server.env
sudo install -m 0644 deploy/pluris-haven-server.service /etc/systemd/system/
sudo install -m 0644 deploy/pluris-haven-backup.service deploy/pluris-haven-backup.timer /etc/systemd/system/
sudo install -d -m 0750 -o pluris-haven -g pluris-haven /var/backups/pluris-haven
sudo systemctl daemon-reload
sudo systemctl enable --now pluris-haven-server
sudo systemctl enable --now pluris-haven-backup.timer
```

Edit `/etc/pluris-haven/server.env` before starting the service. Generate independent secrets with `openssl rand -hex 32`; the JWT secret, friend-code pepper, and database password must all differ.
The server unit creates `/var/lib/pluris-haven` for backup-object storage and
keeps it writable while the rest of the system remains read-only to the
service.

Use Caddy, nginx, or another reverse proxy for HTTPS. `deploy/Caddyfile.example` is a minimal Caddy route. The application only listens on `127.0.0.1:8000`.

Useful checks:

```sh
systemctl status pluris-haven-server
journalctl -u pluris-haven-server -f
curl --fail http://127.0.0.1:8000/ready
```

See [SECURITY-OPERATIONS.md](SECURITY-OPERATIONS.md) for privacy-safe security
signals, initial alert thresholds, capacity checks, and the incident-response
path.

Run the first backup and restore rehearsal before opening registration:

```sh
sudo systemctl start pluris-haven-backup.service
latest="$(find /var/backups/pluris-haven -type f -name 'pluris-*.dump' -printf '%T@ %p\n' | sort -nr | head -1 | cut -d' ' -f2-)"
sudo -u postgres /opt/pluris-haven/server/deploy/restore-rehearsal.sh "$latest"
```

The rehearsal creates a temporary database, restores the dump, verifies the application tables, and drops the temporary database on exit.

## Public launch gate

Keep `PLURIS_REGISTRATION_ENABLED=false` and `PLURIS_FRIENDS_ENABLED=false` until all of these are complete:

- HTTPS and strict reverse-proxy request limits
- load and abuse testing of registration, login, refresh, and friend-code limits
- email verification and account recovery
- privacy, terms, moderation, abuse-reporting, and minor-safety policies
- automated PostgreSQL backups and a successful restore rehearsal
- readiness, authentication-failure, and database-capacity monitoring

The server applies shared database-backed rate limits to registration, login,
refresh, and friend requests. Configure `PLURIS_AUTH_RATE_LIMIT_ATTEMPTS` and
`PLURIS_AUTH_RATE_LIMIT_WINDOW_SECONDS` when needed. A separate broad IP limit
protects refresh from floods of unique invalid tokens.

Updated clients send a random nonce with refresh rotation. One matching retry
within `PLURIS_REFRESH_RETRY_GRACE_SECONDS` replaces the first response token,
covering a lost network response without making refresh tokens deterministic.
Omitting the nonce, changing it, or replaying again keeps strict session
revocation behaviour.

The container image does not enable Uvicorn's proxy-header trust by default.
If a reverse proxy is used, keep the trusted proxy boundary explicit and narrow;
never use `--forwarded-allow-ips=*` on an endpoint that can receive direct
traffic.

Run `uv run alembic upgrade head` during every deployment. The systemd unit does this before startup and refuses to start if migration fails.

## Optional containers

`Dockerfile` and `compose.yml` remain available for isolated testing. Native systemd deployment is the primary path for the live instance. A production Compose deployment must set `PLURIS_FORWARDED_ALLOW_IPS` to the exact reverse-proxy peer IPs; Compose then enables Uvicorn proxy headers only for those peers. Never use `*` or expose the API port directly when this is enabled.
