import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/local/app_customization.dart';
import 'package:pluris_haven/data/local/app_database.dart';
import 'package:pluris_haven/features/home/home_page.dart';
import 'package:pluris_haven/l10n/app_localizations.dart';

import 'test_repository.dart';

void main() {
  testWidgets('rejects near-white appearance text on a light surface', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = testRepository(database);
    final customization = AppCustomization.defaults.copyWith(
      themeMode: HavenThemeMode.light,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAppearanceEditor(
                context,
                customization: customization,
                repository: repository,
              ),
              child: const Text('Open appearance'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open appearance'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(3), '#F5F5F5');
    await tester.scrollUntilVisible(
      find.text('Save appearance'),
      350,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Save appearance'));
    await tester.pumpAndSettle();

    expect(find.textContaining('contrast'), findsOneWidget);
    expect((await repository.loadCustomization()).appearance.textHex, isNull);
    expect(find.byType(AppearanceEditorSheet), findsOneWidget);
  });
}
