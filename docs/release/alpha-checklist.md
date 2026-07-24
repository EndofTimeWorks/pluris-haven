# Alpha Candidate Checklist

Updated: 2026-07-24

This checklist is the release decision record for the Android-first alpha
candidate. A checked item needs command output, a test, a CI artifact, or a
manual device note attached to the release record. Any known data-loss,
encryption, migration, restore, signing, or accessibility failure blocks the
candidate.

## Required evidence

- [ ] `dart format --set-exit-if-changed lib test`
- [ ] `flutter analyze`
- [ ] Full `flutter test`, including encrypted snapshot and local import tests
- [ ] Signed universal Android APK
- [ ] Signed split-per-ABI Android APKs
- [ ] `BUILD.txt` and `SHA256SUMS.txt` match the published artifacts
- [ ] Unsigned iOS release compilation on macOS CI
- [ ] TalkBack and VoiceOver route-by-route notes
- [ ] Keyboard/switch-access and large-text notes
- [ ] High-contrast and reduced-motion notes
- [ ] Simply Plural, PluralKit, Tupperbox, PluralSpace, Prism, Sheaf, and
  Ampersand fixture provenance or an explicit unavailable-source note
- [ ] Encrypted export, interrupted upload, clean restore, and tamper-failure
  evidence

## Explicitly outside this alpha

- Bidirectional synchronization
- Portable identity and federation
- ActivityPub
- Private server-side plaintext processing
- iOS signed distribution

The repository may contain scaffolding for deferred work, but release notes
must not describe any of those items as implemented.
