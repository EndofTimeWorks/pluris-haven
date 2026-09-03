# Completion ledger

This is the finite implementation ledger for the pre-alpha completion programme.
It complements, but does not replace, the current decisions in
[`project-state.md`](project-state.md), product boundaries in
[`product-goals.md`](product-goals.md), and release evidence in
[`engineering-readiness.md`](engineering-readiness.md). Later decisions in
`project-state.md` win if a historical source disagrees.

Last reconciled against pushed baseline `e6fe1d7` on 2026-09-02. `COMPLETE`
means all applicable local product layers are present; `VERIFIED` additionally
requires the recorded test/runtime evidence. External and device evidence is
always recorded separately.

## P0 — data, privacy and truthful claims

| Item                                            | State / maturity                | Exact remaining layers                                                                                                                                                     |
| ----------------------------------------------- | ------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Recent `ph1:` to AAD-bound `ph2:` local upgrade | **COMPLETE / VERIFIED (local)** | Foreground/background ordering and direct legacy-ciphertext regression exist. Real-device upgrade from a distributed earlier build remains part of alpha release evidence. |
| App Lock bootstrap and credential loss          | **COMPLETE / VERIFIED (local)** | Widget coverage verifies ready/protected/inert startup and fail-closed credential loss. iOS/Android device authentication smoke tests remain external/device work.         |
| Notification permission truthfulness            | **COMPLETE / VERIFIED (local)** | Explicit setup prompting and nonprompting delivery checks are covered. Apple dialog timing remains device verification.                                                    |
| Portable recovery and encrypted server backup   | **PARTIAL / VERIFIED (local)**  | Archive/restore and queued deletion coverage exist. Need current real-artifact upgrade rehearsal and device-level recovery smoke evidence before alpha is shippable.       |
| Documentation and public capability claims      | **PARTIAL**                     | Reconcile each importer/product surface as it becomes verified; do not advertise mapper-only compatibility.                                                                |

## P1 — local product and interoperability

| Item                                                   | State / maturity                | Exact remaining layers                                                                                                                                                                                                                                                                                                                                      |
| ------------------------------------------------------ | ------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| OpenPlural v0.1 file import                            | **COMPLETE / VERIFIED (local)** | Current `ImportSource`, plan/guess, ZIP decoder, preview/review/publish path, stable source-ID dedupe, raw-extension preservation and representative fixture/UI coverage are present. Broad real-export compatibility remains release evidence, not an advertised claim.                                                                                    |
| Simply Plural import                                   | **COMPLETE / VERIFIED (local)** | Current parser, preview/review/publish, dedupe and acceptance coverage exist. Keep real-export/device evidence current for release claims.                                                                                                                                                                                                                  |
| PluralKit file/live import                             | **COMPLETE / VERIFIED (local)** | File and bounded live-token paths exist. Bidirectional sync is deferred.                                                                                                                                                                                                                                                                                    |
| Tupperbox, PluralSpace file and Ampersand file support | **PARTIAL**                     | Normalisation/mapper coverage exists; realistic source fixtures, end-to-end production-path verification and narrowly truthful capability language remain. Authenticated PluralSpace API import is deferred.                                                                                                                                                |
| Local chats, categories and channels                   | **PARTIAL / VERIFIED (local)**  | Encrypted category/channel persistence, archive support, category/channel management, system/member/channel boards, member authors, replies, editing and soft-deleted messages are reachable locally. Message revision history, visibly edited state, front association, richer member-wall navigation and System Safety wiring remain.                     |
| Notes and journals Markdown revision history           | **COMPLETE / VERIFIED (local)** | Notes and journals are encrypted at rest; production edits snapshot prior content; Markdown preview, history, pin and restore are reachable from each editor; restoring snapshots the current version for undo; archive coverage and direct local regression coverage are present. Destructive revision safety remains part of System Safety work.          |
| Message revision history                               | **PARTIAL**                     | Generic revision persistence/archive support and restore mechanics exist, but production message edits, visible edited state, history/pin/restore UI and destructive revision safety remain disconnected.                                                                                                                                                   |
| Scoped local API v1 core                               | **COMPLETE / VERIFIED (local)** | Native v1 has explicit enable UI, a persisted loopback endpoint, serialized App Lock lifecycle reconciliation, encrypted per-client grants, scopes, revocation, deterministic errors, repository summary adapters, loopback integration tests and a user/operator contract. Sensitive writes, raw-vault access and remote binding are intentionally absent. |

## P2 — local behaviour already decided

