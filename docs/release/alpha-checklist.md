# Alpha Candidate Checklist

Updated: 2026-07-24

This checklist is the release decision record for the Android-first alpha
candidate. A checked item needs command output, a test, a CI artifact, or a
manual device note attached to the release record. Any known data-loss,
encryption, migration, restore, signing, or accessibility failure blocks the
candidate.

## Required evidence

- [x] `dart format --set-exit-if-changed lib test`
- [x] `flutter analyze`
- [x] Full `flutter test`, including encrypted snapshot and local import tests;
  140 passed with the private Simply Plural and Pluris Haven fixtures enabled
- [x] Signed universal Android APK; locally verified with Java 17 and Flutter
  3.44.4 for `0.2.0-pre-alpha.1.dev.9+2007`
- [x] Signed split-per-ABI Android APKs; arm64, armeabi-v7a, and x86_64
  locally verified with the same signing certificate
- [x] Local `BUILD.txt` and `SHA256SUMS.txt` release assembly; all four APKs
  pass `sha256sum --check`
- [ ] Unsigned iOS release compilation on macOS CI
- [ ] TalkBack and VoiceOver route-by-route notes
- [ ] Keyboard/switch-access and large-text notes
- [ ] High-contrast and reduced-motion notes
- [x] Simply Plural and Pluris Haven private fixtures are recorded locally;
  PluralKit, Tupperbox, PluralSpace, and Prism have inline contract fixtures;
  Sheaf and Ampersand are explicitly research-only references with no Pluris
  import fixture claimed
- [x] Encrypted export, interrupted/resumable upload, clean restore, and
  tamper-failure evidence

## Evidence notes

- Android build `2007` is greater than the highest existing tagged build
  `2006`; `mobile-v0.2.0-pre-alpha.1.dev.9+2007` is not already tagged.
- `apksigner` verifies the universal APK and all three split APKs. `aapt2`
  reports package `works.endoftime.plurishaven` and version name
  `0.2.0-pre-alpha.1.dev.9`.
- The release workflow's GitHub publication step has not run from this local
  checkout. Signing secrets and the remote macOS iOS runner remain external
  release evidence.
- The tag/manual mobile release workflow now makes Android publication depend
  on its unsigned macOS iOS compilation job. The workflow configuration parses
  locally, but the hosted macOS job still needs to run successfully before the
  iOS evidence checkbox can be checked.
- The automated accessibility contract covers entity-specific avatar labels
  and the decorative placeholder fallback. Device-level TalkBack, VoiceOver,
  banner, keyboard/switch, large-text, high-contrast, and reduced-motion notes
  remain required.

## Explicitly outside this alpha

- Bidirectional synchronization
- Portable identity and federation
- ActivityPub
- Private server-side plaintext processing
- iOS signed distribution

The repository may contain scaffolding for deferred work, but release notes
must not describe any of those items as implemented.
