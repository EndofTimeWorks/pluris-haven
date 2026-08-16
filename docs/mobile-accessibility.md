# Mobile accessibility

Accessibility is part of the app contract. Pluris Haven should work for screen
reader users, blind and low-vision users, keyboard/switch users, low-mobility
users, and people who need reduced motion or simpler screens.

## Rules for UI work

- Icon-only controls must have a tooltip or semantic label.
- Decorative icons should be excluded from semantics so TalkBack and VoiceOver
  read the actual row text instead.
- Rows that do nothing must not be exposed as buttons.
- Destructive actions must ask for confirmation and name what will be removed.
- Colour cannot be the only state indicator. Include text such as archived,
  fronting, off, failed, or done.
- Text must scale with system font settings. Avoid hard fixed-height containers
  around text-heavy controls.
- Tap targets should stay at least 48 by 48 logical pixels.
- Back navigation must close sheets before leaving the page.
- Import and sync progress must be visible as text, not just spinners.
- Motion should be minimal and must honour the reduced-motion setting and the
  platform animation preference.

## Covered so far

- Dashboard supports hiding all shortcuts and shows a text empty state.
- Member archive state is shown in text.
- Paste JSON sheet can be dismissed with Android back without crashing.
- Delete actions for members, notes, and reminders use confirmation dialogs.
- Support links are real buttons that open in the browser.
- Reduced motion is persisted and also respects the platform's animation
  preference.
- High contrast is a persisted app preference with a dedicated theme path.
- The widget suite exercises semantic labels for fronting and common icon-only
  controls.
- Member, group, system, and custom-front avatars expose entity-specific image
  semantics rather than announcing initials as if they were the image label.
- Missing or unavailable avatar images expose an explicit decorative
  placeholder state.

## Still needs device coverage

The automated checks cover individual behaviours. They do not replace a
route-by-route pass with TalkBack, VoiceOver, keyboard or switch access. The
remaining device work is:

- TalkBack and VoiceOver on every screen and sheet.
- Keyboard, switch-access, and large-text testing, including focus order.
- High-contrast checks for text, borders, status indicators, charts, and avatars.
- Device-level reduced-motion verification.
- Device-level verification of named avatar and banner semantics; persisted
  user-provided alternative-text fields are not yet implemented.
- Reminder schedules need TalkBack and VoiceOver testing, including permission
  denial and unavailable notification services.

Import and restore progress already exposes text, the current phase, and failure
recovery in widget semantics. Device timing and focus checks remain open.