| Item                                         | State / maturity | Exact remaining layers                                                                                                                                                                                                                                                    |
| -------------------------------------------- | ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Reminders                                    | **PARTIAL**      | Daily/weekly/monthly and after-front data paths exist; permission checks are truthful. Complete member-scoped/delayed semantics where designed, queue/digest behaviour, timezone/recurrence edge coverage and delivery-history UX.                                        |
| Polls                                        | **PARTIAL**      | Single/multi choice, local options/votes and close state exist. Complete promoted visibility/deadline/purge/member/front-restriction/audit and post-vote edit/freeze semantics only where current decisions specify them.                                                 |
| Front history and front audit                | **PARTIAL**      | Local fronts/history and custom fronts work. Front-audit storage exists; normal writers, readers/UI and revision/audit presentation are disconnected.                                                                                                                     |
| System Safety                                | **SCAFFOLDED**   | Pending-action persistence/finalisation APIs exist. Ordinary destructive writers, grace-period policy, reauthentication/break-glass flow, management UI and regressions are not connected.                                                                                |
| Customisation, terminology and accessibility | **PARTIAL**      | Themes, typography, navigation, spacing and several accessibility preferences exist. Audit semantic colours, terminology, visual assets and the low-cognitive-load mode; the latter needs a materially simpler reachable UX plus tests. Root/jailbreak remains warn-only. |

## P2 — distribution, CI and alpha readiness

| Item                                              | State / maturity                          | Exact remaining layers                                                                                                                                                                                                    |
| ------------------------------------------------- | ----------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Development and versioned GitHub release topology | **IMPLEMENTED / VERIFIED (local-static)** | Version parsing, artifact/checksum flow and GitHub Release → independent Play/website fan-out exist. Need safe real GitHub Actions evidence and retry/repair-path evidence.                                               |
| Google Play internal testing                      | **IMPLEMENTED / BLOCKED-EXTERNAL**        | Automation uploads the published release AAB after canonical GitHub publication. A real authorised Console upload is required before external verification.                                                               |
| Google Play closed alpha testing                  | **MISSING**                               | Add explicit/configurable track input, closed upload/promotion path, rerun/idempotency and failure reporting without recreating GitHub Release artifacts; then Console configuration/upload remains external.             |
| Store/listing readiness                           | **PARTIAL / BLOCKED-EXTERNAL**            | Local checklist and URLs must be verified against current site/deployment; Data Safety, age rating, listing media, tester instructions, signing/App Signing and Console values require authorised external configuration. |
| GitHub-hosted CI evidence                         | **MISSING / BLOCKED-EXTERNAL**            | Static workflow validation is not CI evidence. Inspect safe workflows and run/inspect nonpublishing GitHub Actions against a pushed commit.                                                                               |
| Android upgrade/artifact evidence                 | **PARTIAL / BLOCKED-EXTERNAL**            | Local builds/checks and migration tests exist. Test a real signed artifact upgrade from supported pre-alpha state.                                                                                                        |
| Apple release/device evidence                     | **BLOCKED-EXTERNAL**                      | Linux can inspect bundle IDs, manifests and workflow assumptions. Signed install, notification/App Lock/privacy/accessibility/upgrade testing require macOS and simulator/physical hardware.                              |

## Deferred, superseded and blocked decisions

| Item                                                                                       | State                | Boundary                                                                                                                               |
| ------------------------------------------------------------------------------------------ | -------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| Authenticated PluralSpace API import                                                       | **DEFERRED**         | Do not implement without an explicit auth/resource-scope decision.                                                                     |
| Portable identity and federation protocol                                                  | **DEFERRED**         | Product direction is decided; implementation is long-term and not this programme.                                                      |
| Desktop/private browser/watch clients, plugins, third-party ecosystem, standby replication | **DEFERRED**         | Not alpha completion scope.                                                                                                            |
| CLI/TUI                                                                                    | **SUPERSEDED**       | Do not restore.                                                                                                                        |
| Trusted recovery contacts                                                                  | **BLOCKED-DECISION** | Product intent is decided, but threshold/share cryptography and recovery mechanics are unresolved; do not invent primitives or policy. |
| Multiple top-level systems and coercion/decoy behaviour                                    | **BLOCKED-DECISION** | Current product details are unresolved.                                                                                                |

## Completion protocol

For each row advanced by implementation, record the applicable path:

```text
model/schema → persistence → production writer → production reader → UI/API
→ validation/enforcement → migration/compatibility → tests → reachable path
→ truthful docs/status
```

For release work, additionally record trigger, version validation, required
checks, artifact/checksum evidence, publication ordering, retry/idempotency,
target failure reporting and actual CI/external-service evidence. A local test
or static workflow check never upgrades an external target to `VERIFIED`.
