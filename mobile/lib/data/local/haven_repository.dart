import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';

import '../../debug/debug_log.dart';
import '../import/import_sources.dart';
import '../ordering/lexorank.dart';
import '../security/haven_crypto.dart';
import 'app_database.dart';
import 'supported_language.dart';

class HomeSnapshot {
  const HomeSnapshot({
    required this.systemName,
    required this.memberCount,
    required this.groupCount,
    required this.noteCount,
    required this.frontHistoryCount,
    required this.currentFrontLabel,
  });

  final String systemName;
  final int memberCount;
  final int groupCount;
  final int noteCount;
  final int frontHistoryCount;
  final String? currentFrontLabel;

  String get currentFrontText => currentFrontLabel?.trim().isNotEmpty == true
      ? currentFrontLabel!.trim()
      : 'None';

  String get currentFrontStatus =>
      currentFrontLabel?.trim().isNotEmpty == true ? 'fronting' : 'none';
}

class BackgroundJobSummary {
  const BackgroundJobSummary({
    required this.id,
    required this.type,
    required this.status,
    this.source,
    this.fileName,
    this.error,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String type;
  final String status;
  final String? source;
  final String? fileName;
  final String? error;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive => status == 'queued' || status == 'running';
}

class MemberSummary {
  const MemberSummary({
    required this.id,
    required this.displayName,
    this.pronouns,
    this.colorHex,
    this.description,
    this.avatarUrl,
    this.pluralKitId,
    this.archived = false,
    this.isCustomFront = false,
    this.frameShape = 'circle',
    this.lexoRank = '0|zzzzzz',
    this.folderId,
  });

  final String id;
  final String displayName;
  final String? pronouns;
  final String? colorHex;
  final String? description;
  final String? avatarUrl;
  final String? pluralKitId;
  final bool archived;
  final bool isCustomFront;
  final String frameShape;
  final String lexoRank;
  final String? folderId;
}

class MemberDraft {
  const MemberDraft({
    required this.displayName,
    this.pronouns,
    this.colorHex,
    this.description,
    this.avatarUrl,
    this.pluralKitId,
    this.folderId,
  });

  final String displayName;
  final String? pronouns;
  final String? colorHex;
  final String? description;
  final String? avatarUrl;
  final String? pluralKitId;
  final String? folderId;
}

class GroupSummary {
  const GroupSummary({
    required this.id,
    required this.name,
    this.parentGroupId,
    this.colorHex,
    this.description,
    this.emoji,
  });

  final String id;
  final String name;
  final String? parentGroupId;
  final String? colorHex;
  final String? description;
  final String? emoji;
}

class GroupDraft {
  const GroupDraft({
    required this.name,
    this.parentGroupId,
    this.colorHex,
    this.description,
    this.emoji,
  });

  final String name;
  final String? parentGroupId;
  final String? colorHex;
  final String? description;
  final String? emoji;
}

class NoteSummary {
  const NoteSummary({
    required this.id,
    required this.title,
    required this.body,
    this.memberId,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String body;
  final String? memberId;
  final DateTime updatedAt;
}

class NoteDraft {
  const NoteDraft({required this.title, required this.body, this.memberId});

  final String title;
  final String body;
  final String? memberId;
}

class MessageSummary {
  const MessageSummary({
    required this.id,
    required this.body,
    this.memberId,
    required this.createdAt,
    this.archived = false,
  });

  final String id;
  final String body;
  final String? memberId;
  final DateTime createdAt;
  final bool archived;
}

class MessageDraft {
  const MessageDraft({required this.body, this.memberId});

  final String body;
  final String? memberId;
}

class ReminderSummary {
  const ReminderSummary({
    required this.id,
    required this.title,
    this.body,
    required this.scheduleText,
    required this.enabled,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String? body;
  final String scheduleText;
  final bool enabled;
  final DateTime updatedAt;
}

class ReminderDraft {
  const ReminderDraft({
    required this.title,
    this.body,
    required this.scheduleText,
    this.enabled = true,
  });

  final String title;
  final String? body;
  final String scheduleText;
  final bool enabled;
}

enum PollKind {
  singleChoice('single_choice', 'Single choice'),
  multipleChoice('multiple_choice', 'Multiple choice');

  const PollKind(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static PollKind fromStorage(String? value) {
    return PollKind.values.firstWhere(
      (kind) => kind.storageValue == value,
      orElse: () => PollKind.singleChoice,
    );
  }
}

class CustomFieldSummary {
  const CustomFieldSummary({
    required this.id,
    required this.name,
    required this.fieldType,
    this.privacy,
    required this.position,
    required this.valueCount,
  });

  final String id;
  final String name;
  final String fieldType;
  final String? privacy;
  final int position;
  final int valueCount;
}

class CustomFieldDraft {
  const CustomFieldDraft({
    required this.name,
    this.fieldType = 'text',
    this.privacy,
  });

  final String name;
  final String fieldType;
  final String? privacy;
}

class CustomFieldValueSummary {
  const CustomFieldValueSummary({
    required this.id,
    required this.fieldId,
    this.memberId,
    required this.value,
  });

  final String id;
  final String fieldId;
  final String? memberId;
  final String value;
}

class PollOptionSummary {
  const PollOptionSummary({
    required this.id,
    required this.body,
    required this.position,
    required this.selected,
  });

  final String id;
  final String body;
  final int position;
  final bool selected;
}

class PollSummary {
  const PollSummary({
    required this.id,
    required this.question,
    this.description,
    required this.kind,
    required this.closed,
    required this.options,
    required this.updatedAt,
  });

  final String id;
  final String question;
  final String? description;
  final PollKind kind;
  final bool closed;
  final List<PollOptionSummary> options;
  final DateTime updatedAt;

  int get selectedCount => options.where((option) => option.selected).length;

  String get statusLabel => closed ? 'closed' : 'open';
}

class PollDraft {
  const PollDraft({
    required this.question,
    this.description,
    required this.kind,
    required this.options,
  });

  final String question;
  final String? description;
  final PollKind kind;
  final List<String> options;
}

class NotificationEventSummary {
  const NotificationEventSummary({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    this.readAt,
    required this.createdAt,
  });

  final String id;
  final String kind;
  final String title;
  final String body;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isUnread => readAt == null;
}

class NotificationEventDraft {
  const NotificationEventDraft({
    required this.kind,
    required this.title,
    required this.body,
  });

  final String kind;
  final String title;
  final String body;
}

class FrontHistoryEntry {
  const FrontHistoryEntry({
    required this.id,
    required this.label,
    required this.startedAt,
    this.endedAt,
  });

  final String id;
  final String label;
  final DateTime startedAt;
  final DateTime? endedAt;

  bool get isActive => endedAt == null;
}

enum HavenThemeMode {
  dark('dark', 'Dark'),
  light('light', 'Light'),
  system('system', 'System');

  const HavenThemeMode(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static HavenThemeMode fromStorage(String? value) {
    return HavenThemeMode.values.firstWhere(
      (mode) => mode.storageValue == value,
      orElse: () => HavenThemeMode.dark,
    );
  }
}

enum HavenAccentColor {
  purple('purple', 'Purple', 0xFF7B61FF),
  gold('gold', 'Gold', 0xFFF2C75C),
  teal('teal', 'Teal', 0xFF5FD6C2),
  rose('rose', 'Rose', 0xFFFF7AA8);

  const HavenAccentColor(this.storageValue, this.label, this.argb);

  final String storageValue;
  final String label;
  final int argb;

  static HavenAccentColor fromStorage(String? value) {
    return HavenAccentColor.values.firstWhere(
      (accent) => accent.storageValue == value,
      orElse: () => HavenAccentColor.purple,
    );
  }
}

class AppCustomization {
  const AppCustomization({
    required this.themeMode,
    required this.accentColor,
    required this.customAccentHex,
    required this.compactDashboard,
    required this.showDashboardSubtitles,
    required this.dashboardShortcutIds,
    required this.languageCode,
  });

  final HavenThemeMode themeMode;
  final HavenAccentColor accentColor;
  final String? customAccentHex;
  final bool compactDashboard;
  final bool showDashboardSubtitles;
  final List<String> dashboardShortcutIds;
  final String languageCode;

  int get effectiveAccentArgb =>
      _argbFromHex(customAccentHex) ?? accentColor.argb;

  String get accentLabel => customAccentHex == null
      ? accentColor.label
      : 'Custom ${customAccentHex!.toUpperCase()}';

  static AppCustomization get defaults => AppCustomization(
    themeMode: HavenThemeMode.dark,
    accentColor: HavenAccentColor.purple,
    customAccentHex: null,
    compactDashboard: false,
    showDashboardSubtitles: true,
    dashboardShortcutIds: defaultDashboardShortcutIds,
    languageCode: systemLanguageCode,
  );

  AppCustomization copyWith({
    HavenThemeMode? themeMode,
    HavenAccentColor? accentColor,
    Object? customAccentHex = _unchanged,
    bool? compactDashboard,
    bool? showDashboardSubtitles,
    List<String>? dashboardShortcutIds,
    String? languageCode,
  }) {
    return AppCustomization(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      customAccentHex: identical(customAccentHex, _unchanged)
          ? this.customAccentHex
          : customAccentHex as String?,
      compactDashboard: compactDashboard ?? this.compactDashboard,
      showDashboardSubtitles:
          showDashboardSubtitles ?? this.showDashboardSubtitles,
      dashboardShortcutIds: List.unmodifiable(
        dashboardShortcutIds ?? this.dashboardShortcutIds,
      ),
      languageCode: languageCode ?? this.languageCode,
    );
  }

  SupportedLanguage get language => supportedLanguageForCode(languageCode);
}

const Object _unchanged = Object();

const defaultDashboardShortcutIds = [
  'members',
  'front-history',
  'groups',
  'notes',
  'import-export',
  'sync',
  'customize',
];

abstract interface class HavenRepository {
  Stream<HomeSnapshot> watchHomeSnapshot();

  Stream<List<MemberSummary>> watchMembers({
    bool includeArchived = false,
    bool includeCustomFronts = false,
  });

  Stream<List<GroupSummary>> watchGroups();

  Stream<List<NoteSummary>> watchNotes();

  Stream<List<MessageSummary>> watchMessages();

  Stream<List<ReminderSummary>> watchReminders();

  Stream<List<CustomFieldSummary>> watchCustomFields();

  Stream<List<CustomFieldValueSummary>> watchCustomFieldValues();

  Stream<List<PollSummary>> watchPolls();

  Stream<List<NotificationEventSummary>> watchNotificationEvents();

  Stream<List<FrontHistoryEntry>> watchFrontHistory();

  Stream<AppCustomization> watchCustomization();

  Future<AppCustomization> loadCustomization();

  Future<void> setThemeMode(HavenThemeMode mode);

  Future<void> setAccentColor(HavenAccentColor color);

  Future<void> setCustomAccentColor(String? colorHex);

  Future<void> setCompactDashboard(bool compact);

  Future<void> setShowDashboardSubtitles(bool show);

  Future<void> setDashboardShortcutIds(List<String> shortcutIds);

  Future<void> setLanguageCode(String languageCode);

  Future<void> setDashboardShortcutVisible(String shortcutId, bool visible);

  Future<void> moveDashboardShortcut(String shortcutId, int delta);

  Future<void> resetDashboardShortcuts();

  Future<void> saveMember(MemberDraft draft);

  Future<void> updateMember(String memberId, MemberDraft draft);

  Future<void> archiveMember(String memberId);

  Future<void> restoreMember(String memberId);

  Future<void> deleteMember(String memberId);

  Future<void> setFrontMembers(List<String> memberIds);

  Future<void> saveGroup(GroupDraft draft);

  Future<void> saveCustomField(CustomFieldDraft draft);

  Future<void> saveNote(NoteDraft draft);

  Future<void> deleteNote(String noteId);

  Future<void> saveMessage(MessageDraft draft);

  Future<void> saveReminder(ReminderDraft draft);

  Future<void> deleteReminder(String reminderId);

  Future<void> savePoll(PollDraft draft);

  Future<void> togglePollOption(String pollId, String optionId);

  Future<void> closePoll(String pollId);

  Future<void> deletePoll(String pollId);

  Future<void> recordNotificationEvent(NotificationEventDraft draft);

  Future<void> setCustomFront(String label);

  Future<void> clearCurrentFront();

  Future<String> buildLocalArchiveJson();

  Stream<List<BackgroundJobSummary>> watchBackgroundJobs();

  Future<String> enqueueImportArchiveJob(
    String archiveJson, {
    required ImportConflictStrategy strategy,
    String? fileName,
    required ImportSource source,
  });

  Future<bool> runBackgroundJob(String jobId);

  Future<void> importLocalArchiveJson(
    String archiveJson, {
    ImportConflictStrategy strategy = ImportConflictStrategy.skip,
    String? fileName,
    ImportSource source = ImportSource.plurisHavenArchive,
  });

  // v8: Tags

  Stream<List<Tag>> watchTags();

  Future<void> saveTag(Tag tag);

  Future<void> deleteTag(String tagId);

  Stream<List<Tag>> watchTagsForMember(String memberId);

  Future<void> setMemberTags(String memberId, List<String> tagIds);

  // v8: Journals

  Stream<List<JournalEntry>> watchJournals({String? memberId});

  Future<void> saveJournal(JournalEntry entry);

  Future<void> deleteJournal(String entryId);

  // v8: Content revisions

  Stream<List<ContentRevision>> watchRevisions(
    String targetType,
    String targetId,
  );

  Future<void> pinRevision(String revisionId);

  Future<void> unpinRevision(String revisionId);

  Future<void> restoreRevision(
    String revisionId,
    String targetType,
    String targetId,
  );

  // v8: Front audit events

  Stream<List<FrontAuditEvent>> watchFrontAuditEvents(String frontSessionId);

  // v8: Poll vote events

  Stream<List<PollVoteEvent>> watchPollVoteEvents(String pollId);

  // v8: Named fronts

  Stream<List<NamedFront>> watchNamedFronts();

  Future<void> saveNamedFront(NamedFront front, List<String> memberIds);

  Future<void> applyNamedFront(String namedFrontId);

  Future<void> deleteNamedFront(String namedFrontId);

  // v8: Pending actions

  Stream<List<PendingAction>> watchPendingActions();

  Future<void> cancelPendingAction(String actionId);

  Future<void> finalizePendingActions();

  // v8: Lexorank reordering

  Future<void> reorderMember(
    String memberId,
    String? prevRank,
    String? nextRank,
  );
}

class LocalHavenRepository implements HavenRepository {
  LocalHavenRepository(this.database, {HavenCrypto? crypto}) : _crypto = crypto;

  final AppDatabase database;
  final HavenCrypto? _crypto;

  /// Decrypts [ciphertext] using the configured [HavenCrypto], or returns
  /// [ciphertext] unchanged if no crypto is configured (plaintext dev mode).
  Future<String?> _decrypt(String? ciphertext) async {
    final crypto = _crypto;
    if (crypto == null || ciphertext == null) return ciphertext;
    try {
      return await crypto.decrypt(ciphertext);
    } on Object {
      return ciphertext;
    }
  }

  /// Encrypts [plaintext] using the configured [HavenCrypto], or returns
  /// [plaintext] unchanged if no crypto is configured (plaintext dev mode).
  Future<String?> _encrypt(String? plaintext) async {
    final crypto = _crypto;
    if (crypto == null || plaintext == null) return plaintext;
    try {
      return await crypto.encrypt(plaintext);
    } on Object {
      return plaintext;
    }
  }

  /// Computes a blind index for [plaintext] if crypto is configured.
  /// Returns null if no crypto is configured.
  Future<String?> _blindIndex(String plaintext) async {
    final crypto = _crypto;
    if (crypto == null) return null;
    try {
      return await crypto.blindIndex(plaintext);
    } on Object {
      return null;
    }
  }

  Future<void> ensureLocalSystem() async {
    final now = DateTime.now().toUtc();

    await database
        .into(database.pluralSystems)
        .insert(
          PluralSystemsCompanion.insert(
            id: localSystemId,
            name: 'Local system',
            createdAt: now,
            updatedAt: now,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  @override
  Stream<HomeSnapshot> watchHomeSnapshot() {
    return database
        .customSelect(
          _homeSnapshotSql,
          variables: _homeSnapshotVariables,
          readsFrom: {
            database.pluralSystems,
            database.members,
            database.systemGroups,
            database.notes,
            database.frontSessions,
          },
        )
        .watchSingle()
        .map(_mapHomeSnapshot);
  }

  @override
  Stream<List<BackgroundJobSummary>> watchBackgroundJobs() {
    final query = database.select(database.backgroundJobs)
      ..where((job) => job.systemId.equals(localSystemId))
      ..orderBy([
        (job) =>
            OrderingTerm(expression: job.createdAt, mode: OrderingMode.desc),
      ])
      ..limit(8);

    return query.watch().map(
      (rows) => [for (final row in rows) _backgroundJobSummary(row)],
    );
  }

  @override
  Stream<List<MemberSummary>> watchMembers({
    bool includeArchived = false,
    bool includeCustomFronts = false,
  }) {
    final query = database.select(database.members)
      ..orderBy([
        (member) =>
            OrderingTerm(expression: member.lexoRank, mode: OrderingMode.asc),
      ]);

    query.where((member) => member.systemId.equals(localSystemId));
    if (!includeArchived) {
      query.where((member) => member.archived.equals(false));
    }
    if (!includeCustomFronts) {
      query.where((member) => member.isCustomFront.equals(false));
    }

    return query.watch().asyncMap((rows) async {
      final summaries = <MemberSummary>[];
      for (final row in rows) {
        final displayName = await _decrypt(row.displayName);
        summaries.add(
          MemberSummary(
            id: row.id,
            displayName: displayName ?? row.displayName,
            pronouns: row.pronouns,
            colorHex: row.colorHex,
            description: row.description,
            avatarUrl: row.avatarUrl,
            pluralKitId: row.pluralKitId,
            archived: row.archived,
            isCustomFront: row.isCustomFront,
            frameShape: row.frameShape,
            lexoRank: row.lexoRank,
            folderId: row.folderId,
          ),
        );
      }
      return summaries;
    });
  }

  @override
  Stream<List<CustomFieldSummary>> watchCustomFields() {
    final query = database.select(database.customFieldDefinitions)
      ..where((field) => field.systemId.equals(localSystemId))
      ..orderBy([
        (field) =>
            OrderingTerm(expression: field.position, mode: OrderingMode.asc),
        (field) => OrderingTerm(expression: field.name, mode: OrderingMode.asc),
      ]);

    return query.watch().asyncMap((fields) async {
      final values = await database.select(database.customFieldValues).get();
      final valueCounts = <String, int>{};
      for (final value in values) {
        valueCounts[value.fieldId] = (valueCounts[value.fieldId] ?? 0) + 1;
      }
      return [
        for (final field in fields)
          CustomFieldSummary(
            id: field.id,
            name: field.name,
            fieldType: field.fieldType,
            privacy: field.privacy,
            position: field.position,
            valueCount: valueCounts[field.id] ?? 0,
          ),
      ];
    });
  }

  @override
  Stream<List<CustomFieldValueSummary>> watchCustomFieldValues() {
    return database
        .select(database.customFieldValues)
        .watch()
        .map(
          (rows) => [
            for (final row in rows)
              CustomFieldValueSummary(
                id: row.id,
                fieldId: row.fieldId,
                memberId: row.memberId,
                value: row.value,
              ),
          ],
        );
  }

  @override
  Stream<List<GroupSummary>> watchGroups() {
    final query = database.select(database.systemGroups)
      ..where((group) => group.systemId.equals(localSystemId))
      ..orderBy([
        (group) => OrderingTerm(expression: group.name, mode: OrderingMode.asc),
      ]);

    return query.watch().map(
      (rows) => [
        for (final row in rows)
          GroupSummary(
            id: row.id,
            name: row.name,
            parentGroupId: row.parentGroupId,
            colorHex: row.colorHex,
            description: row.description,
            emoji: row.emoji,
          ),
      ],
    );
  }

  @override
  Stream<List<NoteSummary>> watchNotes() {
    final query = database.select(database.notes)
      ..where((note) => note.systemId.equals(localSystemId))
      ..orderBy([
        (note) =>
            OrderingTerm(expression: note.updatedAt, mode: OrderingMode.desc),
      ]);

    return query.watch().map(
      (rows) => [
        for (final row in rows)
          NoteSummary(
            id: row.id,
            title: row.title,
            body: row.body,
            memberId: row.memberId,
            updatedAt: row.updatedAt,
          ),
      ],
    );
  }

  @override
  Stream<List<MessageSummary>> watchMessages() {
    final query = database.select(database.messages)
      ..where(
        (message) =>
            message.systemId.equals(localSystemId) &
            message.archived.equals(false),
      )
      ..orderBy([
        (message) => OrderingTerm(
          expression: message.createdAt,
          mode: OrderingMode.desc,
        ),
      ]);

    return query.watch().map(
      (rows) => [
        for (final row in rows)
          MessageSummary(
            id: row.id,
            body: row.body,
            memberId: row.memberId,
            createdAt: row.createdAt,
            archived: row.archived,
          ),
      ],
    );
  }

  @override
  Stream<List<ReminderSummary>> watchReminders() {
    final query = database.select(database.reminders)
      ..where((reminder) => reminder.systemId.equals(localSystemId))
      ..orderBy([
        (reminder) => OrderingTerm(
          expression: reminder.updatedAt,
          mode: OrderingMode.desc,
        ),
      ]);

    return query.watch().map(
      (rows) => [
        for (final row in rows)
          ReminderSummary(
            id: row.id,
            title: row.title,
            body: row.body,
            scheduleText: row.scheduleText,
            enabled: row.enabled,
            updatedAt: row.updatedAt,
          ),
      ],
    );
  }

  @override
  Stream<List<PollSummary>> watchPolls() {
    final query = database.select(database.polls)
      ..where((poll) => poll.systemId.equals(localSystemId))
      ..orderBy([
        (poll) =>
            OrderingTerm(expression: poll.updatedAt, mode: OrderingMode.desc),
      ]);

    return query.watch().asyncMap(_pollSummaries);
  }

  Future<List<PollSummary>> _pollSummaries(List<Poll> rows) async {
    final summaries = <PollSummary>[];
    for (final row in rows) {
      final options =
          await (database.select(database.pollOptions)
                ..where((option) => option.pollId.equals(row.id))
                ..orderBy([
                  (option) => OrderingTerm(
                    expression: option.position,
                    mode: OrderingMode.asc,
                  ),
                ]))
              .get();
      final votes = await (database.select(
        database.pollVotes,
      )..where((vote) => vote.pollId.equals(row.id))).get();
      final selectedOptionIds = votes.map((vote) => vote.optionId).toSet();

      summaries.add(
        PollSummary(
          id: row.id,
          question: row.question,
          description: row.description,
          kind: PollKind.fromStorage(row.kind),
          closed: row.closed,
          updatedAt: row.updatedAt,
          options: [
            for (final option in options)
              PollOptionSummary(
                id: option.id,
                body: option.body,
                position: option.position,
                selected: selectedOptionIds.contains(option.id),
              ),
          ],
        ),
      );
    }
    return summaries;
  }

  @override
  Stream<List<NotificationEventSummary>> watchNotificationEvents() {
    final query = database.select(database.notificationEvents)
      ..where((event) => event.systemId.equals(localSystemId))
      ..orderBy([
        (event) =>
            OrderingTerm(expression: event.createdAt, mode: OrderingMode.desc),
      ]);

    return query.watch().map(
      (rows) => [
        for (final row in rows)
          NotificationEventSummary(
            id: row.id,
            kind: row.kind,
            title: row.title,
            body: row.body,
            readAt: row.readAt,
            createdAt: row.createdAt,
          ),
      ],
    );
  }

  @override
  Stream<List<FrontHistoryEntry>> watchFrontHistory() {
    final query = database.select(database.frontSessions)
      ..where((session) => session.systemId.equals(localSystemId))
      ..orderBy([
        (session) => OrderingTerm(
          expression: session.startedAt,
          mode: OrderingMode.desc,
        ),
      ]);

    return query.watch().asyncMap(_frontHistoryEntries);
  }

  Future<List<FrontHistoryEntry>> _frontHistoryEntries(
    List<FrontSession> rows,
  ) async {
    final entries = <FrontHistoryEntry>[];
    for (final row in rows) {
      entries.add(
        FrontHistoryEntry(
          id: row.id,
          label: await _frontHistoryLabel(row),
          startedAt: row.startedAt,
          endedAt: row.endedAt,
        ),
      );
    }
    return entries;
  }

  Future<String> _frontHistoryLabel(FrontSession row) async {
    final explicit = row.label?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      return explicit;
    }

    final links = await (database.select(
      database.frontSessionMembers,
    )..where((link) => link.sessionId.equals(row.id))).get();
    if (links.isEmpty) {
      return 'Unknown front';
    }

    final memberIds = links.map((link) => link.memberId).toSet().toList();
    final members = await (database.select(
      database.members,
    )..where((member) => member.id.isIn(memberIds))).get();
    final namesById = {
      for (final member in members) member.id: member.displayName.trim(),
    };
    final names = [
      for (final link in links)
        if ((namesById[link.memberId] ?? '').isNotEmpty)
          namesById[link.memberId]!,
    ];

    return names.isEmpty ? 'Unknown front' : names.join(', ');
  }

  Future<HomeSnapshot> loadHomeSnapshot() async {
    final row = await database
        .customSelect(_homeSnapshotSql, variables: _homeSnapshotVariables)
        .getSingle();

    return _mapHomeSnapshot(row);
  }

  @override
  Stream<AppCustomization> watchCustomization() {
    return database
        .select(database.appPreferences)
        .watch()
        .map(_mapCustomizationRows);
  }

  @override
  Future<AppCustomization> loadCustomization() async {
    final rows = await database.select(database.appPreferences).get();
    return _mapCustomizationRows(rows);
  }

  String get _homeSnapshotSql => '''
SELECT
  COALESCE((SELECT name FROM plural_systems WHERE id = ? LIMIT 1), 'Local system') AS system_name,
  (SELECT COUNT(*) FROM members WHERE system_id = ? AND archived = 0 AND is_custom_front = 0) AS member_count,
  (SELECT COUNT(*) FROM system_groups WHERE system_id = ?) AS group_count,
  (SELECT COUNT(*) FROM notes WHERE system_id = ?) AS note_count,
  (SELECT COUNT(*) FROM front_sessions WHERE system_id = ?) AS front_history_count,
  (
    SELECT label
    FROM front_sessions
    WHERE system_id = ? AND ended_at IS NULL
    ORDER BY started_at DESC
    LIMIT 1
  ) AS current_front_label
          ''';

  List<Variable<String>> get _homeSnapshotVariables =>
      List.filled(6, Variable<String>(localSystemId));

  HomeSnapshot _mapHomeSnapshot(QueryRow row) {
    final data = row.data;

    return HomeSnapshot(
      systemName: data['system_name'] as String,
      memberCount: data['member_count'] as int,
      groupCount: data['group_count'] as int,
      noteCount: data['note_count'] as int,
      frontHistoryCount: data['front_history_count'] as int,
      currentFrontLabel: data['current_front_label'] as String?,
    );
  }

  AppCustomization _mapCustomizationRows(List<AppPreference> rows) {
    final values = {for (final row in rows) row.key: row.value};

    return AppCustomization(
      themeMode: HavenThemeMode.fromStorage(values[_themeModeKey]),
      accentColor: HavenAccentColor.fromStorage(values[_accentColorKey]),
      customAccentHex: _normalizeHexColor(values[_customAccentHexKey]),
      compactDashboard: _readBool(values[_compactDashboardKey]),
      showDashboardSubtitles: _readBool(
        values[_showDashboardSubtitlesKey],
        defaultValue: true,
      ),
      dashboardShortcutIds: _readShortcutIds(values[_dashboardShortcutIdsKey]),
      languageCode: _readLanguageCode(values[_languageCodeKey]),
    );
  }

  bool _readBool(String? value, {bool defaultValue = false}) {
    if (value == null) {
      return defaultValue;
    }

    return value == 'true';
  }

  List<String> _readShortcutIds(String? value) {
    if (value == null) {
      return defaultDashboardShortcutIds;
    }

    final stored = value.trim();
    if (stored == _emptyShortcutIdsValue) {
      return const [];
    }
    if (stored.isEmpty) {
      return defaultDashboardShortcutIds;
    }

    final ids = stored
        .split(',')
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList();

    if (ids.isEmpty) {
      return defaultDashboardShortcutIds;
    }

    return List.unmodifiable(ids);
  }

  String _readLanguageCode(String? value) {
    return supportedLanguageForCode(value).code;
  }

  @override
  Future<void> setThemeMode(HavenThemeMode mode) {
    return _writePreference(_themeModeKey, mode.storageValue);
  }

  @override
  Future<void> setAccentColor(HavenAccentColor color) async {
    await _writePreference(_accentColorKey, color.storageValue);
    await _writePreference(_customAccentHexKey, '');
  }

  @override
  Future<void> setCustomAccentColor(String? colorHex) {
    return _writePreference(
      _customAccentHexKey,
      _normalizeHexColor(colorHex) ?? '',
    );
  }

  @override
  Future<void> setCompactDashboard(bool compact) {
    return _writePreference(_compactDashboardKey, compact.toString());
  }

  @override
  Future<void> setShowDashboardSubtitles(bool show) {
    return _writePreference(_showDashboardSubtitlesKey, show.toString());
  }

  @override
  Future<void> setDashboardShortcutIds(List<String> shortcutIds) {
    return _writePreference(
      _dashboardShortcutIdsKey,
      _serializeIds(shortcutIds),
    );
  }

  @override
  Future<void> setLanguageCode(String languageCode) {
    return _writePreference(
      _languageCodeKey,
      supportedLanguageForCode(languageCode).code,
    );
  }

  @override
  Future<void> setDashboardShortcutVisible(
    String shortcutId,
    bool visible,
  ) async {
    final customization = await loadCustomization();
    final ids = customization.dashboardShortcutIds.toList();
    final existingIndex = ids.indexOf(shortcutId);

    if (visible && existingIndex == -1) {
      ids.add(shortcutId);
    } else if (!visible && existingIndex != -1) {
      ids.removeAt(existingIndex);
    }

    await setDashboardShortcutIds(ids);
  }

  @override
  Future<void> moveDashboardShortcut(String shortcutId, int delta) async {
    if (delta == 0) {
      return;
    }

    final customization = await loadCustomization();
    final ids = customization.dashboardShortcutIds.toList();
    final index = ids.indexOf(shortcutId);
    if (index == -1) {
      return;
    }

    final newIndex = (index + delta).clamp(0, ids.length - 1);
    if (newIndex == index) {
      return;
    }

    final id = ids.removeAt(index);
    ids.insert(newIndex, id);
    await setDashboardShortcutIds(ids);
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

    final now = DateTime.now().toUtc();
    final encryptedName = await _encrypt(displayName);
    final nameHash = await _blindIndex(displayName);
    await database
        .into(database.members)
        .insert(
          MembersCompanion.insert(
            id: 'member-${now.microsecondsSinceEpoch}',
            systemId: localSystemId,
            displayName: encryptedName ?? displayName,
            displayNameHash: Value(nameHash),
            pronouns: Value(_nullIfBlank(draft.pronouns)),
            colorHex: Value(_nullIfBlank(draft.colorHex)),
            description: Value(_nullIfBlank(draft.description)),
            avatarUrl: Value(_nullIfBlank(draft.avatarUrl)),
            pluralKitId: Value(_nullIfBlank(draft.pluralKitId)),
            folderId: Value(_nullIfBlank(draft.folderId)),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  @override
  Future<void> archiveMember(String memberId) async {
    final now = DateTime.now().toUtc();
    await (database.update(database.members)..where(
          (member) =>
              member.systemId.equals(localSystemId) &
              member.id.equals(memberId),
        ))
        .write(
          MembersCompanion(archived: const Value(true), updatedAt: Value(now)),
        );
  }

  @override
  Future<void> updateMember(String memberId, MemberDraft draft) async {
    final displayName = draft.displayName.trim();
    if (displayName.isEmpty) {
      return;
    }

    final now = DateTime.now().toUtc();
    final encryptedName = await _encrypt(displayName);
    final nameHash = await _blindIndex(displayName);
    await (database.update(database.members)..where(
          (member) =>
              member.systemId.equals(localSystemId) &
              member.id.equals(memberId),
        ))
        .write(
          MembersCompanion(
            displayName: Value(encryptedName ?? displayName),
            displayNameHash: Value(nameHash),
            pronouns: Value(_nullIfBlank(draft.pronouns)),
            colorHex: Value(_nullIfBlank(draft.colorHex)),
            description: Value(_nullIfBlank(draft.description)),
            avatarUrl: Value(_nullIfBlank(draft.avatarUrl)),
            pluralKitId: Value(_nullIfBlank(draft.pluralKitId)),
            folderId: Value(_nullIfBlank(draft.folderId)),
            updatedAt: Value(now),
          ),
        );
  }

  @override
  Future<void> restoreMember(String memberId) async {
    final now = DateTime.now().toUtc();
    await (database.update(database.members)..where(
          (member) =>
              member.systemId.equals(localSystemId) &
              member.id.equals(memberId),
        ))
        .write(
          MembersCompanion(archived: const Value(false), updatedAt: Value(now)),
        );
  }

  @override
  Future<void> deleteMember(String memberId) async {
    await database.transaction(() async {
      await (database.delete(
        database.frontSessionMembers,
      )..where((frontMember) => frontMember.memberId.equals(memberId))).go();
      await (database.delete(database.members)..where(
            (member) =>
                member.systemId.equals(localSystemId) &
                member.id.equals(memberId),
          ))
          .go();
    });
  }

  @override
  Future<void> setFrontMembers(List<String> memberIds) async {
    final ids = memberIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (ids.isEmpty) {
      return clearCurrentFront();
    }

    final members =
        await (database.select(database.members)..where(
              (member) =>
                  member.systemId.equals(localSystemId) &
                  member.archived.equals(false) &
                  member.isCustomFront.equals(false) &
                  member.id.isIn(ids),
            ))
            .get();
    if (members.isEmpty) {
      return clearCurrentFront();
    }

    final now = DateTime.now().toUtc();
    final label = members.map((member) => member.displayName).join(', ');

    await database.transaction(() async {
      await _endOpenFrontSessions(now);
      final sessionId = 'front-${now.microsecondsSinceEpoch}';

      await database
          .into(database.frontSessions)
          .insert(
            FrontSessionsCompanion.insert(
              id: sessionId,
              systemId: localSystemId,
              label: Value(label),
              startedAt: now,
              createdAt: now,
              updatedAt: now,
            ),
          );

      await database.batch((batch) {
        batch.insertAll(database.frontSessionMembers, [
          for (final member in members)
            FrontSessionMembersCompanion.insert(
              sessionId: sessionId,
              memberId: member.id,
            ),
        ]);
      });
    });
  }

  @override
  Future<void> saveGroup(GroupDraft draft) async {
    final name = draft.name.trim();
    if (name.isEmpty) {
      return;
    }

    final now = DateTime.now().toUtc();
    await database
        .into(database.systemGroups)
        .insert(
          SystemGroupsCompanion.insert(
            id: 'group-${now.microsecondsSinceEpoch}',
            systemId: localSystemId,
            name: name,
            parentGroupId: Value(_nullIfBlank(draft.parentGroupId)),
            colorHex: Value(_nullIfBlank(draft.colorHex)),
            description: Value(_nullIfBlank(draft.description)),
            emoji: Value(_nullIfBlank(draft.emoji)),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  @override
  Future<void> saveCustomField(CustomFieldDraft draft) async {
    final name = draft.name.trim();
    if (name.isEmpty) {
      return;
    }

    final fieldType = _allowedCustomFieldTypes.contains(draft.fieldType)
        ? draft.fieldType
        : 'text';
    final now = DateTime.now().toUtc();
    final maxPosition =
        await (database.selectOnly(database.customFieldDefinitions)
              ..addColumns([database.customFieldDefinitions.position.max()])
              ..where(
                database.customFieldDefinitions.systemId.equals(localSystemId),
              ))
            .map(
              (row) => row.read(database.customFieldDefinitions.position.max()),
            )
            .getSingleOrNull();

    await database
        .into(database.customFieldDefinitions)
        .insert(
          CustomFieldDefinitionsCompanion.insert(
            id: 'custom-field-${now.microsecondsSinceEpoch}',
            systemId: localSystemId,
            name: name,
            fieldType: Value(fieldType),
            privacy: Value(_nullIfBlank(draft.privacy)),
            position: Value((maxPosition ?? -1) + 1),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  @override
  Future<void> saveNote(NoteDraft draft) async {
    final title = draft.title.trim();
    final body = draft.body.trim();
    if (title.isEmpty && body.isEmpty) {
      return;
    }

    final now = DateTime.now().toUtc();
    await database
        .into(database.notes)
        .insert(
          NotesCompanion.insert(
            id: 'note-${now.microsecondsSinceEpoch}',
            systemId: localSystemId,
            memberId: Value(_nullIfBlank(draft.memberId)),
            title: title.isEmpty ? 'Untitled note' : title,
            body: body,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  @override
  Future<void> deleteNote(String noteId) {
    return (database.delete(database.notes)..where(
          (note) =>
              note.systemId.equals(localSystemId) & note.id.equals(noteId),
        ))
        .go();
  }

  @override
  Future<void> saveMessage(MessageDraft draft) async {
    final body = draft.body.trim();
    if (body.isEmpty) {
      return;
    }

    final now = DateTime.now().toUtc();
    await database
        .into(database.messages)
        .insert(
          MessagesCompanion.insert(
            id: 'message-${now.microsecondsSinceEpoch}',
            systemId: localSystemId,
            memberId: Value(_nullIfBlank(draft.memberId)),
            body: body,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  @override
  Future<void> saveReminder(ReminderDraft draft) async {
    final title = draft.title.trim();
    final scheduleText = draft.scheduleText.trim();
    if (title.isEmpty || scheduleText.isEmpty) {
      return;
    }

    final now = DateTime.now().toUtc();
    await database
        .into(database.reminders)
        .insert(
          RemindersCompanion.insert(
            id: 'reminder-${now.microsecondsSinceEpoch}',
            systemId: localSystemId,
            title: title,
            body: Value(_nullIfBlank(draft.body)),
            scheduleText: scheduleText,
            enabled: Value(draft.enabled),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  @override
  Future<void> deleteReminder(String reminderId) {
    return (database.delete(database.reminders)..where(
          (reminder) =>
              reminder.systemId.equals(localSystemId) &
              reminder.id.equals(reminderId),
        ))
        .go();
  }

  @override
  Future<void> savePoll(PollDraft draft) async {
    final question = draft.question.trim();
    final options = _cleanPollOptions(draft.options);
    if (question.isEmpty || options.length < 2) {
      return;
    }

    final now = DateTime.now().toUtc();
    final pollId = 'poll-${now.microsecondsSinceEpoch}';
    await database.transaction(() async {
      await database
          .into(database.polls)
          .insert(
            PollsCompanion.insert(
              id: pollId,
              systemId: localSystemId,
              question: question,
              description: Value(_nullIfBlank(draft.description)),
              kind: Value(draft.kind.storageValue),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await database.batch((batch) {
        batch.insertAll(database.pollOptions, [
          for (var index = 0; index < options.length; index++)
            PollOptionsCompanion.insert(
              id: '$pollId-option-$index',
              pollId: pollId,
              body: options[index],
              position: index,
            ),
        ]);
      });
    });
  }

  @override
  Future<void> togglePollOption(String pollId, String optionId) async {
    final poll =
        await (database.select(database.polls)..where(
              (poll) =>
                  poll.systemId.equals(localSystemId) & poll.id.equals(pollId),
            ))
            .getSingleOrNull();
    if (poll == null || poll.closed) {
      return;
    }

    final option =
        await (database.select(database.pollOptions)..where(
              (option) =>
                  option.pollId.equals(pollId) & option.id.equals(optionId),
            ))
            .getSingleOrNull();
    if (option == null) {
      return;
    }

    final existing =
        await (database.select(database.pollVotes)..where(
              (vote) =>
                  vote.pollId.equals(pollId) & vote.optionId.equals(optionId),
            ))
            .getSingleOrNull();
    final now = DateTime.now().toUtc();

    await database.transaction(() async {
      if (PollKind.fromStorage(poll.kind) == PollKind.singleChoice) {
        await (database.delete(
          database.pollVotes,
        )..where((vote) => vote.pollId.equals(pollId))).go();
        if (existing == null) {
          await database
              .into(database.pollVotes)
              .insert(
                PollVotesCompanion.insert(
                  pollId: pollId,
                  optionId: optionId,
                  createdAt: now,
                ),
              );
        }
      } else if (existing == null) {
        await database
            .into(database.pollVotes)
            .insert(
              PollVotesCompanion.insert(
                pollId: pollId,
                optionId: optionId,
                createdAt: now,
              ),
            );
      } else {
        await (database.delete(database.pollVotes)..where(
              (vote) =>
                  vote.pollId.equals(pollId) & vote.optionId.equals(optionId),
            ))
            .go();
      }

      await (database.update(database.polls)
            ..where((poll) => poll.id.equals(pollId)))
          .write(PollsCompanion(updatedAt: Value(now)));
    });
  }

  @override
  Future<void> closePoll(String pollId) {
    final now = DateTime.now().toUtc();
    return (database.update(database.polls)..where(
          (poll) =>
              poll.systemId.equals(localSystemId) & poll.id.equals(pollId),
        ))
        .write(
          PollsCompanion(closed: const Value(true), updatedAt: Value(now)),
        );
  }

  @override
  Future<void> deletePoll(String pollId) {
    return database.transaction(() async {
      await (database.delete(
        database.pollVotes,
      )..where((vote) => vote.pollId.equals(pollId))).go();
      await (database.delete(
        database.pollOptions,
      )..where((option) => option.pollId.equals(pollId))).go();
      await (database.delete(database.polls)..where(
            (poll) =>
                poll.systemId.equals(localSystemId) & poll.id.equals(pollId),
          ))
          .go();
    });
  }

  @override
  Future<void> recordNotificationEvent(NotificationEventDraft draft) async {
    final title = draft.title.trim();
    final body = draft.body.trim();
    if (title.isEmpty && body.isEmpty) {
      return;
    }

    final now = DateTime.now().toUtc();
    await database
        .into(database.notificationEvents)
        .insert(
          NotificationEventsCompanion.insert(
            id: 'notification-${now.microsecondsSinceEpoch}',
            systemId: localSystemId,
            kind: draft.kind.trim().isEmpty ? 'general' : draft.kind.trim(),
            title: title.isEmpty ? 'Notification' : title,
            body: body,
            createdAt: now,
          ),
        );
  }

  String _serializeIds(List<String> shortcutIds) {
    final seen = <String>{};
    final ids = <String>[];
    for (final id in shortcutIds) {
      final trimmed = id.trim();
      if (trimmed.isEmpty || !seen.add(trimmed)) {
        continue;
      }
      ids.add(trimmed);
    }
    return ids.isEmpty ? _emptyShortcutIdsValue : ids.join(',');
  }

  List<String> _cleanPollOptions(List<String> options) {
    final seen = <String>{};
    final cleaned = <String>[];
    for (final option in options) {
      final trimmed = option.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      final key = trimmed.toLowerCase();
      if (seen.add(key)) {
        cleaned.add(trimmed);
      }
    }
    return cleaned;
  }

  Future<void> _writePreference(String key, String value) {
    final now = DateTime.now().toUtc();

    return database
        .into(database.appPreferences)
        .insertOnConflictUpdate(
          AppPreferencesCompanion.insert(
            key: key,
            value: value,
            updatedAt: now,
          ),
        );
  }

  @override
  Future<void> setCustomFront(String label) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty) {
      return clearCurrentFront();
    }

    final now = DateTime.now().toUtc();

    await database.transaction(() async {
      await _endOpenFrontSessions(now);

      await database
          .into(database.frontSessions)
          .insert(
            FrontSessionsCompanion.insert(
              id: 'front-${now.microsecondsSinceEpoch}',
              systemId: localSystemId,
              label: Value(trimmed),
              startedAt: now,
              createdAt: now,
              updatedAt: now,
            ),
          );
    });
  }

  @override
  Future<void> clearCurrentFront() async {
    final now = DateTime.now().toUtc();
    await _endOpenFrontSessions(now);
  }

  @override
  Future<String> buildLocalArchiveJson() async {
    final systems = await (database.select(
      database.pluralSystems,
    )..where((system) => system.id.equals(localSystemId))).get();
    final members = await (database.select(
      database.members,
    )..where((member) => member.systemId.equals(localSystemId))).get();
    final groups = await (database.select(
      database.systemGroups,
    )..where((group) => group.systemId.equals(localSystemId))).get();
    final notes = await (database.select(
      database.notes,
    )..where((note) => note.systemId.equals(localSystemId))).get();
    final messages = await (database.select(
      database.messages,
    )..where((message) => message.systemId.equals(localSystemId))).get();
    final reminders = await (database.select(
      database.reminders,
    )..where((reminder) => reminder.systemId.equals(localSystemId))).get();
    final customFields = await (database.select(
      database.customFieldDefinitions,
    )..where((field) => field.systemId.equals(localSystemId))).get();
    final customFieldIds = customFields.map((field) => field.id).toSet();
    final customFieldValues = await database
        .select(database.customFieldValues)
        .get();
    final polls = await (database.select(
      database.polls,
    )..where((poll) => poll.systemId.equals(localSystemId))).get();
    final pollIds = polls.map((poll) => poll.id).toSet();
    final pollOptions = await database.select(database.pollOptions).get();
    final pollVotes = await database.select(database.pollVotes).get();
    final fronts = await (database.select(
      database.frontSessions,
    )..where((front) => front.systemId.equals(localSystemId))).get();
    final frontIds = fronts.map((front) => front.id).toSet();
    final frontMembers = await database
        .select(database.frontSessionMembers)
        .get();
    final namedFronts = await (database.select(
      database.namedFronts,
    )..where((front) => front.systemId.equals(localSystemId))).get();
    final namedFrontIds = namedFronts.map((front) => front.id).toSet();
    final namedFrontMembers = await database
        .select(database.namedFrontMembers)
        .get();
    final importRecords = await (database.select(
      database.importRecords,
    )..where((record) => record.systemId.equals(localSystemId))).get();
    final importPayloads = await (database.select(
      database.importPayloads,
    )..where((payload) => payload.systemId.equals(localSystemId))).get();
    final notificationEvents = await (database.select(
      database.notificationEvents,
    )..where((event) => event.systemId.equals(localSystemId))).get();
    final preferences = await database.select(database.appPreferences).get();

    final archive = {
      'format': 'pluris_haven.local_archive',
      'version': 1,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'system': systems.isEmpty ? null : _systemToJson(systems.single),
      'members': [for (final member in members) _memberToJson(member)],
      'groups': [for (final group in groups) _groupToJson(group)],
      'notes': [for (final note in notes) _noteToJson(note)],
      'messages': [for (final message in messages) _messageToJson(message)],
      'reminders': [
        for (final reminder in reminders) _reminderToJson(reminder),
      ],
      'custom_fields': [
        for (final field in customFields) _customFieldToJson(field),
      ],
      'custom_field_values': [
        for (final value in customFieldValues)
          if (customFieldIds.contains(value.fieldId))
            _customFieldValueToJson(value),
      ],
      'polls': [for (final poll in polls) _pollToJson(poll)],
      'poll_options': [
        for (final option in pollOptions)
          if (pollIds.contains(option.pollId)) _pollOptionToJson(option),
      ],
      'poll_votes': [
        for (final vote in pollVotes)
          if (pollIds.contains(vote.pollId)) _pollVoteToJson(vote),
      ],
      'fronts': [for (final front in fronts) _frontToJson(front)],
      'front_members': [
        for (final link in frontMembers)
          if (frontIds.contains(link.sessionId)) _frontMemberToJson(link),
      ],
      'named_fronts': [
        for (final front in namedFronts) _namedFrontToJson(front),
      ],
      'named_front_members': [
        for (final link in namedFrontMembers)
          if (namedFrontIds.contains(link.namedFrontId))
            _namedFrontMemberToJson(link),
      ],
      'import_records': [
        for (final record in importRecords) _importRecordToJson(record),
      ],
      'raw_payloads': [
        for (final payload in importPayloads) _importPayloadToJson(payload),
      ],
      'notification_events': [
        for (final event in notificationEvents) _notificationEventToJson(event),
      ],
      'preferences': [
        for (final preference in preferences) _preferenceToJson(preference),
      ],
    };

    return const JsonEncoder.withIndent('  ').convert(archive);
  }

  @override
  Future<String> enqueueImportArchiveJob(
    String archiveJson, {
    required ImportConflictStrategy strategy,
    String? fileName,
    required ImportSource source,
  }) async {
    final now = DateTime.now().toUtc();
    final jobId = 'job-${now.microsecondsSinceEpoch}';
    appDebugLog(
      'Queue import job id=$jobId source=${source.name} file=${fileName ?? '(none)'} strategy=${strategy.name}',
    );
    await database
        .into(database.backgroundJobs)
        .insert(
          BackgroundJobsCompanion.insert(
            id: jobId,
            systemId: localSystemId,
            type: 'import_archive',
            status: 'queued',
            source: Value(source.name),
            fileName: Value(_nullIfBlank(fileName)),
            payloadJson: jsonEncode({
              'archive_json': archiveJson,
              'strategy': strategy.name,
            }),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return jobId;
  }

  @override
  Future<bool> runBackgroundJob(String jobId) async {
    final job = await (database.select(
      database.backgroundJobs,
    )..where((job) => job.id.equals(jobId))).getSingleOrNull();
    if (job == null || job.status == 'done') {
      appDebugLog(
        'Skip background job id=$jobId status=${job?.status ?? 'missing'}',
      );
      return true;
    }

    final now = DateTime.now().toUtc();
    appDebugLog(
      'Run background job id=$jobId type=${job.type} source=${job.source}',
    );
    await (database.update(
      database.backgroundJobs,
    )..where((job) => job.id.equals(jobId))).write(
      BackgroundJobsCompanion(
        status: const Value('running'),
        error: const Value(null),
        startedAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    try {
      if (job.type == 'import_archive') {
        final payload = jsonDecode(job.payloadJson);
        if (payload is! Map<String, Object?>) {
          throw const FormatException('Import job payload is invalid.');
        }
        final source = ImportSource.values.firstWhere(
          (source) => source.name == job.source,
          orElse: () => ImportSource.plurisHavenArchive,
        );
        final strategyName = _stringValue(payload['strategy']);
        final strategy = ImportConflictStrategy.values.firstWhere(
          (strategy) => strategy.name == strategyName,
          orElse: () => ImportConflictStrategy.skip,
        );
        await importLocalArchiveJson(
          _requiredString(payload, 'archive_json'),
          strategy: strategy,
          fileName: job.fileName,
          source: source,
        );
      } else {
        throw FormatException('Unsupported background job type: ${job.type}.');
      }

      final finished = DateTime.now().toUtc();
      appDebugLog('Background job complete id=$jobId');
      await (database.update(
        database.backgroundJobs,
      )..where((job) => job.id.equals(jobId))).write(
        BackgroundJobsCompanion(
          status: const Value('done'),
          updatedAt: Value(finished),
          finishedAt: Value(finished),
        ),
      );
      return true;
    } on Object catch (error, stackTrace) {
      appDebugLog(
        'Background job failed id=$jobId',
        error: error,
        stackTrace: stackTrace,
      );
      final failed = DateTime.now().toUtc();
      final errorText = _debugErrorText(error, stackTrace);
      await (database.update(
        database.backgroundJobs,
      )..where((job) => job.id.equals(jobId))).write(
        BackgroundJobsCompanion(
          status: const Value('failed'),
          error: Value(errorText),
          updatedAt: Value(failed),
          finishedAt: Value(failed),
        ),
      );
      return false;
    }
  }

  @override
  Future<void> importLocalArchiveJson(
    String archiveJson, {
    ImportConflictStrategy strategy = ImportConflictStrategy.skip,
    String? fileName,
    ImportSource source = ImportSource.plurisHavenArchive,
  }) async {
    final decoded = jsonDecode(archiveJson);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Expected a JSON object archive.');
    }
    if (decoded['format'] != 'pluris_haven.local_archive') {
      throw const FormatException('Unsupported archive format.');
    }
    if (decoded['version'] != 1) {
      throw FormatException(
        'Unsupported archive version: ${decoded['version']}.',
      );
    }

    final now = DateTime.now().toUtc();
    final members = _jsonObjectList(decoded['members']);
    final groups = _jsonObjectList(decoded['groups']);
    final notes = _jsonObjectList(decoded['notes']);
    final messages = _jsonObjectList(decoded['messages']);
    final reminders = _jsonObjectList(decoded['reminders']);
    final customFields = _jsonObjectList(decoded['custom_fields']);
    final customFieldValues = _jsonObjectList(decoded['custom_field_values']);
    final polls = _jsonObjectList(decoded['polls']);
    final pollOptions = _jsonObjectList(decoded['poll_options']);
    final pollVotes = _jsonObjectList(decoded['poll_votes']);
    final fronts = _jsonObjectList(decoded['fronts']);
    final frontMembers = _jsonObjectList(decoded['front_members']);
    final namedFronts = _jsonObjectList(decoded['named_fronts']);
    final namedFrontMembers = _jsonObjectList(decoded['named_front_members']);
    final avatarAssets = _jsonObjectList(decoded['avatar_assets']);
    final rawPayloads = _jsonObjectList(decoded['raw_payloads']);
    final notificationEvents = _jsonObjectList(decoded['notification_events']);
    final preferences = _jsonObjectList(decoded['preferences']);
    final cleanupCount = _sanitizeArchiveReferences(
      groups: groups,
      members: members,
      notes: notes,
      messages: messages,
      customFields: customFields,
      customFieldValues: customFieldValues,
      polls: polls,
      pollOptions: pollOptions,
      pollVotes: pollVotes,
      fronts: fronts,
      frontMembers: frontMembers,
      namedFronts: namedFronts,
      namedFrontMembers: namedFrontMembers,
    );
    appDebugLog(
      'Import archive source=${source.name} file=${fileName ?? '(none)'} '
      'members=${members.length} groups=${groups.length} notes=${notes.length} '
      'messages=${messages.length} reminders=${reminders.length} fronts=${fronts.length} '
      'namedFronts=${namedFronts.length} '
      'customFields=${customFields.length} customFieldValues=${customFieldValues.length} '
      'polls=${polls.length} pollOptions=${pollOptions.length} pollVotes=${pollVotes.length} '
      'frontMembers=${frontMembers.length} cleanup=$cleanupCount',
    );
    final localAvatarRefs = await _localizeImportAvatars(
      members: members,
      avatarAssets: avatarAssets,
    );

    await database.transaction(() async {
      final system = decoded['system'];
      if (system is Map<String, Object?>) {
        final name = _stringValue(system['name'])?.trim();
        if (name != null && name.isNotEmpty) {
          await database
              .into(database.pluralSystems)
              .insertOnConflictUpdate(
                PluralSystemsCompanion.insert(
                  id: localSystemId,
                  name: name,
                  createdAt: _dateValue(system['created_at']) ?? now,
                  updatedAt: now,
                ),
              );
        }
      }

      for (final group in groups) {
        await _importGroup(group, strategy, now);
      }
      for (final member in members) {
        await _importMember(
          member,
          strategy,
          now,
          localAvatarRefs[_requiredString(member, 'id')],
        );
      }
      for (final note in notes) {
        await _importNote(note, strategy, now);
      }
      for (final message in messages) {
        await _importMessage(message, strategy, now);
      }
      for (final reminder in reminders) {
        await _importReminder(reminder, strategy, now);
      }
      for (final field in customFields) {
        await _importCustomField(field, strategy, now);
      }
      for (final value in customFieldValues) {
        await _importCustomFieldValue(value, strategy, now);
      }
      for (final poll in polls) {
        await _importPoll(poll, strategy, now);
      }
      for (final option in pollOptions) {
        await _importPollOption(option, strategy);
      }
      for (final vote in pollVotes) {
        await _importPollVote(vote);
      }
      for (final front in fronts) {
        await _importFront(front, strategy, now);
      }
      for (final link in frontMembers) {
        await _importFrontMember(link);
      }
      for (final namedFront in namedFronts) {
        await _importNamedFront(namedFront, strategy, now);
      }
      for (final link in namedFrontMembers) {
        await _importNamedFrontMember(link);
      }
      for (final event in notificationEvents) {
        await _importNotificationEvent(event, strategy, now);
      }
      for (final preference in preferences) {
        await _importPreference(preference, strategy, now);
      }

      final importRecordId = 'import-${now.microsecondsSinceEpoch}';
      await database
          .into(database.importRecords)
          .insert(
            ImportRecordsCompanion.insert(
              id: importRecordId,
              systemId: localSystemId,
              source: source.jobSource,
              fileName: Value(_nullIfBlank(fileName)),
              summaryJson: Value(
                jsonEncode({
                  'members': members.length,
                  'groups': groups.length,
                  'notes': notes.length,
                  'messages': messages.length,
                  'reminders': reminders.length,
                  'custom_fields': customFields.length,
                  'custom_field_values': customFieldValues.length,
                  'polls': polls.length,
                  'poll_options': pollOptions.length,
                  'poll_votes': pollVotes.length,
                  'fronts': fronts.length,
                  'front_members': frontMembers.length,
                  'named_fronts': namedFronts.length,
                  'named_front_members': namedFrontMembers.length,
                  'avatar_assets': avatarAssets.length,
                  'raw_payloads': rawPayloads.length,
                  'notification_events': notificationEvents.length,
                  'preferences': preferences.length,
                }),
              ),
              importedAt: now,
            ),
          );

      for (final payload in rawPayloads) {
        await _importPayload(payload, importRecordId, source, strategy, now);
      }
    });
  }

  int _sanitizeArchiveReferences({
    required List<Map<String, Object?>> groups,
    required List<Map<String, Object?>> members,
    required List<Map<String, Object?>> notes,
    required List<Map<String, Object?>> messages,
    required List<Map<String, Object?>> customFields,
    required List<Map<String, Object?>> customFieldValues,
    required List<Map<String, Object?>> polls,
    required List<Map<String, Object?>> pollOptions,
    required List<Map<String, Object?>> pollVotes,
    required List<Map<String, Object?>> fronts,
    required List<Map<String, Object?>> frontMembers,
    required List<Map<String, Object?>> namedFronts,
    required List<Map<String, Object?>> namedFrontMembers,
  }) {
    final groupIds = {
      for (final group in groups) _stringValue(group['id']),
    }.whereType<String>().toSet();
    final memberIds = {
      for (final member in members) _stringValue(member['id']),
    }.whereType<String>().toSet();
    final customFieldIds = {
      for (final field in customFields) _stringValue(field['id']),
    }.whereType<String>().toSet();
    final pollIds = {
      for (final poll in polls) _stringValue(poll['id']),
    }.whereType<String>().toSet();
    final pollOptionIds = {
      for (final option in pollOptions) _stringValue(option['id']),
    }.whereType<String>().toSet();
    final frontIds = {
      for (final front in fronts) _stringValue(front['id']),
    }.whereType<String>().toSet();
    final namedFrontIds = {
      for (final front in namedFronts) _stringValue(front['id']),
    }.whereType<String>().toSet();
    var cleanupCount = 0;

    for (final group in groups) {
      final parentId = _stringValue(group['parent_group_id']);
      if (parentId != null && !groupIds.contains(parentId)) {
        group['parent_group_id'] = null;
        cleanupCount++;
      }
    }

    for (final member in members) {
      final groupId = _stringValue(member['folder_id']);
      if (groupId != null && !groupIds.contains(groupId)) {
        member['folder_id'] = null;
        cleanupCount++;
      }
    }

    for (final note in notes) {
      final memberId = _stringValue(note['member_id']);
      if (memberId != null && !memberIds.contains(memberId)) {
        note['member_id'] = null;
        cleanupCount++;
      }
    }

    for (final message in messages) {
      final memberId = _stringValue(message['member_id']);
      if (memberId != null && !memberIds.contains(memberId)) {
        message['member_id'] = null;
        cleanupCount++;
      }
    }

    customFieldValues.removeWhere((value) {
      final fieldId = _stringValue(value['field_id']);
      final memberId = _stringValue(value['member_id']);
      final keep =
          fieldId != null &&
          customFieldIds.contains(fieldId) &&
          (memberId == null || memberIds.contains(memberId));
      if (!keep) {
        cleanupCount++;
      }
      return !keep;
    });

    pollOptions.removeWhere((option) {
      final pollId = _stringValue(option['poll_id']);
      final keep = pollId != null && pollIds.contains(pollId);
      if (!keep) {
        cleanupCount++;
      }
      return !keep;
    });

    pollVotes.removeWhere((vote) {
      final pollId = _stringValue(vote['poll_id']);
      final optionId = _stringValue(vote['option_id']);
      final keep =
          pollId != null &&
          optionId != null &&
          pollIds.contains(pollId) &&
          pollOptionIds.contains(optionId);
      if (!keep) {
        cleanupCount++;
      }
      return !keep;
    });

    frontMembers.removeWhere((link) {
      final sessionId = _stringValue(link['session_id']);
      final memberId = _stringValue(link['member_id']);
      final keep =
          sessionId != null &&
          memberId != null &&
          frontIds.contains(sessionId) &&
          memberIds.contains(memberId);
      if (!keep) {
        cleanupCount++;
      }
      return !keep;
    });

    namedFrontMembers.removeWhere((link) {
      final namedFrontId = _stringValue(link['named_front_id']);
      final memberId = _stringValue(link['member_id']);
      final keep =
          namedFrontId != null &&
          memberId != null &&
          namedFrontIds.contains(namedFrontId) &&
          memberIds.contains(memberId);
      if (!keep) {
        cleanupCount++;
      }
      return !keep;
    });

    return cleanupCount;
  }

  Future<Map<String, String?>> _localizeImportAvatars({
    required List<Map<String, Object?>> members,
    required List<Map<String, Object?>> avatarAssets,
  }) async {
    final assetsById = <String, _ImportAvatarBytes>{};
    for (final asset in avatarAssets) {
      final id = _stringValue(asset['id']);
      final encodedBytes = _stringValue(asset['bytes_base64']);
      if (id == null || encodedBytes == null) {
        continue;
      }
      try {
        assetsById[id] = _ImportAvatarBytes(
          id: id,
          name: _stringValue(asset['name']) ?? id,
          mimeType: _stringValue(asset['mime_type']),
          bytes: base64Decode(encodedBytes),
        );
      } on FormatException {
        continue;
      }
    }

    final refs = <String, String?>{};
    for (final member in members) {
      final memberId = _requiredString(member, 'id');
      final avatarUrl = _stringValue(member['avatar_url']);
      if (avatarUrl == null || avatarUrl.startsWith('local-avatar:')) {
        refs[memberId] = avatarUrl;
        continue;
      }

      if (avatarUrl.startsWith('import-asset:') ||
          avatarUrl.startsWith('sp-avatar:')) {
        final assetId = avatarUrl.split(':').last;
        final asset = assetsById[assetId];
        refs[memberId] = asset == null
            ? avatarUrl
            : await _storeAvatarBytes(
                id: asset.id,
                sourceName: asset.name,
                mimeType: asset.mimeType,
                bytes: asset.bytes,
              );
        continue;
      }

      if (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')) {
        refs[memberId] = await _downloadAndStoreAvatar(avatarUrl);
        continue;
      }

      refs[memberId] = avatarUrl;
    }
    return refs;
  }

  Future<String?> _downloadAndStoreAvatar(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasAbsolutePath) {
      return url;
    }

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return url;
      }

      final bytes = await _readAvatarResponseBytes(response);
      if (bytes == null || bytes.isEmpty) {
        return url;
      }

      return _storeAvatarBytes(
        id: uri.pathSegments.isEmpty ? 'remote-avatar' : uri.pathSegments.last,
        sourceName: uri.pathSegments.isEmpty
            ? 'remote-avatar'
            : uri.pathSegments.last,
        mimeType: response.headers.contentType?.mimeType,
        bytes: bytes,
      );
    } on Object {
      return url;
    } finally {
      client.close(force: true);
    }
  }

  Future<Uint8List?> _readAvatarResponseBytes(
    HttpClientResponse response,
  ) async {
    const maxAvatarBytes = 10 * 1024 * 1024;
    final chunks = <List<int>>[];
    var total = 0;
    await for (final chunk in response) {
      total += chunk.length;
      if (total > maxAvatarBytes) {
        return null;
      }
      chunks.add(chunk);
    }
    final bytes = Uint8List(total);
    var offset = 0;
    for (final chunk in chunks) {
      bytes.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    return bytes;
  }

  Future<String> _storeAvatarBytes({
    required String id,
    required String sourceName,
    required String? mimeType,
    required Uint8List bytes,
  }) async {
    final root = await _avatarRootDirectory();
    final extension = _avatarExtension(sourceName, mimeType);
    final safeId = _safeFilePart(id);
    final digest = base64Url
        .encode(bytes.take(18).toList())
        .replaceAll('=', '');
    final fileName = '$safeId-$digest$extension';
    final file = File('${root.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return 'local-avatar:$fileName';
  }

  Future<Directory> _avatarRootDirectory() async {
    Directory base;
    try {
      base = await getApplicationDocumentsDirectory();
    } on Object {
      base = Directory('${Directory.systemTemp.path}/pluris-haven-test');
    }

    final avatars = Directory('${base.path}/avatars');
    if (!await avatars.exists()) {
      await avatars.create(recursive: true);
    }
    return avatars;
  }

  Future<void> _importGroup(
    Map<String, Object?> group,
    ImportConflictStrategy strategy,
    DateTime now,
  ) {
    final id = _requiredString(group, 'id');
    final name = _requiredString(group, 'name');
    final companion = SystemGroupsCompanion.insert(
      id: id,
      systemId: localSystemId,
      parentGroupId: Value(_stringValue(group['parent_group_id'])),
      name: name,
      colorHex: Value(_stringValue(group['color_hex'])),
      description: Value(_stringValue(group['description'])),
      emoji: Value(_stringValue(group['emoji'])),
      createdAt: _dateValue(group['created_at']) ?? now,
      updatedAt: strategy == ImportConflictStrategy.update
          ? now
          : (_dateValue(group['updated_at']) ?? now),
    );
    return _insertArchiveRow(database.systemGroups, companion, strategy);
  }

  Future<void> _importMember(
    Map<String, Object?> member,
    ImportConflictStrategy strategy,
    DateTime now,
    String? localAvatarUrl,
  ) {
    final id = _requiredString(member, 'id');
    final displayName = _requiredString(member, 'display_name');
    final companion = MembersCompanion.insert(
      id: id,
      systemId: localSystemId,
      displayName: displayName,
      pronouns: Value(_stringValue(member['pronouns'])),
      colorHex: Value(_stringValue(member['color_hex'])),
      folderId: Value(_stringValue(member['folder_id'])),
      description: Value(_stringValue(member['description'])),
      avatarUrl: Value(localAvatarUrl ?? _stringValue(member['avatar_url'])),
      pluralKitId: Value(_stringValue(member['pluralkit_id'])),
      isCustomFront: Value(member['is_custom_front'] == true),
      archived: Value(member['archived'] == true),
      createdAt: _dateValue(member['created_at']) ?? now,
      updatedAt: strategy == ImportConflictStrategy.update
          ? now
          : (_dateValue(member['updated_at']) ?? now),
    );
    return _insertArchiveRow(database.members, companion, strategy);
  }

  Future<void> _importNote(
    Map<String, Object?> note,
    ImportConflictStrategy strategy,
    DateTime now,
  ) {
    final id = _requiredString(note, 'id');
    final title = _requiredString(note, 'title');
    final companion = NotesCompanion.insert(
      id: id,
      systemId: localSystemId,
      memberId: Value(_stringValue(note['member_id'])),
      title: title,
      body: _stringValue(note['body']) ?? '',
      createdAt: _dateValue(note['created_at']) ?? now,
      updatedAt: strategy == ImportConflictStrategy.update
          ? now
          : (_dateValue(note['updated_at']) ?? now),
    );
    return _insertArchiveRow(database.notes, companion, strategy);
  }

  Future<void> _importMessage(
    Map<String, Object?> message,
    ImportConflictStrategy strategy,
    DateTime now,
  ) {
    final id = _requiredString(message, 'id');
    final body = _requiredString(message, 'body');
    final companion = MessagesCompanion.insert(
      id: id,
      systemId: localSystemId,
      memberId: Value(_stringValue(message['member_id'])),
      body: body,
      archived: Value(message['archived'] == true),
      createdAt: _dateValue(message['created_at']) ?? now,
      updatedAt: strategy == ImportConflictStrategy.update
          ? now
          : (_dateValue(message['updated_at']) ?? now),
    );
    return _insertArchiveRow(database.messages, companion, strategy);
  }

  Future<void> _importReminder(
    Map<String, Object?> reminder,
    ImportConflictStrategy strategy,
    DateTime now,
  ) {
    final id = _requiredString(reminder, 'id');
    final title = _requiredString(reminder, 'title');
    final scheduleText = _requiredString(reminder, 'schedule_text');
    final companion = RemindersCompanion.insert(
      id: id,
      systemId: localSystemId,
      title: title,
      body: Value(_stringValue(reminder['body'])),
      scheduleText: scheduleText,
      enabled: Value(reminder['enabled'] != false),
      createdAt: _dateValue(reminder['created_at']) ?? now,
      updatedAt: strategy == ImportConflictStrategy.update
          ? now
          : (_dateValue(reminder['updated_at']) ?? now),
    );
    return _insertArchiveRow(database.reminders, companion, strategy);
  }

  Future<void> _importCustomField(
    Map<String, Object?> field,
    ImportConflictStrategy strategy,
    DateTime now,
  ) {
    final id = _requiredString(field, 'id');
    final name = _requiredString(field, 'name');
    final companion = CustomFieldDefinitionsCompanion.insert(
      id: id,
      systemId: localSystemId,
      name: name,
      fieldType: Value(_stringValue(field['field_type']) ?? 'text'),
      privacy: Value(_stringValue(field['privacy'])),
      position: Value(_intValue(field['position']) ?? 0),
      createdAt: _dateValue(field['created_at']) ?? now,
      updatedAt: strategy == ImportConflictStrategy.update
          ? now
          : (_dateValue(field['updated_at']) ?? now),
    );
    return _insertArchiveRow(
      database.customFieldDefinitions,
      companion,
      strategy,
    );
  }

  Future<void> _importCustomFieldValue(
    Map<String, Object?> value,
    ImportConflictStrategy strategy,
    DateTime now,
  ) {
    final id = _requiredString(value, 'id');
    final fieldId = _requiredString(value, 'field_id');
    final companion = CustomFieldValuesCompanion.insert(
      id: id,
      fieldId: fieldId,
      memberId: Value(_stringValue(value['member_id'])),
      value: _stringValue(value['value']) ?? '',
      createdAt: _dateValue(value['created_at']) ?? now,
      updatedAt: strategy == ImportConflictStrategy.update
          ? now
          : (_dateValue(value['updated_at']) ?? now),
    );
    return _insertArchiveRow(database.customFieldValues, companion, strategy);
  }

  Future<void> _importPoll(
    Map<String, Object?> poll,
    ImportConflictStrategy strategy,
    DateTime now,
  ) {
    final id = _requiredString(poll, 'id');
    final question = _requiredString(poll, 'question');
    final companion = PollsCompanion.insert(
      id: id,
      systemId: localSystemId,
      question: question,
      description: Value(_stringValue(poll['description'])),
      kind: Value(
        PollKind.fromStorage(_stringValue(poll['kind'])).storageValue,
      ),
      closed: Value(poll['closed'] == true),
      createdAt: _dateValue(poll['created_at']) ?? now,
      updatedAt: strategy == ImportConflictStrategy.update
          ? now
          : (_dateValue(poll['updated_at']) ?? now),
    );
    return _insertArchiveRow(database.polls, companion, strategy);
  }

  Future<void> _importPollOption(
    Map<String, Object?> option,
    ImportConflictStrategy strategy,
  ) {
    final id = _requiredString(option, 'id');
    final companion = PollOptionsCompanion.insert(
      id: id,
      pollId: _requiredString(option, 'poll_id'),
      body: _requiredString(option, 'body'),
      position: _intValue(option['position']) ?? 0,
    );
    return _insertArchiveRow(database.pollOptions, companion, strategy);
  }

  Future<void> _importPollVote(Map<String, Object?> vote) {
    return database
        .into(database.pollVotes)
        .insert(
          PollVotesCompanion.insert(
            pollId: _requiredString(vote, 'poll_id'),
            optionId: _requiredString(vote, 'option_id'),
            createdAt: _dateValue(vote['created_at']) ?? DateTime.now().toUtc(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<void> _importFront(
    Map<String, Object?> front,
    ImportConflictStrategy strategy,
    DateTime now,
  ) {
    final id = _requiredString(front, 'id');
    final companion = FrontSessionsCompanion.insert(
      id: id,
      systemId: localSystemId,
      label: Value(_stringValue(front['label'])),
      startedAt: _dateValue(front['started_at']) ?? now,
      endedAt: Value(_dateValue(front['ended_at'])),
      createdAt: _dateValue(front['created_at']) ?? now,
      updatedAt: strategy == ImportConflictStrategy.update
          ? now
          : (_dateValue(front['updated_at']) ?? now),
    );
    return _insertArchiveRow(database.frontSessions, companion, strategy);
  }

  Future<void> _importFrontMember(Map<String, Object?> link) {
    return database
        .into(database.frontSessionMembers)
        .insert(
          FrontSessionMembersCompanion.insert(
            sessionId: _requiredString(link, 'session_id'),
            memberId: _requiredString(link, 'member_id'),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<void> _importNamedFront(
    Map<String, Object?> front,
    ImportConflictStrategy strategy,
    DateTime now,
  ) {
    final companion = NamedFrontsCompanion.insert(
      id: _requiredString(front, 'id'),
      systemId: localSystemId,
      name: _requiredString(front, 'name'),
      customLabel: Value(_stringValue(front['custom_label'])),
      createdAt: _dateValue(front['created_at']) ?? now,
      updatedAt: strategy == ImportConflictStrategy.update
          ? now
          : (_dateValue(front['updated_at']) ?? now),
    );
    return _insertArchiveRow(database.namedFronts, companion, strategy);
  }

  Future<void> _importNamedFrontMember(Map<String, Object?> link) {
    return database
        .into(database.namedFrontMembers)
        .insert(
          NamedFrontMembersCompanion.insert(
            namedFrontId: _requiredString(link, 'named_front_id'),
            memberId: _requiredString(link, 'member_id'),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<void> _importNotificationEvent(
    Map<String, Object?> event,
    ImportConflictStrategy strategy,
    DateTime now,
  ) {
    final companion = NotificationEventsCompanion.insert(
      id: _requiredString(event, 'id'),
      systemId: localSystemId,
      kind: _requiredString(event, 'kind'),
      title: _requiredString(event, 'title'),
      body: _requiredString(event, 'body'),
      readAt: Value(_dateValue(event['read_at'])),
      createdAt: _dateValue(event['created_at']) ?? now,
    );
    return _insertArchiveRow(database.notificationEvents, companion, strategy);
  }

  Future<void> _importPreference(
    Map<String, Object?> preference,
    ImportConflictStrategy strategy,
    DateTime now,
  ) {
    final companion = AppPreferencesCompanion.insert(
      key: _requiredString(preference, 'key'),
      value: _requiredString(preference, 'value'),
      updatedAt: strategy == ImportConflictStrategy.update
          ? now
          : (_dateValue(preference['updated_at']) ?? now),
    );
    return _insertArchiveRow(database.appPreferences, companion, strategy);
  }

  Future<void> _importPayload(
    Map<String, Object?> payload,
    String importRecordId,
    ImportSource source,
    ImportConflictStrategy strategy,
    DateTime now,
  ) {
    final id = _requiredString(payload, 'id');
    final companion = ImportPayloadsCompanion.insert(
      id: id,
      importRecordId: importRecordId,
      systemId: localSystemId,
      source: _stringValue(payload['source']) ?? source.jobSource,
      collection: _requiredString(payload, 'collection'),
      payloadJson: _requiredString(payload, 'payload_json'),
      importedAt: _dateValue(payload['imported_at']) ?? now,
    );
    return _insertArchiveRow(database.importPayloads, companion, strategy);
  }

  Future<void> _insertArchiveRow<TableDsl extends Table, D>(
    TableInfo<TableDsl, D> table,
    Insertable<D> companion,
    ImportConflictStrategy strategy,
  ) {
    if (strategy == ImportConflictStrategy.update) {
      return database.into(table).insertOnConflictUpdate(companion);
    }

    return database
        .into(table)
        .insert(companion, mode: InsertMode.insertOrIgnore);
  }

  // v8: Tags

  @override
  Stream<List<Tag>> watchTags() {
    final query = database.select(database.tags)
      ..where((t) => t.systemId.equals(localSystemId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc),
      ]);
    return query.watch();
  }

  @override
  Future<void> saveTag(Tag tag) async {
    final now = DateTime.now().toUtc();
    await database
        .into(database.tags)
        .insertOnConflictUpdate(
          TagsCompanion.insert(
            id: tag.id,
            systemId: localSystemId,
            name: tag.name,
            colorHex: Value(tag.colorHex),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  @override
  Future<void> deleteTag(String tagId) async {
    await (database.delete(
      database.memberTags,
    )..where((mt) => mt.tagId.equals(tagId))).go();
    await (database.delete(
      database.tags,
    )..where((t) => t.id.equals(tagId))).go();
  }

  @override
  Stream<List<Tag>> watchTagsForMember(String memberId) {
    final query =
        database.select(database.memberTags).join([
            innerJoin(
              database.tags,
              database.memberTags.tagId.equalsExp(database.tags.id),
            ),
          ])
          ..where(database.memberTags.memberId.equals(memberId))
          ..orderBy([
            OrderingTerm(
              expression: database.tags.name,
              mode: OrderingMode.asc,
            ),
          ]);
    return query.watch().map((rows) {
      return rows.map((row) {
        final tagRow = row.readTable(database.tags);
        return Tag(
          id: tagRow.id,
          systemId: tagRow.systemId,
          name: tagRow.name,
          colorHex: tagRow.colorHex,
          createdAt: tagRow.createdAt,
          updatedAt: tagRow.updatedAt,
        );
      }).toList();
    });
  }

  @override
  Future<void> setMemberTags(String memberId, List<String> tagIds) async {
    await database.transaction(() async {
      await (database.delete(
        database.memberTags,
      )..where((mt) => mt.memberId.equals(memberId))).go();
      for (final tagId in tagIds) {
        await database
            .into(database.memberTags)
            .insert(
              MemberTagsCompanion.insert(tagId: tagId, memberId: memberId),
              mode: InsertMode.insertOrIgnore,
            );
      }
    });
  }

  // v8: Journals

  @override
  Stream<List<JournalEntry>> watchJournals({String? memberId}) {
    final query = database.select(database.journalEntries)
      ..where((j) => j.systemId.equals(localSystemId));
    if (memberId != null) {
      query.where((j) => j.memberId.equals(memberId));
    }
    query.orderBy([
      (j) => OrderingTerm(expression: j.createdAt, mode: OrderingMode.desc),
    ]);
    return query.watch();
  }

  @override
  Future<void> saveJournal(JournalEntry entry) async {
    final now = DateTime.now().toUtc();
    await database
        .into(database.journalEntries)
        .insertOnConflictUpdate(
          JournalEntriesCompanion.insert(
            id: entry.id,
            systemId: localSystemId,
            memberId: Value(entry.memberId),
            title: Value(entry.title),
            body: entry.body,
            createdAt: entry.createdAt,
            updatedAt: now,
          ),
        );
  }

  @override
  Future<void> deleteJournal(String entryId) async {
    await (database.delete(
      database.journalEntries,
    )..where((j) => j.id.equals(entryId))).go();
  }

  // v8: Content revisions

  @override
  Stream<List<ContentRevision>> watchRevisions(
    String targetType,
    String targetId,
  ) {
    final query = database.select(database.contentRevisions)
      ..where(
        (r) => r.targetType.equals(targetType) & r.targetId.equals(targetId),
      )
      ..orderBy([
        (r) => OrderingTerm(expression: r.createdAt, mode: OrderingMode.desc),
      ]);
    return query.watch();
  }

  @override
  Future<void> pinRevision(String revisionId) async {
    await (database.update(
      database.contentRevisions,
    )..where((r) => r.id.equals(revisionId))).write(
      ContentRevisionsCompanion(pinnedAt: Value(DateTime.now().toUtc())),
    );
  }

  @override
  Future<void> unpinRevision(String revisionId) async {
    await (database.update(database.contentRevisions)
          ..where((r) => r.id.equals(revisionId)))
        .write(const ContentRevisionsCompanion(pinnedAt: Value(null)));
  }

  @override
  Future<void> restoreRevision(
    String revisionId,
    String targetType,
    String targetId,
  ) async {
    final revision = await (database.select(
      database.contentRevisions,
    )..where((r) => r.id.equals(revisionId))).getSingleOrNull();
    if (revision == null) return;

    final now = DateTime.now().toUtc();

    switch (targetType) {
      case 'member_bio':
        await (database.update(
          database.members,
        )..where((m) => m.id.equals(targetId))).write(
          MembersCompanion(
            description: Value(revision.body),
            updatedAt: Value(now),
          ),
        );
      case 'note':
        await (database.update(
          database.notes,
        )..where((n) => n.id.equals(targetId))).write(
          NotesCompanion(
            title: Value(revision.title ?? ''),
            body: Value(revision.body),
            updatedAt: Value(now),
          ),
        );
      case 'journal':
        await (database.update(
          database.journalEntries,
        )..where((j) => j.id.equals(targetId))).write(
          JournalEntriesCompanion(
            title: Value(revision.title),
            body: Value(revision.body),
            updatedAt: Value(now),
          ),
        );
      case 'message':
        await (database.update(
          database.messages,
        )..where((m) => m.id.equals(targetId))).write(
          MessagesCompanion(body: Value(revision.body), updatedAt: Value(now)),
        );
    }
  }

  // v8: Front audit events

  @override
  Stream<List<FrontAuditEvent>> watchFrontAuditEvents(String frontSessionId) {
    final query = database.select(database.frontAuditEvents)
      ..where((e) => e.frontId.equals(frontSessionId))
      ..orderBy([
        (e) => OrderingTerm(expression: e.createdAt, mode: OrderingMode.desc),
      ]);
    return query.watch();
  }

  // v8: Poll vote events

  @override
  Stream<List<PollVoteEvent>> watchPollVoteEvents(String pollId) {
    final query = database.select(database.pollVoteEvents)
      ..where((e) => e.pollId.equals(pollId))
      ..orderBy([
        (e) => OrderingTerm(expression: e.createdAt, mode: OrderingMode.desc),
      ]);
    return query.watch();
  }

  // v8: Named fronts

  @override
  Stream<List<NamedFront>> watchNamedFronts() {
    final query = database.select(database.namedFronts)
      ..where((nf) => nf.systemId.equals(localSystemId))
      ..orderBy([
        (nf) => OrderingTerm(expression: nf.name, mode: OrderingMode.asc),
      ]);
    return query.watch();
  }

  @override
  Future<void> saveNamedFront(NamedFront front, List<String> memberIds) async {
    final now = DateTime.now().toUtc();
    await database.transaction(() async {
      await database
          .into(database.namedFronts)
          .insertOnConflictUpdate(
            NamedFrontsCompanion.insert(
              id: front.id,
              systemId: localSystemId,
              name: front.name,
              customLabel: Value(front.customLabel),
              createdAt: front.createdAt,
              updatedAt: now,
            ),
          );
      await (database.delete(
        database.namedFrontMembers,
      )..where((nfm) => nfm.namedFrontId.equals(front.id))).go();
      for (final memberId in memberIds) {
        await database
            .into(database.namedFrontMembers)
            .insert(
              NamedFrontMembersCompanion.insert(
                namedFrontId: front.id,
                memberId: memberId,
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
    });
  }

  @override
  Future<void> applyNamedFront(String namedFrontId) async {
    final namedFront = await (database.select(
      database.namedFronts,
    )..where((front) => front.id.equals(namedFrontId))).getSingleOrNull();
    final members = await (database.select(
      database.namedFrontMembers,
    )..where((nfm) => nfm.namedFrontId.equals(namedFrontId))).get();
    final label = _nullIfBlank(namedFront?.customLabel);
    if (members.isEmpty && label != null) {
      await setCustomFront(label);
      return;
    }
    await setFrontMembers(members.map((m) => m.memberId).toList());
  }

  @override
  Future<void> deleteNamedFront(String namedFrontId) async {
    await (database.delete(
      database.namedFrontMembers,
    )..where((nfm) => nfm.namedFrontId.equals(namedFrontId))).go();
    await (database.delete(
      database.namedFronts,
    )..where((nf) => nf.id.equals(namedFrontId))).go();
  }

  // v8: Pending actions

  @override
  Stream<List<PendingAction>> watchPendingActions() {
    final query = database.select(database.pendingActions)
      ..where(
        (a) => a.systemId.equals(localSystemId) & a.status.equals('pending'),
      )
      ..orderBy([
        (a) =>
            OrderingTerm(expression: a.finalizeAfter, mode: OrderingMode.asc),
      ]);
    return query.watch();
  }

  @override
  Future<void> cancelPendingAction(String actionId) async {
    final now = DateTime.now().toUtc();
    await (database.update(
      database.pendingActions,
    )..where((a) => a.id.equals(actionId))).write(
      PendingActionsCompanion(
        status: const Value('cancelled'),
        cancelledAt: Value(now),
      ),
    );
  }

  @override
  Future<void> finalizePendingActions() async {
    final now = DateTime.now().toUtc();
    final due =
        await (database.select(database.pendingActions)..where(
              (a) =>
                  a.systemId.equals(localSystemId) &
                  a.status.equals('pending') &
                  a.finalizeAfter.isSmallerOrEqualValue(now),
            ))
            .get();

    for (final action in due) {
      switch (action.actionType) {
        case 'member_delete':
          await deleteMember(action.targetId);
        case 'note_delete':
          await deleteNote(action.targetId);
        case 'reminder_delete':
          await deleteReminder(action.targetId);
        case 'poll_delete':
          await deletePoll(action.targetId);
        case 'journal_delete':
          await deleteJournal(action.targetId);
        case 'tag_delete':
          await deleteTag(action.targetId);
        case 'named_front_delete':
          await deleteNamedFront(action.targetId);
      }
      await (database.update(
        database.pendingActions,
      )..where((a) => a.id.equals(action.id))).write(
        PendingActionsCompanion(
          status: const Value('completed'),
          completedAt: Value(now),
        ),
      );
    }
  }

  // v8: Lexorank reordering

  @override
  Future<void> reorderMember(
    String memberId,
    String? prevRank,
    String? nextRank,
  ) async {
    final newRank = Lexorank.between(prevRank, nextRank);
    await (database.update(
      database.members,
    )..where((m) => m.id.equals(memberId))).write(
      MembersCompanion(
        lexoRank: Value(newRank),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> _endOpenFrontSessions(DateTime endedAt) {
    return (database.update(database.frontSessions)..where(
          (session) =>
              session.systemId.equals(localSystemId) & session.endedAt.isNull(),
        ))
        .write(
          FrontSessionsCompanion(
            endedAt: Value(endedAt),
            updatedAt: Value(endedAt),
          ),
        );
  }

  String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  String _debugErrorText(Object error, StackTrace stackTrace) {
    var text = error.toString();
    assert(() {
      final stack = stackTrace.toString().trim();
      if (stack.isNotEmpty) {
        text = '$text\n\nDebug stack:\n$stack';
      }
      return true;
    }());
    return text;
  }

  List<Map<String, Object?>> _jsonObjectList(Object? value) {
    if (value == null) {
      return <Map<String, Object?>>[];
    }
    if (value is! List) {
      throw const FormatException('Expected an archive list.');
    }

    return [
      for (final item in value)
        if (item is Map<String, Object?>) item else _throwArchiveObjectError(),
    ];
  }

  Map<String, Object?> _throwArchiveObjectError() {
    throw const FormatException('Expected an archive object in list.');
  }

  String _requiredString(Map<String, Object?> object, String key) {
    final value = _stringValue(object[key]);
    if (value == null || value.trim().isEmpty) {
      throw FormatException('Missing required archive field: $key.');
    }
    return value;
  }

  String? _stringValue(Object? value) => value is String ? value : null;

  int? _intValue(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    final text = _stringValue(value);
    return text == null ? null : int.tryParse(text);
  }

  DateTime? _dateValue(Object? value) {
    final text = _stringValue(value);
    if (text == null || text.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(text)?.toUtc();
  }

  Map<String, Object?> _systemToJson(PluralSystem system) => {
    'id': system.id,
    'name': system.name,
    'created_at': system.createdAt.toIso8601String(),
    'updated_at': system.updatedAt.toIso8601String(),
  };

  Map<String, Object?> _memberToJson(Member member) => {
    'id': member.id,
    'display_name': member.displayName,
    'pronouns': member.pronouns,
    'color_hex': member.colorHex,
    'folder_id': member.folderId,
    'description': member.description,
    'avatar_url': member.avatarUrl,
    'pluralkit_id': member.pluralKitId,
    'is_custom_front': member.isCustomFront,
    'archived': member.archived,
    'created_at': member.createdAt.toIso8601String(),
    'updated_at': member.updatedAt.toIso8601String(),
  };

  Map<String, Object?> _groupToJson(SystemGroup group) => {
    'id': group.id,
    'parent_group_id': group.parentGroupId,
    'name': group.name,
    'color_hex': group.colorHex,
    'description': group.description,
    'emoji': group.emoji,
    'created_at': group.createdAt.toIso8601String(),
    'updated_at': group.updatedAt.toIso8601String(),
  };

  Map<String, Object?> _noteToJson(Note note) => {
    'id': note.id,
    'member_id': note.memberId,
    'title': note.title,
    'body': note.body,
    'created_at': note.createdAt.toIso8601String(),
    'updated_at': note.updatedAt.toIso8601String(),
  };

  Map<String, Object?> _messageToJson(Message message) => {
    'id': message.id,
    'member_id': message.memberId,
    'body': message.body,
    'archived': message.archived,
    'created_at': message.createdAt.toIso8601String(),
    'updated_at': message.updatedAt.toIso8601String(),
  };

  Map<String, Object?> _reminderToJson(Reminder reminder) => {
    'id': reminder.id,
    'title': reminder.title,
    'body': reminder.body,
    'schedule_text': reminder.scheduleText,
    'enabled': reminder.enabled,
    'created_at': reminder.createdAt.toIso8601String(),
    'updated_at': reminder.updatedAt.toIso8601String(),
  };

  Map<String, Object?> _customFieldToJson(CustomFieldDefinition field) => {
    'id': field.id,
    'name': field.name,
    'field_type': field.fieldType,
    'privacy': field.privacy,
    'position': field.position,
    'created_at': field.createdAt.toIso8601String(),
    'updated_at': field.updatedAt.toIso8601String(),
  };

  Map<String, Object?> _customFieldValueToJson(CustomFieldValue value) => {
    'id': value.id,
    'field_id': value.fieldId,
    'member_id': value.memberId,
    'value': value.value,
    'created_at': value.createdAt.toIso8601String(),
    'updated_at': value.updatedAt.toIso8601String(),
  };

  Map<String, Object?> _pollToJson(Poll poll) => {
    'id': poll.id,
    'question': poll.question,
    'description': poll.description,
    'kind': poll.kind,
    'closed': poll.closed,
    'created_at': poll.createdAt.toIso8601String(),
    'updated_at': poll.updatedAt.toIso8601String(),
  };

  Map<String, Object?> _pollOptionToJson(PollOption option) => {
    'id': option.id,
    'poll_id': option.pollId,
    'body': option.body,
    'position': option.position,
  };

  Map<String, Object?> _pollVoteToJson(PollVote vote) => {
    'poll_id': vote.pollId,
    'option_id': vote.optionId,
    'created_at': vote.createdAt.toIso8601String(),
  };

  Map<String, Object?> _frontToJson(FrontSession front) => {
    'id': front.id,
    'label': front.label,
    'started_at': front.startedAt.toIso8601String(),
    'ended_at': front.endedAt?.toIso8601String(),
    'created_at': front.createdAt.toIso8601String(),
    'updated_at': front.updatedAt.toIso8601String(),
  };

  Map<String, Object?> _frontMemberToJson(FrontSessionMember link) => {
    'session_id': link.sessionId,
    'member_id': link.memberId,
  };

  Map<String, Object?> _namedFrontToJson(NamedFront front) => {
    'id': front.id,
    'name': front.name,
    'custom_label': front.customLabel,
    'created_at': front.createdAt.toIso8601String(),
    'updated_at': front.updatedAt.toIso8601String(),
  };

  Map<String, Object?> _namedFrontMemberToJson(NamedFrontMember link) => {
    'named_front_id': link.namedFrontId,
    'member_id': link.memberId,
  };

  Map<String, Object?> _importRecordToJson(ImportRecord record) => {
    'id': record.id,
    'source': record.source,
    'file_name': record.fileName,
    'summary_json': record.summaryJson,
    'imported_at': record.importedAt.toIso8601String(),
  };

  Map<String, Object?> _importPayloadToJson(ImportPayload payload) => {
    'id': payload.id,
    'import_record_id': payload.importRecordId,
    'source': payload.source,
    'collection': payload.collection,
    'payload_json': payload.payloadJson,
    'imported_at': payload.importedAt.toIso8601String(),
  };

  Map<String, Object?> _notificationEventToJson(NotificationEvent event) => {
    'id': event.id,
    'kind': event.kind,
    'title': event.title,
    'body': event.body,
    'read_at': event.readAt?.toIso8601String(),
    'created_at': event.createdAt.toIso8601String(),
  };

  Map<String, Object?> _preferenceToJson(AppPreference preference) => {
    'key': preference.key,
    'value': preference.value,
    'updated_at': preference.updatedAt.toIso8601String(),
  };
}

BackgroundJobSummary _backgroundJobSummary(BackgroundJob row) {
  return BackgroundJobSummary(
    id: row.id,
    type: row.type,
    status: row.status,
    source: row.source,
    fileName: row.fileName,
    error: row.error,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

class _ImportAvatarBytes {
  const _ImportAvatarBytes({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.bytes,
  });

  final String id;
  final String name;
  final String? mimeType;
  final Uint8List bytes;
}

String _avatarExtension(String sourceName, String? mimeType) {
  final lowerName = sourceName.toLowerCase();
  if (lowerName.endsWith('.png')) {
    return '.png';
  }
  if (lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg')) {
    return '.jpg';
  }
  if (lowerName.endsWith('.webp')) {
    return '.webp';
  }
  if (lowerName.endsWith('.gif')) {
    return '.gif';
  }

  return switch (mimeType) {
    'image/png' => '.png',
    'image/jpeg' => '.jpg',
    'image/webp' => '.webp',
    'image/gif' => '.gif',
    _ => '.bin',
  };
}

String _safeFilePart(String value) {
  final cleaned = value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9._-]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^[-.]+|[-.]+$'), '');
  return cleaned.isEmpty ? 'avatar' : cleaned;
}

String? _normalizeHexColor(String? value) {
  if (value == null) {
    return null;
  }
  final trimmed = value.trim().replaceFirst('#', '');
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(trimmed)) {
    return null;
  }
  return '#${trimmed.toUpperCase()}';
}

int? _argbFromHex(String? value) {
  final normalized = _normalizeHexColor(value);
  if (normalized == null) {
    return null;
  }
  return int.parse('FF${normalized.substring(1)}', radix: 16);
}

const _themeModeKey = 'theme_mode';
const _accentColorKey = 'accent_color';
const _customAccentHexKey = 'custom_accent_hex';
const _compactDashboardKey = 'compact_dashboard';
const _showDashboardSubtitlesKey = 'show_dashboard_subtitles';
const _dashboardShortcutIdsKey = 'dashboard_shortcut_ids';
const _emptyShortcutIdsValue = '__empty__';
const _languageCodeKey = 'language_code';
const _allowedCustomFieldTypes = {
  'text',
  'number',
  'date',
  'boolean',
  'select',
};
