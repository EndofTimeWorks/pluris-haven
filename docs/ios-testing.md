# iOS testing

This build is for people helping test Pluris Haven before a signed TestFlight or
App Store release. Current CI artifacts are unsigned, so they need to be
installed with SideStore, Sideloadly, AltStore, or an Apple Developer-managed
device.

## Getting the build

1. Open the repository's Actions page.
2. Run **iOS Test IPA** from the commit you are testing, or use the unsigned IPA
   from the applicable dev/versioned mobile workflow.
3. Download the unsigned Pluris Haven IPA artifact from that run.
4. Import the IPA into your signing tool and install it.

Install over an existing compatible Pluris Haven test build where possible so
upgrade and local-data migration behavior is exercised instead of testing only
a fresh install.

## What to check

- Cold launch with App Lock disabled does not unexpectedly request Face ID or
  passcode while persisted security settings are still loading.
- With App Lock enabled, private UI stays protected until authentication
  succeeds and returns to the intended screen afterward.
- If device credentials become unavailable, an already-enabled App Lock remains
  fail-closed rather than silently disabling itself.
- Notification permission is first requested from an explicit notification or
  reminder setup action, not later from a front/reminder delivery event.
- After denying notification permission, later delivery attempts do not trigger
  a surprise permission prompt and are not recorded as delivered.
- The app switcher does not show private content.
- With screen-recording or mirroring active, the app shows its privacy screen.
- Import opens Files and accepts the formats actually supported by the current
  build.
- An avatar can be saved to Files, then opened by another app.
- Temporary avatar sharing works, and the share sheet does not expose unrelated
  private files.
- Installing over a supported earlier pre-alpha build preserves/migrates local
  data correctly.

For a bug report, include the iOS version, phone model, commit or Actions run,
what you expected, what happened, and a screenshot or screen recording only if
it contains no private data.
