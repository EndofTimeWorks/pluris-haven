# Reference and Readiness Matrix

Updated: 2026-07-24

This is a comparative product-research record for Pluris Haven. Sheaf,
Ampersand, Simply Plural, and other tools are inspiration and interoperability
references, not specifications to clone. We may study public behavior,
documentation, and test fixtures, but we do not copy source code, artwork,
branding, or proprietary data. The local Sheaf and Ampersand checkouts are
licensed under AGPLv3; any future reuse must go through a separate license
review.

## Sources

| Reference | Evidence used | Role |
| --- | --- | --- |
| Sheaf | `/home/end/Projects/sheaf/docs/IMPORT.md`, `/home/end/Projects/sheaf/docs/CLIENT_DESIGN.md`, importer/export tests, and [the official FAQ](https://sheaf.sh/faq/) | Import fidelity, recovery UX, self-hosting and client-first boundaries |
| Ampersand | `/home/end/Projects/ampersand/README.md`, `src/lib/serialization.ts`, accessibility/options/security code, import/export tests | Serialization, accessibility controls, app-lock and distribution ideas |
| Simply Plural | Pluris Haven's importer, local acceptance fixture, and schema mapping | Compatibility target and round-trip evidence |
| PluralKit, Tupperbox, PluralSpace, Prism | Existing Pluris Haven importer contracts and fixtures | Additional import compatibility targets |

## Comparative matrix

Status values mean: **adopt** is approved for Pluris Haven work,
**evaluate** needs an implementation decision or evidence, **defer** is
intentionally outside the current alpha, and **decline** does not fit the
offline-first product boundary.

| Area | Observed pattern | Pluris Haven decision/status | Evidence and next action |
| --- | --- | --- | --- |
| Import preview | Sheaf describes previewing changes before writing and exposing import toggles and warnings. | Adopt | Import/export UI and acceptance tests; make every destructive or ambiguous import preview its effects. |
| Import error handling | Sheaf calls out safe token handling, retries, rate limits, and actionable warnings. | Adopt | Keep credentials out of logs and provide visible partial-failure details; add fixture tests for retry/error states. |
| Front history conversion | Sheaf converts front switches into intervals and documents lossy cases. | Adopt | Preserve timestamps and provenance; show a warning when a source cannot express an exact interval. |
| Re-import behavior | Sheaf tests stable re-import and duplicate handling. | Adopt | Keep Simply Plural re-import idempotent and extend the same contract to other importers. |
| Export fidelity | Ampersand's serializer preserves Maps, Sets, files, and metadata through an explicit format. | Evaluate | Compare against Pluris Haven archive format; add schema/version and media-hash fixtures before changing the format. |
| Local recovery | Both references emphasize user-controlled local data and practical export paths. | Adopt | Keep export account-free; add encrypted snapshot and clean-restore rehearsal as an alpha gate. |
| Accessibility controls | Ampersand exposes font scaling, high-legibility fonts, reduced motion, contrast, color indicators, and compact-list options. | Adopt | Full mobile WCAG-oriented audit; unresolved accessibility failures block alpha. |
| Semantic state | The references communicate fronting, archived/offline state, and actions as text or labels rather than color alone. | Adopt | Audit every screen for semantics, focus order, text scaling, and 48dp targets. |
| App lock and privacy | Ampersand provides local security controls; Sheaf's client-first model keeps private data on the client. | Evaluate | Keep device-secure master-key storage and assess an explicit app-lock surface after the alpha audit. |
| Self-hosting | Sheaf documents self-hosting and a client-first API boundary. | Evaluate | Backup server remains optional; document opaque chunk storage and portable recovery without making server use mandatory. |
| Distribution | Ampersand documents multiple Android/iOS distribution routes. | Adopt selectively | Ship Android-first signed GitHub prerelease APKs; keep iOS compile-gated until a signing/distribution decision exists. |
| Bidirectional sync | A familiar service pattern is not sufficient evidence for a safe private sync protocol. | Defer | No bidirectional sync, portable identity, federation, or ActivityPub in this alpha workstream. |
| Remote/private sharing | Sharing changes the threat model and requires the still-deferred E2EE/federation protocol. | Defer | Do not add server upload of local system content while the protocol is unsettled. |

## Current implementation targets

1. Preserve the existing encrypted local repository and fail-closed migration
   behavior.
2. Finish the mobile accessibility audit with evidence, not a readiness claim
   based only on widgets existing.
3. Make Android alpha artifacts reproducible and signed, with iOS compilation
   as a separate CI gate.
4. Use the live repository's device-key encrypted snapshot path with the
   optional server's immutable versioned chunk API; this is backup, not
   synchronization.
5. Keep provenance for every real-world importer fixture and never commit
   private exports or avatar archives.

## Provenance rule for implementation

Every adopted pattern must link to a source above and receive a local test,
acceptance criterion, or decision-ledger entry. A reference can inspire a
workflow without forcing its information architecture, visual design, license,
or protocol onto Pluris Haven.
