import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/import/import_sources.dart';
import 'package:pluris_haven/data/local/haven_repository.dart';
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

    await tester.enterText(find.byType(TextField), 'blurry co-con');
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

  testWidgets('opens an SP-style section from the dashboard', (tester) async {
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
    await tester.tap(find.byKey(const ValueKey('save-member-button')));
    await tester.pumpAndSettle();

    expect(find.text('Iris'), findsOneWidget);
    expect(find.text('she/they'), findsOneWidget);

    await tester.tap(find.byTooltip('Member actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set front'));
    await tester.pumpAndSettle();

    expect(repository._snapshot.currentFrontText, 'Iris');
    expect(repository._snapshot.frontHistoryCount, 1);
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

    await tester.tap(find.text('Groups').first);
    await tester.pumpAndSettle();

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
    await tester.tap(find.byKey(const ValueKey('save-group-button')));
    await tester.pumpAndSettle();

    expect(find.text('Caretakers'), findsOneWidget);
    expect(repository._snapshot.groupCount, 1);
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

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    await tester.tap(find.text('Notes').first);
    await tester.pumpAndSettle();

    expect(find.text('No notes yet'), findsOneWidget);

    await tester.tap(find.text('Add note'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('note-title-field')),
      'Grounding',
    );
    await tester.enterText(
      find.byKey(const ValueKey('note-body-field')),
      'Drink water and check meds.',
    );
    await tester.tap(find.byKey(const ValueKey('save-note-button')));
    await tester.pumpAndSettle();

    expect(find.text('Grounding'), findsOneWidget);
    expect(find.text('Drink water and check meds.'), findsOneWidget);
    expect(repository._snapshot.noteCount, 1);
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

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    await openDrawerSection(tester, 'Chat');
    await tester.pumpAndSettle();

    expect(find.text('No messages yet'), findsOneWidget);

    await tester.tap(find.text('Add message'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('message-body-field')),
      'Check in after dinner.',
    );
    await tester.tap(find.byKey(const ValueKey('save-message-button')));
    await tester.pumpAndSettle();

    expect(find.text('Check in after dinner.'), findsOneWidget);
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
    await tester.enterText(
      find.byKey(const ValueKey('reminder-schedule-field')),
      'Daily',
    );
    await tester.enterText(
      find.byKey(const ValueKey('reminder-body-field')),
      'With water',
    );
    await tester.tap(find.byKey(const ValueKey('save-reminder-button')));
    await tester.pumpAndSettle();

    expect(find.text('Medication'), findsOneWidget);
    expect(find.text('Daily'), findsOneWidget);
    expect(find.text('With water'), findsOneWidget);
  });

  testWidgets('updates customization from the app options page', (
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

    await tester.ensureVisible(find.text('Customize'));
    await tester.tap(find.text('Customize'));
    await tester.pumpAndSettle();

    expect(find.text('Dark'), findsOneWidget);
    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();
    expect(find.text('Light'), findsOneWidget);

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

    await tester.scrollUntilVisible(find.text('Analytics'), 220);
    await tester.tap(find.byKey(const ValueKey('shortcut-visible-analytics')));
    await tester.pumpAndSettle();
    expect(
      (await repository.loadCustomization()).dashboardShortcutIds,
      contains('analytics'),
    );

    await tester.tap(find.byKey(const ValueKey('shortcut-up-analytics')));
    await tester.pumpAndSettle();
    final shortcutIds =
        (await repository.loadCustomization()).dashboardShortcutIds;
    expect(shortcutIds.indexOf('analytics'), shortcutIds.length - 2);

    await tester.scrollUntilVisible(find.text('Reset dashboard'), 220);
    await tester.tap(find.text('Reset dashboard'));
    await tester.pumpAndSettle();
    expect(
      (await repository.loadCustomization()).dashboardShortcutIds,
      defaultDashboardShortcutIds,
    );
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
    expect(find.text('Copy JSON'), findsOneWidget);
    expect(find.textContaining('pluris_haven.local_archive'), findsOneWidget);
    expect(find.textContaining('Caretakers'), findsOneWidget);
  });
}

