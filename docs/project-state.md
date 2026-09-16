# Project state

This is the compact current decision record. States distinguish product intent
from implementation; it is not an alpha feature checklist.

## Maturity and release

- **DECIDED:** Pluris Haven is **PRE-ALPHA**. **ALPHA** is next; beta is later
  and requires an explicit transition. Breaking changes and incomplete features
  remain acceptable through alpha.
- **IMPLEMENTED:** Development releases and versioned prereleases are separate.
  Play internal testing is integrated into the versioned release path, but it
  does not determine product maturity or block website metadata for a published
  GitHub release.
- **DECIDED:** Play closed testing is intended for the alpha distribution path;
  its implementation and external verification remain pending.
- **IMPLEMENTED:** Recent practical pre-alpha upgrades migrate protected local
  `ph1:` text to context-bound `ph2:` before legacy reads are retired. This is a
  practical pre-alpha-to-alpha upgrade baseline, not eternal support for every
  experimental build.

## Product and data model

- **DECIDED:** Mobile and offline/local functionality come first. Private local
  use works without an account, server, or Internet; servers are optional relay,
  backup, federation, hosted-account and remote-notification infrastructure.
- **DECIDED:** Sync must be transport-independent: direct device, LAN and manual
  encrypted transport can technically work without a server. Familiar Simply
  Plural workflows, few-click common tasks and deep customisation matter.
- **PARTIAL:** Basic polls and reminders exist. Advanced plural-specific polls,
  delayed-after-front and member-scoped queued/digest reminders are wanted, not
  automatic alpha blockers.
- **PARTIAL / VERIFIED (local):** Front audit, revision restore, local chat
  categories/channels, and recoverable member deletion have coherent local
  persistence and regression coverage. System Safety/break-glass, revision
  pinning, configurable retention, device/sync deletion semantics, and richer
  chat product behaviour remain incomplete. Chats are wanted;
  categories/channels are preserved for that direction.
- **DECIDED:** Notes and journals use Markdown and revision history. Note history
  supersedes the older no-note-history decision. Message edit/history behaviour
  is also wanted.

## Interop and identity

- **DECIDED:** Simply Plural import is core. PluralKit file/live import exists;
  bidirectional sync is future.
- **IMPLEMENTED / VERIFIED (local):** OpenPlural v0.1 file/archive import uses
  the current preview/review/publish path, stable source-ID dedupe, asset
  extraction and encrypted raw-extension preservation. Representative fixture
  coverage exists; do not claim compatibility beyond the supported v0.1 shape
  without real-export evidence. OpenPlural export/standard governance remains
  separate.
- **DEFERRED:** Authenticated PluralSpace API import.
- **DECIDED:** No friendship directory. Deliberate handles, rotating codes,
  links and QR discovery are preferred.
- **DECIDED:** Trusted recovery contacts are wanted for preconfigured recovery
  capability, never ordinary private-data access. Exact threshold/share
  cryptography remains unresolved and must not be invented casually.
- **DECIDED:** Portable user-held identity and federation are long-term product
  direction; implementation is **DEFERRED**. Multiple top-level systems remain
  unresolved.

## Security, access and policy

- **IMPLEMENTED:** App Lock is per-device privacy. Unknown state fails closed
  without premature authentication; losing OS credentials never silently
  disables an already-enabled lock.
- **IMPLEMENTED:** Hosted password recovery uses a one-time emailed token entered
  in the existing mobile flow. Browser reset/deep-link infrastructure is not the
  current recovery UX.
- **DECIDED:** Hosted accounts are 13+. Rooted/jailbroken devices warn, not
  block. Low-cognitive-load mode remains wanted. CLI/TUI is **SUPERSEDED** and
  dropped.
- **IMPLEMENTED / VERIFIED (local):** The first native scoped local API is
  consented, disabled by default, loopback-only and bound to the unlocked app.
  Its persisted endpoint and serialized lifecycle do not silently rotate or
  outlive a later lock. It has per-client encrypted grants, revocation, narrow
  read scopes and deterministic errors; it intentionally exposes no writes or
  raw vault access.

## Current completion priorities

The next completion work includes local chats/messages, note/journal/message
revision product flows, advanced reminders and polls, System Safety/front-audit
gaps, customization/accessibility gaps, Play closed testing, release automation
hardening and alpha readiness.

Full federation/portable-identity protocol work, desktop/private-web/watch
clients, plugins, authenticated PluralSpace API import and other explicitly
deferred platform work are not part of the current completion sweep unless
needed to fix correctness in already-exposed functionality.
