import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pluris_haven/features/home/home_page.dart';
import 'package:pluris_haven/l10n/app_localizations.dart';

void main() {
  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'Pluris Haven',
      packageName: 'works.endoftime.plurishaven.debug',
      version: '0.3.1-alpha.2',
      buildNumber: '3007',
      buildSignature: '',
    );
  });

  for (final locale in const [Locale('en', 'GB'), Locale('en', 'US')]) {
    testWidgets('About shows the installed version in $locale', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: AboutPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('0.3.1-alpha.2'), findsOneWidget);
      expect(find.textContaining('3007'), findsOneWidget);
    });

    testWidgets('User Report includes the installed version in $locale', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: UserReportPage(snapshot: null, onSelect: (_) {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('0.3.1-alpha.2'), findsOneWidget);
      expect(find.textContaining('3007'), findsOneWidget);
    });
  }
}
