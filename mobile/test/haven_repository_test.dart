import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/import/import_archive_mapper.dart';
import 'package:pluris_haven/data/import/import_file_decoder.dart';
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

    await repository.setDashboardShortcutIds(const []);
    customization = await repository.loadCustomization();
    expect(customization.dashboardShortcutIds, isEmpty);
  });

  test('stores members and links them to front sessions', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = LocalHavenRepository(database);
    await repository.ensureLocalSystem();

    await repository.saveMember(
      const MemberDraft(
        displayName: 'Iris',
        pronouns: 'she/they',
        birthday: '02-03',
        emoji: 'I',
        privacy: 'trusted',
      ),
    );

    var members = await repository.watchMembers().first;
    expect(members, hasLength(1));
    expect(members.single.displayName, 'Iris');
    expect(members.single.pronouns, 'she/they');
    expect(members.single.birthday, '02-03');
    expect(members.single.emoji, 'I');
    expect(members.single.privacy, 'trusted');

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

  test('stores members in multiple groups', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = LocalHavenRepository(database);
    await repository.ensureLocalSystem();

    await repository.saveGroup(const GroupDraft(name: 'Caretakers'));
    await repository.saveGroup(const GroupDraft(name: 'Subsystem A'));
    final groups = await repository.watchGroups().first;

    await repository.saveMember(
      MemberDraft(
        displayName: 'Iris',
        folderId: groups.first.id,
        groupIds: [for (final group in groups) group.id],
      ),
    );

    final members = await repository.watchMembers().first;
    expect(members.single.groupIds.toSet(), {
      for (final group in groups) group.id,
    });

    final groupsWithCounts = await repository.watchGroups().first;
    expect([for (final group in groupsWithCounts) group.memberCount], [1, 1]);

    await repository.updateMember(
      members.single.id,
      const MemberDraft(displayName: 'Iris', groupIds: []),
    );

    expect((await repository.watchMembers().first).single.groupIds, isEmpty);
    expect(
      [
        for (final group in await repository.watchGroups().first)
          group.memberCount,
      ],
      [0, 0],
    );
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
    await repository.updateNote(
      notes.single.id,
      const NoteDraft(
        title: 'Grounding edited',
        body: 'Drink water and check meds before bed.',
      ),
    );
    final updatedNotes = await repository.watchNotes().first;
    expect(updatedNotes.single.title, 'Grounding edited');
    expect(updatedNotes.single.body, 'Drink water and check meds before bed.');

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
    await repository.updateMessage(
      messages.single.id,
      const MessageDraft(body: 'Remember to check in after dinner.'),
    );
    final updatedMessages = await repository.watchMessages().first;
    expect(updatedMessages.single.body, 'Remember to check in after dinner.');
    await repository.deleteMessage(updatedMessages.single.id);
    expect(await repository.watchMessages().first, isEmpty);

    expect(reminders.single.title, 'Medication');
    expect(reminders.single.scheduleText, 'Daily');
    expect(reminders.single.enabled, isTrue);
    await repository.setReminderEnabled(reminders.single.id, false);
    final disabledReminders = await repository.watchReminders().first;
    expect(disabledReminders.single.enabled, isFalse);
    expect(events.single.kind, 'front');
    expect(events.single.title, 'Front changed');
  });

  test('stores and updates local polls', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = LocalHavenRepository(database);
    await repository.ensureLocalSystem();

    await repository.savePoll(
      const PollDraft(
        question: 'Dinner?',
        description: 'Pick what works tonight.',
        kind: PollKind.singleChoice,
        options: ['Soup', 'Rice', 'Soup'],
      ),
    );

    var polls = await repository.watchPolls().first;
    expect(polls, hasLength(1));
    expect(polls.single.question, 'Dinner?');
    expect(polls.single.description, 'Pick what works tonight.');
    expect(polls.single.options.map((option) => option.body), ['Soup', 'Rice']);

    await repository.togglePollOption(
      polls.single.id,
      polls.single.options.first.id,
    );
    polls = await repository.watchPolls().first;
    expect(polls.single.selectedCount, 1);
    expect(polls.single.options.first.selected, isTrue);

    await repository.closePoll(polls.single.id);
    polls = await repository.watchPolls().first;
    expect(polls.single.closed, isTrue);

    await repository.deletePoll(polls.single.id);
    polls = await repository.watchPolls().first;
    expect(polls, isEmpty);
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
    await repository.savePoll(
      const PollDraft(
        question: 'Dinner?',
        kind: PollKind.multipleChoice,
        options: ['Soup', 'Rice'],
      ),
    );
    await repository.recordNotificationEvent(
      const NotificationEventDraft(
        kind: 'front',
        title: 'Front changed',
        body: 'Iris is fronting',
      ),
    );
    final member = (await repository.watchMembers().first).single;
    final note = (await repository.watchNotes().first).single;
    final now = DateTime.utc(2026, 1, 2, 3, 4, 5);
    await repository.saveTag(
      Tag(
        id: 'tag-grounded',
        systemId: localSystemId,
        name: 'Grounded',
        colorHex: '#80FFAA',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repository.setMemberTags(member.id, ['tag-grounded']);
    await repository.saveJournal(
      JournalEntry(
        id: 'journal-1',
        systemId: localSystemId,
        memberId: member.id,
        title: 'Switch notes',
        body: 'Felt close to front.',
        visibility: 'system',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await database
        .into(database.contentRevisions)
        .insert(
          ContentRevisionsCompanion.insert(
            id: 'revision-note-1',
            targetType: 'note',
            targetId: note.id,
            title: const Value('Grounding'),
            body: 'Drink water and breathe.',
            pinnedAt: Value(now),
            createdAt: now,
          ),
        );
    await repository.setFrontMembers([member.id]);
    final front = (await repository.watchFrontHistory().first).single;
    await database
        .into(database.frontAuditEvents)
        .insert(
          FrontAuditEventsCompanion.insert(
            id: 'front-audit-1',
            frontId: front.id,
            beforeSnapshot: const Value(null),
            afterSnapshot: const Value('{"members":["Iris"]}'),
            createdAt: now,
          ),
        );
    final poll = (await repository.watchPolls().first).single;
    await database
        .into(database.pollVoteEvents)
        .insert(
          PollVoteEventsCompanion.insert(
            id: 'poll-event-1',
            pollId: poll.id,
            optionId: poll.options.first.id,
            action: 'select',
            createdAt: now,
          ),
        );

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
    expect((archive['tags'] as List), hasLength(1));
    expect((archive['member_tags'] as List), hasLength(1));
    expect((archive['journals'] as List), hasLength(1));
    expect((archive['content_revisions'] as List), hasLength(1));
    expect((archive['polls'] as List), hasLength(1));
    expect((archive['poll_options'] as List), hasLength(2));
    expect((archive['poll_votes'] as List), isA<List>());
    expect((archive['poll_vote_events'] as List), hasLength(1));
    expect((archive['fronts'] as List), hasLength(1));
    expect((archive['front_members'] as List), hasLength(1));
    expect((archive['front_audit_events'] as List), hasLength(1));
    expect((archive['notification_events'] as List), hasLength(1));
    expect((archive['preferences'] as List), isA<List>());
  });

  test('documents local archive table coverage', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = LocalHavenRepository(database);
    await repository.ensureLocalSystem();

    const archivedTables = {
      'plural_systems': 'system',
      'system_groups': 'groups',
      'members': 'members',
      'group_members': 'group_members',
      'notes': 'notes',
      'messages': 'messages',
      'reminders': 'reminders',
      'custom_field_definitions': 'custom_fields',
      'custom_field_values': 'custom_field_values',
      'polls': 'polls',
      'poll_options': 'poll_options',
      'poll_votes': 'poll_votes',
      'front_sessions': 'fronts',
      'front_session_members': 'front_members',
      'import_records': 'import_records',
      'import_payloads': 'raw_payloads',
      'notification_events': 'notification_events',
      'app_preferences': 'preferences',
      'tags': 'tags',
      'member_tags': 'member_tags',
      'journal_entries': 'journals',
      'content_revisions': 'content_revisions',
      'front_audit_events': 'front_audit_events',
      'poll_vote_events': 'poll_vote_events',
      'named_fronts': 'named_fronts',
      'named_front_members': 'named_front_members',
    };
    const intentionallyLocalOnlyTables = {'background_jobs', 'pending_actions'};

    final actualTableNames = database.allTables
        .map((table) => table.actualTableName)
        .toSet();
    expect({
      ...archivedTables.keys,
      ...intentionallyLocalOnlyTables,
    }, actualTableNames);

    final archive =
        jsonDecode(await repository.buildLocalArchiveJson())
            as Map<String, dynamic>;
    expect(archive.keys, containsAll(archivedTables.values));
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
    await source.savePoll(
      const PollDraft(
        question: 'Dinner?',
        kind: PollKind.multipleChoice,
        options: ['Soup', 'Rice'],
      ),
    );
    await source.recordNotificationEvent(
      const NotificationEventDraft(
        kind: 'front',
        title: 'Front changed',
        body: 'Iris is fronting',
      ),
    );
    final member = (await source.watchMembers().first).single;
    final group = (await source.watchGroups().first).single;
    final note = (await source.watchNotes().first).single;
    final now = DateTime.utc(2026, 1, 2, 3, 4, 5);
    await source.updateMember(
      member.id,
      MemberDraft(
        displayName: member.displayName,
        pronouns: member.pronouns,
        folderId: group.id,
      ),
    );
    await source.saveTag(
      Tag(
        id: 'tag-grounded',
        systemId: localSystemId,
        name: 'Grounded',
        colorHex: '#80FFAA',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await source.setMemberTags(member.id, ['tag-grounded']);
    await source.saveJournal(
      JournalEntry(
        id: 'journal-1',
        systemId: localSystemId,
        memberId: member.id,
        title: 'Switch notes',
        body: 'Felt close to front.',
        visibility: 'system',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await sourceDatabase
        .into(sourceDatabase.contentRevisions)
        .insert(
          ContentRevisionsCompanion.insert(
            id: 'revision-note-1',
            targetType: 'note',
            targetId: note.id,
            title: const Value('Grounding'),
            body: 'Drink water and breathe.',
            pinnedAt: Value(now),
            createdAt: now,
          ),
        );
    await source.setFrontMembers([member.id]);
    final front = (await source.watchFrontHistory().first).single;
    await sourceDatabase
        .into(sourceDatabase.frontAuditEvents)
        .insert(
          FrontAuditEventsCompanion.insert(
            id: 'front-audit-1',
            frontId: front.id,
            beforeSnapshot: const Value(null),
            afterSnapshot: const Value('{"members":["Iris"]}'),
            createdAt: now,
          ),
        );
    final poll = (await source.watchPolls().first).single;
    await sourceDatabase
        .into(sourceDatabase.pollVoteEvents)
        .insert(
          PollVoteEventsCompanion.insert(
            id: 'poll-event-1',
            pollId: poll.id,
            optionId: poll.options.first.id,
            action: 'select',
            createdAt: now,
          ),
        );

    final archive = await source.buildLocalArchiveJson();
    final sourceArchive = jsonDecode(archive) as Map<String, dynamic>;
    expect(sourceArchive['group_members'], hasLength(1));
    expect(sourceArchive['member_tags'], hasLength(1));
    expect(sourceArchive['journals'], hasLength(1));
    expect(sourceArchive['content_revisions'], hasLength(1));
    expect(sourceArchive['front_audit_events'], hasLength(1));
    expect(sourceArchive['poll_vote_events'], hasLength(1));
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
    final importedGroups = await target.watchGroups().first;
    expect(importedGroups, hasLength(1));
    expect(importedGroups.single.memberCount, 1);
    expect(await target.watchNotes().first, hasLength(1));
    expect(await target.watchMessages().first, hasLength(1));
    expect(await target.watchReminders().first, hasLength(1));
    final importedMembers = await target.watchMembers().first;
    final importedMember = importedMembers.single;
    expect(await target.watchTags().first, hasLength(1));
    expect(
      (await target.watchTagsForMember(importedMember.id).first).single.name,
      'Grounded',
    );
    expect(
      await target.watchJournals(memberId: importedMember.id).first,
      hasLength(1),
    );
    expect(await target.watchRevisions('note', note.id).first, hasLength(1));
    final polls = await target.watchPolls().first;
    expect(polls, hasLength(1));
    expect(polls.single.options, hasLength(2));
    expect(
      await target.watchPollVoteEvents(polls.single.id).first,
      hasLength(1),
    );
    expect(await target.watchNotificationEvents().first, hasLength(1));
    final importedFronts = await target.watchFrontHistory().first;
    expect(importedFronts, hasLength(1));
    expect(
      await target.watchFrontAuditEvents(importedFronts.single.id).first,
      hasLength(1),
    );
    final targetArchive =
        jsonDecode(await target.buildLocalArchiveJson())
            as Map<String, dynamic>;
    expect(targetArchive['group_members'], hasLength(1));
    expect(targetArchive['member_tags'], hasLength(1));
    expect(targetArchive['journals'], hasLength(1));
    expect(targetArchive['content_revisions'], hasLength(1));
    expect(targetArchive['front_audit_events'], hasLength(1));
    expect(targetArchive['poll_vote_events'], hasLength(1));

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

  test('rehearses a restore without changing the current database', () async {
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
    final member = (await source.watchMembers().first).single;
    final now = DateTime.utc(2026, 1, 2, 3, 4, 5);
    await source.saveTag(
      Tag(
        id: 'tag-grounded',
        systemId: localSystemId,
        name: 'Grounded',
        colorHex: '#80FFAA',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await source.setMemberTags(member.id, ['tag-grounded']);
    await source.saveJournal(
      JournalEntry(
        id: 'journal-1',
        systemId: localSystemId,
        memberId: member.id,
        title: 'Switch notes',
        body: 'Felt close to front.',
        visibility: 'system',
        createdAt: now,
        updatedAt: now,
      ),
    );
    final archive = await source.buildLocalArchiveJson();
    await sourceDatabase.close();

    final targetDatabase = AppDatabase(NativeDatabase.memory());
    addTearDown(targetDatabase.close);
    final target = LocalHavenRepository(targetDatabase);
    await target.ensureLocalSystem();

    final rehearsal = await target.rehearseLocalArchiveRestore(
      archive,
      strategy: ImportConflictStrategy.update,
      fileName: 'backup.json',
    );

    expect(rehearsal.canRestore, isTrue);
    expect(rehearsal.error, isNull);
    expect(rehearsal.counts['members'], 1);
    expect(rehearsal.counts['groups'], 1);
    expect(rehearsal.counts['notes'], 1);
    expect(rehearsal.counts['tags'], 1);
    expect(rehearsal.counts['member_tags'], 1);
    expect(rehearsal.counts['journals'], 1);
    expect(rehearsal.counts['import_records'], 1);
    expect(await target.watchMembers().first, isEmpty);
    expect(await target.watchGroups().first, isEmpty);
    expect(await target.watchNotes().first, isEmpty);
    expect(await target.watchTags().first, isEmpty);
    expect(await target.watchJournals().first, isEmpty);
  });

  test('reports restore rehearsal failures without throwing', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = LocalHavenRepository(database);
    await repository.ensureLocalSystem();

    final rehearsal = await repository.rehearseLocalArchiveRestore(
      '{"format":"wrong"}',
      fileName: 'broken.json',
    );

    expect(rehearsal.canRestore, isFalse);
    expect(rehearsal.error, contains('Unsupported archive format'));
    expect(await repository.watchMembers().first, isEmpty);
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
    expect(fronts.single.label, 'Iris');
    expect(messages.single.body, 'hello');

    final importRecords = await database.select(database.importRecords).get();
    expect(importRecords.single.source, 'simplyplural_file');

    final payloads = await database.select(database.importPayloads).get();
    expect(payloads.map((payload) => payload.collection), contains('members'));

    final reExported = await repository.buildLocalArchiveJson();
    expect(reExported, contains('"raw_payloads"'));
    expect(reExported, contains('"collection": "members"'));
  });

  test(
    're-imports Simply Plural front history without foreign key failures',
    () async {
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
  "users": [{"_id": "owner1", "username": "Imported system"}],
  "members": [{"_id": "m1", "name": "Iris"}],
  "frontStatuses": [{"_id": "cf1", "name": "Asleep"}],
  "frontHistory": [
    {
      "_id": "f1",
      "member": "m1",
      "custom": false,
      "customStatus": "blurry",
      "startTime": 1767225600000,
      "endTime": 1767229200000
    },
    {
      "_id": "f2",
      "member": "cf1",
      "custom": true,
      "customStatus": "Asleep",
      "startTime": 1767232800000,
      "endTime": 1767236400000
    }
  ],
  "securityLogs": [{"_id": "log1", "kind": "login"}]
}
''',
      );

      await repository.importLocalArchiveJson(
        normalized.archiveJson,
        source: ImportSource.simplyPlural,
        fileName: 'simply-plural.json',
      );
      await repository.importLocalArchiveJson(
        normalized.archiveJson,
        source: ImportSource.simplyPlural,
        fileName: 'simply-plural.json',
      );

      final members = await repository
          .watchMembers(includeArchived: true)
          .first;
      final fronts = await repository.watchFrontHistory().first;
      final namedFronts = await repository.watchNamedFronts().first;
      final payloads = await database.select(database.importPayloads).get();

      expect(members.map((member) => member.displayName), contains('Iris'));
      expect(
        members.map((member) => member.displayName),
        isNot(contains('Asleep')),
      );
      expect(namedFronts.map((front) => front.customLabel), contains('Asleep'));
      expect(fronts, hasLength(2));
      expect(fronts.map((front) => front.label), contains('Asleep'));
      expect(
        fronts.singleWhere((front) => front.label == 'Iris').statusNote,
        'blurry',
      );
      await repository.applyNamedFront(namedFronts.single.id);
      final home = await repository.watchHomeSnapshot().first;
      expect(home.currentFrontLabel, 'Asleep');
      final exported =
          jsonDecode(await repository.buildLocalArchiveJson())
              as Map<String, dynamic>;
      final exportedFronts = (exported['fronts'] as List)
          .cast<Map<String, dynamic>>();
      expect(
        exportedFronts.any((front) => front['status_note'] == 'blurry'),
        isTrue,
      );
      expect(
        payloads.map((payload) => payload.collection),
        contains('securityLogs'),
      );
    },
  );

  test('runs queued import jobs from the local database', () async {
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
  "members": [{"id": "m1", "name": "Iris", "pronouns": "she/they"}]
}
''',
    );

    final jobId = await repository.enqueueImportArchiveJob(
      normalized.archiveJson,
      strategy: ImportConflictStrategy.skip,
      source: ImportSource.simplyPlural,
      fileName: 'simply-plural.json',
    );

    var jobs = await repository.watchBackgroundJobs().first;
    expect(jobs.single.id, jobId);
    expect(jobs.single.status, 'queued');

    expect(await repository.runQueuedImportJobs(), isTrue);

    jobs = await repository.watchBackgroundJobs().first;
    expect(jobs.single.status, 'done');

    final members = await repository.watchMembers().first;
    expect(members.single.displayName, 'Iris');
  });

  test('stores imported avatar assets locally', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = LocalHavenRepository(database);
    await repository.ensureLocalSystem();

    final archive = normalizeImportTextToLocalArchive(
      source: ImportSource.simplyPlural,
      fileName: 'sp.json',
      importedAt: DateTime.utc(2026),
      text: '''
{
  "members": [{"_id": "m1", "name": "Iris", "avatarUuid": "avatar-1"}]
}
''',
      avatarAssets: [
        ImportAvatarAsset(
          id: 'avatar-1',
          name: 'avatars/avatar-1.png',
          mimeType: 'image/png',
          bytes: Uint8List.fromList([1, 2, 3, 4]),
        ),
      ],
    );

    await repository.importLocalArchiveJson(
      archive.archiveJson,
      source: ImportSource.simplyPlural,
      fileName: 'sp.json',
    );

    final rows = await database.select(database.members).get();
    expect(rows.single.avatarUrl, startsWith('local-avatar:'));
    expect(rows.single.avatarUrl, endsWith('.png'));
  });
}
