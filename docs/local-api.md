# Local API v1

The local API is an optional native-device integration surface. It is disabled
by default and binds only to `127.0.0.1` while Pluris Haven is unlocked and
running. It does not listen on LAN or WAN interfaces, and it sends no CORS
headers for browser access. Requests must use the displayed `127.0.0.1` host;
other Host headers are rejected to prevent DNS rebinding through the loopback
listener.

Enable it from **Tokens** in the mobile app. The first enable selects an
available loopback port and keeps that endpoint for later unlocks and ordinary
app restarts. If that saved port is unavailable, Pluris Haven remains
not-listening and tells the user instead of silently rotating client endpoints.
Create one client for each local
integration, choose only the read scopes it needs, and copy the generated token
at creation time. The token is displayed once; Pluris Haven stores only an
encrypted client list and a keyed token fingerprint. Revoke a client to stop
that token immediately.

App Lock stopping or backgrounding the protected app stops the listener without
removing the user's explicit enable choice. It can start again after a later
successful unlock.

## Contract

The base URL is shown by the app after enabling the API. API responses use JSON,
include `Cache-Control: no-store`, and return machine-readable errors in this
shape:

```json
{ "error": { "code": "scope_required" } }
```

The current namespace is deliberately small:

| Method | Path          | Required scope | Contents                        |
| ------ | ------------- | -------------- | ------------------------------- |
| `GET`  | `/v1/health`  | none           | API version and listener health |
| `GET`  | `/v1/system`  | `system.read`  | Local system summary and counts |
| `GET`  | `/v1/members` | `members.read` | Member summaries                |
| `GET`  | `/v1/front`   | `fronts.read`  | Current front member summaries  |

Authenticated data requests use `Authorization: Bearer <client-token>`.
Missing, invalid, or revoked credentials return `401 invalid_client`; a valid
client without the needed scope returns `403 scope_required`. Unknown paths and
unsupported methods return `404 not_found` and `405 method_not_allowed`.

There are intentionally no write endpoints, no raw database access, no notes,
journals, messages, backup material, account/session access, or remote API
binding in v1. Future sensitive writes must use explicit scopes and existing
domain and safety enforcement rather than bypassing the repository.
