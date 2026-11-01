# Project state

Pluris Haven is **pre-alpha**. Alpha is the next milestone; moving to beta needs a separate
decision. This page records product decisions. The [completion ledger](completion-ledger.md) tracks
implementation and test evidence.

## Local product

The mobile app and offline use come first. Members, fronts and other local features must work
without an account or network connection. Private content must not leave the device as plaintext by
default. Some database metadata, including relationships and timestamps, is not encrypted.

Simply Plural-style ease of use, quick common tasks and deep customisation are product goals. People
must be able to choose their own terms. Notes and journals use Markdown and revision history;
message edit history is also wanted.

Basic polls and reminders work locally. More complex voting rules, queued and digest reminders,
retention rules and System Safety still need decisions or implementation. These advanced features do
not automatically block alpha. Front audits, revision restore, chat categories and channels, and
recoverable member deletion have local persistence and tests; their remaining behaviour is tracked
in the ledger.

The scoped local API is implemented for narrow read access but hidden until Experimental feature
controls are ready. It binds to loopback while the app is unlocked, uses per-client grants and
exposes no raw vault access or writes. An old enable preference is retired at startup.

## Import and identity

Simply Plural import is core. PluralKit file and bounded live import exist; bidirectional sync is
later work. OpenPlural v0.1 file import has local fixture and preview coverage, but broad
real-export compatibility has not been proved. PluralPort Draft v0.1 file import/export maps
systems, members and fronts. Other records are retained rather than assigned unratified wire
meanings. There is no PluralPort conformance suite yet. File interchange does not imply live sync or
federation.

Sync, if implemented, must not depend on one hosted server. Manual encrypted transport, direct
devices and LAN transport remain possible directions. Hosted federation and portable user-held
identity are long-term work, not alpha requirements. Authenticated PluralSpace API import is
deferred.

There will be no friendship directory. Discovery should be deliberate through exact handles,
rotating codes, links or QR. Trusted recovery contacts are wanted, but the share/threshold design is
undecided; do not invent it to close a checklist item.

## Security and access

App Lock is per-device. Unknown startup state stays protected, and loss of OS credentials must not
silently disable an enabled lock. Password-protected local archives provide portable recovery;
device-key server snapshots do not.

Hosted accounts are optional and outside the current local-product priority. The server prototype
has one-time emailed password recovery; public registration remains disabled. Hosted accounts are
intended for people aged 13 or older. No public production service is assumed here.

Web-to-app deep links are not implemented or verified. The Android association file alone is not a
working App Link, and iOS lacks the corresponding association and route handling. Rooted or
jailbroken devices receive a warning, not a block. Low-cognitive-load mode remains a goal. CLI/TUI
clients were dropped.

## Release boundary

Development builds and versioned releases are separate. Play internal testing is part of the
versioned path; closed alpha testing still needs external configuration and verification. A store
path does not change product maturity. Recent supported pre-alpha databases migrate protected `ph1:`
text to context-bound `ph2:`; this is a practical upgrade path, not a promise to support every
experimental build forever.

See [distribution](distribution.md) for release channels and
[engineering readiness](engineering-readiness.md) for the remaining checks.
