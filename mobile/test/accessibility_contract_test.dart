import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/local/app_database.dart';
import 'package:pluris_haven/data/local/haven_repository.dart';
import 'package:pluris_haven/features/home/home_page.dart';
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

  test('app customization defaults keep accessibility opt-in and explicit', () {
    expect(AppCustomization.defaults.reducedMotion, isFalse);
    expect(AppCustomization.defaults.highContrast, isFalse);
    expect(AppCustomization.defaults.largeText, isFalse);
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
