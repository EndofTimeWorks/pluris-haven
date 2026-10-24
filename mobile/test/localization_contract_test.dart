import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/local/supported_language.dart';
import 'package:pluris_haven/l10n/app_localizations.dart';
import 'package:pluris_haven/l10n/app_localizations_en.dart';

void main() {
  test('US English catalogue contains intentional base-English overrides', () {
    final english = _messagesIn('lib/l10n/app_en.arb');
    final usEnglish = _messagesIn('lib/l10n/app_en_US.arb');

    expect(usEnglish.keys, everyElement(isIn(english.keys)));
    for (final entry in usEnglish.entries) {
      expect(entry.value, isNot(english[entry.key]));
    }
    expect(english.values, everyElement(isNotEmpty));
    expect(usEnglish.values, everyElement(isNotEmpty));
  });

  test('only UK and US English are explicit selectable variants', () {
    final englishLanguages = supportedLanguages.where(
      (language) => language.locale.languageCode == 'en',
    );

    expect(
      englishLanguages.map((language) => language.code),
      orderedEquals(['en', 'en-US']),
    );
    expect(supportedLanguageLocales.first, const Locale('en'));
    expect(supportedLanguageLocales[1], const Locale('en', 'US'));
  });

  test('unlisted regional English locales intentionally use base English', () {
    for (final locale in const [
      Locale('en', 'GB'),
      Locale('en', 'CA'),
      Locale('en', 'IN'),
    ]) {
      final localizations = lookupAppLocalizations(locale);
      expect(localizations, isA<AppLocalizationsEn>());
      expect(localizations, isNot(isA<AppLocalizationsEnUs>()));
      expect(localizations.localeName, 'en');
      expect(localizations.customizeTitle, 'Customise');
    }
  });

  test('regional English preserves reviewed spelling differences', () {
    final uk = AppLocalizationsEn();
    final us = AppLocalizationsEnUs();

    expect(uk.syncOffDescription, contains('synchronisation'));
    expect(us.syncOffDescription, contains('synchronization'));
    expect(uk.importStepNormalizeFieldsTitle, 'Normalise fields');
    expect(us.importStepNormalizeFieldsTitle, 'Normalize fields');
    expect(uk.importReasonUnrecognised, contains('recognise'));
    expect(us.importReasonUnrecognised, contains('recognize'));
    expect(uk.importStepPrepareSimplyPluralAvatarsDetail, contains('localise'));
    expect(us.importStepPrepareSimplyPluralAvatarsDetail, contains('localize'));
  });

  test('integrity warnings resolve for UK fallback and US English', () {
    for (final locale in const [Locale('en', 'GB'), Locale('en', 'US')]) {
      final l10n = lookupAppLocalizations(locale);
      expect(l10n.importReasonAmpersandMarkers, contains('Ampersand'));
      expect(l10n.importPreservesLocalProfile, contains('unchanged'));
      expect(l10n.nativeImportUpdatesProfile, contains('system profile'));
      expect(l10n.reminderTimeError, contains('9am'));
      expect(l10n.unsavedChangesTitle, 'Unsaved changes');
    }
  });

  test('English interpolation and pluralisation remain intact', () {
    final uk = AppLocalizationsEn();
    final us = AppLocalizationsEnUs();

    for (final localizations in [uk, us]) {
      expect(localizations.frontHistoryCountSubtitle(1), '1 entry');
      expect(localizations.frontHistoryCountSubtitle(2), '2 entries');
      expect(
        localizations.importDiagnosticInvalidPortableFormat('bad version'),
        contains('bad version'),
      );
      expect(
        localizations.couldNotSavePluralPortFile('permission denied'),
        contains('permission denied'),
      );
      expect(
        localizations.removeMemberFailed('database locked'),
        contains('database locked'),
      );
    }
  });
}

Map<String, String> _messagesIn(String path) {
  final json =
      jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
  return {
    for (final entry in json.entries)
      if (!entry.key.startsWith('@')) entry.key: entry.value! as String,
  };
}