Future<void> openDrawerSection(WidgetTester tester, String label) async {
  await tester.tap(find.byTooltip('Open navigation menu'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
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
      onListen: () => _customizationController.add(_customization),
    );
    _membersController = StreamController<List<MemberSummary>>.broadcast(
      sync: true,
      onListen: () => _membersController.add(_visibleMembers),
    );
    _groupsController = StreamController<List<GroupSummary>>.broadcast(
      sync: true,
      onListen: () => _groupsController.add(_groups),
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
  }

  HomeSnapshot _snapshot;
  AppCustomization _customization = AppCustomization.defaults;
  List<MemberSummary> _members = const [];
  List<GroupSummary> _groups = const [];
  List<NoteSummary> _notes = const [];
  List<MessageSummary> _messages = const [];
  List<ReminderSummary> _reminders = const [];
  List<NotificationEventSummary> _notificationEvents = const [];
  List<FrontHistoryEntry> _frontHistory = const [];
  late final StreamController<HomeSnapshot> _controller;
  late final StreamController<AppCustomization> _customizationController;
  late final StreamController<List<MemberSummary>> _membersController;
  late final StreamController<List<GroupSummary>> _groupsController;
  late final StreamController<List<NoteSummary>> _notesController;
  late final StreamController<List<MessageSummary>> _messagesController;
  late final StreamController<List<ReminderSummary>> _remindersController;
  late final StreamController<List<NotificationEventSummary>>
  _notificationEventsController;
  late final StreamController<List<FrontHistoryEntry>> _frontHistoryController;

  @override
  Stream<HomeSnapshot> watchHomeSnapshot() => _controller.stream;

  @override
  Stream<List<MemberSummary>> watchMembers({bool includeArchived = false}) {
    if (includeArchived) {
      return _membersController.stream.map(List.unmodifiable);
    }

    return _membersController.stream.map(
      (members) =>
          List.unmodifiable(members.where((member) => !member.archived)),
    );
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
  Stream<List<NotificationEventSummary>> watchNotificationEvents() {
    return _notificationEventsController.stream.map(List.unmodifiable);
  }

  @override
  Stream<List<FrontHistoryEntry>> watchFrontHistory() {
    return _frontHistoryController.stream.map(List.unmodifiable);
  }

  @override
  Stream<AppCustomization> watchCustomization() =>
      _customizationController.stream;

  @override
  Future<AppCustomization> loadCustomization() async => _customization;

  @override
  Future<void> setThemeMode(HavenThemeMode mode) async {
    _customization = _customization.copyWith(themeMode: mode);
    _customizationController.add(_customization);
  }

  @override
  Future<void> setAccentColor(HavenAccentColor color) async {
    _customization = _customization.copyWith(accentColor: color);
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

    _members = [
      ..._members,
      MemberSummary(
        id: 'fake-member-${_members.length + 1}',
        displayName: displayName,
        pronouns: _nullIfBlank(draft.pronouns),
        colorHex: _nullIfBlank(draft.colorHex),
        description: _nullIfBlank(draft.description),
      ),
    ];
    _emitMembers();
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
            description: member.description,
            archived: true,
          )
        else
          member,
    ];
    _emitMembers();
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
    _addFrontHistoryEntry(_snapshot.currentFrontLabel!);
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
    _groupsController.add(_groups);
    _emitSnapshot(groupCount: _groups.length);
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
  Future<void> saveReminder(ReminderDraft draft) async {
    final title = draft.title.trim();
    final schedule = draft.scheduleText.trim();
    if (title.isEmpty || schedule.isEmpty) {
      return;
    }

    _reminders = [
      ReminderSummary(
        id: 'fake-reminder-${_reminders.length + 1}',
        title: title,
        body: _nullIfBlank(draft.body),
        scheduleText: schedule,
        enabled: draft.enabled,
        updatedAt: DateTime(2026),
      ),
      ..._reminders,
    ];
    _remindersController.add(_reminders);
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
    _emitSnapshot(
      frontHistoryCount: _snapshot.frontHistoryCount + 1,
      currentFrontLabel: label,
    );
    _addFrontHistoryEntry(label);
  }

  @override
  Future<void> clearCurrentFront() async {
    _endOpenFrontHistory();
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
  Future<void> importLocalArchiveJson(
    String archiveJson, {
    ImportConflictStrategy strategy = ImportConflictStrategy.skip,
    String? fileName,
  }) async {}

  List<MemberSummary> get _visibleMembers =>
      _members.where((member) => !member.archived).toList(growable: false);

  void _emitMembers() {
    _membersController.add(_members);
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
    await _groupsController.close();
    await _notesController.close();
    await _messagesController.close();
    await _remindersController.close();
    await _notificationEventsController.close();
    await _frontHistoryController.close();
  }
}
