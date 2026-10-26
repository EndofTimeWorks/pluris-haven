import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/local/app_database.dart';
import 'package:pluris_haven/data/local/haven_repository.dart';
import 'package:pluris_haven/features/home/home_page.dart';
import 'package:pluris_haven/l10n/app_localizations.dart';

import 'test_repository.dart';

void main() {
  testWidgets('current front card is announced as an action', (tester) async {
    final semantics = tester.ensureSemantics();
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = testRepository(database);
    await repository.ensureLocalSystem();
    await repository.saveMember(const MemberDraft(displayName: 'River'));
    final river = (await repository.watchMembers().first).single;
    await repository.setFrontMembers([river.id]);
    final snapshot = await repository.loadHomeSnapshot();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CurrentFrontEntry(snapshot: snapshot, repository: repository),
        ),
      ),
    );
    await tester.pump();

    final isButton = tester
        .getSemantics(find.byType(CurrentFrontEntry))
        .getSemanticsData()
        .flagsCollection
        .isButton;
    final cardLabel = tester
        .getSemantics(find.byType(CurrentFrontEntry))
        .getSemanticsData()
        .label;
    expect(cardLabel, contains('River'));
    expect(find.bySemanticsLabel('River is fronting.'), findsNothing);
    final avatarTooltip = tester
        .getSemantics(find.byType(Tooltip))
        .getSemanticsData()
        .tooltip;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    semantics.dispose();
    expect(isButton, isTrue);
    expect(avatarTooltip, isEmpty);
  });

  testWidgets('current front name stays readable at double text scale', (
    tester,
  ) async {
    const frontName = 'The Lantern Collective of the Northern Reaches';
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = testRepository(database);
    await repository.ensureLocalSystem();
    await repository.setCustomFront(frontName);
    final snapshot = await repository.loadHomeSnapshot();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 412,
              child: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(2)),
                child: CurrentFrontEntry(
                  snapshot: snapshot,
                  repository: repository,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      tester
          .renderObject<RenderParagraph>(find.text(frontName))
          .didExceedMaxLines,
      isFalse,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
