import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/local/app_database.dart';
import 'package:pluris_haven/data/local/haven_repository.dart';
import 'package:pluris_haven/features/home/home_page.dart';
import 'package:pluris_haven/l10n/app_localizations.dart';

import 'test_repository.dart';

void main() {
  testWidgets('top fronts exposes a separate labelled node for each front', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final database = AppDatabase(NativeDatabase.memory());
    final repository = testRepository(database);
    addTearDown(database.close);
    await repository.ensureLocalSystem();
    final endedAt = DateTime.now().subtract(const Duration(hours: 1));
    await repository.saveFrontHistoryEntry(
      FrontHistoryDraft(
        label: 'River',
        startedAt: endedAt.subtract(const Duration(hours: 2)),
        endedAt: endedAt,
      ),
    );
    await repository.saveFrontHistoryEntry(
      FrontHistoryDraft(
        label: 'Wren',
        startedAt: endedAt.subtract(const Duration(hours: 1)),
        endedAt: endedAt,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: AnalyticsPage(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Top fronts'));

    expect(
      find.bySemanticsLabel(RegExp(r'^River, .*1 session$')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp(r'^Wren, .*1 session$')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp(r'River.*Wren', dotAll: true)),
      findsNothing,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
    semantics.dispose();
  });

  testWidgets('empty analytics distinguishes a short window from no history', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final repository = testRepository(database);
    addTearDown(database.close);
    await repository.ensureLocalSystem();
    final endedAt = DateTime.now().subtract(const Duration(days: 60));
    await repository.saveFrontHistoryEntry(
      FrontHistoryDraft(
        label: 'Earlier front',
        startedAt: endedAt.subtract(const Duration(hours: 1)),
        endedAt: endedAt,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: AnalyticsPage(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No fronts in this period'), findsOneWidget);
    expect(
      find.text('Choose a longer period or All to see earlier front history.'),
      findsOneWidget,
    );
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(find.text('Earlier front'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
  });
}
