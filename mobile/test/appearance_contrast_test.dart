import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/local/app_customization.dart';
import 'package:pluris_haven/data/local/app_database.dart';
import 'package:pluris_haven/features/home/home_page.dart';
import 'package:pluris_haven/l10n/app_localizations.dart';
import 'package:pluris_haven/main.dart';

import 'test_repository.dart';

void main() {
  test('Material You ignores unreadable stored text colours', () {
    final customization = AppCustomization.defaults.copyWith(
      visualTheme: HavenVisualTheme.materialYou,
      appearance: const HavenAppearanceOverrides(textHex: '#F5F5F5'),
    );
    final base = ColorScheme.fromSeed(
      seedColor: Color(customization.effectiveAccentArgb),
      brightness: Brightness.light,
    );

    final rendered = PlurisHavenApp.materialYouColorScheme(
      customization: customization,
      brightness: Brightness.light,
      dynamicScheme: base,
    );

    expect(rendered.onSurface, base.onSurface);
    expect(customization.appearance.textHex, '#F5F5F5');
  });

  testWidgets(
    'restored unreadable colours render safely without erasing them',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = testRepository(database);
      await repository.ensureLocalSystem();
      await repository.setThemeMode(HavenThemeMode.light);
      await repository.setAppearanceOverrides(
        const HavenAppearanceOverrides(
          textHex: '#F5F5F5',
          mutedTextHex: '#F5F5F5',
        ),
      );

      await tester.pumpWidget(PlurisHavenApp(repository: repository));
      await tester.pump();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.theme!.colorScheme.onSurface, isNot(const Color(0xFFF5F5F5)));
      expect(
        app.theme!.colorScheme.onSurfaceVariant,
        isNot(const Color(0xFFF5F5F5)),
      );
      expect(
        appearanceColoursReadable(
          appearance: const HavenAppearanceOverrides(),
          background: app.theme!.scaffoldBackgroundColor,
          surface: app.theme!.colorScheme.surface,
          card: app.theme!.colorScheme.surfaceContainerHighest,
          text: app.theme!.colorScheme.onSurface,
          mutedText: app.theme!.colorScheme.onSurfaceVariant,
        ),
        isTrue,
      );
      expect(
        (await repository.loadCustomization()).appearance.textHex,
        '#F5F5F5',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );

  testWidgets('dark palette stays stored when switching to light mode', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = testRepository(database);
    await repository.ensureLocalSystem();
    await repository.setThemeMode(HavenThemeMode.dark);
    await repository.setAppearanceOverrides(
      const HavenAppearanceOverrides(textHex: '#F5F5F5'),
    );

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();
    var app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.darkTheme!.colorScheme.onSurface, const Color(0xFFF5F5F5));

    await repository.setThemeMode(HavenThemeMode.light);
    await tester.pump();
    app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme!.colorScheme.onSurface, isNot(const Color(0xFFF5F5F5)));
    expect(
      (await repository.loadCustomization()).appearance.textHex,
      '#F5F5F5',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

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
