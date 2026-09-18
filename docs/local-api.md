# Local API v1

The local API implementation is an optional native-device integration surface.
It is currently hidden in the Alpha UI, pending the project's Experimental
feature controls. A legacy `local_api.enabled` preference is explicitly retired
at startup, so an earlier hidden enable choice cannot restart a listener after
an upgrade.

When exposed through Experimental controls, it binds only to `127.0.0.1` while
Pluris Haven is unlocked and running. It does not listen on LAN or WAN
interfaces, and it sends no CORS headers for browser access. Requests must use
the displayed `127.0.0.1` host; other Host headers are rejected to prevent DNS
rebinding through the loopback listener.

## Contract

When Experimental controls expose the API, the base URL is shown by the app
after enabling it. API responses use JSON,
include `Cache-Control: no-store`, and return machine-readable errors in this
shape:

```json
{ "error": { "code": "scope_required" } }
```

The current namespace is deliberately small:

| Method | Path          | Required scope | Contents                        |
| ------ | ------------- | -------------- | ------------------------------- |
| `GET`  | `/v1/health`  | client token   | API version and listener health |
| `GET`  | `/v1/system`  | `system.read`  | Local system summary and counts |
| `GET`  | `/v1/members` | `members.read` | Member summaries                |
| `GET`  | `/v1/front`   | `fronts.read`  | Current front member summaries  |

All requests use `Authorization: Bearer <client-token>`.
Missing, invalid, or revoked credentials return `401 invalid_client`; a valid
client without the needed scope returns `403 scope_required`. Unknown paths and
unsupported methods return `404 not_found` and `405 method_not_allowed`.

There are intentionally no write endpoints, no raw database access, no notes,
journals, messages, backup material, account/session access, or remote API
binding in v1. Future sensitive writes must use explicit scopes and existing
domain and safety enforcement rather than bypassing the repository.
