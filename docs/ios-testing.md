# iOS testing

This build is for people helping test Pluris Haven before an App Store or
TestFlight release. It is unsigned, so it needs to be installed with a tool
such as SideStore, Sideloadly, or an Apple Developer-managed device.

## Getting the build

1. Open the repository's Actions page.
2. Run **iOS Test IPA** from the commit you are testing.
3. Download `pluris-haven-ios-test-unsigned` from that run's artifacts.
4. Import the IPA into your signing tool and install it.

Please install over an existing Pluris Haven test build where possible. That
keeps local data available while testing an update.

## What to check

- App lock returns to the screen you were using after Face ID or passcode.
- The app switcher does not show private content.
- With screen-recording or mirroring active, the app shows its privacy screen.
- Import opens Files and accepts a supported archive or image.
- An avatar can be saved to Files, then opened by another app.
- Temporary avatar sharing works, and the share sheet does not expose any
  other files.

For a bug report, include the iOS version, phone model, commit or Actions run,
what you expected, what happened, and a screenshot or screen recording if it
does not contain private data.
