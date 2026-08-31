import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/local/app_database.dart';
import 'package:pluris_haven/data/local/haven_repository.dart';
import 'package:pluris_haven/features/home/home_page.dart';
import 'package:pluris_haven/l10n/app_localizations.dart';
import 'package:pluris_haven/main.dart';

import 'test_repository.dart';

void main() {
  testWidgets('accessibility preferences reach the app media contract', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = testRepository(database);
    await repository.ensureLocalSystem();
    await repository.setReducedMotion(true);
    await repository.setLargeText(true);

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    final mediaQueries = tester.widgetList<MediaQuery>(find.byType(MediaQuery));
    final appMediaQuery = mediaQueries.last;
    expect(appMediaQuery.data.disableAnimations, isTrue);
    expect(appMediaQuery.data.accessibleNavigation, isTrue);
    expect(appMediaQuery.data.textScaler.scale(16), greaterThan(16));
    expect(find.byTooltip('Open navigation menu'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('high contrast preference reaches both app themes', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = testRepository(database);
    await repository.ensureLocalSystem();
    await repository.setHighContrast(true);

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme!.colorScheme.surface, Colors.white);
    expect(app.darkTheme!.colorScheme.surface, const Color(0xFF11131A));
    expect(app.darkTheme!.scaffoldBackgroundColor, Colors.black);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('appearance text scale reaches the app media contract', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = testRepository(database);
    await repository.ensureLocalSystem();
    await repository.setAppearanceOverrides(
      const HavenAppearanceOverrides(textScale: 1.25),
    );

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    final mediaQueries = tester.widgetList<MediaQuery>(find.byType(MediaQuery));
    final appMediaQuery = mediaQueries.last;
    expect(appMediaQuery.data.textScaler.scale(16), closeTo(20, 0.01));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('card appearance override reaches the standard theme', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = testRepository(database);
    await repository.ensureLocalSystem();
    await repository.setAppearanceOverrides(
      const HavenAppearanceOverrides(cardHex: '#102030'),
    );

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme!.cardTheme.color, const Color(0xFF102030));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  test('app customization defaults keep accessibility opt-in and explicit', () {
    expect(AppCustomization.defaults.reducedMotion, isFalse);
    expect(AppCustomization.defaults.highContrast, isFalse);
    expect(AppCustomization.defaults.largeText, isFalse);
  });

  test('appearance distinguishes colour overrides from layout overrides', () {
    expect(
      const HavenAppearanceOverrides(cardRadius: 20).hasColorOverrides,
      isFalse,
    );
    expect(
      const HavenAppearanceOverrides(cardHex: '#20242B').hasColorOverrides,
      isTrue,
    );
  });

  test('Material You derives every role from a custom palette', () {
    const dynamicScheme = ColorScheme.light(
      primary: Color(0xFF00639B),
      onPrimary: Colors.white,
      surface: Color(0xFFF5FAFF),
      surfaceContainerHighest: Color(0xFFDDE3EB),
      onSurface: Color(0xFF151B20),
      onSurfaceVariant: Color(0xFF41474D),
      outline: Color(0xFF71787E),
      outlineVariant: Color(0xFFC1C7CE),
    );
    final customization = AppCustomization.defaults.copyWith(
      visualTheme: HavenVisualTheme.materialYou,
      appearance: const HavenAppearanceOverrides(
        backgroundHex: '#171922',
        cardHex: '#2B2E3D',
      ),
    );

    final scheme = PlurisHavenApp.materialYouColorScheme(
      customization: customization,
      brightness: Brightness.dark,
      dynamicScheme: dynamicScheme,
    );
    final expected = ColorScheme.fromSeed(
      seedColor: Color(customization.effectiveAccentArgb),
      brightness: Brightness.dark,
    );

    expect(scheme.primary, expected.primary);
    expect(scheme.outline, expected.outline);
    expect(scheme.surfaceContainerHighest, const Color(0xFF2B2E3D));
  });

  test('Material You honours a custom accent without other overrides', () {
    const dynamicScheme = ColorScheme.light(
      primary: Color(0xFF00639B),
      onPrimary: Colors.white,
      surface: Color(0xFFF5FAFF),
      surfaceContainerHighest: Color(0xFFDDE3EB),
      onSurface: Color(0xFF151B20),
      onSurfaceVariant: Color(0xFF41474D),
      outline: Color(0xFF71787E),
      outlineVariant: Color(0xFFC1C7CE),
    );
    final customization = AppCustomization.defaults.copyWith(
      visualTheme: HavenVisualTheme.materialYou,
      customAccentHex: '#12ABEF',
    );

    final scheme = PlurisHavenApp.materialYouColorScheme(
      customization: customization,
      brightness: Brightness.light,
      dynamicScheme: dynamicScheme,
    );
    final expected = ColorScheme.fromSeed(
      seedColor: Color(customization.effectiveAccentArgb),
      brightness: Brightness.light,
    );

    expect(scheme.primary, expected.primary);
  });

  testWidgets('shared icon bubbles use the active accent colour', (
    tester,
  ) async {
    const accent = Color(0xFF12ABEF);
    final scheme = ColorScheme.fromSeed(seedColor: accent);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorScheme: scheme),
        home: const Center(child: SpIconBubble(icon: Icons.person_rounded)),
      ),
    );

    expect(
      tester.widget<Icon>(find.byIcon(Icons.person_rounded)).color,
      scheme.primary,
    );
  });

  testWidgets('shared cards honour appearance layout overrides', (
    tester,
  ) async {
    const extension = HavenVisualThemeExtension(
      HavenVisualTheme.original,
      cardRadius: 22,
      spacingScale: .8,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [extension]),
        home: Scaffold(
          body: SpCard(
            padding: const EdgeInsets.all(10),
            onTap: () {},
            child: const SizedBox(width: 10, height: 10),
          ),
        ),
      ),
    );

    final decoration = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    final box = decoration.decoration as BoxDecoration;
    expect(box.borderRadius, BorderRadius.circular(22));
    expect(
      tester.widget<Padding>(find.byType(Padding)).padding,
      const EdgeInsets.all(8),
    );
    expect(
      tester.widget<InkWell>(find.byType(InkWell)).borderRadius,
      BorderRadius.circular(22),
    );
  });

  testWidgets('avatars expose named image semantics', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SpAvatar(
            size: 48,
            color: Color(0xFF7B61FF),
            label: 'R',
            semanticLabel: 'Avatar for River',
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Avatar for River'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Decorative avatar placeholder'),
      findsNothing,
    );
  });

  testWidgets('status and settings rows expose useful semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              const StatusPill(text: 'offline'),
              SpSettingsRow('Sync', 'not available yet', onTap: () {}),
            ],
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Status offline'), findsOneWidget);
    final settingsSemantics = tester.getSemantics(find.byType(SpSettingsRow));
    expect(settingsSemantics.label, contains('Sync'));
    expect(settingsSemantics.label, contains('not available yet'));
  });

  testWidgets('every drawer route has a semantic label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SpDrawer(
          snapshot: null,
          selected: SpSection.dashboard,
          onSelect: (_) {},
        ),
      ),
    );

    final l10n = AppLocalizations.of(tester.element(find.byType(SpDrawer)));
    final drawerList = find.byType(Scrollable);
    for (final section in SpSection.values) {
      final label = section.label(l10n);
      final text = find.text(label);
      await tester.scrollUntilVisible(text, 180, scrollable: drawerList);
      expect(
        find.bySemanticsLabel(RegExp('^${RegExp.escape(label)}')),
        findsOneWidget,
      );
    }
  });

  testWidgets('import and restore progress announce their current status', (
    tester,
  ) async {
    final summary = RestoreRehearsalSummary(
      canRestore: false,
      fileName: 'backup.json',
      counts: const {},
      checkedAt: DateTime(2026),
      elapsed: Duration.zero,
      error: 'The archive could not be restored safely.',
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ListView(
          children: [
            const ImportProgressCard(
              status: 'Importing members...',
              isActive: true,
            ),
            RestoreRehearsalResult(summary: summary),
          ],
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('Import status: Importing members...'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Restore status: Restore rehearsal failed. '
        'The archive could not be restored safely.',
      ),
      findsOneWidget,
    );
  });
}
