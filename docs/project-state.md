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
  GitHub release. **DECIDED:** Play closed testing is intended for the alpha
  distribution path; its implementation and verification remain pending.
- **IMPLEMENTED:** Recent practical pre-alpha upgrades migrate protected local
  `ph1:` text to context-bound `ph2:` before legacy reads are retired. This is
  a beta/alpha baseline, not eternal support for every experiment.

## Product and data model

- **DECIDED:** Mobile and offline/local functionality come first. Private local
  use works without an account, server, or Internet; servers are optional relay,
  backup, federation and remote-notification infrastructure.
- **DECIDED:** Sync must be transport-independent: direct device, LAN and
  manual encrypted transport can technically work without a server. Familiar
  Simply Plural workflows, few-click common tasks and deep customisation matter.
- **PARTIAL:** Basic polls and reminders exist. Advanced plural-specific polls,
  delayed-after-front and member-scoped queued/digest reminders are wanted, not
  automatic alpha blockers.
- **SCAFFOLDED:** System Safety/break-glass, revision pinning, front audit,
  chat categories/channels and generic revisions have storage foundations but
  are not complete product behaviour. Chats are wanted; categories/channels are
  preserved for that direction. Notes and journals require Markdown and revision
  history; that supersedes the older no-note-history decision. Message history
  is also wanted.

## Interop and identity

- **DECIDED:** Simply Plural import is core. PluralKit file/live import exists;
  bidirectional sync is future. OpenPlural is wanted: its importer disappearing
  was a history casualty, not deliberate removal. Do not redesign its export
  standard during cleanup.
- **DEFERRED:** Authenticated PluralSpace API import.
- **DECIDED:** No friendship directory; deliberate handles, codes, links and QR
  discovery are preferred. Trusted recovery contacts are wanted for preconfigured
  recovery capability, never ordinary private-data access; mechanics are unresolved.
- **DECIDED:** Portable user-held identity and federation are long-term product
  direction; implementation is **DEFERRED**.
  Multiple top-level systems are unresolved.

## Security, access and policy

- **IMPLEMENTED:** App Lock is per-device privacy. Unknown state fails closed;
  losing OS credentials never silently disables an already-enabled lock.
- **DECIDED:** Hosted accounts are 13+. Rooted/jailbroken devices warn, not
  block. Low-cognitive-load mode remains wanted. CLI/TUI is **SUPERSEDED** and
  dropped.
- **DECIDED:** Alpha password recovery uses a one-time emailed token entered in
  the existing mobile flow. Browser reset/deep-link infrastructure is not scope.
- **DECIDED:** A scoped, consented, revocable local API is wanted soon; it must
  not grant ambient decrypted-data access. It is not implemented in this cleanup.

## Not implemented in this cleanup

This cleanup does not implement federation completion, trusted-contact recovery,
OpenPlural restoration, the near-term local API, chat UI, note/revision UI,
plugins, desktop/watch clients or remote-notification ecosystems. Their next
work priority is decided separately; this list does not exclude them from alpha.
