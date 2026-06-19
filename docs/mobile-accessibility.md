# Mobile Accessibility

Accessibility is part of the app contract. Pluris Haven should work for screen
reader users, blind and low-vision users, keyboard/switch users, low-mobility
users, and people who need reduced motion or simpler screens.

## Rules for UI Work

- Icon-only controls must have a tooltip or semantic label.
- Decorative icons should be excluded from semantics so TalkBack and VoiceOver
  read the actual row text instead.
- Rows that do nothing must not be exposed as buttons.
- Destructive actions must ask for confirmation and name what will be removed.
- Color cannot be the only state indicator. Include text such as archived,
  fronting, off, failed, or done.
- Text must scale with system font settings. Avoid hard fixed-height containers
  around text-heavy controls.
- Tap targets should stay at least 48 by 48 logical pixels.
- Back navigation must close sheets before leaving the page.
- Import and sync progress must be visible as text, not just spinners.
- Motion should be minimal until a reduced-motion setting exists.

## Current Coverage

- Dashboard supports hiding all shortcuts and shows a text empty state.
- Member archive state is shown in text.
- Paste JSON sheet can be dismissed with Android back without crashing.
- Delete actions for members, notes, and reminders use confirmation dialogs.
- Support links are real buttons that open in the browser.

## Still Needed

- Full TalkBack and VoiceOver pass on every screen.
- Keyboard, switch-access, and large-text testing.
- High-contrast theme pass.
- Reduced-motion setting.
- Alt text fields for imported/stored avatars.
- Better structured reminder scheduling with actual notification scheduling.
- Focus order checks for import sheets and long forms.
