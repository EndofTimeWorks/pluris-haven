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
- Reduced motion is persisted and also respects the platform's animation
  preference.
- High contrast is a persisted app preference with a dedicated theme path.
- The widget suite exercises semantic labels for fronting and common icon-only
  controls.
- Member, group, system, and custom-front avatars expose entity-specific image
  semantics rather than announcing initials as if they were the image label.
- Missing or unavailable avatar images expose an explicit decorative
  placeholder state.

## Alpha blocking audit

The alpha candidate is blocked until each item below has a passing manual or
automated check. A check may be marked complete only with an evidence link in
the release record or a focused test.

- [ ] TalkBack pass on every app route and sheet.
- [ ] VoiceOver pass on every app route and sheet.
- [ ] Keyboard and switch-access pass, including focus order and back behavior.
- [ ] Large-text pass at the largest supported system scale without clipped
  actions or hidden form fields.
- [ ] High-contrast pass for text, borders, status indicators, charts, and
  avatars.
- [ ] Reduced-motion pass for navigation, sheets, import progress, and
  notifications.
- [ ] Every icon-only action has a unique tooltip or semantic label.
- [ ] Every status communicated by color also has text or a semantic state.
- [ ] Destructive actions identify the object and require confirmation.
- [ ] Import and restore progress exposes text, current phase, and failure
  recovery.
- [ ] Avatar and banner inputs expose meaningful alternative text or an
  explicitly described decorative state.

## Still Needed

- Full TalkBack and VoiceOver pass on every screen.
- Keyboard, switch-access, and large-text testing.
- High-contrast theme pass.
- Reduced-motion setting.
- Device-level verification of named avatar and banner semantics; persisted
  user-provided alternative-text fields are not yet implemented.
- Better structured reminder scheduling with actual notification scheduling.
- Focus order checks for import sheets and long forms.

The full audit is intentionally still open. Existing automated coverage is
evidence for individual behaviors, not a substitute for device-level
TalkBack/VoiceOver and switch-access testing.
