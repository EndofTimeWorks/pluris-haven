import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/import/import_archive_mapper.dart';
import 'package:pluris_haven/data/import/import_sources.dart';
import 'package:pluris_haven/data/local/app_database.dart';
import 'package:pluris_haven/data/local/haven_repository.dart';

void main() {
  test('stores and clears current front in the local database', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = LocalHavenRepository(database);
    await repository.ensureLocalSystem();

    var snapshot = await repository.loadHomeSnapshot();
    expect(snapshot.systemName, 'Local system');
    expect(snapshot.currentFrontText, 'None');
    expect(snapshot.frontHistoryCount, 0);

    await repository.setCustomFront('blurry co-con');
    snapshot = await repository.loadHomeSnapshot();
    expect(snapshot.currentFrontText, 'blurry co-con');
    expect(snapshot.currentFrontStatus, 'fronting');
    expect(snapshot.frontHistoryCount, 1);

    var history = await repository.watchFrontHistory().first;
    expect(history, hasLength(1));
    expect(history.single.label, 'blurry co-con');
    expect(history.single.isActive, isTrue);

    await repository.clearCurrentFront();
    snapshot = await repository.loadHomeSnapshot();
    expect(snapshot.currentFrontText, 'None');
    expect(snapshot.currentFrontStatus, 'none');
    expect(snapshot.frontHistoryCount, 1);

    history = await repository.watchFrontHistory().first;
    expect(history.single.isActive, isFalse);
  });

  test('stores app customization in the local database', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = LocalHavenRepository(database);
    await repository.ensureLocalSystem();

    var customization = await repository.loadCustomization();
    expect(customization.themeMode, HavenThemeMode.dark);
    expect(customization.accentColor, HavenAccentColor.purple);
    expect(customization.compactDashboard, isFalse);
    expect(customization.showDashboardSubtitles, isTrue);
    expect(customization.dashboardShortcutIds, defaultDashboardShortcutIds);
    expect(customization.languageCode, 'system');

    await repository.setThemeMode(HavenThemeMode.system);
    await repository.setAccentColor(HavenAccentColor.teal);
    await repository.setCompactDashboard(true);
    await repository.setShowDashboardSubtitles(false);
    await repository.setDashboardShortcutVisible('analytics', true);
    await repository.moveDashboardShortcut('analytics', -10);
    await repository.setDashboardShortcutVisible('notes', false);
    await repository.setLanguageCode('pt-BR');

    customization = await repository.loadCustomization();
    expect(customization.themeMode, HavenThemeMode.system);
    expect(customization.accentColor, HavenAccentColor.teal);
    expect(customization.compactDashboard, isTrue);
    expect(customization.showDashboardSubtitles, isFalse);
    expect(customization.dashboardShortcutIds.first, 'analytics');
    expect(customization.dashboardShortcutIds, isNot(contains('notes')));
    expect(customization.languageCode, 'pt-BR');
    expect(customization.language.label, 'português brasileiro');

    await repository.resetDashboardShortcuts();
    customization = await repository.loadCustomization();
    expect(customization.dashboardShortcutIds, defaultDashboardShortcutIds);
  });

  test('stores members and links them to front sessions', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = LocalHavenRepository(database);
    await repository.ensureLocalSystem();

    await repository.saveMember(
      const MemberDraft(displayName: 'Iris', pronouns: 'she/they'),
    );

    var members = await repository.watchMembers().first;
    expect(members, hasLength(1));
    expect(members.single.displayName, 'Iris');
    expect(members.single.pronouns, 'she/they');

    var snapshot = await repository.loadHomeSnapshot();
    expect(snapshot.memberCount, 1);

    await repository.setFrontMembers([members.single.id]);
    snapshot = await repository.loadHomeSnapshot();
    expect(snapshot.currentFrontText, 'Iris');
    expect(snapshot.frontHistoryCount, 1);

    final history = await repository.watchFrontHistory().first;
    expect(history.single.label, 'Iris');

    final frontLinks = await database
        .select(database.frontSessionMembers)
        .get();
    expect(frontLinks, hasLength(1));
    expect(frontLinks.single.memberId, members.single.id);

    await repository.archiveMember(members.single.id);
    members = await repository.watchMembers().first;
    expect(members, isEmpty);

    snapshot = await repository.loadHomeSnapshot();
    expect(snapshot.memberCount, 0);
  });

  test('stores groups in the local database', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = LocalHavenRepository(database);
    await repository.ensureLocalSystem();

    await repository.saveGroup(
      const GroupDraft(
        name: 'Caretakers',
        emoji: '*',
        description: 'Internal support crew',
      ),
    );

    final groups = await repository.watchGroups().first;
    expect(groups, hasLength(1));
    expect(groups.single.name, 'Caretakers');
    expect(groups.single.emoji, '*');
    expect(groups.single.description, 'Internal support crew');

    final snapshot = await repository.loadHomeSnapshot();
    expect(snapshot.groupCount, 1);
  });

  test('stores notes in the local database', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = LocalHavenRepository(database);
    await repository.ensureLocalSystem();

    await repository.saveNote(
      const NoteDraft(title: 'Grounding', body: 'Drink water and check meds.'),
    );

    final notes = await repository.watchNotes().first;
    expect(notes, hasLength(1));
    expect(notes.single.title, 'Grounding');
    expect(notes.single.body, 'Drink water and check meds.');

    final snapshot = await repository.loadHomeSnapshot();
    expect(snapshot.noteCount, 1);
  });

  test('stores messages, reminders, and notification events locally', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = LocalHavenRepository(database);
    await repository.ensureLocalSystem();

    await repository.saveMessage(
      const MessageDraft(body: 'Remember to check in.'),
    );
    await repository.saveReminder(
      const ReminderDraft(
        title: 'Medication',
        body: 'With water',
        scheduleText: 'Daily',
      ),
    );
    await repository.recordNotificationEvent(
      const NotificationEventDraft(
        kind: 'front',
        title: 'Front changed',
        body: 'Iris is fronting',
      ),
    );

    final messages = await repository.watchMessages().first;
    final reminders = await repository.watchReminders().first;
    final events = await repository.watchNotificationEvents().first;

    expect(messages.single.body, 'Remember to check in.');
    expect(reminders.single.title, 'Medication');
    expect(reminders.single.scheduleText, 'Daily');
    expect(events.single.kind, 'front');
    expect(events.single.title, 'Front changed');
  });

  test('exports a versioned local archive', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = LocalHavenRepository(database);
    await repository.ensureLocalSystem();
    await repository.saveMember(
      const MemberDraft(displayName: 'Iris', pronouns: 'she/they'),
    );
    await repository.saveGroup(const GroupDraft(name: 'Caretakers'));
    await repository.saveNote(
      const NoteDraft(title: 'Grounding', body: 'Drink water.'),
    );
    await repository.saveMessage(const MessageDraft(body: 'System check-in.'));
    await repository.saveReminder(
      const ReminderDraft(title: 'Meds', scheduleText: 'Daily'),
    );
    await repository.recordNotificationEvent(
      const NotificationEventDraft(
        kind: 'front',
        title: 'Front changed',
        body: 'Iris is fronting',
      ),
    );
    final member = (await repository.watchMembers().first).single;
    await repository.setFrontMembers([member.id]);

    final archive =
        jsonDecode(await repository.buildLocalArchiveJson())
            as Map<String, dynamic>;

    expect(archive['format'], 'pluris_haven.local_archive');
    expect(archive['version'], 1);
    expect((archive['members'] as List), hasLength(1));
    expect((archive['groups'] as List), hasLength(1));
    expect((archive['notes'] as List), hasLength(1));
    expect((archive['messages'] as List), hasLength(1));
    expect((archive['reminders'] as List), hasLength(1));
    expect((archive['fronts'] as List), hasLength(1));
    expect((archive['front_members'] as List), hasLength(1));
    expect((archive['notification_events'] as List), hasLength(1));
    expect((archive['preferences'] as List), isA<List>());
  });

  test('imports a local archive into an empty database', () async {
    final sourceDatabase = AppDatabase(NativeDatabase.memory());
    final source = LocalHavenRepository(sourceDatabase);
    await source.ensureLocalSystem();

    await source.saveMember(
      const MemberDraft(displayName: 'Iris', pronouns: 'she/they'),
    );
    await source.saveGroup(const GroupDraft(name: 'Caretakers'));
    await source.saveNote(
      const NoteDraft(title: 'Grounding', body: 'Drink water.'),
    );
    await source.saveMessage(const MessageDraft(body: 'System check-in.'));
    await source.saveReminder(
      const ReminderDraft(title: 'Meds', scheduleText: 'Daily'),
    );
    await source.recordNotificationEvent(
      const NotificationEventDraft(
        kind: 'front',
        title: 'Front changed',
        body: 'Iris is fronting',
      ),
    );
    final member = (await source.watchMembers().first).single;
    await source.setFrontMembers([member.id]);

    final archive = await source.buildLocalArchiveJson();
    await sourceDatabase.close();

    final targetDatabase = AppDatabase(NativeDatabase.memory());
    addTearDown(targetDatabase.close);
    final target = LocalHavenRepository(targetDatabase);
    await target.ensureLocalSystem();

    await target.importLocalArchiveJson(
      archive,
      strategy: ImportConflictStrategy.update,
      fileName: 'backup.json',
    );

    expect(await target.watchMembers().first, hasLength(1));
    expect(await target.watchGroups().first, hasLength(1));
    expect(await target.watchNotes().first, hasLength(1));
    expect(await target.watchMessages().first, hasLength(1));
    expect(await target.watchReminders().first, hasLength(1));
    expect(await target.watchNotificationEvents().first, hasLength(1));
    expect(await target.watchFrontHistory().first, hasLength(1));

    final snapshot = await target.loadHomeSnapshot();
    expect(snapshot.memberCount, 1);
    expect(snapshot.groupCount, 1);
    expect(snapshot.noteCount, 1);
    expect(snapshot.frontHistoryCount, 1);

    final importRecords = await targetDatabase
        .select(targetDatabase.importRecords)
        .get();
    expect(importRecords, hasLength(1));
    expect(importRecords.single.source, 'plurishaven_archive');
    expect(importRecords.single.fileName, 'backup.json');
  });

  test('imports normalized external archives', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = LocalHavenRepository(database);
    await repository.ensureLocalSystem();

    final normalized = normalizeImportTextToLocalArchive(
      source: ImportSource.simplyPlural,
      fileName: 'simply-plural.json',
      importedAt: DateTime.utc(2026),
      text: '''
{
  "system": {"name": "Imported system"},
  "members": [{"id": "m1", "name": "Iris", "pronouns": "she/they"}],
  "frontHistory": [
    {"id": "f1", "startedAt": "2026-01-01T12:00:00Z", "members": ["m1"]}
  ],
  "messages": [{"id": "msg1", "body": "hello"}]
}
''',
    );

    await repository.importLocalArchiveJson(
      normalized.archiveJson,
      source: ImportSource.simplyPlural,
      fileName: 'simply-plural.json',
    );

    final members = await repository.watchMembers().first;
    final fronts = await repository.watchFrontHistory().first;
    final messages = await repository.watchMessages().first;

    expect(members.single.displayName, 'Iris');
    expect(members.single.pronouns, 'she/they');
    expect(fronts.single.label, 'Unknown front');
    expect(messages.single.body, 'hello');

    final importRecords = await database.select(database.importRecords).get();
    expect(importRecords.single.source, 'simplyplural_file');

    final payloads = await database.select(database.importPayloads).get();
    expect(payloads.map((payload) => payload.collection), contains('members'));

    final reExported = await repository.buildLocalArchiveJson();
    expect(reExported, contains('"raw_payloads"'));
    expect(reExported, contains('"collection": "members"'));
  });
}
