import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/import/import_sources.dart';
import 'package:pluris_haven/data/local/app_database.dart';
import 'package:pluris_haven/data/local/haven_repository.dart';
import 'package:pluris_haven/data/security/archive_encryption.dart';
import 'package:pluris_haven/main.dart';

void main() {
  testWidgets('shows the offline home dashboard', (tester) async {
    final repository = FakeHavenRepository(
      const HomeSnapshot(
        systemName: 'Local system',
        memberCount: 0,
        groupCount: 0,
        noteCount: 0,
        frontHistoryCount: 0,
        currentFrontLabel: null,
      ),
    );
    addTearDown(repository.close);

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Members'), findsOneWidget);
    expect(find.text('Front History'), findsOneWidget);
    expect(find.text('Customize'), findsOneWidget);
    expect(find.text('Local system'), findsWidgets);
  });

  testWidgets('sets and clears a custom front from the home screen', (
    tester,
  ) async {
    final repository = FakeHavenRepository(
      const HomeSnapshot(
        systemName: 'Local system',
        memberCount: 0,
        groupCount: 0,
        noteCount: 0,
        frontHistoryCount: 0,
        currentFrontLabel: null,
      ),
    );
    addTearDown(repository.close);

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    await tester.tap(find.text('Front History'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('set front'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('custom-front-label-field')),
      'blurry co-con',
    );
    await tester.tap(find.text('Set'));
    await tester.pumpAndSettle();

    expect(find.text('blurry co-con'), findsWidgets);
    expect(find.text('fronting'), findsOneWidget);
    expect(find.text('started 1/1 12:00 - active'), findsOneWidget);

    await tester.tap(find.text('set front'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(find.text('None'), findsOneWidget);
    expect(find.text('none'), findsOneWidget);
    expect(find.text('started 1/1 12:00 - ended 1/1 13:00'), findsOneWidget);
  });

  testWidgets('edits and deletes front history entries', (tester) async {
    final repository = FakeHavenRepository(
      const HomeSnapshot(
        systemName: 'Local system',
        memberCount: 0,
        groupCount: 0,
        noteCount: 0,
        frontHistoryCount: 0,
        currentFrontLabel: null,
      ),
    );
    addTearDown(repository.close);

    await repository.setCustomFront('blurry co-con');

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    await tester.tap(find.text('Front History'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('blurry co-con').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('front-status-note-field')),
      'felt blurry after lunch',
    );
    await tester.tap(
      find.byKey(const ValueKey('save-front-status-note-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('felt blurry after lunch'), findsOneWidget);
    expect(
      repository._frontHistory.single.statusNote,
      'felt blurry after lunch',
    );

    await tester.enterText(
      find.byKey(const ValueKey('front-history-search-field')),
      'lunch',
    );
    await tester.pumpAndSettle();
    expect(find.text('felt blurry after lunch'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('front-history-search-field')),
      'no match',
    );
    await tester.pumpAndSettle();
    expect(find.text('No matching fronts'), findsOneWidget);

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('blurry co-con').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete entry'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(repository._frontHistory, isEmpty);
    expect(find.text('No front history yet'), findsOneWidget);
  });

  testWidgets('saves applies and deletes custom and named fronts', (
    tester,
  ) async {
    final repository = FakeHavenRepository(
      const HomeSnapshot(
        systemName: 'Local system',
        memberCount: 0,
        groupCount: 0,
        noteCount: 0,
        frontHistoryCount: 0,
        currentFrontLabel: null,
      ),
    );
    addTearDown(repository.close);

    await repository.saveMember(const MemberDraft(displayName: 'River'));
    await repository.saveMember(const MemberDraft(displayName: 'Sage'));

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    await tester.tap(find.text('Front History'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('set front'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('custom-front-label-field')),
      'Asleep',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('save-custom-front-button')),
    );
    await tester.tap(find.byKey(const ValueKey('save-custom-front-button')));
    await tester.pumpAndSettle();

    expect(find.text('Saved fronts'), findsOneWidget);
    expect(find.text('Asleep'), findsWidgets);
    expect(repository._namedFronts.single.customLabel, 'Asleep');
    expect(
      repository._namedFrontMembers[repository._namedFronts.single.id],
      isEmpty,
    );

    await tester.enterText(
      find.byKey(const ValueKey('saved-front-search-field')),
      'asle',
    );
    await tester.pumpAndSettle();
    expect(find.text('Asleep'), findsWidgets);
    await tester.enterText(
      find.byKey(const ValueKey('saved-front-search-field')),
      'missing',
    );
    await tester.pumpAndSettle();
    expect(find.text('No matching saved fronts'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('saved-front-search-field')),
      '',
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('front-member-search-field')),
      'riv',
    );
    await tester.pumpAndSettle();
    expect(find.text('River'), findsOneWidget);
    expect(find.text('Sage'), findsNothing);
    await tester.enterText(
      find.byKey(const ValueKey('front-member-search-field')),
      '',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('River'));
    await tester.tap(find.text('Sage'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('save-selected-named-front-button')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('named-front-name-field')),
      'River + Sage',
    );
    await tester.tap(
      find.byKey(const ValueKey('confirm-save-named-front-button')),
    );
    await tester.pumpAndSettle();

    expect(repository._namedFronts.length, 2);
    final combo = repository._namedFronts.singleWhere(
      (front) => front.name == 'River + Sage',
    );
    expect(repository._namedFrontMembers[combo.id], [
      'fake-member-1',
      'fake-member-2',
    ]);

    await tester.ensureVisible(find.text('River + Sage'));
    await tester.tap(find.byTooltip('Set saved front').last);
    await tester.pumpAndSettle();
    expect(repository._snapshot.currentFrontText, 'River, Sage');
    expect(
      find.bySemanticsLabel('River is currently fronting'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Sage is currently fronting'), findsOneWidget);

    await tester.tap(find.text('set front'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete saved front').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(repository._namedFronts.length, 1);
  });

  testWidgets('manages custom fronts as saved front states', (tester) async {
    final repository = FakeHavenRepository(
      const HomeSnapshot(
        systemName: 'Local system',
        memberCount: 0,
        groupCount: 0,
        noteCount: 0,
        frontHistoryCount: 0,
        currentFrontLabel: null,
      ),
    );
    addTearDown(repository.close);

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom Fronts'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('add-custom-front-page-button')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('custom-front-page-name-field')),
      'Asleep',
    );
    await tester.enterText(
      find.byKey(const ValueKey('custom-front-page-color-field')),
      '#ABCDEF',
    );
    await tester.enterText(
      find.byKey(const ValueKey('custom-front-page-description-field')),
      'Resting',
    );
    await tester.tap(
      find.byKey(const ValueKey('save-custom-front-page-button')),
    );
    await tester.pumpAndSettle();

    expect(repository._namedFronts.single.customLabel, 'Asleep');
    expect(repository._namedFronts.single.colorHex, '#ABCDEF');
    expect(
      repository._namedFrontMembers[repository._namedFronts.single.id],
      isEmpty,
    );
    expect(find.text('Asleep'), findsWidgets);

    await tester.tap(find.byTooltip('Edit custom front'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('custom-front-page-name-field')),
      'Away',
    );
    await tester.tap(
      find.byKey(const ValueKey('save-custom-front-page-button')),
    );
    await tester.pumpAndSettle();

    expect(repository._namedFronts.single.customLabel, 'Away');
    expect(find.text('Away'), findsWidgets);

    await tester.tap(find.byTooltip('Set custom front'));
    await tester.pumpAndSettle();
    expect(repository._snapshot.currentFrontText, 'Away');

    await tester.tap(find.byTooltip('Delete custom front'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(repository._namedFronts, isEmpty);
  });

  testWidgets('shows local analytics from front history', (tester) async {
    final repository = FakeHavenRepository(
      const HomeSnapshot(
        systemName: 'Local system',
        memberCount: 0,
        groupCount: 0,
        noteCount: 0,
        frontHistoryCount: 0,
        currentFrontLabel: null,
      ),
    );
    addTearDown(repository.close);

    await repository.setCustomFront('Asleep');
    await repository.clearCurrentFront();
    await repository.setCustomFront('Away');
    await repository.clearCurrentFront();

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    await openDrawerSection(tester, 'Analytics');
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    expect(find.text('Total front time'), findsOneWidget);
    expect(find.text('Sessions'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Top fronts'), findsOneWidget);
    expect(find.text('Asleep'), findsOneWidget);
    expect(find.text('Away'), findsOneWidget);
    expect(find.text('Hour of day'), findsOneWidget);
  });

  testWidgets('opens a familiar section from the dashboard', (tester) async {
    final repository = FakeHavenRepository(
      const HomeSnapshot(
        systemName: 'Local system',
        memberCount: 0,
        groupCount: 0,
        noteCount: 0,
        frontHistoryCount: 0,
        currentFrontLabel: null,
      ),
    );
    addTearDown(repository.close);

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    await tester.tap(find.text('Members').first);
    await tester.pumpAndSettle();

    expect(find.text('Search members'), findsOneWidget);
    expect(find.text('No members saved locally'), findsOneWidget);

    await tester.tap(find.text('Add member'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('member-name-field')),
      'Iris',
    );
    await tester.enterText(
      find.byKey(const ValueKey('member-pronouns-field')),
      'she/they',
    );
    await tester.enterText(
      find.byKey(const ValueKey('member-color-hex-field')),
      '#12abef',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('save-member-button')),
    );
    await tester.tap(find.byKey(const ValueKey('save-member-button')));
    await tester.pumpAndSettle();

    expect(find.text('Iris'), findsOneWidget);
    expect(find.text('she/they'), findsOneWidget);
    expect(repository._members.single.colorHex, '#12ABEF');

    await tester.enterText(find.byType(TextField).first, 'zzzz');
    await tester.pumpAndSettle();
    expect(find.text('No matching members'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'iris');
    await tester.pumpAndSettle();
    expect(find.text('Iris'), findsOneWidget);

    await tester.tap(find.byTooltip('Member actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set front'));
    await tester.pumpAndSettle();

    expect(repository._snapshot.currentFrontText, 'Iris');
    expect(repository._snapshot.frontHistoryCount, 1);
  });

  testWidgets('archives restores edits and deletes members', (tester) async {
    final repository = FakeHavenRepository(
      const HomeSnapshot(
        systemName: 'Local system',
        memberCount: 0,
        groupCount: 0,
        noteCount: 0,
        frontHistoryCount: 0,
        currentFrontLabel: null,
      ),
    );
    addTearDown(repository.close);

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    await tester.tap(find.text('Members').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add member'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('member-name-field')),
      'Iris',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('save-member-button')),
    );
    await tester.tap(find.byKey(const ValueKey('save-member-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Member actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();
    await tester.pump();

    expect(find.text('Iris'), findsOneWidget);
    expect(find.text('no pronouns - archived'), findsOneWidget);
    expect(repository._snapshot.memberCount, 0);

    await tester.tap(find.byTooltip('Member actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();

    expect(repository._snapshot.memberCount, 1);

    await tester.tap(find.byTooltip('Member actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('member-name-field')),
      'Iris edited',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('save-member-button')),
    );
    await tester.tap(find.byKey(const ValueKey('save-member-button')));
    await tester.pumpAndSettle();

    expect(find.text('Iris edited'), findsOneWidget);

    await tester.tap(find.byTooltip('Member actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Iris edited'), findsNothing);
    expect(find.text('No members saved locally'), findsOneWidget);
  });

  testWidgets('opens member profile details and actions', (tester) async {
    final repository = FakeHavenRepository(
      const HomeSnapshot(
        systemName: 'Local system',
        memberCount: 0,
        groupCount: 0,
        noteCount: 0,
        frontHistoryCount: 0,
        currentFrontLabel: null,
      ),
    );
    addTearDown(repository.close);

    await repository.saveGroup(const GroupDraft(name: 'Caretakers'));
    await repository.saveGroup(const GroupDraft(name: 'Subsystem A'));
    await repository.saveMember(
      const MemberDraft(
        displayName: 'River',
        pronouns: 'they/them',
        colorHex: '#62D6B8',
        birthday: '02-03',
        emoji: 'R',
        privacy: 'trusted',
        description: 'Protector and organizer.',
        avatarUrl: 'local-avatar:river.png',
        pluralKitId: 'abcde',
        folderId: 'fake-group-1',
        groupIds: ['fake-group-1', 'fake-group-2'],
      ),
    );

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    await openDrawerSection(tester, 'Members');
    await tester.tap(find.text('River'));
    await tester.pumpAndSettle();

    expect(find.text('Protector and organizer.'), findsOneWidget);
    expect(find.text('they/them'), findsWidgets);
    expect(find.text('02-03'), findsOneWidget);
    expect(find.text('trusted'), findsWidgets);
    expect(find.text('abcde'), findsOneWidget);
    expect(find.text('#62D6B8'), findsOneWidget);
    expect(find.text('Caretakers, Subsystem A'), findsOneWidget);

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Set front'));
    await tester.tap(find.widgetWithText(FilledButton, 'Set front'));
    await tester.pumpAndSettle();

    expect(repository._snapshot.currentFrontText, 'River');
  });

  testWidgets('duplicates a member profile into the editor', (tester) async {
    final repository = FakeHavenRepository(
      const HomeSnapshot(
        systemName: 'Local system',
        memberCount: 0,
        groupCount: 0,
        noteCount: 0,
        frontHistoryCount: 0,
        currentFrontLabel: null,
      ),
    );
    addTearDown(repository.close);

    await repository.saveGroup(const GroupDraft(name: 'Caretakers'));
    await repository.saveMember(
      const MemberDraft(
        displayName: 'River',
        pronouns: 'they/them',
        colorHex: '#62D6B8',
        birthday: '02-03',
        emoji: 'R',
        privacy: 'trusted',
        description: 'Protector and organizer.',
        avatarUrl: 'local-avatar:river.png',
        pluralKitId: 'abcde',
        folderId: 'fake-group-1',
        groupIds: ['fake-group-1'],
      ),
    );

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    await openDrawerSection(tester, 'Members');
    await tester.tap(find.byTooltip('Member actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('member-name-field')))
          .controller!
          .text,
      'River copy',
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('member-pronouns-field')),
          )
          .controller!
          .text,
      'they/them',
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('member-pluralkit-field')),
          )
          .controller!
          .text,
      isEmpty,
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('save-member-button')),
    );
    await tester.tap(find.byKey(const ValueKey('save-member-button')));
    await tester.pumpAndSettle();

    expect(repository._members, hasLength(2));
    final duplicate = repository._members.last;
    expect(duplicate.displayName, 'River copy');
    expect(duplicate.colorHex, '#62D6B8');
    expect(duplicate.avatarUrl, 'local-avatar:river.png');
    expect(duplicate.pluralKitId, isNull);
    expect(duplicate.groupIds, ['fake-group-1']);
  });

  testWidgets('creates and assigns tags from a member profile', (tester) async {
    final repository = FakeHavenRepository(
      const HomeSnapshot(
        systemName: 'Local system',
        memberCount: 0,
        groupCount: 0,
        noteCount: 0,
        frontHistoryCount: 0,
        currentFrontLabel: null,
      ),
    );
    addTearDown(repository.close);

    await repository.saveMember(const MemberDraft(displayName: 'River'));

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    await openDrawerSection(tester, 'Members');
    await tester.tap(find.text('River'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Member tags'));
    await tester.tap(find.text('Member tags'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('member-tag-name-field')),
      'Protector',
    );
    await tester.enterText(
      find.byKey(const ValueKey('member-tag-color-field')),
      '#80ffaa',
    );
    await tester.tap(find.byKey(const ValueKey('create-member-tag-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save-member-tags-button')));
    await tester.pumpAndSettle();

    expect(find.text('Protector'), findsOneWidget);
    expect(repository._tags.single.colorHex, '#80FFAA');
    expect(repository._memberTagIds[repository._members.single.id], [
      repository._tags.single.id,
    ]);
  });

  testWidgets('assigns multiple groups from the member editor', (tester) async {
    final repository = FakeHavenRepository(
      const HomeSnapshot(
        systemName: 'Local system',
        memberCount: 0,
        groupCount: 0,
        noteCount: 0,
        frontHistoryCount: 0,
        currentFrontLabel: null,
      ),
    );
    addTearDown(repository.close);

    await repository.saveGroup(const GroupDraft(name: 'Caretakers'));
    await repository.saveGroup(const GroupDraft(name: 'Subsystem A'));

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    await openDrawerSection(tester, 'Members');
    await tester.tap(find.text('Add member'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('member-name-field')),
      'Iris',
    );
    await tester.ensureVisible(find.widgetWithText(FilterChip, 'Caretakers'));
    await tester.tap(find.widgetWithText(FilterChip, 'Caretakers'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(FilterChip, 'Subsystem A'));
    await tester.tap(find.widgetWithText(FilterChip, 'Subsystem A'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('save-member-button')),
    );
    await tester.tap(find.byKey(const ValueKey('save-member-button')));
    await tester.pumpAndSettle();

    expect(repository._members.single.folderId, 'fake-group-1');
    expect(repository._members.single.groupIds, [
      'fake-group-1',
      'fake-group-2',
    ]);
  });

  testWidgets('opens local useful links and how-to guides', (tester) async {
    final repository = FakeHavenRepository(
      const HomeSnapshot(
        systemName: 'Local system',
        memberCount: 0,
        groupCount: 0,
        noteCount: 0,
        frontHistoryCount: 0,
        currentFrontLabel: null,
      ),
    );
    addTearDown(repository.close);

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    await openDrawerSection(tester, 'Useful Links');

    expect(find.text('Import from Simply Plural'), findsOneWidget);
    expect(find.text('Back up local data'), findsOneWidget);
    expect(find.text("What's new"), findsOneWidget);
    expect(find.text('APK releases'), findsOneWidget);

    await tester.tap(find.text('How-to guides'));
    await tester.pumpAndSettle();

    expect(find.text("How-to's"), findsWidgets);
    expect(find.text('Track a front'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Save custom fronts'), 220);
    expect(find.text('Save custom fronts'), findsOneWidget);
  });

  testWidgets('shows clickable project and optional support details', (
    tester,
  ) async {
    final repository = FakeHavenRepository(
      const HomeSnapshot(
        systemName: 'Local system',
        memberCount: 0,
        groupCount: 0,
        noteCount: 0,
        frontHistoryCount: 0,
        currentFrontLabel: null,
      ),
    );
    addTearDown(repository.close);

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    await openDrawerSection(tester, 'About');

    expect(find.text('Offline-first plural system tracker.'), findsOneWidget);
    expect(find.text('Simply Plural, PluralKit, OpenPlural'), findsOneWidget);
    expect(find.text('github.com/EndofTimeWorks/pluris-haven'), findsOneWidget);
    expect(find.text('Optional support'), findsOneWidget);
    expect(find.text('GitHub Sponsors'), findsOneWidget);
    expect(find.text('patreon.com/EndofTimeWorks'), findsOneWidget);
    await tester.scrollUntilVisible(find.byTooltip('Copy Monero address'), 220);
    expect(find.byTooltip('Copy Monero address'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('copy-monero-address-button')),
    );
    await tester.pump();
    final copyButton = find
        .byKey(const ValueKey('copy-monero-address-button'))
        .hitTestable();
    expect(copyButton, findsOneWidget);
    await tester.tap(copyButton);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Monero address copied'), findsOneWidget);
  });

  testWidgets('opens local account and privacy status pages', (tester) async {
    final repository = FakeHavenRepository(
      const HomeSnapshot(
        systemName: 'Local system',
        memberCount: 2,
        groupCount: 1,
        noteCount: 3,
        frontHistoryCount: 4,
        currentFrontLabel: 'River',
      ),
    );
    addTearDown(repository.close);

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    await openDrawerSection(tester, 'Account Settings');
    expect(find.text('Cloud account'), findsOneWidget);
    expect(find.text('Field encryption'), findsOneWidget);

    await openDrawerSection(tester, 'Privacy buckets');
    expect(find.text('Private'), findsOneWidget);
    expect(find.text('Custom fields privacy'), findsOneWidget);

    await openDrawerSection(tester, 'Tokens');
    expect(find.text('PluralKit live import'), findsOneWidget);

    await openDrawerSection(tester, 'User Report');
    expect(find.text('User Report'), findsWidgets);
    expect(find.widgetWithText(FilledButton, 'Copy report'), findsOneWidget);
  });

  testWidgets('adds a local group from the groups section', (tester) async {
    final repository = FakeHavenRepository(
      const HomeSnapshot(
        systemName: 'Local system',
        memberCount: 0,
        groupCount: 0,
        noteCount: 0,
        frontHistoryCount: 0,
        currentFrontLabel: null,
      ),
    );
    addTearDown(repository.close);

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    await openDrawerSection(tester, 'Groups');

    expect(find.text('No groups yet'), findsOneWidget);

    await tester.tap(find.text('Add group'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('group-name-field')),
      'Caretakers',
    );
    await tester.enterText(
      find.byKey(const ValueKey('group-emoji-field')),
      '*',
    );
    await tester.enterText(
      find.byKey(const ValueKey('group-color-hex-field')),
      '00ffaa',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('save-group-button')));
    await tester.tap(find.byKey(const ValueKey('save-group-button')));
    await tester.pumpAndSettle();

    expect(find.text('Caretakers'), findsOneWidget);
    expect(repository._groups.single.colorHex, '#00FFAA');
    expect(repository._snapshot.groupCount, 1);
  });

  testWidgets('edits and deletes nested groups locally', (tester) async {
    final repository = FakeHavenRepository(
      const HomeSnapshot(
        systemName: 'Local system',
        memberCount: 0,
        groupCount: 0,
        noteCount: 0,
        frontHistoryCount: 0,
        currentFrontLabel: null,
      ),
    );
    addTearDown(repository.close);

    await repository.saveGroup(const GroupDraft(name: 'Caretakers'));
    await repository.saveGroup(
      const GroupDraft(name: 'Gate crew', parentGroupId: 'fake-group-1'),
    );

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    await openDrawerSection(tester, 'Groups');
    expect(find.text('Caretakers'), findsOneWidget);
    expect(find.text('Gate crew'), findsOneWidget);

    await tester.tap(find.text('Gate crew'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('group-name-field')),
      'Gatekeepers',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('save-group-button')));
    await tester.tap(find.byKey(const ValueKey('save-group-button')));
    await tester.pumpAndSettle();

    expect(find.text('Gatekeepers'), findsOneWidget);
    expect(repository._groups.last.name, 'Gatekeepers');
    expect(repository._groups.last.parentGroupId, 'fake-group-1');

    await tester.tap(find.byTooltip('Group actions').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Caretakers'), findsNothing);
    expect(find.text('Gatekeepers'), findsOneWidget);
    expect(repository._groups.single.parentGroupId, isNull);
    expect(repository._snapshot.groupCount, 1);
  });

  testWidgets('routes section import actions to import setup', (tester) async {
    final repository = FakeHavenRepository(
      const HomeSnapshot(
        systemName: 'Local system',
        memberCount: 0,
        groupCount: 0,
        noteCount: 0,
        frontHistoryCount: 0,
        currentFrontLabel: null,
      ),
    );
    addTearDown(repository.close);

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    await tester.tap(find.text('Members').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Import'));
    await tester.pumpAndSettle();

    expect(find.text('Import setup'), findsOneWidget);
    expect(find.text('Upload file'), findsOneWidget);
    expect(find.text('Attach avatars'), findsOneWidget);
    expect(find.text('Service'), findsOneWidget);
  });

  testWidgets('adds a local custom field from custom fields section', (
    tester,
  ) async {
    final repository = FakeHavenRepository(
      const HomeSnapshot(
        systemName: 'Local system',
        memberCount: 0,
        groupCount: 0,
        noteCount: 0,
        frontHistoryCount: 0,
        currentFrontLabel: null,
      ),
    );
    addTearDown(repository.close);

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    await openDrawerSection(tester, 'Custom Fields');
    await tester.pumpAndSettle();

    expect(find.text('No custom fields yet'), findsOneWidget);

    await tester.tap(find.text('Add field'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('custom-field-name-field')),
      'Favorite drink',
    );
    await tester.tap(find.byKey(const ValueKey('custom-field-type-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('custom-field-privacy-field')),
      'private',
    );
    await tester.tap(find.byKey(const ValueKey('save-custom-field-button')));
    await tester.pumpAndSettle();

    expect(find.text('Favorite drink'), findsOneWidget);
    expect(find.text('select - 0 values - private'), findsOneWidget);

    await tester.tap(find.byTooltip('Custom field actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('custom-field-name-field')),
      'Comfort drink',
    );
    await tester.tap(find.byKey(const ValueKey('save-custom-field-button')));
    await tester.pumpAndSettle();

    expect(find.text('Comfort drink'), findsOneWidget);
    expect(find.text('Favorite drink'), findsNothing);

    await tester.tap(find.text('Comfort drink'));
    await tester.pumpAndSettle();
    expect(find.text('System'), findsOneWidget);
    expect(find.text('not set'), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey('custom-field-system-value-row')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('custom-field-value-field')),
      'shared profile data',
    );
    await tester.tap(
      find.byKey(const ValueKey('save-custom-field-value-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('select - 1 values - private'), findsOneWidget);

    await repository.saveMember(const MemberDraft(displayName: 'Iris'));
    final field = repository._customFields.single;
    repository._customFields = [
      CustomFieldSummary(
        id: field.id,
        name: field.name,
        fieldType: field.fieldType,
        privacy: field.privacy,
        position: field.position,
        valueCount: 2,
      ),
    ];
    repository._customFieldValues = [
      ...repository._customFieldValues,
      CustomFieldValueSummary(
        id: 'fake-custom-field-value-1',
        fieldId: field.id,
        memberId: repository._members.single.id,
        value: 'coffee',
      ),
    ];
    repository._customFieldsController.add(repository._customFields);
    repository._customFieldValuesController.add(repository._customFieldValues);
    await tester.pumpAndSettle();

    expect(find.text('select - 2 values - private'), findsOneWidget);

    await tester.tap(find.text('Comfort drink'));
    await tester.pumpAndSettle();

    expect(find.text('System'), findsOneWidget);
    expect(find.text('shared profile data'), findsOneWidget);
    expect(find.text('Iris'), findsOneWidget);
    expect(find.text('coffee'), findsOneWidget);

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Custom field actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('No custom fields yet'), findsOneWidget);
    expect(repository._customFieldValues, isEmpty);
  });

  testWidgets('shows custom field values on member profiles', (tester) async {
    final repository = FakeHavenRepository(
      const HomeSnapshot(
        systemName: 'Local system',
        memberCount: 0,
        groupCount: 0,
        noteCount: 0,
        frontHistoryCount: 0,
        currentFrontLabel: null,
      ),
    );
    addTearDown(repository.close);

    await repository.saveMember(const MemberDraft(displayName: 'Iris'));
    repository._customFields = const [
      CustomFieldSummary(
        id: 'fake-custom-field-1',
        name: 'Favorite drink',
        fieldType: 'text',
        privacy: 'private',
        position: 0,
        valueCount: 1,
      ),
    ];
    repository._customFieldValues = [
      CustomFieldValueSummary(
        id: 'fake-custom-field-value-1',
        fieldId: 'fake-custom-field-1',
        memberId: repository._members.single.id,
        value: 'coffee',
      ),
    ];

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    await openDrawerSection(tester, 'Members');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Iris'));
    await tester.pumpAndSettle();

    expect(find.text('Data'), findsOneWidget);
    expect(find.text('Favorite drink'), findsOneWidget);
    expect(find.text('coffee'), findsOneWidget);
    expect(find.text('private'), findsOneWidget);

    await tester.ensureVisible(find.text('Favorite drink'));
    await tester.tap(find.text('Favorite drink'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('custom-field-value-field')),
      'tea',
    );
    await tester.tap(
      find.byKey(const ValueKey('save-custom-field-value-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('tea'), findsOneWidget);
    expect(find.text('coffee'), findsNothing);

    await tester.ensureVisible(find.text('Favorite drink'));
    await tester.tap(find.text('Favorite drink'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(find.text('not set'), findsWidgets);
    expect(find.text('tea'), findsNothing);
    expect(repository._customFieldValues, isEmpty);
  });

  testWidgets('adds a local note from the notes section', (tester) async {
    final repository = FakeHavenRepository(
      const HomeSnapshot(
        systemName: 'Local system',
        memberCount: 0,
        groupCount: 0,
        noteCount: 0,
        frontHistoryCount: 0,
        currentFrontLabel: null,
      ),
    );
    addTearDown(repository.close);
    await repository.saveMember(
      const MemberDraft(displayName: 'River', colorHex: '#AA66CC'),
    );

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    await openDrawerSection(tester, 'Notes');

    expect(find.text('No notes yet'), findsOneWidget);

    await tester.tap(find.text('Add note'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('note-title-field')),
      'Grounding',
    );
    await tester.tap(find.byKey(const ValueKey('note-member-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('River').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('note-body-field')),
      'Drink water and check meds.',
    );
    await tester.tap(find.byKey(const ValueKey('save-note-button')));
    await tester.pumpAndSettle();

    expect(find.text('Grounding'), findsOneWidget);
    expect(find.textContaining('River note'), findsOneWidget);
    expect(find.textContaining('Drink water and check meds.'), findsOneWidget);
    expect(repository._notes.single.memberId, 'fake-member-1');
    expect(repository._snapshot.noteCount, 1);

    await tester.enterText(find.byType(TextField).first, 'missing');
    await tester.pumpAndSettle();
    expect(find.text('No matching notes'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'water');
    await tester.pumpAndSettle();
    expect(find.text('Grounding'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'river');
    await tester.pumpAndSettle();
    expect(find.text('Grounding'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Grounding'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('note-title-field')),
      'Grounding edited',
    );
    await tester.enterText(
      find.byKey(const ValueKey('note-body-field')),
      'Drink water and check meds before bed.',
    );
    await tester.tap(find.byKey(const ValueKey('save-note-button')));
    await tester.pumpAndSettle();

    expect(find.text('Grounding edited'), findsOneWidget);
    expect(
      repository._notes.single.body,
      'Drink water and check meds before bed.',
    );
    expect(repository._notes.single.memberId, 'fake-member-1');

    await tester.tap(find.byTooltip('Delete note'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Grounding'), findsNothing);
    expect(find.text('No notes yet'), findsOneWidget);
    expect(repository._snapshot.noteCount, 0);
  });

  testWidgets('creates edits searches and deletes journal entries', (
    tester,
  ) async {
    final repository = FakeHavenRepository(
      const HomeSnapshot(
        systemName: 'Local system',
        memberCount: 0,
        groupCount: 0,
        noteCount: 0,
        frontHistoryCount: 0,
        currentFrontLabel: null,
      ),
    );
    addTearDown(repository.close);

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    await openDrawerSection(tester, 'Journals');
    expect(find.text('No journal entries yet'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('add-journal-entry-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('journal-title-field')),
      'Long day',
    );
    await tester.enterText(
      find.byKey(const ValueKey('journal-body-field')),
      'Lots happened after switching.',
    );
    await tester.tap(find.byKey(const ValueKey('save-journal-entry-button')));
    await tester.pumpAndSettle();

    expect(find.text('Long day'), findsOneWidget);
    expect(repository._journals.single.body, 'Lots happened after switching.');

    await tester.enterText(find.byType(TextField).first, 'switching');
    await tester.pumpAndSettle();
    expect(find.text('Long day'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'missing');
    await tester.pumpAndSettle();
    expect(find.text('No matching journals'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Long day'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('journal-title-field')),
      'Long day edited',
    );
    await tester.tap(find.byKey(const ValueKey('save-journal-entry-button')));
    await tester.pumpAndSettle();

    expect(find.text('Long day edited'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete journal entry'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(repository._journals, isEmpty);
    expect(find.text('No journal entries yet'), findsOneWidget);
  });

  testWidgets('adds a local message from the chat section', (tester) async {
    final repository = FakeHavenRepository(
      const HomeSnapshot(
        systemName: 'Local system',
        memberCount: 0,
        groupCount: 0,
        noteCount: 0,
        frontHistoryCount: 0,
        currentFrontLabel: null,
      ),
    );
    addTearDown(repository.close);
    await repository.saveMember(
      const MemberDraft(displayName: 'Sage', colorHex: '#66CCAA'),
    );

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    await openDrawerSection(tester, 'Chat');
    await tester.pumpAndSettle();

    expect(find.text('No messages yet'), findsOneWidget);

    await tester.tap(find.text('Add message'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('message-member-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sage').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('message-body-field')),
      'Check in after dinner.',
    );
    await tester.tap(find.byKey(const ValueKey('save-message-button')));
    await tester.pumpAndSettle();

    expect(find.text('Check in after dinner.'), findsOneWidget);
    expect(find.textContaining('Sage -'), findsOneWidget);
    expect(repository._messages.single.memberId, 'fake-member-1');

    await tester.enterText(find.byType(TextField).first, 'sage');
    await tester.pumpAndSettle();
    expect(find.text('Check in after dinner.'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Check in after dinner.'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('message-body-field')),
      'Check in after dinner. Bring water.',
    );
    await tester.tap(find.byKey(const ValueKey('save-message-button')));
    await tester.pumpAndSettle();

    expect(find.text('Check in after dinner. Bring water.'), findsOneWidget);
    expect(repository._messages.single.memberId, 'fake-member-1');

    await tester.tap(find.byTooltip('Delete message'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(repository._messages, isEmpty);
    expect(find.text('No messages yet'), findsOneWidget);
  });

  testWidgets('adds a local reminder from the reminders section', (
    tester,
  ) async {
    final repository = FakeHavenRepository(
      const HomeSnapshot(
        systemName: 'Local system',
        memberCount: 0,
        groupCount: 0,
        noteCount: 0,
        frontHistoryCount: 0,
        currentFrontLabel: null,
      ),
    );
    addTearDown(repository.close);

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    await openDrawerSection(tester, 'Reminders');
    await tester.pumpAndSettle();

    expect(find.text('No reminders yet'), findsOneWidget);

    await tester.tap(find.text('Add reminder'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('reminder-title-field')),
      'Medication',
    );
    await tester.tap(
      find.byKey(const ValueKey('reminder-schedule-kind-field')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weekly').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reminder-weekday-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Friday').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('reminder-time-field')),
      '08:30',
    );
    await tester.enterText(
      find.byKey(const ValueKey('reminder-body-field')),
      'With water',
    );
    await tester.tap(find.byKey(const ValueKey('save-reminder-button')));
    await tester.pumpAndSettle();

    expect(find.text('Medication'), findsOneWidget);
    expect(find.text('Weekly on Friday at 08:30'), findsOneWidget);
    expect(find.text('With water'), findsOneWidget);
    expect(find.text('on'), findsOneWidget);
    expect(repository._reminders.single.scheduleKind, 'weekly');
    expect(repository._reminders.single.scheduleTime, '08:30');
    expect(repository._reminders.single.scheduleDowMask, 1 << 4);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(repository._reminders.single.enabled, isFalse);
    expect(find.text('off'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(repository._reminders.single.enabled, isTrue);
    expect(find.text('on'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete reminder'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Medication'), findsNothing);
    expect(find.text('No reminders yet'), findsOneWidget);
  });

  testWidgets('creates and votes on a local poll', (tester) async {
    final repository = FakeHavenRepository(
      const HomeSnapshot(
        systemName: 'Local system',
        memberCount: 0,
        groupCount: 0,
        noteCount: 0,
        frontHistoryCount: 0,
        currentFrontLabel: null,
      ),
    );
    addTearDown(repository.close);

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    await openDrawerSection(tester, 'Polls');
    await tester.pumpAndSettle();

    expect(find.text('No polls yet'), findsOneWidget);

    await tester.tap(find.text('Create poll'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('poll-question-field')),
      'Dinner?',
    );
    await tester.enterText(
      find.byKey(const ValueKey('poll-option-field-0')),
      'Soup',
    );
    await tester.enterText(
      find.byKey(const ValueKey('poll-option-field-1')),
      'Rice',
    );
    await tester.tap(find.byKey(const ValueKey('save-poll-button')));
    await tester.pumpAndSettle();

    expect(find.text('Dinner?'), findsOneWidget);
    expect(find.text('Soup'), findsOneWidget);
    expect(find.text('Rice'), findsOneWidget);

    await tester.tap(find.text('Soup'));
    await tester.pumpAndSettle();

    expect(repository._polls.single.selectedCount, 1);
    expect(repository._polls.single.options.first.selected, isTrue);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(repository._polls.single.closed, isTrue);

    await tester.tap(find.byTooltip('Delete poll'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Dinner?'), findsNothing);
    expect(find.text('No polls yet'), findsOneWidget);
  });

  testWidgets('updates customization from the app options page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repository = FakeHavenRepository(
      const HomeSnapshot(
        systemName: 'Local system',
        memberCount: 0,
        groupCount: 0,
        noteCount: 0,
        frontHistoryCount: 0,
        currentFrontLabel: null,
      ),
    );
    addTearDown(repository.close);

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    await tester.ensureVisible(find.text('Customize'));
    await tester.tap(find.text('Customize'));
    await tester.pumpAndSettle();

    expect(find.text('Dark'), findsOneWidget);
    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();
    expect(find.text('Light'), findsOneWidget);

    await tester.tap(find.text('Accent color'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('current-accent-hex')), findsOneWidget);
    expect(find.text('#7B61FF'), findsWidgets);
    await tester.enterText(
      find.byKey(const ValueKey('custom-accent-hex-field')),
      '12abef',
    );
    await tester.tap(find.byKey(const ValueKey('save-custom-accent-button')));
    await tester.pumpAndSettle();
    expect((await repository.loadCustomization()).customAccentHex, '#12ABEF');

    await tester.tap(find.text('Accent color'));
    await tester.pumpAndSettle();
    expect(find.text('#12ABEF'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('copy-accent-hex-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('clear-custom-accent-button')));
    await tester.pumpAndSettle();
    expect((await repository.loadCustomization()).customAccentHex, isNull);

    await tester.tap(find.text('Compact dashboard'));
    await tester.pumpAndSettle();
    expect((await repository.loadCustomization()).compactDashboard, isTrue);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('language-setting-row')),
      220,
    );
    await tester.tap(find.byKey(const ValueKey('language-setting-row')));
    await tester.pumpAndSettle();
    expect(find.text('Choose your language'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('language-option-ar')).first);
    await tester.pumpAndSettle();
    expect((await repository.loadCustomization()).languageCode, 'ar');

    final pageScrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Analytics'),
      220,
      scrollable: pageScrollable,
    );
    final analyticsSwitch = find.byKey(
      const ValueKey('shortcut-visible-analytics'),
    );
    await tester.scrollUntilVisible(
      analyticsSwitch,
      220,
      scrollable: pageScrollable,
    );
    await tester.tap(analyticsSwitch);
    await tester.pumpAndSettle();
    expect(
      (await repository.loadCustomization()).dashboardShortcutIds,
      isNot(contains('analytics')),
    );
    await tester.scrollUntilVisible(
      find.text('Reset dashboard'),
      220,
      scrollable: pageScrollable,
      maxScrolls: 30,
    );
    await tester.tap(find.text('Reset dashboard'));
    await tester.pumpAndSettle();
    expect(
      (await repository.loadCustomization()).dashboardShortcutIds,
      defaultDashboardShortcutIds,
    );
  });

  testWidgets('keeps an intentionally empty dashboard shortcut list', (
    tester,
  ) async {
    final repository = FakeHavenRepository(
      const HomeSnapshot(
        systemName: 'Local system',
        memberCount: 0,
        groupCount: 0,
        noteCount: 0,
        frontHistoryCount: 0,
        currentFrontLabel: null,
      ),
    );
    addTearDown(repository.close);

    await repository.setDashboardShortcutIds(const []);
    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('No dashboard shortcuts'), findsOneWidget);
    expect(find.text('Open Customize to add shortcuts back.'), findsOneWidget);
    expect(
      (await repository.loadCustomization()).dashboardShortcutIds,
      isEmpty,
    );
  });

  testWidgets('updates accessibility preferences from app options', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repository = FakeHavenRepository(
      const HomeSnapshot(
        systemName: 'Local system',
        memberCount: 0,
        groupCount: 0,
        noteCount: 0,
        frontHistoryCount: 0,
        currentFrontLabel: null,
      ),
    );
    addTearDown(repository.close);

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    await tester.ensureVisible(find.text('Customize'));
    await tester.tap(find.text('Customize'));
    await tester.pumpAndSettle();

    final pageScrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Reduced motion'),
      220,
      scrollable: pageScrollable,
    );
    await tester.tap(find.text('Reduced motion'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('High contrast'),
      220,
      scrollable: pageScrollable,
    );
    await tester.tap(find.text('High contrast'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Larger app text'),
      220,
      scrollable: pageScrollable,
    );
    await tester.tap(find.text('Larger app text'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Compact lists'),
      220,
      scrollable: pageScrollable,
    );
    await tester.tap(find.text('Compact lists'));
    await tester.pumpAndSettle();

    final customization = await repository.loadCustomization();
    expect(customization.reducedMotion, isTrue);
    expect(customization.highContrast, isTrue);
    expect(customization.largeText, isTrue);
    expect(customization.compactLists, isTrue);
  });

  testWidgets('shows upload-first import setup and PluralKit live fields', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repository = FakeHavenRepository(
      const HomeSnapshot(
        systemName: 'Local system',
        memberCount: 0,
        groupCount: 0,
        noteCount: 0,
        frontHistoryCount: 0,
        currentFrontLabel: null,
      ),
    );
    addTearDown(repository.close);

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    await tester.ensureVisible(find.text('Import / Export'));
    await tester.tap(find.text('Import / Export'));
    await tester.pumpAndSettle();

    expect(find.text('Import setup'), findsOneWidget);
    expect(find.text('Upload file'), findsOneWidget);
    expect(find.text('Service'), findsOneWidget);
    expect(find.text('Simply Plural'), findsOneWidget);
    expect(find.text('Simply Plural plan'), findsOneWidget);
    expect(find.text('Preview before writing'), findsNothing);
    expect(find.text('Review matches'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('import-source-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PluralKit live').last);
    await tester.pumpAndSettle();

    expect(find.text('pk;token'), findsOneWidget);
    expect(find.text('PluralKit live plan'), findsOneWidget);
    expect(find.text('needs network'), findsOneWidget);
  });

  testWidgets('back from import page returns to dashboard', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repository = FakeHavenRepository(
      const HomeSnapshot(
        systemName: 'Local system',
        memberCount: 0,
        groupCount: 0,
        noteCount: 0,
        frontHistoryCount: 0,
        currentFrontLabel: null,
      ),
    );
    addTearDown(repository.close);

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    await tester.ensureVisible(find.text('Import / Export'));
    await tester.tap(find.text('Import / Export'));
    await tester.pumpAndSettle();
    expect(find.text('Import setup'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Currently fronting'), findsOneWidget);
    expect(find.text('Import setup'), findsNothing);
  });

  testWidgets('back from paste JSON sheet closes the sheet safely', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repository = FakeHavenRepository(
      const HomeSnapshot(
        systemName: 'Local system',
        memberCount: 0,
        groupCount: 0,
        noteCount: 0,
        frontHistoryCount: 0,
        currentFrontLabel: null,
      ),
    );
    addTearDown(repository.close);

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    await tester.ensureVisible(find.text('Import / Export'));
    await tester.tap(find.text('Import / Export'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('paste-import-json-button')));
    await tester.pumpAndSettle();

    expect(find.text('Paste JSON'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Paste JSON'), findsNothing);
    expect(find.text('Import setup'), findsOneWidget);
  });

  testWidgets('opens failed import job details and copies full error', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repository = FakeHavenRepository(
      const HomeSnapshot(
        systemName: 'Local system',
        memberCount: 0,
        groupCount: 0,
        noteCount: 0,
        frontHistoryCount: 0,
        currentFrontLabel: null,
      ),
    );
    addTearDown(repository.close);
    repository.seedBackgroundJob(
      BackgroundJobSummary(
        id: 'failed-import',
        type: 'import_archive',
        status: 'failed',
        source: 'simplyPlural',
        fileName: 'simplyplural.json',
        error: 'SqliteException(787): FOREIGN KEY constraint failed\nline 2',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026, 1, 1, 1),
      ),
    );

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    await tester.ensureVisible(find.text('Import / Export'));
    await tester.tap(find.text('Import / Export'));
    await tester.pumpAndSettle();
    final pageScrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('simplyplural.json'),
      240,
      scrollable: pageScrollable,
      maxScrolls: 30,
    );
    await tester.ensureVisible(find.text('simplyplural.json'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('simplyplural.json'));
    await tester.pumpAndSettle();

    expect(find.text('Error'), findsOneWidget);
    expect(find.textContaining('FOREIGN KEY constraint failed'), findsWidgets);

    await tester.tap(find.text('Copy full'));
    await tester.pumpAndSettle();

    expect(find.text('Full error copied'), findsOneWidget);
  });

  testWidgets('pasted JSON creates an import preview', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repository = FakeHavenRepository(
      const HomeSnapshot(
        systemName: 'Local system',
        memberCount: 0,
        groupCount: 0,
        noteCount: 0,
        frontHistoryCount: 0,
        currentFrontLabel: null,
      ),
    );
    addTearDown(repository.close);

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    await tester.ensureVisible(find.text('Import / Export'));
    await tester.tap(find.text('Import / Export'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('paste-import-json-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('paste-import-json-field')),
      jsonEncode({
        'members': [
          {'_id': 'sp-member-1', 'name': 'Iris'},
        ],
        'securityLogs': [
          {'_id': 'log-1', 'action': 'login'},
        ],
      }),
    );
    await tester.tap(find.text('Preview pasted JSON'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Preview ready'), findsOneWidget);
    expect(find.textContaining('1 members'), findsOneWidget);
    expect(find.textContaining('preserved source collection'), findsWidgets);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('restore-rehearsal-button')),
      240,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('restore-rehearsal-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('restore-rehearsal-button')));
    await tester.pumpAndSettle();

    expect(find.text('Restore rehearsal passed'), findsOneWidget);
    expect(
      find.textContaining('Nothing was written to your app data'),
      findsOneWidget,
    );
    expect(find.text('members: 1'), findsWidgets);
    await tester.scrollUntilVisible(find.text('Import archive'), 240);
    expect(find.text('Import archive'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Refresh preview'), -240);
    await tester.tap(find.text('Refresh preview'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Preview ready'), findsOneWidget);
  });

  testWidgets('pasted encrypted archive decrypts before preview', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repository = FakeHavenRepository(
      const HomeSnapshot(
        systemName: 'Local system',
        memberCount: 0,
        groupCount: 0,
        noteCount: 0,
        frontHistoryCount: 0,
        currentFrontLabel: null,
      ),
    );
    addTearDown(repository.close);

    final encrypted = await encryptArchiveJson(
      archiveJson: jsonEncode({
        'format': 'pluris_haven.local_archive',
        'version': 1,
        'members': [
          {'id': 'member-1', 'display_name': 'Iris'},
        ],
      }),
      passphrase: 'shared passphrase',
      iterations: 1200,
    );

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    await tester.ensureVisible(find.text('Import / Export'));
    await tester.tap(find.text('Import / Export'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('paste-import-json-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('paste-import-json-field')),
      encrypted,
    );
    await tester.tap(find.text('Preview pasted JSON'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('import-passphrase-field')),
      findsOneWidget,
    );
    expect(find.textContaining('Encrypted archive loaded'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('import-passphrase-field')),
      'shared passphrase',
    );
    await tester.tap(find.text('Refresh preview'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Preview ready'), findsOneWidget);
    expect(find.textContaining('1 members'), findsOneWidget);
  });

  testWidgets('builds a local archive from import export', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repository = FakeHavenRepository(
      const HomeSnapshot(
        systemName: 'Local system',
        memberCount: 0,
        groupCount: 0,
        noteCount: 0,
        frontHistoryCount: 0,
        currentFrontLabel: null,
      ),
    );
    addTearDown(repository.close);
    await repository.saveMember(const MemberDraft(displayName: 'Iris'));
    await repository.saveGroup(const GroupDraft(name: 'Caretakers'));
    await repository.saveNote(
      const NoteDraft(title: 'Grounding', body: 'Water'),
    );

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    await tester.ensureVisible(find.text('Import / Export'));
    await tester.tap(find.text('Import / Export'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Export local archive'), 240);
    await tester.ensureVisible(find.text('Export local archive'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Export local archive'));
    await tester.pumpAndSettle();

    expect(find.text('Local archive'), findsOneWidget);
    expect(find.text('Save JSON file'), findsOneWidget);
    expect(find.text('Copy JSON'), findsOneWidget);
    expect(find.textContaining('pluris_haven.local_archive'), findsOneWidget);
    expect(find.textContaining('Caretakers'), findsOneWidget);

    Navigator.of(tester.element(find.text('Local archive'))).pop();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Encrypted export'), 240);
    await tester.tap(find.text('Encrypted export'));
    await tester.pumpAndSettle();

    expect(find.text('Encrypted export'), findsWidgets);
    expect(
      find.byKey(const ValueKey('encrypted-export-passphrase-field')),
      findsOneWidget,
    );
    expect(find.text('Save encrypted file'), findsOneWidget);
  });
}

Future<void> openDrawerSection(WidgetTester tester, String label) async {
  await tester.tap(find.byTooltip('Open navigation menu'));
  await tester.pumpAndSettle();
  final labelFinder = find.descendant(
    of: find.byType(Drawer),
    matching: find.text(label),
  );
  if (!tester.any(labelFinder)) {
    await tester.scrollUntilVisible(
      labelFinder,
      120,
      scrollable: find.byType(Scrollable).last,
    );
  }
  await tester.ensureVisible(labelFinder.last);
  await tester.pumpAndSettle();
  await tester.tap(labelFinder.last);
  await tester.pumpAndSettle();
}

class FakeHavenRepository implements HavenRepository {
  FakeHavenRepository(this._snapshot) {
    _controller = StreamController<HomeSnapshot>.broadcast(
      sync: true,
      onListen: () => _controller.add(_snapshot),
    );
    _customizationController = StreamController<AppCustomization>.broadcast(
      sync: true,
    );
    _membersController = StreamController<List<MemberSummary>>.broadcast(
      sync: true,
      onListen: () => _membersController.add(_members),
    );
    _currentFrontMembersController =
        StreamController<List<MemberSummary>>.broadcast(
          sync: true,
          onListen: () =>
              _currentFrontMembersController.add(_currentFrontMembers()),
        );
    _groupsController = StreamController<List<GroupSummary>>.broadcast(
      sync: true,
      onListen: () => _emitGroups(),
    );
    _notesController = StreamController<List<NoteSummary>>.broadcast(
      sync: true,
      onListen: () => _notesController.add(_notes),
    );
    _messagesController = StreamController<List<MessageSummary>>.broadcast(
      sync: true,
      onListen: () => _messagesController.add(_messages),
    );
    _remindersController = StreamController<List<ReminderSummary>>.broadcast(
      sync: true,
      onListen: () => _remindersController.add(_reminders),
    );
    _customFieldsController =
        StreamController<List<CustomFieldSummary>>.broadcast(
          sync: true,
          onListen: () => _customFieldsController.add(_customFields),
        );
    _customFieldValuesController =
        StreamController<List<CustomFieldValueSummary>>.broadcast(
          sync: true,
          onListen: () => _customFieldValuesController.add(_customFieldValues),
        );
    _pollsController = StreamController<List<PollSummary>>.broadcast(
      sync: true,
      onListen: () => _pollsController.add(_polls),
    );
    _notificationEventsController =
        StreamController<List<NotificationEventSummary>>.broadcast(
          sync: true,
          onListen: () =>
              _notificationEventsController.add(_notificationEvents),
        );
    _frontHistoryController =
        StreamController<List<FrontHistoryEntry>>.broadcast(
          sync: true,
          onListen: () => _frontHistoryController.add(_frontHistory),
        );
    _backgroundJobsController =
        StreamController<List<BackgroundJobSummary>>.broadcast(
          sync: true,
          onListen: () => _backgroundJobsController.add(_backgroundJobs),
        );
    _namedFrontsController = StreamController<List<NamedFront>>.broadcast(
      sync: true,
      onListen: () => _namedFrontsController.add(_namedFronts),
    );
    _tagsController = StreamController<List<Tag>>.broadcast(
      sync: true,
      onListen: () => _tagsController.add(_tags),
    );
    _memberTagsController =
        StreamController<Map<String, List<String>>>.broadcast(
          sync: true,
          onListen: () => _memberTagsController.add(_memberTagIds),
        );
    _journalsController = StreamController<List<JournalEntry>>.broadcast(
      sync: true,
      onListen: () => _journalsController.add(_journals),
    );
  }

  HomeSnapshot _snapshot;
  AppCustomization _customization = AppCustomization.defaults;
  List<MemberSummary> _members = const [];
  List<GroupSummary> _groups = const [];
  List<NoteSummary> _notes = const [];
  List<MessageSummary> _messages = const [];
  List<ReminderSummary> _reminders = const [];
  List<CustomFieldSummary> _customFields = const [];
  List<CustomFieldValueSummary> _customFieldValues = const [];
  List<PollSummary> _polls = const [];
  List<NotificationEventSummary> _notificationEvents = const [];
  List<FrontHistoryEntry> _frontHistory = const [];
  List<BackgroundJobSummary> _backgroundJobs = const [];
  List<NamedFront> _namedFronts = const [];
  List<Tag> _tags = const [];
  List<JournalEntry> _journals = const [];
  List<String> _currentFrontMemberIds = const [];
  final Map<String, List<String>> _namedFrontMembers = {};
  Map<String, List<String>> _memberTagIds = const {};
  late final StreamController<HomeSnapshot> _controller;
  late final StreamController<AppCustomization> _customizationController;
  late final StreamController<List<MemberSummary>> _membersController;
  late final StreamController<List<MemberSummary>>
  _currentFrontMembersController;
  late final StreamController<List<GroupSummary>> _groupsController;
  late final StreamController<List<NoteSummary>> _notesController;
  late final StreamController<List<MessageSummary>> _messagesController;
  late final StreamController<List<ReminderSummary>> _remindersController;
  late final StreamController<List<CustomFieldSummary>> _customFieldsController;
  late final StreamController<List<CustomFieldValueSummary>>
  _customFieldValuesController;
  late final StreamController<List<PollSummary>> _pollsController;
  late final StreamController<List<NotificationEventSummary>>
  _notificationEventsController;
  late final StreamController<List<FrontHistoryEntry>> _frontHistoryController;
  late final StreamController<List<BackgroundJobSummary>>
  _backgroundJobsController;
  late final StreamController<List<NamedFront>> _namedFrontsController;
  late final StreamController<List<Tag>> _tagsController;
  late final StreamController<Map<String, List<String>>> _memberTagsController;
  late final StreamController<List<JournalEntry>> _journalsController;

  void seedBackgroundJob(BackgroundJobSummary job) {
    _backgroundJobs = [job, ..._backgroundJobs];
    _backgroundJobsController.add(_backgroundJobs);
  }

  @override
  Stream<HomeSnapshot> watchHomeSnapshot() => _controller.stream;

  @override
  Stream<List<MemberSummary>> watchMembers({
    bool includeArchived = false,
    bool includeCustomFronts = false,
  }) async* {
    List<MemberSummary> filtered(List<MemberSummary> members) {
      return [
        for (final member in members)
          if ((includeArchived || !member.archived) &&
              (includeCustomFronts || !member.isCustomFront))
            member,
      ];
    }

    yield List.unmodifiable(filtered(_members));
    await for (final members in _membersController.stream) {
      yield List.unmodifiable(filtered(members));
    }
  }

  @override
  Stream<List<MemberSummary>> watchCurrentFrontMembers() {
    return _currentFrontMembersController.stream.map(List.unmodifiable);
  }

  @override
  Stream<List<GroupSummary>> watchGroups() {
    return _groupsController.stream.map(List.unmodifiable);
  }

  @override
  Stream<List<NoteSummary>> watchNotes() {
    return _notesController.stream.map(List.unmodifiable);
  }

  @override
  Stream<List<MessageSummary>> watchMessages() {
    return _messagesController.stream.map(List.unmodifiable);
  }

  @override
  Stream<List<ReminderSummary>> watchReminders() {
    return _remindersController.stream.map(List.unmodifiable);
  }

  @override
  Stream<List<CustomFieldSummary>> watchCustomFields() {
    return _customFieldsController.stream.map(List.unmodifiable);
  }

  @override
  Stream<List<CustomFieldValueSummary>> watchCustomFieldValues() {
    return _customFieldValuesController.stream.map(List.unmodifiable);
  }

  @override
  Stream<List<PollSummary>> watchPolls() {
    return _pollsController.stream.map(List.unmodifiable);
  }

  @override
  Stream<List<NotificationEventSummary>> watchNotificationEvents() {
    return _notificationEventsController.stream.map(List.unmodifiable);
  }

  @override
  Stream<List<FrontHistoryEntry>> watchFrontHistory() {
    return _frontHistoryController.stream.map(List.unmodifiable);
  }

  @override
  Stream<List<BackgroundJobSummary>> watchBackgroundJobs() {
    return _backgroundJobsController.stream.map(List.unmodifiable);
  }

  @override
  Stream<AppCustomization> watchCustomization() async* {
    yield _customization;
    yield* _customizationController.stream;
  }

  @override
  Future<AppCustomization> loadCustomization() async => _customization;

  @override
  Future<void> setThemeMode(HavenThemeMode mode) async {
    _customization = _customization.copyWith(themeMode: mode);
    _customizationController.add(_customization);
  }

  @override
  Future<void> setAccentColor(HavenAccentColor color) async {
    _customization = _customization.copyWith(
      accentColor: color,
      customAccentHex: null,
    );
    _customizationController.add(_customization);
  }

  @override
  Future<void> setCustomAccentColor(String? colorHex) async {
    _customization = _customization.copyWith(customAccentHex: colorHex);
    _customizationController.add(_customization);
  }

  @override
  Future<void> setCompactDashboard(bool compact) async {
    _customization = _customization.copyWith(compactDashboard: compact);
    _customizationController.add(_customization);
  }

  @override
  Future<void> setShowDashboardSubtitles(bool show) async {
    _customization = _customization.copyWith(showDashboardSubtitles: show);
    _customizationController.add(_customization);
  }

  @override
  Future<void> setReducedMotion(bool reduced) async {
    _customization = _customization.copyWith(reducedMotion: reduced);
    _customizationController.add(_customization);
  }

  @override
  Future<void> setHighContrast(bool highContrast) async {
    _customization = _customization.copyWith(highContrast: highContrast);
    _customizationController.add(_customization);
  }

  @override
  Future<void> setLargeText(bool largeText) async {
    _customization = _customization.copyWith(largeText: largeText);
    _customizationController.add(_customization);
  }

  @override
  Future<void> setCompactLists(bool compact) async {
    _customization = _customization.copyWith(compactLists: compact);
    _customizationController.add(_customization);
  }

  @override
  Future<void> setDashboardShortcutIds(List<String> shortcutIds) async {
    _customization = _customization.copyWith(dashboardShortcutIds: shortcutIds);
    _customizationController.add(_customization);
  }

  @override
  Future<void> setLanguageCode(String languageCode) async {
    _customization = _customization.copyWith(languageCode: languageCode);
    _customizationController.add(_customization);
  }

  @override
  Future<void> setDashboardShortcutVisible(String shortcutId, bool visible) {
    final ids = _customization.dashboardShortcutIds.toList();
    final existingIndex = ids.indexOf(shortcutId);
    if (visible && existingIndex == -1) {
      ids.add(shortcutId);
    } else if (!visible && existingIndex != -1) {
      ids.removeAt(existingIndex);
    }
    return setDashboardShortcutIds(ids);
  }

  @override
  Future<void> moveDashboardShortcut(String shortcutId, int delta) {
    final ids = _customization.dashboardShortcutIds.toList();
    final index = ids.indexOf(shortcutId);
    if (index == -1 || delta == 0) {
      return Future.value();
    }
    final newIndex = (index + delta).clamp(0, ids.length - 1);
    if (newIndex == index) {
      return Future.value();
    }
    final id = ids.removeAt(index);
    ids.insert(newIndex, id);
    return setDashboardShortcutIds(ids);
  }

  @override
  Future<void> resetDashboardShortcuts() {
    return setDashboardShortcutIds(defaultDashboardShortcutIds);
  }

  @override
  Future<void> saveMember(MemberDraft draft) async {
    final displayName = draft.displayName.trim();
    if (displayName.isEmpty) {
      return;
    }

    final groupIds = _normalizedFakeGroupIds(draft);
    final folderId =
        _nullIfBlank(draft.folderId) ?? _firstFakeGroupId(groupIds);
    _members = [
      ..._members,
      MemberSummary(
        id: 'fake-member-${_members.length + 1}',
        displayName: displayName,
        pronouns: _nullIfBlank(draft.pronouns),
        colorHex: _nullIfBlank(draft.colorHex),
        birthday: _nullIfBlank(draft.birthday),
        emoji: _nullIfBlank(draft.emoji),
        privacy: _nullIfBlank(draft.privacy),
        description: _nullIfBlank(draft.description),
        avatarUrl: _nullIfBlank(draft.avatarUrl),
        pluralKitId: _nullIfBlank(draft.pluralKitId),
        folderId: folderId,
        groupIds: groupIds.toList(growable: false),
      ),
    ];
    _emitMembers();
    _emitGroups();
    _emitSnapshot(memberCount: _visibleMembers.length);
  }

  @override
  Future<void> archiveMember(String memberId) async {
    _members = [
      for (final member in _members)
        if (member.id == memberId)
          MemberSummary(
            id: member.id,
            displayName: member.displayName,
            pronouns: member.pronouns,
            colorHex: member.colorHex,
            birthday: member.birthday,
            emoji: member.emoji,
            privacy: member.privacy,
            description: member.description,
            avatarUrl: member.avatarUrl,
            pluralKitId: member.pluralKitId,
            folderId: member.folderId,
            groupIds: member.groupIds,
            archived: true,
          )
        else
          member,
    ];
    _emitMembers();
    _emitGroups();
    _emitSnapshot(memberCount: _visibleMembers.length);
  }

  @override
  Future<void> updateMember(String memberId, MemberDraft draft) async {
    final displayName = draft.displayName.trim();
    if (displayName.isEmpty) {
      return;
    }

    final preserveGroups = draft.groupIds == null && draft.folderId == null;
    final groupIds = preserveGroups
        ? <String>{}
        : _normalizedFakeGroupIds(draft);
    final folderId = preserveGroups
        ? null
        : _nullIfBlank(draft.folderId) ?? _firstFakeGroupId(groupIds);
    _members = [
      for (final member in _members)
        if (member.id == memberId)
          MemberSummary(
            id: member.id,
            displayName: displayName,
            pronouns: _nullIfBlank(draft.pronouns),
            colorHex: _nullIfBlank(draft.colorHex),
            birthday: _nullIfBlank(draft.birthday),
            emoji: _nullIfBlank(draft.emoji),
            privacy: _nullIfBlank(draft.privacy),
            description: _nullIfBlank(draft.description),
            avatarUrl: _nullIfBlank(draft.avatarUrl),
            pluralKitId: _nullIfBlank(draft.pluralKitId),
            folderId: preserveGroups ? member.folderId : folderId,
            groupIds: preserveGroups
                ? member.groupIds
                : groupIds.toList(growable: false),
            archived: member.archived,
          )
        else
          member,
    ];
    _emitMembers();
    _emitGroups();
    _emitSnapshot(memberCount: _visibleMembers.length);
  }

  @override
  Future<void> restoreMember(String memberId) async {
    _members = [
      for (final member in _members)
        if (member.id == memberId)
          MemberSummary(
            id: member.id,
            displayName: member.displayName,
            pronouns: member.pronouns,
            colorHex: member.colorHex,
            birthday: member.birthday,
            emoji: member.emoji,
            privacy: member.privacy,
            description: member.description,
            avatarUrl: member.avatarUrl,
            pluralKitId: member.pluralKitId,
            folderId: member.folderId,
            groupIds: member.groupIds,
            archived: false,
          )
        else
          member,
    ];
    _emitMembers();
    _emitGroups();
    _emitSnapshot(memberCount: _visibleMembers.length);
  }

  @override
  Future<void> deleteMember(String memberId) async {
    _members = [
      for (final member in _members)
        if (member.id != memberId) member,
    ];
    _emitMembers();
    _emitGroups();
    _emitSnapshot(memberCount: _visibleMembers.length);
  }

  @override
  Future<void> setFrontMembers(List<String> memberIds) async {
    final ids = memberIds.toSet();
    final selected = _visibleMembers
        .where((member) => ids.contains(member.id))
        .toList(growable: false);

    if (selected.isEmpty) {
      return clearCurrentFront();
    }

    _emitSnapshot(
      frontHistoryCount: _snapshot.frontHistoryCount + 1,
      currentFrontLabel: selected
          .map((member) => member.displayName)
          .join(', '),
    );
    _currentFrontMemberIds = [for (final member in selected) member.id];
    _emitCurrentFrontMembers();
    _addFrontHistoryEntry(_snapshot.currentFrontLabel!);
  }

  @override
  Future<void> updateFrontStatusNote(String frontId, String? statusNote) async {
    final normalized = _nullIfBlank(statusNote);
    _frontHistory = [
      for (final entry in _frontHistory)
        if (entry.id == frontId)
          FrontHistoryEntry(
            id: entry.id,
            label: entry.label,
            statusNote: normalized,
            startedAt: entry.startedAt,
            endedAt: entry.endedAt,
          )
        else
          entry,
    ];
    _frontHistoryController.add(_frontHistory);
  }

  @override
  Future<void> deleteFrontSession(String frontId) async {
    final deletedActive = _frontHistory.any(
      (entry) => entry.id == frontId && entry.isActive,
    );
    _frontHistory = [
      for (final entry in _frontHistory)
        if (entry.id != frontId) entry,
    ];
    _frontHistoryController.add(_frontHistory);
    if (deletedActive) {
      _currentFrontMemberIds = const [];
      _emitCurrentFrontMembers();
    }
    _emitSnapshot(
      frontHistoryCount: _frontHistory.length,
      clearCurrentFront: deletedActive,
    );
  }

  @override
  Future<void> saveGroup(GroupDraft draft) async {
    final name = draft.name.trim();
    if (name.isEmpty) {
      return;
    }

    _groups = [
      ..._groups,
      GroupSummary(
        id: 'fake-group-${_groups.length + 1}',
        name: name,
        parentGroupId: _nullIfBlank(draft.parentGroupId),
        colorHex: _nullIfBlank(draft.colorHex),
        description: _nullIfBlank(draft.description),
        emoji: _nullIfBlank(draft.emoji),
      ),
    ];
    _emitGroups();
    _emitSnapshot(groupCount: _groups.length);
  }

  @override
  Future<void> updateGroup(String groupId, GroupDraft draft) async {
    final name = draft.name.trim();
    if (name.isEmpty) {
      return;
    }
    _groups = [
      for (final group in _groups)
        if (group.id == groupId)
          GroupSummary(
            id: group.id,
            name: name,
            parentGroupId: _nullIfBlank(draft.parentGroupId),
            colorHex: _nullIfBlank(draft.colorHex),
            description: _nullIfBlank(draft.description),
            emoji: _nullIfBlank(draft.emoji),
          )
        else
          group,
    ];
    _emitGroups();
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    _groups = [
      for (final group in _groups)
        if (group.id != groupId)
          GroupSummary(
            id: group.id,
            name: group.name,
            parentGroupId: group.parentGroupId == groupId
                ? null
                : group.parentGroupId,
            colorHex: group.colorHex,
            description: group.description,
            emoji: group.emoji,
          ),
    ];
    _emitGroups();
    _emitSnapshot(groupCount: _groups.length);
  }

  @override
  Future<void> saveCustomField(CustomFieldDraft draft) async {
    final name = draft.name.trim();
    if (name.isEmpty) {
      return;
    }

    _customFields = [
      ..._customFields,
      CustomFieldSummary(
        id: 'fake-custom-field-${_customFields.length + 1}',
        name: name,
        fieldType: draft.fieldType,
        privacy: _nullIfBlank(draft.privacy),
        position: _customFields.length,
        valueCount: 0,
      ),
    ];
    _customFieldsController.add(_customFields);
  }

  @override
  Future<void> updateCustomField(String fieldId, CustomFieldDraft draft) async {
    final name = draft.name.trim();
    if (name.isEmpty) {
      return;
    }

    _customFields = [
      for (final field in _customFields)
        if (field.id == fieldId)
          CustomFieldSummary(
            id: field.id,
            name: name,
            fieldType: draft.fieldType,
            privacy: _nullIfBlank(draft.privacy),
            position: field.position,
            valueCount: field.valueCount,
          )
        else
          field,
    ];
    _customFieldsController.add(_customFields);
  }

  @override
  Future<void> deleteCustomField(String fieldId) async {
    _customFields = [
      for (final field in _customFields)
        if (field.id != fieldId) field,
    ];
    _customFieldValues = [
      for (final value in _customFieldValues)
        if (value.fieldId != fieldId) value,
    ];
    _customFieldsController.add(_customFields);
    _customFieldValuesController.add(_customFieldValues);
  }

  @override
  Future<void> setCustomFieldValue({
    required String fieldId,
    required String? memberId,
    required String value,
  }) async {
    final trimmed = value.trim();
    final ownerId = _nullIfBlank(memberId);
    final existingIndex = _customFieldValues.indexWhere(
      (fieldValue) =>
          fieldValue.fieldId == fieldId && fieldValue.memberId == ownerId,
    );

    if (trimmed.isEmpty) {
      if (existingIndex != -1) {
        _customFieldValues = [
          for (var index = 0; index < _customFieldValues.length; index++)
            if (index != existingIndex) _customFieldValues[index],
        ];
      }
    } else if (existingIndex == -1) {
      _customFieldValues = [
        ..._customFieldValues,
        CustomFieldValueSummary(
          id: 'fake-custom-field-value-${_customFieldValues.length + 1}',
          fieldId: fieldId,
          memberId: ownerId,
          value: trimmed,
        ),
      ];
    } else {
      _customFieldValues = [
        for (var index = 0; index < _customFieldValues.length; index++)
          if (index == existingIndex)
            CustomFieldValueSummary(
              id: _customFieldValues[index].id,
              fieldId: fieldId,
              memberId: ownerId,
              value: trimmed,
            )
          else
            _customFieldValues[index],
      ];
    }

    _customFields = [
      for (final field in _customFields)
        CustomFieldSummary(
          id: field.id,
          name: field.name,
          fieldType: field.fieldType,
          privacy: field.privacy,
          position: field.position,
          valueCount: _customFieldValues
              .where((value) => value.fieldId == field.id)
              .length,
        ),
    ];
    _customFieldsController.add(_customFields);
    _customFieldValuesController.add(_customFieldValues);
  }

  @override
  Future<void> saveNote(NoteDraft draft) async {
    final title = draft.title.trim();
    final body = draft.body.trim();
    if (title.isEmpty && body.isEmpty) {
      return;
    }

    _notes = [
      NoteSummary(
        id: 'fake-note-${_notes.length + 1}',
        title: title.isEmpty ? 'Untitled note' : title,
        body: body,
        memberId: _nullIfBlank(draft.memberId),
        updatedAt: DateTime(2026),
      ),
      ..._notes,
    ];
    _notesController.add(_notes);
    _emitSnapshot(noteCount: _notes.length);
  }

  @override
  Future<void> updateNote(String noteId, NoteDraft draft) async {
    final title = draft.title.trim();
    final body = draft.body.trim();
    if (title.isEmpty && body.isEmpty) {
      return;
    }

    _notes = [
      for (final note in _notes)
        if (note.id == noteId)
          NoteSummary(
            id: note.id,
            title: title.isEmpty ? 'Untitled note' : title,
            body: body,
            memberId: _nullIfBlank(draft.memberId),
            updatedAt: DateTime(2026, 1, 2),
          )
        else
          note,
    ];
    _notesController.add(_notes);
  }

  @override
  Future<void> deleteNote(String noteId) async {
    _notes = [
      for (final note in _notes)
        if (note.id != noteId) note,
    ];
    _notesController.add(_notes);
    _emitSnapshot(noteCount: _notes.length);
  }

  @override
  Future<void> saveMessage(MessageDraft draft) async {
    final body = draft.body.trim();
    if (body.isEmpty) {
      return;
    }

    _messages = [
      MessageSummary(
        id: 'fake-message-${_messages.length + 1}',
        body: body,
        memberId: _nullIfBlank(draft.memberId),
        createdAt: DateTime(2026),
      ),
      ..._messages,
    ];
    _messagesController.add(_messages);
  }

  @override
  Future<void> updateMessage(String messageId, MessageDraft draft) async {
    final body = draft.body.trim();
    if (body.isEmpty) {
      return;
    }

    _messages = [
      for (final message in _messages)
        if (message.id == messageId)
          MessageSummary(
            id: message.id,
            body: body,
            memberId: _nullIfBlank(draft.memberId),
            createdAt: message.createdAt,
            archived: message.archived,
          )
        else
          message,
    ];
    _messagesController.add(_messages);
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    _messages = [
      for (final message in _messages)
        if (message.id != messageId) message,
    ];
    _messagesController.add(_messages);
  }

  @override
  Future<String?> saveReminder(ReminderDraft draft) async {
    final title = draft.title.trim();
    final schedule = draft.scheduleText.trim();
    if (title.isEmpty || schedule.isEmpty) {
      return null;
    }

    final id = 'fake-reminder-${_reminders.length + 1}';
    _reminders = [
      ReminderSummary(
        id: id,
        title: title,
        body: _nullIfBlank(draft.body),
        scheduleText: schedule,
        scheduleKind: draft.scheduleKind,
        scheduleTime: draft.scheduleTime,
        scheduleDowMask: draft.scheduleDowMask,
        scheduleDom: draft.scheduleDom,
        enabled: draft.enabled,
        updatedAt: DateTime(2026),
      ),
      ..._reminders,
    ];
    _remindersController.add(_reminders);
    return id;
  }

  @override
  Future<void> setReminderEnabled(String reminderId, bool enabled) async {
    _reminders = [
      for (final reminder in _reminders)
        if (reminder.id == reminderId)
          ReminderSummary(
            id: reminder.id,
            title: reminder.title,
            body: reminder.body,
            scheduleText: reminder.scheduleText,
            scheduleKind: reminder.scheduleKind,
            scheduleTime: reminder.scheduleTime,
            scheduleDowMask: reminder.scheduleDowMask,
            scheduleDom: reminder.scheduleDom,
            enabled: enabled,
            updatedAt: DateTime(2026),
          )
        else
          reminder,
    ];
    _remindersController.add(_reminders);
  }

  @override
  Future<void> deleteReminder(String reminderId) async {
    _reminders = [
      for (final reminder in _reminders)
        if (reminder.id != reminderId) reminder,
    ];
    _remindersController.add(_reminders);
  }

  @override
  Future<void> savePoll(PollDraft draft) async {
    final question = draft.question.trim();
    final options = draft.options
        .map((option) => option.trim())
        .where((option) => option.isNotEmpty)
        .toList();
    if (question.isEmpty || options.length < 2) {
      return;
    }

    final pollId = 'fake-poll-${_polls.length + 1}';
    _polls = [
      PollSummary(
        id: pollId,
        question: question,
        description: _nullIfBlank(draft.description),
        kind: draft.kind,
        closed: false,
        updatedAt: DateTime(2026),
        options: [
          for (var index = 0; index < options.length; index++)
            PollOptionSummary(
              id: '$pollId-option-$index',
              body: options[index],
              position: index,
              selected: false,
            ),
        ],
      ),
      ..._polls,
    ];
    _pollsController.add(_polls);
  }

  @override
  Future<void> togglePollOption(String pollId, String optionId) async {
    _polls = [
      for (final poll in _polls)
        if (poll.id == pollId && !poll.closed)
          PollSummary(
            id: poll.id,
            question: poll.question,
            description: poll.description,
            kind: poll.kind,
            closed: poll.closed,
            updatedAt: DateTime(2026),
            options: [
              for (final option in poll.options)
                PollOptionSummary(
                  id: option.id,
                  body: option.body,
                  position: option.position,
                  selected: poll.kind == PollKind.singleChoice
                      ? option.id == optionId && !option.selected
                      : option.id == optionId
                      ? !option.selected
                      : option.selected,
                ),
            ],
          )
        else
          poll,
    ];
    _pollsController.add(_polls);
  }

  @override
  Future<void> closePoll(String pollId) async {
    _polls = [
      for (final poll in _polls)
        if (poll.id == pollId)
          PollSummary(
            id: poll.id,
            question: poll.question,
            description: poll.description,
            kind: poll.kind,
            closed: true,
            options: poll.options,
            updatedAt: DateTime(2026),
          )
        else
          poll,
    ];
    _pollsController.add(_polls);
  }

  @override
  Future<void> deletePoll(String pollId) async {
    _polls = [
      for (final poll in _polls)
        if (poll.id != pollId) poll,
    ];
    _pollsController.add(_polls);
  }

  @override
  Future<void> recordNotificationEvent(NotificationEventDraft draft) async {
    _notificationEvents = [
      NotificationEventSummary(
        id: 'fake-notification-${_notificationEvents.length + 1}',
        kind: draft.kind,
        title: draft.title,
        body: draft.body,
        createdAt: DateTime(2026),
      ),
      ..._notificationEvents,
    ];
    _notificationEventsController.add(_notificationEvents);
  }

  @override
  Future<void> setCustomFront(String label) async {
    _currentFrontMemberIds = const [];
    _emitCurrentFrontMembers();
    _emitSnapshot(
      frontHistoryCount: _snapshot.frontHistoryCount + 1,
      currentFrontLabel: label,
    );
    _addFrontHistoryEntry(label);
  }

  @override
  Future<void> clearCurrentFront() async {
    _endOpenFrontHistory();
    _currentFrontMemberIds = const [];
    _emitCurrentFrontMembers();
    _emitSnapshot(clearCurrentFront: true);
  }

  @override
  Future<String> buildLocalArchiveJson() async {
    return const JsonEncoder.withIndent('  ').convert({
      'format': 'pluris_haven.local_archive',
      'version': 1,
      'system': {'id': 'local-system', 'name': _snapshot.systemName},
      'members': [
        for (final member in _members)
          {'id': member.id, 'display_name': member.displayName},
      ],
      'groups': [
        for (final group in _groups) {'id': group.id, 'name': group.name},
      ],
      'notes': [
        for (final note in _notes) {'id': note.id, 'title': note.title},
      ],
      'messages': [
        for (final message in _messages)
          {'id': message.id, 'body': message.body},
      ],
      'reminders': [
        for (final reminder in _reminders)
          {'id': reminder.id, 'title': reminder.title},
      ],
      'polls': [
        for (final poll in _polls)
          {
            'id': poll.id,
            'question': poll.question,
            'kind': poll.kind.storageValue,
          },
      ],
      'poll_options': [
        for (final poll in _polls)
          for (final option in poll.options)
            {
              'id': option.id,
              'poll_id': poll.id,
              'body': option.body,
              'position': option.position,
            },
      ],
      'poll_votes': [],
      'fronts': [
        for (final front in _frontHistory)
          {'id': front.id, 'label': front.label},
      ],
      'front_members': [],
      'notification_events': [
        for (final event in _notificationEvents)
          {'id': event.id, 'title': event.title},
      ],
      'preferences': [],
    });
  }

  @override
  Future<RestoreRehearsalSummary> rehearseLocalArchiveRestore(
    String archiveJson, {
    ImportConflictStrategy strategy = ImportConflictStrategy.prompt,
    String? fileName,
    ImportSource source = ImportSource.plurisHavenArchive,
  }) async {
    final decoded = jsonDecode(archiveJson);
    final archive = decoded is Map<String, Object?> ? decoded : const {};
    int countList(String key) =>
        archive[key] is List ? (archive[key] as List<Object?>).length : 0;

    return RestoreRehearsalSummary(
      canRestore: true,
      fileName: fileName,
      counts: {
        'members': countList('members'),
        'custom_fronts': 0,
        'groups': countList('groups'),
        'group_members': countList('group_members'),
        'notes': countList('notes'),
        'messages': countList('messages'),
        'reminders': countList('reminders'),
        'custom_fields': countList('custom_fields'),
        'custom_field_values': countList('custom_field_values'),
        'polls': countList('polls'),
        'poll_options': countList('poll_options'),
        'poll_votes': countList('poll_votes'),
        'fronts': countList('fronts'),
        'front_members': countList('front_members'),
        'named_fronts': countList('named_fronts'),
        'named_front_members': countList('named_front_members'),
        'import_records': 1,
        'raw_payloads': countList('raw_payloads'),
        'notification_events': countList('notification_events'),
        'preferences': countList('preferences'),
      },
      checkedAt: DateTime(2026),
      elapsed: const Duration(milliseconds: 17),
    );
  }

  @override
  Future<String> enqueueImportArchiveJob(
    String archiveJson, {
    required ImportConflictStrategy strategy,
    String? fileName,
    required ImportSource source,
  }) async {
    final now = DateTime(2026, 1, 1, 14, _backgroundJobs.length);
    final jobId = 'fake-job-${_backgroundJobs.length + 1}';
    _backgroundJobs = [
      BackgroundJobSummary(
        id: jobId,
        type: 'import_archive',
        status: 'queued',
        source: source.name,
        fileName: fileName,
        createdAt: now,
        updatedAt: now,
      ),
      ..._backgroundJobs,
    ];
    _backgroundJobsController.add(_backgroundJobs);
    return jobId;
  }

  @override
  Future<bool> runBackgroundJob(String jobId) async {
    _backgroundJobs = [
      for (final job in _backgroundJobs)
        job.id == jobId
            ? BackgroundJobSummary(
                id: job.id,
                type: job.type,
                status: 'done',
                source: job.source,
                fileName: job.fileName,
                createdAt: job.createdAt,
                updatedAt: DateTime(2026, 1, 1, 15),
              )
            : job,
    ];
    _backgroundJobsController.add(_backgroundJobs);
    return true;
  }

  @override
  Future<void> importLocalArchiveJson(
    String archiveJson, {
    ImportConflictStrategy strategy = ImportConflictStrategy.skip,
    String? fileName,
    ImportSource source = ImportSource.plurisHavenArchive,
    bool localizeAvatars = true,
  }) async {}

  @override
  Stream<List<Tag>> watchTags() =>
      _tagsController.stream.map((tags) => List.unmodifiable(tags));

  @override
  Future<void> saveTag(Tag tag) async {
    _tags = [
      for (final existing in _tags)
        if (existing.id != tag.id) existing,
      tag,
    ]..sort((left, right) => left.name.compareTo(right.name));
    _tagsController.add(_tags);
  }

  @override
  Future<void> deleteTag(String tagId) async {
    _tags = [
      for (final tag in _tags)
        if (tag.id != tagId) tag,
    ];
    _memberTagIds = {
      for (final entry in _memberTagIds.entries)
        entry.key: [
          for (final id in entry.value)
            if (id != tagId) id,
        ],
    };
    _tagsController.add(_tags);
    _memberTagsController.add(_memberTagIds);
  }

  @override
  Stream<List<Tag>> watchTagsForMember(String memberId) {
    return _memberTagsController.stream.map((assignments) {
      final ids = assignments[memberId]?.toSet() ?? const <String>{};
      return List.unmodifiable([
        for (final tag in _tags)
          if (ids.contains(tag.id)) tag,
      ]);
    });
  }

  @override
  Future<void> setMemberTags(String memberId, List<String> tagIds) async {
    _memberTagIds = {..._memberTagIds, memberId: tagIds};
    _memberTagsController.add(_memberTagIds);
  }

  @override
  Stream<List<JournalEntry>> watchJournals({String? memberId}) {
    return _journalsController.stream.map((journals) {
      return List.unmodifiable([
        for (final journal in journals)
          if (memberId == null || journal.memberId == memberId) journal,
      ]);
    });
  }

  @override
  Future<void> saveJournal(JournalEntry entry) async {
    _journals = [
      entry,
      for (final journal in _journals)
        if (journal.id != entry.id) journal,
    ]..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    _journalsController.add(_journals);
  }

  @override
  Future<void> deleteJournal(String entryId) async {
    _journals = [
      for (final journal in _journals)
        if (journal.id != entryId) journal,
    ];
    _journalsController.add(_journals);
  }

  @override
  Stream<List<ContentRevision>> watchRevisions(
    String targetType,
    String targetId,
  ) => Stream.value(const []);

  @override
  Future<void> pinRevision(String revisionId) async {}

  @override
  Future<void> unpinRevision(String revisionId) async {}

  @override
  Future<void> restoreRevision(
    String revisionId,
    String targetType,
    String targetId,
  ) async {}

  @override
  Stream<List<FrontAuditEvent>> watchFrontAuditEvents(String frontSessionId) =>
      Stream.value(const []);

  @override
  Stream<List<PollVoteEvent>> watchPollVoteEvents(String pollId) =>
      Stream.value(const []);

  @override
  Stream<List<NamedFront>> watchNamedFronts() =>
      _namedFrontsController.stream.map(List.unmodifiable);

  @override
  Future<void> saveNamedFront(NamedFront front, List<String> memberIds) async {
    _namedFronts = [
      for (final existing in _namedFronts)
        if (existing.id != front.id) existing,
      front,
    ];
    _namedFrontMembers[front.id] = List.unmodifiable(memberIds);
    _namedFrontsController.add(_namedFronts);
  }

  @override
  Future<void> applyNamedFront(String namedFrontId) async {
    NamedFront? front;
    for (final candidate in _namedFronts) {
      if (candidate.id == namedFrontId) {
        front = candidate;
        break;
      }
    }
    if (front == null) {
      return;
    }
    final customLabel = front.customLabel?.trim();
    if (customLabel != null && customLabel.isNotEmpty) {
      await setCustomFront(customLabel);
      return;
    }
    await setFrontMembers(_namedFrontMembers[namedFrontId] ?? const []);
  }

  @override
  Future<void> deleteNamedFront(String namedFrontId) async {
    _namedFronts = [
      for (final front in _namedFronts)
        if (front.id != namedFrontId) front,
    ];
    _namedFrontMembers.remove(namedFrontId);
    _namedFrontsController.add(_namedFronts);
  }

  @override
  Stream<List<PendingAction>> watchPendingActions() => Stream.value(const []);

  @override
  Future<void> cancelPendingAction(String actionId) async {}

  @override
  Future<void> finalizePendingActions() async {}

  @override
  Future<void> reorderMember(
    String memberId,
    String? prevRank,
    String? nextRank,
  ) async {}

  List<MemberSummary> get _visibleMembers => _members
      .where((member) => !member.archived && !member.isCustomFront)
      .toList(growable: false);

  void _emitMembers() {
    _membersController.add(_members);
    _emitCurrentFrontMembers();
  }

  void _emitGroups() {
    _groupsController.add(_groupsWithCounts());
  }

  Set<String> _normalizedFakeGroupIds(MemberDraft draft) {
    final ids = <String>{};
    for (final groupId in draft.groupIds ?? const <String>[]) {
      final normalized = _nullIfBlank(groupId);
      if (normalized != null) {
        ids.add(normalized);
      }
    }
    final folderId = _nullIfBlank(draft.folderId);
    if (folderId != null) {
      ids.add(folderId);
    }
    return ids;
  }

  String? _firstFakeGroupId(Set<String> groupIds) {
    return groupIds.isEmpty ? null : groupIds.first;
  }

  List<GroupSummary> _groupsWithCounts() {
    final counts = <String, int>{};
    for (final member in _members) {
      final ids = <String>{...member.groupIds};
      if (ids.isEmpty && member.folderId != null) {
        ids.add(member.folderId!);
      }
      for (final groupId in ids) {
        counts[groupId] = (counts[groupId] ?? 0) + 1;
      }
    }
    return [
      for (final group in _groups)
        GroupSummary(
          id: group.id,
          name: group.name,
          parentGroupId: group.parentGroupId,
          colorHex: group.colorHex,
          description: group.description,
          emoji: group.emoji,
          memberCount: counts[group.id] ?? 0,
        ),
    ];
  }

  List<MemberSummary> _currentFrontMembers() {
    final ids = _currentFrontMemberIds.toSet();
    return [
      for (final member in _visibleMembers)
        if (ids.contains(member.id)) member,
    ];
  }

  void _emitCurrentFrontMembers() {
    _currentFrontMembersController.add(_currentFrontMembers());
  }

  void _addFrontHistoryEntry(String label) {
    final now = DateTime(2026, 1, 1, 12, _frontHistory.length);
    _endOpenFrontHistory(endedAt: now);
    _frontHistory = [
      FrontHistoryEntry(
        id: 'fake-front-${_frontHistory.length + 1}',
        label: label,
        startedAt: now,
      ),
      ..._frontHistory,
    ];
    _frontHistoryController.add(_frontHistory);
  }

  void _endOpenFrontHistory({DateTime? endedAt}) {
    final ended = endedAt ?? DateTime(2026, 1, 1, 13);
    _frontHistory = [
      for (final entry in _frontHistory)
        entry.isActive
            ? FrontHistoryEntry(
                id: entry.id,
                label: entry.label,
                statusNote: entry.statusNote,
                startedAt: entry.startedAt,
                endedAt: ended,
              )
            : entry,
    ];
    _frontHistoryController.add(_frontHistory);
  }

  void _emitSnapshot({
    int? memberCount,
    int? groupCount,
    int? noteCount,
    int? frontHistoryCount,
    String? currentFrontLabel,
    bool clearCurrentFront = false,
  }) {
    _snapshot = HomeSnapshot(
      systemName: _snapshot.systemName,
      memberCount: memberCount ?? _snapshot.memberCount,
      groupCount: groupCount ?? _snapshot.groupCount,
      noteCount: noteCount ?? _snapshot.noteCount,
      frontHistoryCount: frontHistoryCount ?? _snapshot.frontHistoryCount,
      currentFrontLabel: clearCurrentFront
          ? null
          : currentFrontLabel ?? _snapshot.currentFrontLabel,
    );
    _controller.add(_snapshot);
  }

  String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  Future<void> close() async {
    await _controller.close();
    await _customizationController.close();
    await _membersController.close();
    await _currentFrontMembersController.close();
    await _groupsController.close();
    await _notesController.close();
    await _messagesController.close();
    await _remindersController.close();
    await _customFieldsController.close();
    await _customFieldValuesController.close();
    await _pollsController.close();
    await _notificationEventsController.close();
    await _frontHistoryController.close();
    await _backgroundJobsController.close();
    await _namedFrontsController.close();
    await _tagsController.close();
    await _memberTagsController.close();
    await _journalsController.close();
  }
}
