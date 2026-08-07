import 'package:flutter/widgets.dart';

const systemLanguageCode = 'system';

class SupportedLanguage {
  const SupportedLanguage(this.code, this.label, {this.flutterLocale});

  final String code;
  final String label;
  final Locale? flutterLocale;

  Locale get locale {
    final override = flutterLocale;
    if (override != null) {
      return override;
    }

    final parts = code.split('-');
    if (parts.length == 1) {
      return Locale(parts.first);
    }
    return Locale(parts.first, parts[1]);
  }
}

const supportedLanguages = [
  SupportedLanguage(systemLanguageCode, 'System default'),
  SupportedLanguage('ar', 'العربية'),
  SupportedLanguage('bg', 'Български'),
  SupportedLanguage('bn', 'বাংলা'),
  SupportedLanguage('ca', 'català'),
  SupportedLanguage('cs', 'čeština'),
  SupportedLanguage('da', 'Dansk'),
  SupportedLanguage('de', 'Deutsch'),
  SupportedLanguage('el', 'Ελληνικά'),
  SupportedLanguage('en', 'English (UK)'),
  SupportedLanguage('en-US', 'English (US)'),
  SupportedLanguage('es', 'español'),
  SupportedLanguage('fa', 'فارسی'),
  SupportedLanguage('fr', 'français'),
  SupportedLanguage('he', 'עברית'),
  SupportedLanguage('hin', 'हिन्दी', flutterLocale: Locale('hi')),
  SupportedLanguage('hr', 'hrvatski'),
  SupportedLanguage('hu', 'magyar'),
  SupportedLanguage('hy', 'Հայերեն'),
  SupportedLanguage('id', 'Bahasa Indonesia'),
  SupportedLanguage('it', 'italiano'),
  SupportedLanguage('ja', '日本語'),
  SupportedLanguage('ka', 'ქართული'),
  SupportedLanguage('kab', 'taqbaylit'),
  SupportedLanguage('ko', '한국어'),
  SupportedLanguage('nl', 'Nederlands'),
  SupportedLanguage('pl', 'polski'),
  SupportedLanguage('pt-BR', 'português brasileiro'),
  SupportedLanguage('ru', 'pyccкий'),
  SupportedLanguage('sk', 'slovensky'),
  SupportedLanguage('sl', 'slovenščina'),
  SupportedLanguage(
    'sr-Cyrl',
    'српски',
    flutterLocale: Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Cyrl'),
  ),
  SupportedLanguage(
    'sr-Latn',
    'srpski',
    flutterLocale: Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn'),
  ),
  SupportedLanguage('sv', 'svenska'),
  SupportedLanguage('ta', 'தமிழ்'),
  SupportedLanguage('tr', 'Türkçe'),
  SupportedLanguage('uk', 'українська'),
  SupportedLanguage('vi', 'Tiếng Việt'),
  SupportedLanguage('zh-CN', '简体中文'),
  SupportedLanguage('zh-TW', '繁體中文'),
];

List<Locale> get supportedLanguageLocales {
  return [
    for (final language in supportedLanguages)
      if (language.code != systemLanguageCode) language.locale,
  ];
}

SupportedLanguage supportedLanguageForCode(String? code) {
  return supportedLanguages.firstWhere(
    (language) => language.code == code,
    orElse: () => supportedLanguages.first,
  );
}
