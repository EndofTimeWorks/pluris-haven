import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// Wraps [AppLocalizations.delegate] so every locale the language picker
/// offers resolves to something, not just the two ([Locale('en')] and
/// [Locale('en', 'US')]) with real ARB content today.
///
/// The language picker's own copy already tells the user "Interface text
/// stays English until translations are added" - this makes that true
/// instead of a crash. [AppLocalizations.delegate] on its own reports a
/// locale it has no ARB file for as unsupported, and [Localizations.of]
/// then returns null for it, which the generated non-nullable
/// `AppLocalizations.of(context)` turns into a null-check failure.
class FallbackAppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const FallbackAppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) {
    if (AppLocalizations.delegate.isSupported(locale)) {
      return AppLocalizations.delegate.load(locale);
    }
    return AppLocalizations.delegate.load(const Locale('en'));
  }

  @override
  bool shouldReload(FallbackAppLocalizationsDelegate old) => false;
}
