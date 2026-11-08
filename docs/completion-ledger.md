# Completion ledger

This is the current pre-alpha remediation status. “Fixed” below means the specified local path
passed tests; it does not mean Android, iOS or a screen reader has been checked. The October
black-box report remains the source for reproduction steps. [Project state](project-state.md) holds
product decisions, and [engineering readiness](engineering-readiness.md) holds release checks.

## Data integrity and recovery

- **F14, N7–N12, N14 — Fixed locally.** Add/replace fronting preserves unchanged sessions and active
  custom fronts. One member can end without ending other or archived fronters. Co-fronting polls
  accept multiple active members. Repository and widget regressions pass; check touch and
  screen-reader behaviour on a device.
- **Manual front history — Fixed for new writes.** Persistence rejects end-before-start, invalid
  future active starts and duplicate active sessions for one member. Co-fronting remains valid, and
  editing an active entry leaves it active. Existing invalid rows remain readable and exportable;
  test upgrades with historical device data.
- **N33 — Partial.** Startup checks the key before opening the database. Missing, corrupt and
  temporarily inaccessible keys have distinct guidance and Retry. Existing database, WAL, SHM or
  avatar data prevents a new key being provisioned. Original data stays untouched. Test interrupted
  recovery, restart and restored-device states on Android and iOS.
- **iOS backup marker — Fixed in source; device check needed.** The marker is backup-excluded. A
  restored marker can be replaced only when no encrypted data remains; a missing key with data fails
  closed. Dart file-state tests pass. Swift and iCloud restore checks need macOS/iOS.
- **Empty archive preferences — Fixed locally.** Reset appearance can produce an empty value. Plain
  and encrypted restore tests accept it without accepting a missing value.
- **Portable archives — Implemented locally.** Password-protected `.phx.json` archives restore local
  data and the current front into a fresh database. Keep older readers. The streaming `.pluris`
  format is partial and cannot replace this recovery path yet.
- **Local encryption upgrade — Fixed locally.** Supported recent `ph1:` values migrate to
  context-bound `ph2:`; a signed-device upgrade from an earlier distributed build remains to be
  tested.
- **App Lock and notification permissions — Fixed locally; device checks needed.** Widget tests
  cover protected startup and fail-closed credential loss, and notification setup and delivery
  permission paths. Device authentication and Apple permission timing still need testing.
- **Member purge and votes — Fixed for current lifecycle.** Archive and recoverable removal retain
  vote history. Purge clears profile data and member-owned links while retaining a stable historical
  ID and poll totals. Changing historical vote retention needs an owner decision.

## Imports and local features

- **N27, N52, F63 — Partial.** Native preferences conflicts are prompted, orphaned front links are
  flagged, pasted drafts survive navigation, and job labels are readable. Create rejects colliding
  content IDs inside the transaction before writes; repeated or missing IDs in an archive fail for
  every choice. Existing custom-field definitions can still be reused after member purge. The
  preview does not cover every record type, Create does not remap IDs, and adapter round trips need
  more evidence.
- **PluralPort Draft v0.1 — Partial.** File import/export maps systems, members and fronts.
  Unsupported records stay in encrypted source data. Reference checks and import results need work;
  there is no published conformance suite. This is distinct from live sync.
- **OpenPlural v0.1 — Locally tested.** File/ZIP import, preview, source-ID dedupe, assets and
  raw-extension preservation have fixture coverage. Real exports are needed for broad compatibility
  claims.
- **Simply Plural, PluralKit — Locally tested.** Simply Plural and PluralKit file paths and bounded
  PluralKit live import have tests. Bidirectional sync is deferred.
- **Tupperbox, PluralSpace, Ampersand — Partial.** Source-shaped sanitised fixtures cover preview,
  normalisation and repeat-import dedupe. Broader claims need real exporter files. Authenticated
  PluralSpace API import is deferred.
- **N24 — Fixed locally.** Journals keep subject and optional author separately, allow backdating,
  open in read view and preserve those fields in archives. Existing entries keep an unrecorded
  author.
- **N25 — Fixed locally.** Chat filters by board, category and stable channel ID. Category names
  appear in channel choices; multiple fronters do not silently choose an author. Device selection
  announcements need checking.
- **Notes, journals and messages — Locally tested.** Content is encrypted; production edits create
  revisions, and history, pin and restore are reachable. Destructive revision protection remains
  part of System Safety.
