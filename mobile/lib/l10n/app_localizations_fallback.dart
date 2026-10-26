import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// Uses base English copy for picker locales without their own ARB file.
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
