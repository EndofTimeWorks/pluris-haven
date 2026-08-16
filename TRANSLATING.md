# Translating Pluris Haven

Mobile app text goes through Flutter's ARB-based localisation system in
`mobile/lib/l10n/`. Two locales have real content today: `en` (British
English, the base) and `en_US` (American English). The in-app language picker
already lists around three dozen other languages, but picking one of those
just falls back to English for now, with a note in the picker saying so.
Adding a real translation for one of those is what this doc is about.

## Where translations come from

Only two sources are used for translated text:

- Google Translate, as a starting point a human then checks
- Community contributors who actually speak the language

No AI-generated translations. A machine-translated first pass is fine as a
starting point, but it needs a human fluent in the language to check it
before it goes in.

## If the language isn't in the picker at all

The steps below assume the language is already one of the roughly three
dozen options in the picker, just untranslated. If someone wants to translate
into a language that isn't listed there yet, add it first: open
`mobile/lib/data/local/supported_language.dart` and add a
`SupportedLanguage(code, label)` entry to `supportedLanguages`, in the same
alphabetical-by-code position as its neighbours. `label` is the language's own
name for itself in its own script, the way every other entry does it
(`'Deutsch'`, not `'German'`). Use a plain ICU code for `code` (`'th'`,
`'fi'`) unless the language needs a region or script qualifier, in which case
use a dash the way `'pt-BR'` and `'zh-CN'` already do - the `locale` getter on
that class turns a dash-separated code into the right `Locale` automatically.
Only pass `flutterLocale` explicitly if the code doesn't map cleanly (see the
`sr-Cyrl`/`sr-Latn` entries for why). Once the language has a picker entry,
follow the steps below to actually give it content.

## Adding a language

1. Look at `mobile/lib/l10n/app_en.arb`. It's the template: every key the app
   uses, in British English, with a `@key` metadata block above any key that
   takes a placeholder (e.g. `usePresetLabel`).
2. Copy it to `mobile/lib/l10n/app_<code>.arb`, where `<code>` is the
   language's ICU code with an underscore before any region/script, not a
   dash - `de.arb`, `pt_BR.arb`, `zh_CN.arb`, `sr_Latn.arb`. This differs from
   the dash-separated codes shown in `mobile/lib/data/local/supported_language.dart`
   (`pt-BR`, `zh-CN`); that file's codes are Pluris Haven's own internal
   language-picker identifiers, not the ARB filename.
3. Translate every value. Leave the `@key` metadata blocks and placeholder
   names (the `{presetLabel}` style tokens) alone; only translate the actual
   message text around them.
4. Set `"@@locale"` at the top of the new file to match, using the same
   underscore format (`"de"`, `"pt_BR"`).
5. From `mobile/`, run `flutter gen-l10n` to regenerate the Dart
   localisation classes, then `flutter analyze` and `flutter test` to make
   sure nothing broke.

## Testing a translation locally

Pick the language from the in-app language picker (Customise → Language), or
set your device/emulator's system language and leave Pluris Haven on
"System default." Check text doesn't overflow on smaller screens and that
placeholders land in a sensible place for the language's word order.

## Partial translations

You don't have to translate every key to open a PR. Missing keys fall back to
English rather than breaking the build, but say in the PR which parts are
still untranslated so it's easy to track what's left.

## What's not set up yet

There's no translation management platform (Weblate, Crowdin, etc.) wired up
yet - for now, translations come in as regular pull requests editing ARB
files directly. That may change once there's enough translation activity to
justify it.