- **N43 — Fixed in source; delivery check needed.** Weekly reminders persist multiple weekdays
  through archive restore. Stable notification IDs cancel obsolete schedules on edit, disable and
  delete. Scheduling failures are shown without deleting the saved reminder. Native delivery,
  permissions and timezone changes while closed need device tests.
- **N3 — Fixed locally.** Dot-separated 12-hour times such as 9.30pm store as 21:30.
- **N13, F30 — Fixed locally.** Hourly overlap counts once, timeline rows have names and endpoints,
  and the hour chart has a value scale. Check charts with device screen readers.
- **Advanced polls and reminders — Partial.** Shared and member-attributed votes, co-fronting
  restrictions, daily/weekly/monthly and after-front reminders exist. Poll retention, result
  visibility and edit rules, and queued/digest reminder semantics still need decisions.
- **System Safety — Blocked on decisions.** Pending-action storage exists but production actions do
  not use it. Decide protected actions, grace period, reauthentication and break-glass rules before
  exposure.

## Access, navigation and website

- **N28, N31 — Partial.** Dashboard scaling, UK history dates, large-text dropdowns and a narrow 2×
  weekly-reminder form passed local checks. More scaled and RTL screens need testing.
- **N29 — Partial.** Front picker, shared rows, settings rows and tested note/reminder flows return
  focus to their launcher. Confirmed deletion returns focus to a surviving control. Other sheets and
  disabled controls need checking.
- **N53, F37 — Partial.** Member, group, note, journal, reminder, poll and saved-front actions have
  contextual labels; duplicate names use a short ID where needed. Decorative chevrons are omitted
  from semantics. Other controls and duplicate announcements need a device pass.
- **N54 — Fixed in client; device check needed.** Poll options include their question and selection
  state. Verify reading order with TalkBack or VoiceOver.
- **Settings and errors — Fixed for changed controls.** Shared settings rows no longer repeat their
  spoken title or open planned-feature dialogs. Representative long-name dropdowns fit, and changed
  delete, import, archive, profile and backup errors show plain messages. Other paths need review.
- **N62, N63 — Fixed locally; device check needed.** Notification events are separate semantics rows
  with persistent Mark as read. Large-text front-picker actions remain reachable.
- **Member name spoofing — Fixed for new edits.** Invisible and direction controls are rejected,
  duplicate visible names prompt a warning, and existing duplicates are distinguished in pickers.
  Imported names are not rewritten.
- **Privacy buckets — Partial.** Existing buckets can be edited. They remain separate from the
  member profile Privacy text; unifying the models needs a decision.
- **F3, N36 — F3 partial; N36 fixed.** The member editor uses member wording, and empty states
  mention supported imports rather than only Simply Plural. Technical fields remain visible to
  everyone.
- **N30, N32 — N30 open; N32 fixed locally.** Shortcut order survives hiding and showing. Visual
  inconsistencies remain.
- **W4, W5 — Fixed in source.** Website theme and support checks pass. The owner approved
  `security@plurishaven.app` for general support and security reports; mailbox delivery and real
  browser preference switching still need checking.
- **Local API — Implemented but hidden.** Narrow loopback read scopes and per-client grants exist.
  The UI remains hidden until Experimental controls are ready; startup retires the old enable
  choice.
- **Internal background sync — No-op.** The registered task currently returns success without
  synchronising. Do not advertise it as sync.
- **Server accounts, online backup, federation — Deferred.** No public server is in the current
  local-product scope. Historical S1–S9 and N45–N48 are not marked fixed by this ledger. A narrow
  login-rate regression was fixed in source and tested at `/v1/auth/login`; no public endpoint was
  inspected or changed.

## Latest local verification

The last full run against this code passed **509 Flutter tests with 2 skipped**. The schema
migration suite passed **13 tests**. Changed-code analysis, Dart format and localisation checks
passed. Whole-package analysis still reports one unused import in the owner's pre-existing untracked
`mobile/test/cac_demo_import_test.dart`; that file was not changed. The website check, build,
generated-page accessibility and security-header checks passed. The Android debug APK built with
SHA-256 `518f55f58dae92ba98835fcf58ac769e0601260fedacb4fafe73a0b38afc3d6d`.

No Android runner was attached and this host has no `/dev/kvm`; the APK was not run. iOS, iCloud
restore, native notification delivery, TalkBack and VoiceOver remain unverified. No database schema
or archive format changed in the latest client batches. Tests cover the specified paths, not every
old black-box finding.
