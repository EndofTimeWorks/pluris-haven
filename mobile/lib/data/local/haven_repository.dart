import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';

import '../../debug/debug_log.dart';
import '../avatar/avatar_file_policy.dart';
import '../import/remote_avatar_policy.dart';
import '../import/import_sources.dart';
import '../security/haven_crypto.dart';
import 'app_customization.dart';
import 'app_database.dart';
import 'chat_store.dart';
import 'group_store.dart';
import 'journal_store.dart';
import 'member_store.dart';
import 'message_store.dart';
import 'note_store.dart';
import 'poll_store.dart';
import 'rehearsal_database_connection.dart';
import 'reminder_store.dart';
import 'tag_store.dart';

export 'app_customization.dart'
    show
        AppCustomization,
        HavenAccentColor,
        HavenThemeMode,
        defaultDashboardShortcutIds;
export 'chat_store.dart'
    show
        ChatCategoryDraft,
        ChatCategorySummary,
        ChatChannelDraft,
        ChatChannelSummary;
export 'group_store.dart' show GroupDraft, GroupSummary;
export 'note_store.dart' show NoteDraft, NoteSummary;
export 'message_store.dart' show MessageDraft, MessageSummary;
export 'member_store.dart' show MemberDraft, MemberSummary;
export 'poll_store.dart'
    show PollDraft, PollKind, PollOptionSummary, PollSummary;
export 'reminder_store.dart' show ReminderDraft, ReminderSummary;

const _legacyLocalEncryptedTextPrefix = 'ph1:';
const _localEncryptedTextPrefix = 'ph2:';
const _memberEncryptionSweepPreference =
    'internal.member_encryption_sweep_version';
const _localEncryptionSweepPreference =
    'internal.local_encryption_sweep_version';
const _memberEncryptionSweepVersion = '2';
const _localEncryptionSweepVersion = '2';

class HomeSnapshot {
  const HomeSnapshot({
    required this.systemName,
    required this.memberCount,
    required this.groupCount,
    required this.noteCount,
    required this.frontHistoryCount,
    required this.currentFrontLabel,
    this.systemColorHex,
    this.systemAvatarUrl,
    this.systemDescription,
  });

  final String systemName;
  final int memberCount;
  final int groupCount;
  final int noteCount;
  final int frontHistoryCount;
  final String? currentFrontLabel;
  final String? systemColorHex;
  final String? systemAvatarUrl;
  final String? systemDescription;

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

class RetainedImportPayloadSummary {
  const RetainedImportPayloadSummary({
    required this.importRecordId,
    required this.source,
    required this.collections,
    required this.payloadCount,
    required this.importedAt,
  });

  final String importRecordId;
  final String source;
  final List<String> collections;
  final int payloadCount;
  final DateTime importedAt;
}

class PrivacyBucketSummary {
  const PrivacyBucketSummary({
    required this.id,
    required this.name,
    this.description,
    this.colorHex,
    this.memberIds = const [],
  });

  final String id;
  final String name;
  final String? description;
  final String? colorHex;
  final List<String> memberIds;
}

class PrivacyBucketDraft {
  const PrivacyBucketDraft({
    required this.name,
    this.description,
    this.colorHex,
    this.memberIds = const [],
  });

  final String name;
  final String? description;
  final String? colorHex;
  final List<String> memberIds;
}

class RestoreRehearsalSummary {
  const RestoreRehearsalSummary({
    required this.canRestore,
    required this.fileName,
    required this.counts,
    required this.checkedAt,
    required this.elapsed,
    this.error,
  });

  final bool canRestore;
  final String? fileName;
  final Map<String, int> counts;
  final DateTime checkedAt;
  final Duration elapsed;
  final String? error;

  int get totalRecords =>
      counts.values.fold(0, (total, count) => total + count);

  Iterable<MapEntry<String, int>> get visibleCounts =>
      counts.entries.where((entry) => entry.value > 0);
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
    this.statusNote,
    required this.startedAt,
    this.endedAt,
    this.memberIds = const [],
  });

  final String id;
  final String label;
  final String? statusNote;
  final DateTime startedAt;
  final DateTime? endedAt;
  final List<String> memberIds;

  bool get isActive => endedAt == null;
}

class FrontHistoryDraft {
  const FrontHistoryDraft({
    required this.startedAt,
    required this.endedAt,
    this.memberIds = const [],
    this.label,
    this.statusNote,
  });

  final DateTime startedAt;
  final DateTime endedAt;
  final List<String> memberIds;
  final String? label;
  final String? statusNote;
}

class SystemProfileDraft {
  const SystemProfileDraft({
    required this.name,
    this.colorHex,
    this.avatarUrl,
    this.description,
  });

  final String name;
  final String? colorHex;
  final String? avatarUrl;
  final String? description;
}

abstract interface class HavenRepository {
  Stream<HomeSnapshot> watchHomeSnapshot();

  Stream<List<MemberSummary>> watchMembers({
    bool includeArchived = false,
    bool includeCustomFronts = false,
  });

  Stream<List<MemberSummary>> watchCurrentFrontMembers();

  Stream<List<GroupSummary>> watchGroups();

  Stream<List<NoteSummary>> watchNotes();

  Stream<List<MessageSummary>> watchMessages();

  Stream<List<ChatCategorySummary>> watchChatCategories();

  Stream<List<ChatChannelSummary>> watchChatChannels();

  Stream<List<ReminderSummary>> watchReminders();

  Stream<List<CustomFieldSummary>> watchCustomFields();

  Stream<List<CustomFieldValueSummary>> watchCustomFieldValues();

  Stream<List<PollSummary>> watchPolls();

  Stream<List<NotificationEventSummary>> watchNotificationEvents();

  Stream<List<PrivacyBucketSummary>> watchPrivacyBuckets();

  Stream<List<FrontHistoryEntry>> watchFrontHistory();

  Stream<AppCustomization> watchCustomization();

  Future<AppCustomization> loadCustomization();

  Future<void> setThemeMode(HavenThemeMode mode);

  Future<void> setAccentColor(HavenAccentColor color);

  Future<void> setCustomAccentColor(String? colorHex);

  Future<void> setCompactDashboard(bool compact);

  Future<void> setShowDashboardSubtitles(bool show);

  Future<void> setReducedMotion(bool reduced);

  Future<void> setFrontStatusNotification(bool enabled);

  Future<void> setHighContrast(bool highContrast);

  Future<void> setLargeText(bool largeText);

  Future<void> setCompactLists(bool compact);

  Future<void> setDashboardShortcutIds(List<String> shortcutIds);

  Future<void> setLanguageCode(String languageCode);

  Future<void> updateSystemProfile(SystemProfileDraft draft);

  Future<void> setDashboardShortcutVisible(String shortcutId, bool visible);

  Future<void> moveDashboardShortcut(String shortcutId, int delta);

  Future<void> resetDashboardShortcuts();

  Future<void> saveMember(MemberDraft draft);

  Future<void> updateMember(String memberId, MemberDraft draft);

  Future<void> archiveMember(String memberId);

  Future<void> restoreMember(String memberId);

  Future<void> deleteMember(String memberId);

  Future<List<ReminderSummary>> setFrontMembers(List<String> memberIds);

  Future<void> updateFrontStatusNote(String frontId, String? statusNote);

  Future<void> saveFrontHistoryEntry(FrontHistoryDraft draft);

  Future<void> updateFrontHistoryEntry(String frontId, FrontHistoryDraft draft);

  Future<void> deleteFrontSession(String frontId);

  Future<void> saveGroup(GroupDraft draft);

  Future<void> updateGroup(String groupId, GroupDraft draft);

  Future<void> deleteGroup(String groupId);

  Future<void> saveCustomField(CustomFieldDraft draft);

  Future<void> updateCustomField(String fieldId, CustomFieldDraft draft);

  Future<void> deleteCustomField(String fieldId);

  Future<void> setCustomFieldValue({
    required String fieldId,
    required String? memberId,
    required String value,
  });

  Future<void> saveNote(NoteDraft draft);

  Future<void> updateNote(String noteId, NoteDraft draft);

  Future<void> deleteNote(String noteId);

  Future<void> saveMessage(MessageDraft draft);

  Future<void> updateMessage(String messageId, MessageDraft draft);

  Future<void> deleteMessage(String messageId);

  Future<void> saveChatCategory(ChatCategoryDraft draft);

  Future<void> updateChatCategory(String categoryId, ChatCategoryDraft draft);

  Future<void> deleteChatCategory(String categoryId);

  Future<void> saveChatChannel(ChatChannelDraft draft);

  Future<void> updateChatChannel(String channelId, ChatChannelDraft draft);

  Future<void> deleteChatChannel(String channelId);

  Future<String?> saveReminder(ReminderDraft draft);

  Future<void> setReminderEnabled(String reminderId, bool enabled);

  Future<void> deleteReminder(String reminderId);

  Future<void> savePoll(PollDraft draft);

  Future<void> togglePollOption(String pollId, String optionId);

  Future<void> closePoll(String pollId);

  Future<void> deletePoll(String pollId);

  Future<void> savePrivacyBucket(PrivacyBucketDraft draft);

  Future<void> updatePrivacyBucket(String bucketId, PrivacyBucketDraft draft);

  Future<void> deletePrivacyBucket(String bucketId);

  Future<void> recordNotificationEvent(NotificationEventDraft draft);

  Future<List<ReminderSummary>> setCustomFront(String label);

  Future<void> clearCurrentFront();

  Future<String> buildLocalArchiveJson();

  Future<RestoreRehearsalSummary> rehearseLocalArchiveRestore(
    String archiveJson, {
    ImportConflictStrategy strategy = ImportConflictStrategy.prompt,
    String? fileName,
    ImportSource source = ImportSource.plurisHavenArchive,
  });

  Stream<List<BackgroundJobSummary>> watchBackgroundJobs();

  Stream<List<RetainedImportPayloadSummary>> watchRetainedImportPayloads();

  Future<void> deleteRetainedImportPayloads(String importRecordId);

  Future<String> enqueueImportArchiveJob(
    String archiveJson, {
    required ImportConflictStrategy strategy,
    String? fileName,
    required ImportSource source,
  });

  Future<bool> runBackgroundJob(String jobId);

  Future<void> importLocalArchiveJson(
    String archiveJson, {
    ImportConflictStrategy strategy = ImportConflictStrategy.prompt,
    String? fileName,
    ImportSource source = ImportSource.plurisHavenArchive,
    bool localizeAvatars = true,
  });

  // Tags

  Stream<List<Tag>> watchTags();

  Future<void> saveTag(Tag tag);

  Future<void> deleteTag(String tagId);

  Stream<List<Tag>> watchTagsForMember(String memberId);

  Future<void> setMemberTags(String memberId, List<String> tagIds);

  // Journals

  Stream<List<JournalEntry>> watchJournals({String? memberId});

  Future<void> saveJournal(JournalEntry entry);

  Future<void> deleteJournal(String entryId);

  // Content revisions

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

  // Front audit events

  Stream<List<FrontAuditEvent>> watchFrontAuditEvents(String frontSessionId);

  // Poll vote events

  Stream<List<PollVoteEvent>> watchPollVoteEvents(String pollId);

  // Named fronts

  Stream<List<NamedFront>> watchNamedFronts();

  Future<void> saveNamedFront(NamedFront front, List<String> memberIds);

  Future<List<ReminderSummary>> applyNamedFront(String namedFrontId);

  Future<void> deleteNamedFront(String namedFrontId);

  // Pending actions

  Stream<List<PendingAction>> watchPendingActions();

  Future<void> cancelPendingAction(String actionId);

  Future<void> finalizePendingActions();

  // Lexorank reordering

  Future<void> reorderMember(
    String memberId,
    String? prevRank,
    String? nextRank,
  );
}

class LocalHavenRepository implements HavenRepository {
  LocalHavenRepository(this.database, {required this.crypto})
    : _customization = LocalAppCustomizationStore(database) {
    _tags = LocalTagStore(
      database,
      encryptText: _encryptLocalText,
      encryptNullableText: _encryptNullableLocalText,
      decryptText: _decryptLocalText,
    );
    _journals = LocalJournalStore(
      database,
      encryptText: _encryptLocalText,
      encryptNullableText: _encryptNullableLocalText,
      decryptText: _decryptLocalText,
    );
    _notes = LocalNoteStore(
      database,
      encryptText: _encryptLocalText,
      decryptText: _decryptLocalText,
    );
    _messages = LocalMessageStore(
      database,
      encryptText: _encryptLocalText,
      decryptText: _decryptLocalText,
    );
    _chat = LocalChatStore(
      database,
      encryptText: _encryptLocalText,
      encryptNullableText: _encryptNullableLocalText,
      decryptText: _decryptLocalText,
    );
    _members = LocalMemberStore(
      database,
      encryptText: _encryptMember,
      decryptText: _decryptMemberValue,
      blindIndex: _blindIndex,
      onDeleted: (memberId) =>
          _memberDecryptCache.removeWhere((key, _) => key.$1 == memberId),
    );
    _groups = LocalGroupStore(
      database,
      encryptText: _encryptLocalText,
      encryptNullableText: _encryptNullableLocalText,
      decryptText: _decryptLocalText,
    );
    _polls = LocalPollStore(
      database,
      encryptText: _encryptLocalText,
      encryptNullableText: _encryptNullableLocalText,
      decryptText: _decryptLocalText,
    );
    _reminders = LocalReminderStore(
      database,
      encryptText: _encryptLocalText,
      encryptNullableText: _encryptNullableLocalText,
      decryptText: _decryptLocalText,
    );
  }

  final AppDatabase database;
  final HavenCrypto crypto;
  final LocalAppCustomizationStore _customization;
  late final LocalTagStore _tags;
  late final LocalJournalStore _journals;
  late final LocalNoteStore _notes;
  late final LocalMessageStore _messages;
  late final LocalChatStore _chat;
  late final LocalMemberStore _members;
  late final LocalGroupStore _groups;
  late final LocalPollStore _polls;
  late final LocalReminderStore _reminders;
  final Map<(String, String), ({String? ciphertext, String? plaintext})>
  _memberDecryptCache = {};

  String _memberAad(String memberId, String field) =>
      'members:$memberId:$field';

  Future<String?> _encryptMember(
    String memberId,
    String field,
    String? plaintext,
  ) {
    return crypto.encrypt(plaintext, aad: _memberAad(memberId, field));
  }

  Future<String?> _decryptMember(
    Member member,
    String field,
    String? ciphertext,
  ) {
    return _decryptMemberValue(member.id, field, ciphertext);
  }

  Future<String?> _decryptMemberValue(
    String memberId,
    String field,
    String? ciphertext,
  ) async {
    final key = (memberId, field);
    final cached = _memberDecryptCache[key];
    if (cached != null && cached.ciphertext == ciphertext) {
      return cached.plaintext;
    }
    final plaintext = await crypto.decrypt(
      ciphertext,
      aad: _memberAad(memberId, field),
    );
    _memberDecryptCache[key] = (ciphertext: ciphertext, plaintext: plaintext);
    return plaintext;
  }

  Future<String?> _migrateMemberField(
    Member member,
    String field,
    String? legacyCiphertext,
  ) async {
    final plaintext = member.profileEncryptionVersion == 0
        ? legacyCiphertext
        : await crypto.decrypt(legacyCiphertext);
    return _encryptMember(member.id, field, plaintext);
  }

  /// Computes a blind index for [plaintext].
  Future<String?> _blindIndex(String plaintext) async {
    return await crypto.blindIndex(plaintext);
  }

  Future<void> ensureLocalSystem() async {
    final now = DateTime.now().toUtc();

    await database
        .into(database.pluralSystems)
        .insert(
          PluralSystemsCompanion.insert(
            id: localSystemId,
            name: await _encryptLocalText(
              'Local system',
              'plural_systems',
              localSystemId,
              'name',
            ),
            createdAt: now,
            updatedAt: now,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<void> migrateMemberNamesToEncryption() async {
    if (await _preferenceEquals(
      _memberEncryptionSweepPreference,
      _memberEncryptionSweepVersion,
    )) {
      return;
    }
    await database.transaction(() async {
      final members = await (database.select(
        database.members,
      )..where((member) => member.systemId.equals(localSystemId))).get();
      for (final member in members) {
        if (member.profileEncryptionVersion >= 2) {
          await _verifyEncryptedMemberProfile(member);
          continue;
        }

        final displayName = member.displayNameHash == null
            ? member.displayName
            : await crypto.decrypt(member.displayName);
        if (displayName == null) {
          throw StateError('Member name could not be migrated: ${member.id}');
        }

        final encrypted = await _encryptMember(
          member.id,
          'display_name',
          displayName,
        );
        if (encrypted == null) {
          throw StateError('Member name encryption returned no value.');
        }
        final blindIndex = await crypto.blindIndex(displayName);
        await (database.update(
          database.members,
        )..where((row) => row.id.equals(member.id))).write(
          MembersCompanion(
            displayName: Value(encrypted),
            displayNameHash: Value(blindIndex),
            profileEncryptionVersion: const Value(2),
            pronouns: Value(
              await _migrateMemberField(member, 'pronouns', member.pronouns),
            ),
            colorHex: Value(
              await _migrateMemberField(member, 'color_hex', member.colorHex),
            ),
            birthday: Value(
              await _migrateMemberField(member, 'birthday', member.birthday),
            ),
            emoji: Value(
              await _migrateMemberField(member, 'emoji', member.emoji),
            ),
            privacy: Value(
              await _migrateMemberField(member, 'privacy', member.privacy),
            ),
            description: Value(
              await _migrateMemberField(
                member,
                'description',
                member.description,
              ),
            ),
            avatarUrl: Value(
              await _migrateMemberField(member, 'avatar_url', member.avatarUrl),
            ),
            pluralKitId: Value(
              await _migrateMemberField(
                member,
                'pluralkit_id',
                member.pluralKitId,
              ),
            ),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
      }
      await _writePreference(
        _memberEncryptionSweepPreference,
        _memberEncryptionSweepVersion,
      );
    });
  }

  Future<void> _verifyEncryptedMemberProfile(Member member) async {
    await _decryptMember(member, 'display_name', member.displayName);
    await _decryptMember(member, 'pronouns', member.pronouns);
    await _decryptMember(member, 'color_hex', member.colorHex);
    await _decryptMember(member, 'birthday', member.birthday);
    await _decryptMember(member, 'emoji', member.emoji);
    await _decryptMember(member, 'privacy', member.privacy);
    await _decryptMember(member, 'description', member.description);
    await _decryptMember(member, 'avatar_url', member.avatarUrl);
    await _decryptMember(member, 'pluralkit_id', member.pluralKitId);
  }

  String _localTextAad(String table, String rowId, String column) =>
      'pluris-haven:local-text:v2\u0000$table\u0000$rowId\u0000$column';

  Future<String> _encryptLocalText(
    String value,
    String table,
    String rowId,
    String column,
  ) async {
    final encrypted = await crypto.encrypt(
      value,
      aad: _localTextAad(table, rowId, column),
    );
    if (encrypted == null) {
      throw StateError('Local text encryption returned no value.');
    }
    return '$_localEncryptedTextPrefix$encrypted';
  }

  Future<String?> _encryptNullableLocalText(
    String? value,
    String table,
    String rowId,
    String column,
  ) async {
    return value == null
        ? null
        : _encryptLocalText(value, table, rowId, column);
  }

  Future<String?> _decryptLocalText(
    String? stored,
    String table,
    String rowId,
    String column,
  ) async {
    if (stored == null) return null;
    if (stored.startsWith(_legacyLocalEncryptedTextPrefix)) {
      return crypto.decrypt(
        stored.substring(_legacyLocalEncryptedTextPrefix.length),
      );
    }
    if (!stored.startsWith(_localEncryptedTextPrefix)) {
      throw StateError('Protected local text is not encrypted.');
    }
    return crypto.decrypt(
      stored.substring(_localEncryptedTextPrefix.length),
      aad: _localTextAad(table, rowId, column),
    );
  }

  Future<String> _migrateLocalText(
    String stored,
    String table,
    String rowId,
    String column,
  ) async {
    if (stored.startsWith(_localEncryptedTextPrefix)) {
      return stored;
    }
    final plaintext = stored.startsWith(_legacyLocalEncryptedTextPrefix)
        ? await crypto.decrypt(
            stored.substring(_legacyLocalEncryptedTextPrefix.length),
          )
        : stored;
    if (plaintext == null) {
      throw StateError('Legacy local text decryption returned no value.');
    }
    return _encryptLocalText(plaintext, table, rowId, column);
  }

  bool _needsLocalTextMigration(String? stored) =>
      stored != null && !stored.startsWith(_localEncryptedTextPrefix);

  Future<void> migrateLocalPrivateContentToEncryption() async {
    if (await _preferenceEquals(
      _localEncryptionSweepPreference,
      _localEncryptionSweepVersion,
    )) {
      return;
    }
    await database.transaction(() async {
      final notes = await database.select(database.notes).get();
      final messages = await database.select(database.messages).get();
      final fronts = await database.select(database.frontSessions).get();
      final journals = await database.select(database.journalEntries).get();
      final reminders = await database.select(database.reminders).get();
      final polls = await database.select(database.polls).get();
      final pollOptions = await database.select(database.pollOptions).get();
      final customFields = await database
          .select(database.customFieldDefinitions)
          .get();
      final customFieldValues = await database
          .select(database.customFieldValues)
          .get();
      final groups = await database.select(database.systemGroups).get();
      final tags = await database.select(database.tags).get();
      final namedFronts = await database.select(database.namedFronts).get();
      final privacyBuckets = await database
          .select(database.privacyBuckets)
          .get();
      final systems = await database.select(database.pluralSystems).get();
      final chatCategories = await database
          .select(database.chatCategories)
          .get();
      final chatChannels = await database.select(database.chatChannels).get();
      final notificationEvents = await database
          .select(database.notificationEvents)
          .get();
      final contentRevisions = await database
          .select(database.contentRevisions)
          .get();
      final frontAuditEvents = await database
          .select(database.frontAuditEvents)
          .get();
      final importRecords = await database.select(database.importRecords).get();
      final importPayloads = await database
          .select(database.importPayloads)
          .get();
      final backgroundJobs = await database
          .select(database.backgroundJobs)
          .get();
      for (final note in notes) {
        if (!_needsLocalTextMigration(note.title) &&
            !_needsLocalTextMigration(note.body)) {
          continue;
        }
        await (database.update(
          database.notes,
        )..where((row) => row.id.equals(note.id))).write(
          NotesCompanion(
            title: Value(
              await _migrateLocalText(note.title, 'notes', note.id, 'title'),
            ),
            body: Value(
              await _migrateLocalText(note.body, 'notes', note.id, 'body'),
            ),
          ),
        );
      }
      for (final message in messages) {
        if (!_needsLocalTextMigration(message.body)) continue;
        await (database.update(
          database.messages,
        )..where((row) => row.id.equals(message.id))).write(
          MessagesCompanion(
            body: Value(
              await _migrateLocalText(
                message.body,
                'messages',
                message.id,
                'body',
              ),
            ),
          ),
        );
      }
      for (final front in fronts) {
        if (!_needsLocalTextMigration(front.label) &&
            !_needsLocalTextMigration(front.statusNote)) {
          continue;
        }
        await (database.update(
          database.frontSessions,
        )..where((row) => row.id.equals(front.id))).write(
          FrontSessionsCompanion(
            label: Value(
              await _migrateNullableLocalText(
                front.label,
                'front_sessions',
                front.id,
                'label',
              ),
            ),
            statusNote: Value(
              await _migrateNullableLocalText(
                front.statusNote,
                'front_sessions',
                front.id,
                'status_note',
              ),
            ),
          ),
        );
      }
      for (final journal in journals) {
        if (!_needsLocalTextMigration(journal.title) &&
            !_needsLocalTextMigration(journal.body)) {
          continue;
        }
        await (database.update(
          database.journalEntries,
        )..where((row) => row.id.equals(journal.id))).write(
          JournalEntriesCompanion(
            title: Value(
              await _migrateNullableLocalText(
                journal.title,
                'journal_entries',
                journal.id,
                'title',
              ),
            ),
            body: Value(
              await _migrateLocalText(
                journal.body,
                'journal_entries',
                journal.id,
                'body',
              ),
            ),
          ),
        );
      }
      for (final reminder in reminders) {
        if (![
          reminder.title,
          reminder.body,
          reminder.scheduleText,
          reminder.triggerEvent,
          reminder.scheduleKind,
          reminder.scheduleTime,
        ].any(_needsLocalTextMigration)) {
          continue;
        }
        await (database.update(
          database.reminders,
        )..where((row) => row.id.equals(reminder.id))).write(
          RemindersCompanion(
            title: Value(
              await _migrateLocalText(
                reminder.title,
                'reminders',
                reminder.id,
                'title',
              ),
            ),
            body: Value(
              await _migrateNullableLocalText(
                reminder.body,
                'reminders',
                reminder.id,
                'body',
              ),
            ),
            scheduleText: Value(
              await _migrateLocalText(
                reminder.scheduleText,
                'reminders',
                reminder.id,
                'schedule_text',
              ),
            ),
            triggerEvent: Value(
              await _migrateNullableLocalText(
                reminder.triggerEvent,
                'reminders',
                reminder.id,
                'trigger_event',
              ),
            ),
            scheduleKind: Value(
              await _migrateNullableLocalText(
                reminder.scheduleKind,
                'reminders',
                reminder.id,
                'schedule_kind',
              ),
            ),
            scheduleTime: Value(
              await _migrateNullableLocalText(
                reminder.scheduleTime,
                'reminders',
                reminder.id,
                'schedule_time',
              ),
            ),
          ),
        );
      }
      for (final poll in polls) {
        if (!_needsLocalTextMigration(poll.question) &&
            !_needsLocalTextMigration(poll.description)) {
          continue;
        }
        await (database.update(
          database.polls,
        )..where((row) => row.id.equals(poll.id))).write(
          PollsCompanion(
            question: Value(
              await _migrateLocalText(
                poll.question,
                'polls',
                poll.id,
                'question',
              ),
            ),
            description: Value(
              await _migrateNullableLocalText(
                poll.description,
                'polls',
                poll.id,
                'description',
              ),
            ),
          ),
        );
      }
      for (final option in pollOptions) {
        if (!_needsLocalTextMigration(option.body)) continue;
        await (database.update(
          database.pollOptions,
        )..where((row) => row.id.equals(option.id))).write(
          PollOptionsCompanion(
            body: Value(
              await _migrateLocalText(
                option.body,
                'poll_options',
                option.id,
                'body',
              ),
            ),
          ),
        );
      }
      for (final field in customFields) {
        if (!_needsLocalTextMigration(field.name) &&
            !_needsLocalTextMigration(field.privacy)) {
          continue;
        }
        await (database.update(
          database.customFieldDefinitions,
        )..where((row) => row.id.equals(field.id))).write(
          CustomFieldDefinitionsCompanion(
            name: Value(
              await _migrateLocalText(
                field.name,
                'custom_field_definitions',
                field.id,
                'name',
              ),
            ),
            privacy: Value(
              await _migrateNullableLocalText(
                field.privacy,
                'custom_field_definitions',
                field.id,
                'privacy',
              ),
            ),
          ),
        );
      }
      for (final value in customFieldValues) {
        if (!_needsLocalTextMigration(value.value)) continue;
        await (database.update(
          database.customFieldValues,
        )..where((row) => row.id.equals(value.id))).write(
          CustomFieldValuesCompanion(
            value: Value(
              await _migrateLocalText(
                value.value,
                'custom_field_values',
                value.id,
                'value',
              ),
            ),
          ),
        );
      }
      for (final group in groups) {
        if (![
          group.name,
          group.colorHex,
          group.description,
          group.emoji,
        ].any(_needsLocalTextMigration)) {
          continue;
        }
        await (database.update(
          database.systemGroups,
        )..where((row) => row.id.equals(group.id))).write(
          SystemGroupsCompanion(
            name: Value(
              await _migrateLocalText(
                group.name,
                'system_groups',
                group.id,
                'name',
              ),
            ),
            colorHex: Value(
              await _migrateNullableLocalText(
                group.colorHex,
                'system_groups',
                group.id,
                'color_hex',
              ),
            ),
            description: Value(
              await _migrateNullableLocalText(
                group.description,
                'system_groups',
                group.id,
                'description',
              ),
            ),
            emoji: Value(
              await _migrateNullableLocalText(
                group.emoji,
                'system_groups',
                group.id,
                'emoji',
              ),
            ),
          ),
        );
      }
      for (final tag in tags) {
        if (!_needsLocalTextMigration(tag.name) &&
            !_needsLocalTextMigration(tag.colorHex)) {
          continue;
        }
        await (database.update(
          database.tags,
        )..where((row) => row.id.equals(tag.id))).write(
          TagsCompanion(
            name: Value(
              await _migrateLocalText(tag.name, 'tags', tag.id, 'name'),
            ),
            colorHex: Value(
              await _migrateNullableLocalText(
                tag.colorHex,
                'tags',
                tag.id,
                'color_hex',
              ),
            ),
          ),
        );
      }
      for (final front in namedFronts) {
        if (![
          front.name,
          front.customLabel,
          front.colorHex,
          front.avatarUrl,
          front.description,
        ].any(_needsLocalTextMigration)) {
          continue;
        }
        await (database.update(
          database.namedFronts,
        )..where((row) => row.id.equals(front.id))).write(
          NamedFrontsCompanion(
            name: Value(
              await _migrateLocalText(
                front.name,
                'named_fronts',
                front.id,
                'name',
              ),
            ),
            customLabel: Value(
              await _migrateNullableLocalText(
                front.customLabel,
                'named_fronts',
                front.id,
                'custom_label',
              ),
            ),
            colorHex: Value(
              await _migrateNullableLocalText(
                front.colorHex,
                'named_fronts',
                front.id,
                'color_hex',
              ),
            ),
            avatarUrl: Value(
              await _migrateNullableLocalText(
                front.avatarUrl,
                'named_fronts',
                front.id,
                'avatar_url',
              ),
            ),
            description: Value(
              await _migrateNullableLocalText(
                front.description,
                'named_fronts',
                front.id,
                'description',
              ),
            ),
          ),
        );
      }
      for (final bucket in privacyBuckets) {
        if (![
          bucket.name,
          bucket.description,
          bucket.colorHex,
        ].any(_needsLocalTextMigration)) {
          continue;
        }
        await (database.update(
          database.privacyBuckets,
        )..where((row) => row.id.equals(bucket.id))).write(
          PrivacyBucketsCompanion(
            name: Value(
              await _migrateLocalText(
                bucket.name,
                'privacy_buckets',
                bucket.id,
                'name',
              ),
            ),
            description: Value(
              await _migrateNullableLocalText(
                bucket.description,
                'privacy_buckets',
                bucket.id,
                'description',
              ),
            ),
            colorHex: Value(
              await _migrateNullableLocalText(
                bucket.colorHex,
                'privacy_buckets',
                bucket.id,
                'color_hex',
              ),
            ),
          ),
        );
      }
      for (final system in systems) {
        if (![
          system.name,
          system.colorHex,
          system.avatarUrl,
          system.description,
        ].any(_needsLocalTextMigration)) {
          continue;
        }
        await (database.update(
          database.pluralSystems,
        )..where((row) => row.id.equals(system.id))).write(
          PluralSystemsCompanion(
            name: Value(
              await _migrateLocalText(
                system.name,
                'plural_systems',
                system.id,
                'name',
              ),
            ),
            colorHex: Value(
              await _migrateNullableLocalText(
                system.colorHex,
                'plural_systems',
                system.id,
                'color_hex',
              ),
            ),
            avatarUrl: Value(
              await _migrateNullableLocalText(
                system.avatarUrl,
                'plural_systems',
                system.id,
                'avatar_url',
              ),
            ),
            description: Value(
              await _migrateNullableLocalText(
                system.description,
                'plural_systems',
                system.id,
                'description',
              ),
            ),
          ),
        );
      }
      for (final category in chatCategories) {
        if (!_needsLocalTextMigration(category.name) &&
            !_needsLocalTextMigration(category.description)) {
          continue;
        }
        await (database.update(
          database.chatCategories,
        )..where((row) => row.id.equals(category.id))).write(
          ChatCategoriesCompanion(
            name: Value(
              await _migrateLocalText(
                category.name,
                'chat_categories',
                category.id,
                'name',
              ),
            ),
            description: Value(
              await _migrateNullableLocalText(
                category.description,
                'chat_categories',
                category.id,
                'description',
              ),
            ),
          ),
        );
      }
      for (final channel in chatChannels) {
        if (![
          channel.name,
          channel.description,
          channel.colorHex,
        ].any(_needsLocalTextMigration)) {
          continue;
        }
        await (database.update(
          database.chatChannels,
        )..where((row) => row.id.equals(channel.id))).write(
          ChatChannelsCompanion(
            name: Value(
              await _migrateLocalText(
                channel.name,
                'chat_channels',
                channel.id,
                'name',
              ),
            ),
            description: Value(
              await _migrateNullableLocalText(
                channel.description,
                'chat_channels',
                channel.id,
                'description',
              ),
            ),
            colorHex: Value(
              await _migrateNullableLocalText(
                channel.colorHex,
                'chat_channels',
                channel.id,
                'color_hex',
              ),
            ),
          ),
        );
      }
      for (final event in notificationEvents) {
        if (!_needsLocalTextMigration(event.title) &&
            !_needsLocalTextMigration(event.body)) {
          continue;
        }
        await (database.update(
          database.notificationEvents,
        )..where((row) => row.id.equals(event.id))).write(
          NotificationEventsCompanion(
            title: Value(
              await _migrateLocalText(
                event.title,
                'notification_events',
                event.id,
                'title',
              ),
            ),
            body: Value(
              await _migrateLocalText(
                event.body,
                'notification_events',
                event.id,
                'body',
              ),
            ),
          ),
        );
      }
      for (final revision in contentRevisions) {
        if (!_needsLocalTextMigration(revision.title) &&
            !_needsLocalTextMigration(revision.body)) {
          continue;
        }
        await (database.update(
          database.contentRevisions,
        )..where((row) => row.id.equals(revision.id))).write(
          ContentRevisionsCompanion(
            title: Value(
              await _migrateNullableLocalText(
                revision.title,
                'content_revisions',
                revision.id,
                'title',
              ),
            ),
            body: Value(
              await _migrateLocalText(
                revision.body,
                'content_revisions',
                revision.id,
                'body',
              ),
            ),
          ),
        );
      }
      for (final event in frontAuditEvents) {
        if (!_needsLocalTextMigration(event.beforeSnapshot) &&
            !_needsLocalTextMigration(event.afterSnapshot)) {
          continue;
        }
        await (database.update(
          database.frontAuditEvents,
        )..where((row) => row.id.equals(event.id))).write(
          FrontAuditEventsCompanion(
            beforeSnapshot: Value(
              await _migrateNullableLocalText(
                event.beforeSnapshot,
                'front_audit_events',
                event.id,
                'before_snapshot',
              ),
            ),
            afterSnapshot: Value(
              await _migrateNullableLocalText(
                event.afterSnapshot,
                'front_audit_events',
                event.id,
                'after_snapshot',
              ),
            ),
          ),
        );
      }
      for (final record in importRecords) {
        if (!_needsLocalTextMigration(record.fileName) &&
            !_needsLocalTextMigration(record.summaryJson)) {
          continue;
        }
        await (database.update(
          database.importRecords,
        )..where((row) => row.id.equals(record.id))).write(
          ImportRecordsCompanion(
            fileName: Value(
              await _migrateNullableLocalText(
                record.fileName,
                'import_records',
                record.id,
                'file_name',
              ),
            ),
            summaryJson: Value(
              await _migrateNullableLocalText(
                record.summaryJson,
                'import_records',
                record.id,
                'summary_json',
              ),
            ),
          ),
        );
      }
      for (final payload in importPayloads) {
        if (!_needsLocalTextMigration(payload.payloadJson)) continue;
        await (database.update(
          database.importPayloads,
        )..where((row) => row.id.equals(payload.id))).write(
          ImportPayloadsCompanion(
            payloadJson: Value(
              await _migrateLocalText(
                payload.payloadJson,
                'import_payloads',
                payload.id,
                'payload_json',
              ),
            ),
          ),
        );
      }
      for (final job in backgroundJobs) {
        if (![
          job.fileName,
          job.payloadJson,
          job.error,
        ].any(_needsLocalTextMigration)) {
          continue;
        }
        await (database.update(
          database.backgroundJobs,
        )..where((row) => row.id.equals(job.id))).write(
          BackgroundJobsCompanion(
            fileName: Value(
              await _migrateNullableLocalText(
                job.fileName,
                'background_jobs',
                job.id,
                'file_name',
              ),
            ),
            payloadJson: Value(
              await _migrateLocalText(
                job.payloadJson,
                'background_jobs',
                job.id,
                'payload_json',
              ),
            ),
            error: Value(
              await _migrateNullableLocalText(
                job.error,
                'background_jobs',
                job.id,
                'error',
              ),
            ),
          ),
        );
      }
      await _writePreference(
        _localEncryptionSweepPreference,
        _localEncryptionSweepVersion,
      );
    });
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
        .asyncMap(_mapHomeSnapshot);
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

    return query.watch().asyncMap(
      (rows) async => [
        for (final row in rows) await _backgroundJobSummary(row),
      ],
    );
  }

  @override
  Stream<List<RetainedImportPayloadSummary>> watchRetainedImportPayloads() {
    return database
        .customSelect(
          '''
SELECT
  import_record_id,
  source,
  imported_at,
  COUNT(*) AS payload_count,
  GROUP_CONCAT(collection, char(31)) AS collections
FROM import_payloads
WHERE system_id = ?
GROUP BY import_record_id, source, imported_at
ORDER BY imported_at DESC
''',
          variables: [Variable(localSystemId)],
          readsFrom: {database.importPayloads},
        )
        .watch()
        .map(
          (rows) => [
            for (final row in rows)
              RetainedImportPayloadSummary(
                importRecordId: row.read<String>('import_record_id'),
                source: row.read<String>('source'),
                collections:
                    row
                        .read<String>('collections')
                        .split(String.fromCharCode(31))
                      ..sort(),
                payloadCount: row.read<int>('payload_count'),
                importedAt: row.read<DateTime>('imported_at'),
              ),
          ],
        );
  }

  @override
  Future<void> deleteRetainedImportPayloads(String importRecordId) {
    return (database.delete(database.importPayloads)..where(
          (payload) =>
              payload.systemId.equals(localSystemId) &
              payload.importRecordId.equals(importRecordId),
        ))
        .go();
  }

  Future<BackgroundJobSummary> _backgroundJobSummary(BackgroundJob row) async {
    return BackgroundJobSummary(
      id: row.id,
      type: row.type,
      status: row.status,
      source: row.source,
      fileName: await _decryptLocalText(
        row.fileName,
        'background_jobs',
        row.id,
        'file_name',
      ),
      error: await _decryptLocalText(
        row.error,
        'background_jobs',
        row.id,
        'error',
      ),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  @override
  Stream<List<MemberSummary>> watchMembers({
    bool includeArchived = false,
    bool includeCustomFronts = false,
  }) => _members.watch(
    includeArchived: includeArchived,
    includeCustomFronts: includeCustomFronts,
  );

  @override
  Stream<List<MemberSummary>> watchCurrentFrontMembers() =>
      _members.watchCurrentFront();

  @override
  Stream<List<CustomFieldSummary>> watchCustomFields() {
    final query = database.select(database.customFieldDefinitions)
      ..where((field) => field.systemId.equals(localSystemId))
      ..orderBy([
        (field) =>
            OrderingTerm(expression: field.position, mode: OrderingMode.asc),
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
            name:
                (await _decryptLocalText(
                  field.name,
                  'custom_field_definitions',
                  field.id,
                  'name',
                )) ??
                '',
            fieldType: field.fieldType,
            privacy: await _decryptLocalText(
              field.privacy,
              'custom_field_definitions',
              field.id,
              'privacy',
            ),
            position: field.position,
            valueCount: valueCounts[field.id] ?? 0,
          ),
      ];
    });
  }

  @override
  Stream<List<CustomFieldValueSummary>> watchCustomFieldValues() {
    return database.select(database.customFieldValues).watch().asyncMap((
      rows,
    ) async {
      final fields = await (database.select(
        database.customFieldDefinitions,
      )..where((field) => field.systemId.equals(localSystemId))).get();
      final fieldIds = fields.map((field) => field.id).toSet();
      return [
        for (final row in rows)
          if (fieldIds.contains(row.fieldId))
            CustomFieldValueSummary(
              id: row.id,
              fieldId: row.fieldId,
              memberId: row.memberId,
              value:
                  (await _decryptLocalText(
                    row.value,
                    'custom_field_values',
                    row.id,
                    'value',
                  )) ??
                  '',
            ),
      ];
    });
  }

  @override
  Stream<List<GroupSummary>> watchGroups() => _groups.watch();

  @override
  Stream<List<PrivacyBucketSummary>> watchPrivacyBuckets() {
    return database
        .customSelect(
          '''
SELECT
  pb.id,
  pb.name,
  pb.description,
  pb.color_hex,
  GROUP_CONCAT(pbm.member_id) AS member_ids
FROM privacy_buckets pb
LEFT JOIN privacy_bucket_members pbm ON pbm.bucket_id = pb.id
WHERE pb.system_id = ?
GROUP BY pb.id, pb.name, pb.description, pb.color_hex, pb.position
ORDER BY pb.position ASC
''',
          variables: [Variable<String>(localSystemId)],
          readsFrom: {database.privacyBuckets, database.privacyBucketMembers},
        )
        .watch()
        .asyncMap(
          (rows) async => [
            for (final row in rows)
              PrivacyBucketSummary(
                id: row.read<String>('id'),
                name:
                    (await _decryptLocalText(
                      row.read<String>('name'),
                      'privacy_buckets',
                      row.read<String>('id'),
                      'name',
                    )) ??
                    '',
                description: await _decryptLocalText(
                  row.readNullable<String>('description'),
                  'privacy_buckets',
                  row.read<String>('id'),
                  'description',
                ),
                colorHex: await _decryptLocalText(
                  row.readNullable<String>('color_hex'),
                  'privacy_buckets',
                  row.read<String>('id'),
                  'color_hex',
                ),
                memberIds: _splitJoinedIds(row.data['member_ids']),
              ),
          ],
        );
  }

  @override
  Stream<List<NoteSummary>> watchNotes() => _notes.watch();

  @override
  Stream<List<MessageSummary>> watchMessages() => _messages.watch();

  @override
  Stream<List<ChatCategorySummary>> watchChatCategories() =>
      _chat.watchCategories();

  @override
  Stream<List<ChatChannelSummary>> watchChatChannels() => _chat.watchChannels();

  @override
  Stream<List<ReminderSummary>> watchReminders() => _reminders.watch();

  @override
  Stream<List<PollSummary>> watchPolls() => _polls.watch();

  @override
  Stream<List<NotificationEventSummary>> watchNotificationEvents() {
    final query = database.select(database.notificationEvents)
      ..where((event) => event.systemId.equals(localSystemId))
      ..orderBy([
        (event) =>
            OrderingTerm(expression: event.createdAt, mode: OrderingMode.desc),
      ]);

    return query.watch().asyncMap(
      (rows) async => [
        for (final row in rows)
          NotificationEventSummary(
            id: row.id,
            kind: row.kind,
            title:
                (await _decryptLocalText(
                  row.title,
                  'notification_events',
                  row.id,
                  'title',
                )) ??
                '',
            body:
                (await _decryptLocalText(
                  row.body,
                  'notification_events',
                  row.id,
                  'body',
                )) ??
                '',
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
      final links = await (database.select(
        database.frontSessionMembers,
      )..where((link) => link.sessionId.equals(row.id))).get();
      entries.add(
        FrontHistoryEntry(
          id: row.id,
          label: await _frontHistoryLabel(row),
          statusNote: await _decryptLocalText(
            row.statusNote,
            'front_sessions',
            row.id,
            'status_note',
          ),
          startedAt: row.startedAt,
          endedAt: row.endedAt,
          memberIds: [for (final link in links) link.memberId],
        ),
      );
    }
    return entries;
  }

  Future<String> _frontHistoryLabel(FrontSession row) async {
    final explicit = (await _decryptLocalText(
      row.label,
      'front_sessions',
      row.id,
      'label',
    ))?.trim();
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
    final namesById = <String, String>{};
    for (final member in members) {
      final name = (await _decryptMember(
        member,
        'display_name',
        member.displayName,
      ))?.trim();
      if (name != null && name.isNotEmpty) {
        namesById[member.id] = name;
      }
    }
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
  Stream<AppCustomization> watchCustomization() => _customization.watch();

  @override
  Future<AppCustomization> loadCustomization() => _customization.load();

  String get _homeSnapshotSql => '''
SELECT
  COALESCE((SELECT name FROM plural_systems WHERE id = ? LIMIT 1), 'Local system') AS system_name,
  (SELECT color_hex FROM plural_systems WHERE id = ? LIMIT 1) AS system_color_hex,
  (SELECT avatar_url FROM plural_systems WHERE id = ? LIMIT 1) AS system_avatar_url,
  (SELECT description FROM plural_systems WHERE id = ? LIMIT 1) AS system_description,
  (SELECT COUNT(*) FROM members WHERE system_id = ? AND archived = 0 AND is_custom_front = 0) AS member_count,
  (SELECT COUNT(*) FROM system_groups WHERE system_id = ?) AS group_count,
  (SELECT COUNT(*) FROM notes WHERE system_id = ?) AS note_count,
  (SELECT COUNT(*) FROM front_sessions WHERE system_id = ?) AS front_history_count
          ''';

  List<Variable<String>> get _homeSnapshotVariables =>
      List.filled(8, Variable<String>(localSystemId));

  Future<HomeSnapshot> _mapHomeSnapshot(QueryRow row) async {
    final data = row.data;
    final storedSystemName = data['system_name'] as String;

    return HomeSnapshot(
      systemName:
          (storedSystemName.startsWith(_localEncryptedTextPrefix) ||
              storedSystemName.startsWith(_legacyLocalEncryptedTextPrefix))
          ? (await _decryptLocalText(
                  storedSystemName,
                  'plural_systems',
                  localSystemId,
                  'name',
                )) ??
                'Local system'
          : storedSystemName,
      memberCount: data['member_count'] as int,
      groupCount: data['group_count'] as int,
      noteCount: data['note_count'] as int,
      frontHistoryCount: data['front_history_count'] as int,
      currentFrontLabel: await _currentFrontLabel(),
      systemColorHex: await _decryptLocalText(
        data['system_color_hex'] as String?,
        'plural_systems',
        localSystemId,
        'color_hex',
      ),
      systemAvatarUrl: await _decryptLocalText(
        data['system_avatar_url'] as String?,
        'plural_systems',
        localSystemId,
        'avatar_url',
      ),
      systemDescription: await _decryptLocalText(
        data['system_description'] as String?,
        'plural_systems',
        localSystemId,
        'description',
      ),
    );
  }

  @override
  Future<void> updateSystemProfile(SystemProfileDraft draft) async {
    final name = draft.name.trim();
    if (name.isEmpty) {
      throw const FormatException('System name is required.');
    }
    final now = DateTime.now().toUtc();
    await (database.update(
      database.pluralSystems,
    )..where((system) => system.id.equals(localSystemId))).write(
      PluralSystemsCompanion(
        name: Value(
          await _encryptLocalText(
            name,
            'plural_systems',
            localSystemId,
            'name',
          ),
        ),
        colorHex: Value(
          await _encryptNullableLocalText(
            normalizeHexColor(draft.colorHex),
            'plural_systems',
            localSystemId,
            'color_hex',
          ),
        ),
        avatarUrl: Value(
          await _encryptNullableLocalText(
            _trimToNull(draft.avatarUrl),
            'plural_systems',
            localSystemId,
            'avatar_url',
          ),
        ),
        description: Value(
          await _encryptNullableLocalText(
            _trimToNull(draft.description),
            'plural_systems',
            localSystemId,
            'description',
          ),
        ),
        updatedAt: Value(now),
      ),
    );
  }

  Future<String?> _currentFrontLabel() async {
    final sessions =
        await (database.select(database.frontSessions)
              ..where(
                (front) =>
                    front.systemId.equals(localSystemId) &
                    front.endedAt.isNull(),
              )
              ..orderBy([
                (front) => OrderingTerm(
                  expression: front.startedAt,
                  mode: OrderingMode.asc,
                ),
              ]))
            .get();
    if (sessions.isEmpty) {
      return null;
    }

    final labels = <String>[];
    for (final session in sessions) {
      final explicit = (await _decryptLocalText(
        session.label,
        'front_sessions',
        session.id,
        'label',
      ))?.trim();
      if (explicit != null && explicit.isNotEmpty) {
        labels.add(explicit);
        continue;
      }

      final links = await (database.select(
        database.frontSessionMembers,
      )..where((link) => link.sessionId.equals(session.id))).get();
      if (links.isEmpty) {
        continue;
      }

      final members =
          await (database.select(database.members)..where(
                (member) => member.id.isIn(
                  links.map((link) => link.memberId).toSet().toList(),
                ),
              ))
              .get();
      final namesById = <String, String>{};
      for (final member in members) {
        final displayName = await _decryptMember(
          member,
          'display_name',
          member.displayName,
        );
        final name = displayName?.trim() ?? '';
        if (name.isNotEmpty) {
          namesById[member.id] = name;
        }
      }
      for (final link in links) {
        final name = namesById[link.memberId];
        if (name != null && name.isNotEmpty) {
          labels.add(name);
        }
      }
    }

    final uniqueLabels = <String>[];
    final seen = <String>{};
    for (final label in labels) {
      if (seen.add(label.toLowerCase())) {
        uniqueLabels.add(label);
      }
    }
    return uniqueLabels.isEmpty ? null : uniqueLabels.join(', ');
  }

  List<String> _splitJoinedIds(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return const [];
    }
    return value
        .split(',')
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<void> setThemeMode(HavenThemeMode mode) =>
      _customization.setThemeMode(mode);

  @override
  Future<void> setAccentColor(HavenAccentColor color) =>
      _customization.setAccentColor(color);

  @override
  Future<void> setCustomAccentColor(String? colorHex) =>
      _customization.setCustomAccentColor(colorHex);

  @override
  Future<void> setCompactDashboard(bool compact) =>
      _customization.setCompactDashboard(compact);

  @override
  Future<void> setShowDashboardSubtitles(bool show) =>
      _customization.setShowDashboardSubtitles(show);

  @override
  Future<void> setReducedMotion(bool reduced) =>
      _customization.setReducedMotion(reduced);

  @override
  Future<void> setFrontStatusNotification(bool enabled) =>
      _customization.setFrontStatusNotification(enabled);

  @override
  Future<void> setHighContrast(bool highContrast) =>
      _customization.setHighContrast(highContrast);

  @override
  Future<void> setLargeText(bool largeText) =>
      _customization.setLargeText(largeText);

  @override
  Future<void> setCompactLists(bool compact) =>
      _customization.setCompactLists(compact);

  @override
  Future<void> setDashboardShortcutIds(List<String> shortcutIds) =>
      _customization.setDashboardShortcutIds(shortcutIds);

  @override
  Future<void> setLanguageCode(String languageCode) =>
      _customization.setLanguageCode(languageCode);

  @override
  Future<void> setDashboardShortcutVisible(String shortcutId, bool visible) =>
      _customization.setDashboardShortcutVisible(shortcutId, visible);

  @override
  Future<void> moveDashboardShortcut(String shortcutId, int delta) =>
      _customization.moveDashboardShortcut(shortcutId, delta);

  @override
  Future<void> resetDashboardShortcuts() =>
      _customization.resetDashboardShortcuts();

  @override
  Future<void> saveMember(MemberDraft draft) => _members.save(draft);

  @override
  Future<void> archiveMember(String memberId) =>
      _members.archive(memberId, archived: true);

  @override
  Future<void> updateMember(String memberId, MemberDraft draft) =>
      _members.update(memberId, draft);

  Future<String?> _migrateNullableLocalText(
    String? stored,
    String table,
    String rowId,
    String column,
  ) async {
    return stored == null
        ? null
        : _migrateLocalText(stored, table, rowId, column);
  }

  @override
  Future<void> restoreMember(String memberId) =>
      _members.archive(memberId, archived: false);

  @override
  Future<void> deleteMember(String memberId) => _members.delete(memberId);

  @override
  Future<List<ReminderSummary>> setFrontMembers(List<String> memberIds) async {
    final ids = memberIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (ids.isEmpty) {
      await clearCurrentFront();
      return const [];
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
      await clearCurrentFront();
      return const [];
    }

    final now = DateTime.now().toUtc();

    return database.transaction(() async {
      final openSessions =
          await (database.select(database.frontSessions)..where(
                (front) =>
                    front.systemId.equals(localSystemId) &
                    front.endedAt.isNull(),
              ))
              .get();
      final openSessionIds = openSessions.map((session) => session.id).toList();
      final openLinks = openSessionIds.isEmpty
          ? const <FrontSessionMember>[]
          : await (database.select(
              database.frontSessionMembers,
            )..where((link) => link.sessionId.isIn(openSessionIds))).get();

      final sessionsByMember = <String, Set<String>>{};
      for (final link in openLinks) {
        sessionsByMember
            .putIfAbsent(link.memberId, () => <String>{})
            .add(link.sessionId);
      }
      final desiredIds = members.map((member) => member.id).toSet();
      final sessionsToClose = <String>{};
      for (final entry in sessionsByMember.entries) {
        if (!desiredIds.contains(entry.key)) {
          sessionsToClose.addAll(entry.value);
        }
      }

      for (final sessionId in sessionsToClose) {
        await _endFrontSession(sessionId, now);
      }

      final remainingActiveMemberIds = <String>{};
      for (final entry in sessionsByMember.entries) {
        if (entry.value.any(
          (sessionId) => !sessionsToClose.contains(sessionId),
        )) {
          remainingActiveMemberIds.add(entry.key);
        }
      }

      var offset = 0;
      final newlyStartedMemberIds = <String>{};
      for (final member in members) {
        if (remainingActiveMemberIds.contains(member.id)) {
          continue;
        }
        final startedAt = now.add(Duration(microseconds: offset++));
        final sessionId = 'front-${startedAt.microsecondsSinceEpoch}';
        await database
            .into(database.frontSessions)
            .insert(
              FrontSessionsCompanion.insert(
                id: sessionId,
                systemId: localSystemId,
                startedAt: startedAt,
                createdAt: startedAt,
                updatedAt: startedAt,
              ),
            );
        await database
            .into(database.frontSessionMembers)
            .insert(
              FrontSessionMembersCompanion.insert(
                sessionId: sessionId,
                memberId: member.id,
              ),
            );
        newlyStartedMemberIds.add(member.id);
      }

      return _reminders.claimAfterFront(
        newlyStartedMemberIds: newlyStartedMemberIds,
        frontStarted: newlyStartedMemberIds.isNotEmpty,
        firedAt: now,
      );
    });
  }

  @override
  Future<void> updateFrontStatusNote(String frontId, String? statusNote) async {
    await (database.update(database.frontSessions)..where(
          (front) =>
              front.systemId.equals(localSystemId) & front.id.equals(frontId),
        ))
        .write(
          FrontSessionsCompanion(
            statusNote: Value(
              await _encryptNullableLocalText(
                _nullIfBlank(statusNote),
                'front_sessions',
                frontId,
                'status_note',
              ),
            ),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
  }

  @override
  Future<void> saveFrontHistoryEntry(FrontHistoryDraft draft) async {
    final now = DateTime.now().toUtc();
    final id = 'front-${now.microsecondsSinceEpoch}';
    await _writeFrontHistoryEntry(id, draft, now, create: true);
  }

  @override
  Future<void> updateFrontHistoryEntry(
    String frontId,
    FrontHistoryDraft draft,
  ) {
    return _writeFrontHistoryEntry(
      frontId,
      draft,
      DateTime.now().toUtc(),
      create: false,
    );
  }

  Future<void> _writeFrontHistoryEntry(
    String frontId,
    FrontHistoryDraft draft,
    DateTime now, {
    required bool create,
  }) async {
    final startedAt = draft.startedAt.toUtc();
    final endedAt = draft.endedAt.toUtc();
    if (endedAt.isBefore(startedAt)) {
      throw const FormatException('Front end cannot be before its start.');
    }
    final memberIds = draft.memberIds.toSet().toList(growable: false);
    final label = _nullIfBlank(draft.label);
    if (memberIds.isEmpty && label == null) {
      throw const FormatException('Choose members or enter a front label.');
    }
    await database.transaction(() async {
      if (create) {
        await database
            .into(database.frontSessions)
            .insert(
              FrontSessionsCompanion.insert(
                id: frontId,
                systemId: localSystemId,
                label: Value(
                  await _encryptNullableLocalText(
                    memberIds.isEmpty ? label : null,
                    'front_sessions',
                    frontId,
                    'label',
                  ),
                ),
                statusNote: Value(
                  await _encryptNullableLocalText(
                    _nullIfBlank(draft.statusNote),
                    'front_sessions',
                    frontId,
                    'status_note',
                  ),
                ),
                startedAt: startedAt,
                endedAt: Value(endedAt),
                createdAt: now,
                updatedAt: now,
              ),
            );
      } else {
        await (database.update(database.frontSessions)..where(
              (front) =>
                  front.id.equals(frontId) &
                  front.systemId.equals(localSystemId),
            ))
            .write(
              FrontSessionsCompanion(
                label: Value(
                  await _encryptNullableLocalText(
                    memberIds.isEmpty ? label : null,
                    'front_sessions',
                    frontId,
                    'label',
                  ),
                ),
                statusNote: Value(
                  await _encryptNullableLocalText(
                    _nullIfBlank(draft.statusNote),
                    'front_sessions',
                    frontId,
                    'status_note',
                  ),
                ),
                startedAt: Value(startedAt),
                endedAt: Value(endedAt),
                updatedAt: Value(now),
              ),
            );
        await (database.delete(
          database.frontSessionMembers,
        )..where((link) => link.sessionId.equals(frontId))).go();
      }
      for (final memberId in memberIds) {
        await database
            .into(database.frontSessionMembers)
            .insert(
              FrontSessionMembersCompanion.insert(
                sessionId: frontId,
                memberId: memberId,
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
    });
  }

  @override
  Future<void> deleteFrontSession(String frontId) async {
    await database.transaction(() async {
      await (database.delete(
        database.frontSessionMembers,
      )..where((link) => link.sessionId.equals(frontId))).go();
      await (database.delete(database.frontSessions)..where(
            (front) =>
                front.systemId.equals(localSystemId) & front.id.equals(frontId),
          ))
          .go();
    });
  }

  @override
  Future<void> saveGroup(GroupDraft draft) => _groups.save(draft);

  @override
  Future<void> updateGroup(String groupId, GroupDraft draft) =>
      _groups.update(groupId, draft);

  @override
  Future<void> deleteGroup(String groupId) => _groups.delete(groupId);

  @override
  Future<void> savePrivacyBucket(PrivacyBucketDraft draft) async {
    final name = draft.name.trim();
    if (name.isEmpty) return;
    final now = DateTime.now().toUtc();
    final bucketId = 'privacy-bucket-${now.microsecondsSinceEpoch}';
    await database.transaction(() async {
      final positionExpression = database.privacyBuckets.position.max();
      final maxPosition =
          await (database.selectOnly(database.privacyBuckets)
                ..addColumns([positionExpression])
                ..where(database.privacyBuckets.systemId.equals(localSystemId)))
              .map((row) => row.read(positionExpression))
              .getSingle();
      await database
          .into(database.privacyBuckets)
          .insert(
            PrivacyBucketsCompanion.insert(
              id: bucketId,
              systemId: localSystemId,
              name: await _encryptLocalText(
                name,
                'privacy_buckets',
                bucketId,
                'name',
              ),
              description: Value(
                await _encryptNullableLocalText(
                  _nullIfBlank(draft.description),
                  'privacy_buckets',
                  bucketId,
                  'description',
                ),
              ),
              colorHex: Value(
                await _encryptNullableLocalText(
                  normalizeHexColor(draft.colorHex),
                  'privacy_buckets',
                  bucketId,
                  'color_hex',
                ),
              ),
              position: Value((maxPosition ?? -1) + 1),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await _replacePrivacyBucketMembers(bucketId, draft.memberIds);
    });
  }

  @override
  Future<void> updatePrivacyBucket(
    String bucketId,
    PrivacyBucketDraft draft,
  ) async {
    final name = draft.name.trim();
    if (name.isEmpty) return;
    await database.transaction(() async {
      await (database.update(database.privacyBuckets)..where(
            (bucket) =>
                bucket.id.equals(bucketId) &
                bucket.systemId.equals(localSystemId),
          ))
          .write(
            PrivacyBucketsCompanion(
              name: Value(
                await _encryptLocalText(
                  name,
                  'privacy_buckets',
                  bucketId,
                  'name',
                ),
              ),
              description: Value(
                await _encryptNullableLocalText(
                  _nullIfBlank(draft.description),
                  'privacy_buckets',
                  bucketId,
                  'description',
                ),
              ),
              colorHex: Value(
                await _encryptNullableLocalText(
                  normalizeHexColor(draft.colorHex),
                  'privacy_buckets',
                  bucketId,
                  'color_hex',
                ),
              ),
              updatedAt: Value(DateTime.now().toUtc()),
            ),
          );
      await _replacePrivacyBucketMembers(bucketId, draft.memberIds);
    });
  }

  Future<void> _replacePrivacyBucketMembers(
    String bucketId,
    List<String> memberIds,
  ) async {
    await (database.delete(
      database.privacyBucketMembers,
    )..where((link) => link.bucketId.equals(bucketId))).go();
    for (final memberId in memberIds.toSet()) {
      await database
          .into(database.privacyBucketMembers)
          .insert(
            PrivacyBucketMembersCompanion.insert(
              bucketId: bucketId,
              memberId: memberId,
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
  }

  @override
  Future<void> deletePrivacyBucket(String bucketId) async {
    await database.transaction(() async {
      await (database.delete(
        database.privacyBucketMembers,
      )..where((link) => link.bucketId.equals(bucketId))).go();
      await (database.delete(database.privacyBuckets)..where(
            (bucket) =>
                bucket.id.equals(bucketId) &
                bucket.systemId.equals(localSystemId),
          ))
          .go();
    });
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
    final fieldId = 'custom-field-${now.microsecondsSinceEpoch}';
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
            id: fieldId,
            systemId: localSystemId,
            name: await _encryptLocalText(
              name,
              'custom_field_definitions',
              fieldId,
              'name',
            ),
            fieldType: Value(fieldType),
            privacy: Value(
              await _encryptNullableLocalText(
                _nullIfBlank(draft.privacy),
                'custom_field_definitions',
                fieldId,
                'privacy',
              ),
            ),
            position: Value((maxPosition ?? -1) + 1),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  @override
  Future<void> updateCustomField(String fieldId, CustomFieldDraft draft) async {
    final name = draft.name.trim();
    if (name.isEmpty) {
      return;
    }

    final fieldType = _allowedCustomFieldTypes.contains(draft.fieldType)
        ? draft.fieldType
        : 'text';
    await (database.update(database.customFieldDefinitions)..where(
          (field) =>
              field.id.equals(fieldId) & field.systemId.equals(localSystemId),
        ))
        .write(
          CustomFieldDefinitionsCompanion(
            name: Value(
              await _encryptLocalText(
                name,
                'custom_field_definitions',
                fieldId,
                'name',
              ),
            ),
            fieldType: Value(fieldType),
            privacy: Value(
              await _encryptNullableLocalText(
                _nullIfBlank(draft.privacy),
                'custom_field_definitions',
                fieldId,
                'privacy',
              ),
            ),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
  }

  @override
  Future<void> deleteCustomField(String fieldId) async {
    await database.transaction(() async {
      await (database.delete(
        database.customFieldValues,
      )..where((value) => value.fieldId.equals(fieldId))).go();
      await (database.delete(database.customFieldDefinitions)..where(
            (field) =>
                field.id.equals(fieldId) & field.systemId.equals(localSystemId),
          ))
          .go();
    });
  }

  @override
  Future<void> setCustomFieldValue({
    required String fieldId,
    required String? memberId,
    required String value,
  }) async {
    final trimmed = value.trim();
    final ownerId = _nullIfBlank(memberId);
    final existing =
        await (database.select(database.customFieldValues)..where(
              (row) =>
                  row.fieldId.equals(fieldId) &
                  (ownerId == null
                      ? row.memberId.isNull()
                      : row.memberId.equals(ownerId)),
            ))
            .getSingleOrNull();

    if (trimmed.isEmpty) {
      if (existing != null) {
        await (database.delete(
          database.customFieldValues,
        )..where((row) => row.id.equals(existing.id))).go();
      }
      return;
    }

    final now = DateTime.now().toUtc();
    if (existing == null) {
      final valueId = 'custom-field-value-${now.microsecondsSinceEpoch}';
      await database
          .into(database.customFieldValues)
          .insert(
            CustomFieldValuesCompanion.insert(
              id: valueId,
              fieldId: fieldId,
              memberId: Value(ownerId),
              value: await _encryptLocalText(
                trimmed,
                'custom_field_values',
                valueId,
                'value',
              ),
              createdAt: now,
              updatedAt: now,
            ),
          );
      return;
    }

    await (database.update(
      database.customFieldValues,
    )..where((row) => row.id.equals(existing.id))).write(
      CustomFieldValuesCompanion(
        value: Value(
          await _encryptLocalText(
            trimmed,
            'custom_field_values',
            existing.id,
            'value',
          ),
        ),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> saveNote(NoteDraft draft) => _notes.save(draft);

  @override
  Future<void> updateNote(String noteId, NoteDraft draft) =>
      _notes.update(noteId, draft);

  @override
  Future<void> deleteNote(String noteId) => _notes.delete(noteId);

  @override
  Future<void> saveMessage(MessageDraft draft) => _messages.save(draft);

  @override
  Future<void> updateMessage(String messageId, MessageDraft draft) =>
      _messages.update(messageId, draft);

  @override
  Future<void> deleteMessage(String messageId) => _messages.delete(messageId);

  @override
  Future<void> saveChatCategory(ChatCategoryDraft draft) =>
      _chat.saveCategory(draft);

  @override
  Future<void> updateChatCategory(String categoryId, ChatCategoryDraft draft) =>
      _chat.updateCategory(categoryId, draft);

  @override
  Future<void> deleteChatCategory(String categoryId) =>
      _chat.deleteCategory(categoryId);

  @override
  Future<void> saveChatChannel(ChatChannelDraft draft) =>
      _chat.saveChannel(draft);

  @override
  Future<void> updateChatChannel(String channelId, ChatChannelDraft draft) =>
      _chat.updateChannel(channelId, draft);

  @override
  Future<void> deleteChatChannel(String channelId) =>
      _chat.deleteChannel(channelId);

  @override
  Future<String?> saveReminder(ReminderDraft draft) => _reminders.save(draft);

  @override
  Future<void> setReminderEnabled(String reminderId, bool enabled) =>
      _reminders.setEnabled(reminderId, enabled);

  @override
  Future<void> deleteReminder(String reminderId) =>
      _reminders.delete(reminderId);

  @override
  Future<void> savePoll(PollDraft draft) => _polls.save(draft);

  @override
  Future<void> togglePollOption(String pollId, String optionId) =>
      _polls.toggleOption(pollId, optionId);

  @override
  Future<void> closePoll(String pollId) => _polls.close(pollId);

  @override
  Future<void> deletePoll(String pollId) => _polls.delete(pollId);

  @override
  Future<void> recordNotificationEvent(NotificationEventDraft draft) async {
    final title = draft.title.trim();
    final body = draft.body.trim();
    if (title.isEmpty && body.isEmpty) {
      return;
    }

    final now = DateTime.now().toUtc();
    final eventId = 'notification-${now.microsecondsSinceEpoch}';
    await database
        .into(database.notificationEvents)
        .insert(
          NotificationEventsCompanion.insert(
            id: eventId,
            systemId: localSystemId,
            kind: draft.kind.trim().isEmpty ? 'general' : draft.kind.trim(),
            title: await _encryptLocalText(
              title.isEmpty ? 'Notification' : title,
              'notification_events',
              eventId,
              'title',
            ),
            body: await _encryptLocalText(
              body,
              'notification_events',
              eventId,
              'body',
            ),
            createdAt: now,
          ),
        );
  }

  Future<bool> _preferenceEquals(String key, String expectedValue) async {
    final preference = await (database.select(
      database.appPreferences,
    )..where((row) => row.key.equals(key))).getSingleOrNull();
    return preference?.value == expectedValue;
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
  Future<List<ReminderSummary>> setCustomFront(String label) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty) {
      await clearCurrentFront();
      return const [];
    }

    final now = DateTime.now().toUtc();

    return database.transaction(() async {
      final existing =
          await (database.select(database.frontSessions)..where(
                (front) =>
                    front.systemId.equals(localSystemId) &
                    front.endedAt.isNull(),
              ))
              .get();
      for (final front in existing) {
        if ((await _decryptLocalText(
              front.label,
              'front_sessions',
              front.id,
              'label',
            ))?.trim() ==
            trimmed) {
          return const <ReminderSummary>[];
        }
      }

      final frontId = 'front-${now.microsecondsSinceEpoch}';
      await database
          .into(database.frontSessions)
          .insert(
            FrontSessionsCompanion.insert(
              id: frontId,
              systemId: localSystemId,
              label: Value(
                await _encryptLocalText(
                  trimmed,
                  'front_sessions',
                  frontId,
                  'label',
                ),
              ),
              startedAt: now,
              createdAt: now,
              updatedAt: now,
            ),
          );
      return _reminders.claimAfterFront(
        newlyStartedMemberIds: const {},
        frontStarted: true,
        firedAt: now,
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
    final memberIds = members.map((member) => member.id).toSet();
    final groups = await (database.select(
      database.systemGroups,
    )..where((group) => group.systemId.equals(localSystemId))).get();
    final groupIds = groups.map((group) => group.id).toSet();
    final groupMembers = await database.select(database.groupMembers).get();
    final notes = await (database.select(
      database.notes,
    )..where((note) => note.systemId.equals(localSystemId))).get();
    final noteIds = notes.map((note) => note.id).toSet();
    final chatCategories = await (database.select(
      database.chatCategories,
    )..where((category) => category.systemId.equals(localSystemId))).get();
    final chatCategoryIds = chatCategories
        .map((category) => category.id)
        .toSet();
    final chatChannels = await (database.select(
      database.chatChannels,
    )..where((channel) => channel.systemId.equals(localSystemId))).get();
    final messages = await (database.select(
      database.messages,
    )..where((message) => message.systemId.equals(localSystemId))).get();
    final messageIds = messages.map((message) => message.id).toSet();
    final reminders = await (database.select(
      database.reminders,
    )..where((reminder) => reminder.systemId.equals(localSystemId))).get();
    final tags = await (database.select(
      database.tags,
    )..where((tag) => tag.systemId.equals(localSystemId))).get();
    final tagIds = tags.map((tag) => tag.id).toSet();
    final memberTags = await database.select(database.memberTags).get();
    final journals = await (database.select(
      database.journalEntries,
    )..where((journal) => journal.systemId.equals(localSystemId))).get();
    final journalIds = journals.map((journal) => journal.id).toSet();
    final contentRevisions = await database
        .select(database.contentRevisions)
        .get();
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
    final pollOptionIds = pollOptions.map((option) => option.id).toSet();
    final pollVotes = await database.select(database.pollVotes).get();
    final pollVoteEvents = await database.select(database.pollVoteEvents).get();
    final fronts = await (database.select(
      database.frontSessions,
    )..where((front) => front.systemId.equals(localSystemId))).get();
    final frontIds = fronts.map((front) => front.id).toSet();
    final frontMembers = await database
        .select(database.frontSessionMembers)
        .get();
    final frontAuditEvents = await database
        .select(database.frontAuditEvents)
        .get();
    final namedFronts = await (database.select(
      database.namedFronts,
    )..where((front) => front.systemId.equals(localSystemId))).get();
    final namedFrontIds = namedFronts.map((front) => front.id).toSet();
    final namedFrontMembers = await database
        .select(database.namedFrontMembers)
        .get();
    final privacyBuckets = await (database.select(
      database.privacyBuckets,
    )..where((bucket) => bucket.systemId.equals(localSystemId))).get();
    final privacyBucketIds = privacyBuckets.map((bucket) => bucket.id).toSet();
    final privacyBucketMembers = await database
        .select(database.privacyBucketMembers)
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
    final avatarAssets = await _exportLocalAvatarAssets([
      if (systems.isNotEmpty)
        await _decryptLocalText(
          systems.single.avatarUrl,
          'plural_systems',
          systems.single.id,
          'avatar_url',
        ),
      for (final member in members)
        await _decryptMember(member, 'avatar_url', member.avatarUrl),
      for (final front in namedFronts)
        await _decryptLocalText(
          front.avatarUrl,
          'named_fronts',
          front.id,
          'avatar_url',
        ),
    ]);

    final archive = {
      'format': 'pluris_haven.local_archive',
      'version': 1,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'system': systems.isEmpty ? null : await _systemToJson(systems.single),
      'members': [for (final member in members) await _memberToJson(member)],
      'groups': [for (final group in groups) await _groupToJson(group)],
      'group_members': [
        for (final link in groupMembers)
          if (groupIds.contains(link.groupId)) _groupMemberToJson(link),
      ],
      'notes': [for (final note in notes) await _noteToJson(note)],
      'chat_categories': [
        for (final category in chatCategories)
          await _chatCategoryToJson(category),
      ],
      'chat_channels': [
        for (final channel in chatChannels)
          if (channel.categoryId == null ||
              chatCategoryIds.contains(channel.categoryId))
            await _chatChannelToJson(channel),
      ],
      'messages': [
        for (final message in messages) await _messageToJson(message),
      ],
      'reminders': [
        for (final reminder in reminders) await _reminderToJson(reminder),
      ],
      'tags': [for (final tag in tags) await _tagToJson(tag)],
      'member_tags': [
        for (final link in memberTags)
          if (tagIds.contains(link.tagId) && memberIds.contains(link.memberId))
            _memberTagToJson(link),
      ],
      'journals': [
        for (final journal in journals) await _journalToJson(journal),
      ],
      'content_revisions': [
        for (final revision in contentRevisions)
          if (_revisionBelongsToArchive(
            revision,
            memberIds: memberIds,
            noteIds: noteIds,
            journalIds: journalIds,
            messageIds: messageIds,
          ))
            await _contentRevisionToJson(revision),
      ],
      'custom_fields': [
        for (final field in customFields) await _customFieldToJson(field),
      ],
      'custom_field_values': [
        for (final value in customFieldValues)
          if (customFieldIds.contains(value.fieldId))
            await _customFieldValueToJson(value),
      ],
      'polls': [for (final poll in polls) await _pollToJson(poll)],
      'poll_options': [
        for (final option in pollOptions)
          if (pollIds.contains(option.pollId)) await _pollOptionToJson(option),
      ],
      'poll_votes': [
        for (final vote in pollVotes)
          if (pollIds.contains(vote.pollId)) _pollVoteToJson(vote),
      ],
      'poll_vote_events': [
        for (final event in pollVoteEvents)
          if (pollIds.contains(event.pollId) &&
              pollOptionIds.contains(event.optionId))
            _pollVoteEventToJson(event),
      ],
      'fronts': [for (final front in fronts) await _frontToJson(front)],
      'front_members': [
        for (final link in frontMembers)
          if (frontIds.contains(link.sessionId)) _frontMemberToJson(link),
      ],
      'front_audit_events': [
        for (final event in frontAuditEvents)
          if (frontIds.contains(event.frontId))
            await _frontAuditEventToJson(event),
      ],
      'named_fronts': [
        for (final front in namedFronts) await _namedFrontToJson(front),
      ],
      'named_front_members': [
        for (final link in namedFrontMembers)
          if (namedFrontIds.contains(link.namedFrontId))
            _namedFrontMemberToJson(link),
      ],
      'privacy_buckets': [
        for (final bucket in privacyBuckets) await _privacyBucketToJson(bucket),
      ],
      'privacy_bucket_members': [
        for (final link in privacyBucketMembers)
          if (privacyBucketIds.contains(link.bucketId) &&
              memberIds.contains(link.memberId))
            _privacyBucketMemberToJson(link),
      ],
      'avatar_assets': avatarAssets,
      'import_records': [
        for (final record in importRecords) await _importRecordToJson(record),
      ],
      'raw_payloads': [
        for (final payload in importPayloads)
          await _importPayloadToJson(payload),
      ],
      'notification_events': [
        for (final event in notificationEvents)
          await _notificationEventToJson(event),
      ],
      'preferences': [
        for (final preference in preferences) _preferenceToJson(preference),
      ],
    };

    _sanitizeExportedAvatarReferences(
      archive,
      embeddedAssetIds: {
        for (final asset in avatarAssets) ?_stringValue(asset['id']),
      },
    );

    return const JsonEncoder.withIndent('  ').convert(archive);
  }

  void _sanitizeExportedAvatarReferences(
    Map<String, Object?> archive, {
    required Set<String> embeddedAssetIds,
  }) {
    void sanitizeRecord(Object? value) {
      if (value is! Map<String, Object?>) {
        return;
      }
      value['avatar_url'] = _portableExportAvatarReference(
        _stringValue(value['avatar_url']),
        embeddedAssetIds: embeddedAssetIds,
      );
    }

    sanitizeRecord(archive['system']);
    for (final collectionName in const ['members', 'named_fronts']) {
      final records = archive[collectionName];
      if (records is List<Object?>) {
        for (final record in records) {
          sanitizeRecord(record);
        }
      }
    }
  }

  String? _portableExportAvatarReference(
    String? value, {
    required Set<String> embeddedAssetIds,
  }) {
    final reference = value?.trim();
    if (reference == null || reference.isEmpty) {
      return null;
    }

    const localPrefix = 'local-avatar:';
    if (reference.startsWith(localPrefix)) {
      final assetId = reference.substring(localPrefix.length).trim();
      return embeddedAssetIds.contains(assetId) ? '$localPrefix$assetId' : null;
    }

    final uri = Uri.tryParse(reference);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return reference;
    }

    // Native document URIs and filesystem paths only work on the source
    // device. Exported avatar bytes must be referenced through avatar_assets.
    return null;
  }

  @override
  Future<RestoreRehearsalSummary> rehearseLocalArchiveRestore(
    String archiveJson, {
    ImportConflictStrategy strategy = ImportConflictStrategy.prompt,
    String? fileName,
    ImportSource source = ImportSource.plurisHavenArchive,
  }) async {
    final startedAt = DateTime.now().toUtc();
    final previousMultipleDatabaseWarning =
        driftRuntimeOptions.dontWarnAboutMultipleDatabases;
    late final AppDatabase rehearsalDatabase;
    try {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      rehearsalDatabase = AppDatabase(await openRehearsalDatabaseConnection());
    } finally {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases =
          previousMultipleDatabaseWarning;
    }
    try {
      final rehearsalRepository = LocalHavenRepository(
        rehearsalDatabase,
        crypto: crypto,
      );
      await rehearsalRepository.ensureLocalSystem();
      await rehearsalRepository.importLocalArchiveJson(
        archiveJson,
        strategy: strategy,
        fileName: fileName,
        source: source,
        localizeAvatars: false,
      );
      final counts = await _rehearsalCounts(rehearsalDatabase);
      final checkedAt = DateTime.now().toUtc();
      appDebugLog(
        'Restore rehearsal passed source=${source.name} '
        'file=${fileName ?? '(none)'} counts=$counts',
      );
      return RestoreRehearsalSummary(
        canRestore: true,
        fileName: fileName,
        counts: counts,
        checkedAt: checkedAt,
        elapsed: checkedAt.difference(startedAt),
      );
    } on Object catch (error, stackTrace) {
      final checkedAt = DateTime.now().toUtc();
      appDebugLog(
        'Restore rehearsal failed source=${source.name} '
        'file=${fileName ?? '(none)'}',
        error: error,
        stackTrace: stackTrace,
      );
      return RestoreRehearsalSummary(
        canRestore: false,
        fileName: fileName,
        counts: const {},
        checkedAt: checkedAt,
        elapsed: checkedAt.difference(startedAt),
        error: error.toString(),
      );
    } finally {
      await rehearsalDatabase.close();
    }
  }

  Future<Map<String, int>> _rehearsalCounts(AppDatabase database) async {
    final members = await database.select(database.members).get();
    final groups = await database.select(database.systemGroups).get();
    final groupMembers = await database.select(database.groupMembers).get();
    final notes = await database.select(database.notes).get();
    final chatCategories = await database.select(database.chatCategories).get();
    final chatChannels = await database.select(database.chatChannels).get();
    final messages = await database.select(database.messages).get();
    final reminders = await database.select(database.reminders).get();
    final tags = await database.select(database.tags).get();
    final memberTags = await database.select(database.memberTags).get();
    final journals = await database.select(database.journalEntries).get();
    final contentRevisions = await database
        .select(database.contentRevisions)
        .get();
    final customFields = await database
        .select(database.customFieldDefinitions)
        .get();
    final customFieldValues = await database
        .select(database.customFieldValues)
        .get();
    final polls = await database.select(database.polls).get();
    final pollOptions = await database.select(database.pollOptions).get();
    final pollVotes = await database.select(database.pollVotes).get();
    final pollVoteEvents = await database.select(database.pollVoteEvents).get();
    final fronts = await database.select(database.frontSessions).get();
    final frontMembers = await database
        .select(database.frontSessionMembers)
        .get();
    final frontAuditEvents = await database
        .select(database.frontAuditEvents)
        .get();
    final namedFronts = await database.select(database.namedFronts).get();
    final namedFrontMembers = await database
        .select(database.namedFrontMembers)
        .get();
    final privacyBuckets = await database.select(database.privacyBuckets).get();
    final privacyBucketMembers = await database
        .select(database.privacyBucketMembers)
        .get();
    final importRecords = await database.select(database.importRecords).get();
    final rawPayloads = await database.select(database.importPayloads).get();
    final notificationEvents = await database
        .select(database.notificationEvents)
        .get();
    final preferences = await database.select(database.appPreferences).get();

    final customFrontCount = members
        .where((member) => member.isCustomFront)
        .length;

    return {
      'members': members.length - customFrontCount,
      'custom_fronts': customFrontCount,
      'groups': groups.length,
      'group_members': groupMembers.length,
      'notes': notes.length,
      'chat_categories': chatCategories.length,
      'chat_channels': chatChannels.length,
      'messages': messages.length,
      'reminders': reminders.length,
      'tags': tags.length,
      'member_tags': memberTags.length,
      'journals': journals.length,
      'content_revisions': contentRevisions.length,
      'custom_fields': customFields.length,
      'custom_field_values': customFieldValues.length,
      'polls': polls.length,
      'poll_options': pollOptions.length,
      'poll_votes': pollVotes.length,
      'poll_vote_events': pollVoteEvents.length,
      'fronts': fronts.length,
      'front_members': frontMembers.length,
      'front_audit_events': frontAuditEvents.length,
      'named_fronts': namedFronts.length,
      'named_front_members': namedFrontMembers.length,
      'privacy_buckets': privacyBuckets.length,
      'privacy_bucket_members': privacyBucketMembers.length,
      'import_records': importRecords.length,
      'raw_payloads': rawPayloads.length,
      'notification_events': notificationEvents.length,
      'preferences': preferences.length,
    };
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
            fileName: Value(
              await _encryptNullableLocalText(
                _nullIfBlank(fileName),
                'background_jobs',
                jobId,
                'file_name',
              ),
            ),
            payloadJson: await _encryptLocalText(
              jsonEncode({
                'archive_json': archiveJson,
                'strategy': strategy.name,
              }),
              'background_jobs',
              jobId,
              'payload_json',
            ),
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
        final payload = jsonDecode(
          (await _decryptLocalText(
                job.payloadJson,
                'background_jobs',
                job.id,
                'payload_json',
              )) ??
              '',
        );
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
          fileName: await _decryptLocalText(
            job.fileName,
            'background_jobs',
            job.id,
            'file_name',
          ),
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
          error: Value(
            await _encryptLocalText(
              errorText,
              'background_jobs',
              job.id,
              'error',
            ),
          ),
          updatedAt: Value(failed),
          finishedAt: Value(failed),
        ),
      );
      return false;
    }
  }

  Future<bool> runQueuedImportJobs() async {
    final jobs =
        await (database.select(database.backgroundJobs)
              ..where(
                (job) =>
                    job.systemId.equals(localSystemId) &
                    job.type.equals('import_archive') &
                    job.status.isIn(const ['queued', 'running']),
              )
              ..orderBy([
                (job) => OrderingTerm(
                  expression: job.createdAt,
                  mode: OrderingMode.asc,
                ),
              ]))
            .get();
    if (jobs.isEmpty) {
      appDebugLog('No queued import jobs to run');
      return true;
    }

    var allSucceeded = true;
    for (final job in jobs) {
      allSucceeded = await runBackgroundJob(job.id) && allSucceeded;
    }
    return allSucceeded;
  }

  @override
  Future<void> importLocalArchiveJson(
    String archiveJson, {
    ImportConflictStrategy strategy = ImportConflictStrategy.prompt,
    String? fileName,
    ImportSource source = ImportSource.plurisHavenArchive,
    bool localizeAvatars = true,
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
    final groupMembers = _jsonObjectList(decoded['group_members']);
    final notes = _jsonObjectList(decoded['notes']);
    final chatCategories = _jsonObjectList(decoded['chat_categories']);
    final chatChannels = _jsonObjectList(decoded['chat_channels']);
    final messages = _jsonObjectList(decoded['messages']);
    final reminders = _jsonObjectList(decoded['reminders']);
    final tags = _jsonObjectList(decoded['tags']);
    final memberTags = _jsonObjectList(decoded['member_tags']);
    final journals = _jsonObjectList(decoded['journals']);
    final contentRevisions = _jsonObjectList(decoded['content_revisions']);
    final customFields = _jsonObjectList(decoded['custom_fields']);
    final customFieldValues = _jsonObjectList(decoded['custom_field_values']);
    final polls = _jsonObjectList(decoded['polls']);
    final pollOptions = _jsonObjectList(decoded['poll_options']);
    final pollVotes = _jsonObjectList(decoded['poll_votes']);
    final pollVoteEvents = _jsonObjectList(decoded['poll_vote_events']);
    final fronts = _jsonObjectList(decoded['fronts']);
    final frontMembers = _jsonObjectList(decoded['front_members']);
    final frontAuditEvents = _jsonObjectList(decoded['front_audit_events']);
    final namedFronts = _jsonObjectList(decoded['named_fronts']);
    final namedFrontMembers = _jsonObjectList(decoded['named_front_members']);
    final privacyBuckets = _jsonObjectList(decoded['privacy_buckets']);
    final privacyBucketMembers = _jsonObjectList(
      decoded['privacy_bucket_members'],
    );
    final avatarAssets = _jsonObjectList(decoded['avatar_assets']);
    final rawPayloads = _jsonObjectList(decoded['raw_payloads']);
    final notificationEvents = _jsonObjectList(decoded['notification_events']);
    final preferences = _jsonObjectList(decoded['preferences']);
    final cleanupCount = _sanitizeArchiveReferences(
      groups: groups,
      groupMembers: groupMembers,
      members: members,
      notes: notes,
      chatCategories: chatCategories,
      chatChannels: chatChannels,
      messages: messages,
      tags: tags,
      memberTags: memberTags,
      journals: journals,
      contentRevisions: contentRevisions,
      customFields: customFields,
      customFieldValues: customFieldValues,
      polls: polls,
      pollOptions: pollOptions,
      pollVotes: pollVotes,
      pollVoteEvents: pollVoteEvents,
      fronts: fronts,
      frontMembers: frontMembers,
      frontAuditEvents: frontAuditEvents,
      namedFronts: namedFronts,
      namedFrontMembers: namedFrontMembers,
    );
    appDebugLog(
      'Import archive source=${source.name} file=${fileName ?? '(none)'} '
      'members=${members.length} groups=${groups.length} notes=${notes.length} '
      'messages=${messages.length} reminders=${reminders.length} fronts=${fronts.length} '
      'namedFronts=${namedFronts.length} '
      'tags=${tags.length} memberTags=${memberTags.length} journals=${journals.length} '
      'contentRevisions=${contentRevisions.length} frontAuditEvents=${frontAuditEvents.length} '
      'pollVoteEvents=${pollVoteEvents.length} '
      'customFields=${customFields.length} customFieldValues=${customFieldValues.length} '
      'polls=${polls.length} pollOptions=${pollOptions.length} pollVotes=${pollVotes.length} '
      'frontMembers=${frontMembers.length} groupMembers=${groupMembers.length} '
      'cleanup=$cleanupCount',
    );
    final system = decoded['system'];
    final systemRecord = system is Map<String, Object?> ? system : null;
    final localAvatarRefs = localizeAvatars
        ? await _localizeImportAvatars(
            members: [?systemRecord, ...members, ...namedFronts],
            avatarAssets: avatarAssets,
          )
        : const <String, String>{};
    if (localizeAvatars) {
      for (final record in [?systemRecord, ...members, ...namedFronts]) {
        record['avatar_url'] = localAvatarRefs[_requiredString(record, 'id')];
      }
    }

    await database.transaction(() async {
      if (systemRecord != null) {
        final name = _stringValue(systemRecord['name'])?.trim();
        if (name != null && name.isNotEmpty) {
          await database
              .into(database.pluralSystems)
              .insertOnConflictUpdate(
                PluralSystemsCompanion.insert(
                  id: localSystemId,
                  name: await _encryptLocalText(
                    name,
                    'plural_systems',
                    localSystemId,
                    'name',
                  ),
                  colorHex: Value(
                    await _encryptNullableLocalText(
                      _stringValue(systemRecord['color_hex']),
                      'plural_systems',
                      localSystemId,
                      'color_hex',
                    ),
                  ),
                  avatarUrl: Value(
                    await _encryptNullableLocalText(
                      localAvatarRefs[localSystemId] ??
                          _stringValue(systemRecord['avatar_url']),
                      'plural_systems',
                      localSystemId,
                      'avatar_url',
                    ),
                  ),
                  description: Value(
                    await _encryptNullableLocalText(
                      _stringValue(systemRecord['description']),
                      'plural_systems',
                      localSystemId,
                      'description',
                    ),
                  ),
                  createdAt: _dateValue(systemRecord['created_at']) ?? now,
                  updatedAt: now,
                ),
              );
        }
      }

      for (final group in groups) {
        await _importGroup(group, strategy, now);
      }
      for (final member in members) {
        final memberId = _requiredString(member, 'id');
        await _importMember(member, strategy, now, localAvatarRefs[memberId]);
        final folderId = _stringValue(member['folder_id']);
        if (folderId != null) {
          await _importGroupMember({
            'group_id': folderId,
            'member_id': memberId,
          });
        }
      }
      for (final link in groupMembers) {
        await _importGroupMember(link);
      }
      for (final note in notes) {
        await _importNote(note, strategy, now);
      }
      for (final category in chatCategories) {
        await _importChatCategory(category, strategy, now);
      }
      for (final channel in chatChannels) {
        await _importChatChannel(channel, strategy, now);
      }
      for (final message in messages) {
        await _importMessage(message, strategy, now);
      }
      for (final reminder in reminders) {
        await _importReminder(reminder, strategy, now);
      }
      for (final tag in tags) {
        await _importTag(tag, strategy, now);
      }
      for (final link in memberTags) {
        await _importMemberTag(link);
      }
      for (final journal in journals) {
        await _importJournal(journal, strategy, now);
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
      for (final event in pollVoteEvents) {
        await _importPollVoteEvent(event, strategy, now);
      }
      for (final front in fronts) {
        await _importFront(front, strategy, now);
      }
      for (final link in frontMembers) {
        await _importFrontMember(link);
      }
      for (final event in frontAuditEvents) {
        await _importFrontAuditEvent(event, strategy, now);
      }
      for (final namedFront in namedFronts) {
        await _importNamedFront(
          namedFront,
          strategy,
          now,
          localAvatarRefs[_requiredString(namedFront, 'id')],
        );
      }
      for (final link in namedFrontMembers) {
        await _importNamedFrontMember(link);
      }
      for (final bucket in privacyBuckets) {
        await _importPrivacyBucket(bucket, strategy, now);
      }
      for (final link in privacyBucketMembers) {
        await _importPrivacyBucketMember(link);
      }
      for (final event in notificationEvents) {
        await _importNotificationEvent(event, strategy, now);
      }
      for (final preference in preferences) {
        await _importPreference(preference, strategy, now);
      }
      for (final revision in contentRevisions) {
        await _importContentRevision(revision, strategy, now);
      }

      final importRecordId = 'import-${now.microsecondsSinceEpoch}';
      await database
          .into(database.importRecords)
          .insert(
            ImportRecordsCompanion.insert(
              id: importRecordId,
              systemId: localSystemId,
              source: source.jobSource,
              fileName: Value(
                await _encryptNullableLocalText(
                  _nullIfBlank(fileName),
                  'import_records',
                  importRecordId,
                  'file_name',
                ),
              ),
              summaryJson: Value(
                await _encryptLocalText(
                  jsonEncode({
                    'members': members.length,
                    'groups': groups.length,
                    'group_members': groupMembers.length,
                    'notes': notes.length,
                    'chat_categories': chatCategories.length,
                    'chat_channels': chatChannels.length,
                    'messages': messages.length,
                    'reminders': reminders.length,
                    'tags': tags.length,
                    'member_tags': memberTags.length,
                    'journals': journals.length,
                    'content_revisions': contentRevisions.length,
                    'custom_fields': customFields.length,
                    'custom_field_values': customFieldValues.length,
                    'polls': polls.length,
                    'poll_options': pollOptions.length,
                    'poll_votes': pollVotes.length,
                    'poll_vote_events': pollVoteEvents.length,
                    'fronts': fronts.length,
                    'front_members': frontMembers.length,
                    'front_audit_events': frontAuditEvents.length,
                    'named_fronts': namedFronts.length,
                    'named_front_members': namedFrontMembers.length,
                    'privacy_buckets': privacyBuckets.length,
                    'privacy_bucket_members': privacyBucketMembers.length,
                    'avatar_assets': avatarAssets.length,
                    'raw_payloads': rawPayloads.length,
                    'notification_events': notificationEvents.length,
                    'preferences': preferences.length,
                  }),
                  'import_records',
                  importRecordId,
                  'summary_json',
                ),
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
    required List<Map<String, Object?>> groupMembers,
    required List<Map<String, Object?>> members,
    required List<Map<String, Object?>> notes,
    required List<Map<String, Object?>> chatCategories,
    required List<Map<String, Object?>> chatChannels,
    required List<Map<String, Object?>> messages,
    required List<Map<String, Object?>> tags,
    required List<Map<String, Object?>> memberTags,
    required List<Map<String, Object?>> journals,
    required List<Map<String, Object?>> contentRevisions,
    required List<Map<String, Object?>> customFields,
    required List<Map<String, Object?>> customFieldValues,
    required List<Map<String, Object?>> polls,
    required List<Map<String, Object?>> pollOptions,
    required List<Map<String, Object?>> pollVotes,
    required List<Map<String, Object?>> pollVoteEvents,
    required List<Map<String, Object?>> fronts,
    required List<Map<String, Object?>> frontMembers,
    required List<Map<String, Object?>> frontAuditEvents,
    required List<Map<String, Object?>> namedFronts,
    required List<Map<String, Object?>> namedFrontMembers,
  }) {
    final groupIds = {
      for (final group in groups) _stringValue(group['id']),
    }.whereType<String>().toSet();
    final memberIds = {
      for (final member in members) _stringValue(member['id']),
    }.whereType<String>().toSet();
    final noteIds = {
      for (final note in notes) _stringValue(note['id']),
    }.whereType<String>().toSet();
    final chatCategoryIds = {
      for (final category in chatCategories) _stringValue(category['id']),
    }.whereType<String>().toSet();
    final chatChannelIds = {
      for (final channel in chatChannels) _stringValue(channel['id']),
    }.whereType<String>().toSet();
    final messageIds = {
      for (final message in messages) _stringValue(message['id']),
    }.whereType<String>().toSet();
    final tagIds = {
      for (final tag in tags) _stringValue(tag['id']),
    }.whereType<String>().toSet();
    final journalIds = {
      for (final journal in journals) _stringValue(journal['id']),
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
      final groupId = _stringValue(group['id']);
      final parentId = _stringValue(group['parent_group_id']);
      if (parentId != null &&
          (parentId == groupId ||
              !groupIds.contains(parentId) ||
              _groupParentChainHasCycle(groupId, parentId, groups))) {
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

    groupMembers.removeWhere((link) {
      final groupId = _stringValue(link['group_id']);
      final memberId = _stringValue(link['member_id']);
      final keep =
          groupId != null &&
          memberId != null &&
          groupIds.contains(groupId) &&
          memberIds.contains(memberId);
      if (!keep) {
        cleanupCount++;
      }
      return !keep;
    });

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
      final boardMemberId = _stringValue(message['board_member_id']);
      if (boardMemberId != null && !memberIds.contains(boardMemberId)) {
        message['board_member_id'] = null;
        cleanupCount++;
      }
      final channelId = _stringValue(message['channel_id']);
      if (channelId != null && !chatChannelIds.contains(channelId)) {
        message['channel_id'] = null;
        cleanupCount++;
      }
      final parentMessageId = _stringValue(message['parent_message_id']);
      if (parentMessageId != null && !messageIds.contains(parentMessageId)) {
        message['parent_message_id'] = null;
        cleanupCount++;
      }
    }

    for (final channel in chatChannels) {
      final categoryId = _stringValue(channel['category_id']);
      if (categoryId != null && !chatCategoryIds.contains(categoryId)) {
        channel['category_id'] = null;
        cleanupCount++;
      }
    }

    memberTags.removeWhere((link) {
      final tagId = _stringValue(link['tag_id']);
      final memberId = _stringValue(link['member_id']);
      final keep =
          tagId != null &&
          memberId != null &&
          tagIds.contains(tagId) &&
          memberIds.contains(memberId);
      if (!keep) {
        cleanupCount++;
      }
      return !keep;
    });

    for (final journal in journals) {
      final memberId = _stringValue(journal['member_id']);
      if (memberId != null && !memberIds.contains(memberId)) {
        journal['member_id'] = null;
        cleanupCount++;
      }
    }

    contentRevisions.removeWhere((revision) {
      final targetType = _stringValue(revision['target_type']);
      final targetId = _stringValue(revision['target_id']);
      final keep =
          targetType != null &&
          targetId != null &&
          _revisionTargetBelongsToArchive(
            targetType: targetType,
            targetId: targetId,
            memberIds: memberIds,
            noteIds: noteIds,
            journalIds: journalIds,
            messageIds: messageIds,
          );
      if (!keep) {
        cleanupCount++;
      }
      return !keep;
    });

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

    pollVoteEvents.removeWhere((event) {
      final pollId = _stringValue(event['poll_id']);
      final optionId = _stringValue(event['option_id']);
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

    frontAuditEvents.removeWhere((event) {
      final frontId = _stringValue(event['front_id']);
      final keep = frontId != null && frontIds.contains(frontId);
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

  bool _revisionBelongsToArchive(
    ContentRevision revision, {
    required Set<String> memberIds,
    required Set<String> noteIds,
    required Set<String> journalIds,
    required Set<String> messageIds,
  }) {
    return _revisionTargetBelongsToArchive(
      targetType: revision.targetType,
      targetId: revision.targetId,
      memberIds: memberIds,
      noteIds: noteIds,
      journalIds: journalIds,
      messageIds: messageIds,
    );
  }

  bool _revisionTargetBelongsToArchive({
    required String targetType,
    required String targetId,
    required Set<String> memberIds,
    required Set<String> noteIds,
    required Set<String> journalIds,
    required Set<String> messageIds,
  }) {
    return switch (targetType) {
      'member_bio' => memberIds.contains(targetId),
      'note' => noteIds.contains(targetId),
      'journal' => journalIds.contains(targetId),
      'message' => messageIds.contains(targetId),
      _ => false,
    };
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
      if (avatarUrl == null) {
        refs[memberId] = avatarUrl;
        continue;
      }

      if (avatarUrl.startsWith('local-avatar:')) {
        final assetId = avatarUrl.substring('local-avatar:'.length).trim();
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

  Future<List<Map<String, Object?>>> _exportLocalAvatarAssets(
    Iterable<String?> avatarUrls,
  ) async {
    final fileNames =
        <String>{
          for (final avatarUrl in avatarUrls)
            if (avatarUrl != null && avatarUrl.startsWith('local-avatar:'))
              avatarUrl.substring('local-avatar:'.length).trim(),
        }..removeWhere(
          (name) => name.isEmpty || name.contains('/') || name.contains('\\'),
        );
    if (fileNames.isEmpty) {
      return const [];
    }

    final root = await _avatarRootDirectory();
    final assets = <Map<String, Object?>>[];
    for (final fileName in fileNames) {
      final file = File('${root.path}/$fileName');
      if (!await file.exists()) {
        continue;
      }
      final length = await file.length();
      if (length <= 0 || length > 10 * 1024 * 1024) {
        continue;
      }
      final bytes = await file.readAsBytes();
      assets.add({
        'id': fileName,
        'name': fileName,
        'mime_type': _avatarMimeType(fileName, bytes),
        'bytes_base64': base64Encode(bytes),
      });
    }
    return assets;
  }

  String? _avatarMimeType(String fileName, Uint8List bytes) {
    final detected = sniffAvatarMimeType(bytes);
    if (detected != null) return detected;
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.svg')) return 'image/svg+xml';
    return null;
  }

  Future<String?> _downloadAndStoreAvatar(String url) async {
    final uri = Uri.tryParse(url);
    final allowedAddresses = uri == null
        ? null
        : await allowedRemoteAvatarAddresses(uri);
    if (uri == null || allowedAddresses == null) {
      appDebugLog('Avatar download skipped unsafe URL');
      return null;
    }

    final pinnedAddress = allowedAddresses.first;
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 8);
    client.findProxy = (_) => 'DIRECT';
    client.connectionFactory = (requestUri, proxyHost, proxyPort) async {
      if (proxyHost != null ||
          requestUri.host.toLowerCase() != uri.host.toLowerCase() ||
          requestUri.port != uri.port) {
        throw const SocketException('Avatar connection target changed.');
      }
      final task = await Socket.startConnect(pinnedAddress, requestUri.port);
      final secureSocket = task.socket.then(
        (socket) => SecureSocket.secure(socket, host: requestUri.host),
      );
      return ConnectionTask.fromSocket(secureSocket, task.cancel);
    };
    try {
      final request = await client.getUrl(uri);
      request.followRedirects = false;
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        appDebugLog(
          'Avatar download skipped host=${uri.host} status=${response.statusCode}',
        );
        return null;
      }

      final bytes = await _readAvatarResponseBytes(response);
      if (bytes == null || bytes.isEmpty) {
        appDebugLog('Avatar download skipped host=${uri.host} invalid bytes');
        return null;
      }

      return _storeAvatarBytes(
        id: uri.pathSegments.isEmpty ? 'remote-avatar' : uri.pathSegments.last,
        sourceName: uri.pathSegments.isEmpty
            ? 'remote-avatar'
            : uri.pathSegments.last,
        mimeType: response.headers.contentType?.mimeType,
        bytes: bytes,
      );
    } on Object catch (error, stackTrace) {
      appDebugLog(
        'Avatar download failed host=${uri.host}',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    } finally {
      client.close(force: true);
    }
  }

  Future<Uint8List?> _readAvatarResponseBytes(
    HttpClientResponse response,
  ) async {
    final declaredLength = response.contentLength;
    if (declaredLength > maximumAvatarBytes) return null;
    final bytes = BytesBuilder(copy: false);
    await response
        .forEach((chunk) {
          if (bytes.length > maximumAvatarBytes - chunk.length) {
            throw const FormatException('Avatar response exceeds size limit.');
          }
          bytes.add(chunk);
        })
        .timeout(const Duration(seconds: 10));
    return bytes.takeBytes();
  }

  Future<String> _storeAvatarBytes({
    required String id,
    required String sourceName,
    required String? mimeType,
    required Uint8List bytes,
  }) async {
    final root = await _avatarRootDirectory();
    final detectedMimeType = sniffAvatarMimeType(bytes) ?? mimeType;
    final extension = _avatarExtension(sourceName, detectedMimeType);
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
  ) async {
    final id = _requiredString(group, 'id');
    final name = _requiredString(group, 'name');
    final companion = SystemGroupsCompanion.insert(
      id: id,
      systemId: localSystemId,
      parentGroupId: Value(_stringValue(group['parent_group_id'])),
      name: await _encryptLocalText(name, 'system_groups', id, 'name'),
      colorHex: Value(
        await _encryptNullableLocalText(
          _stringValue(group['color_hex']),
          'system_groups',
          id,
          'color_hex',
        ),
      ),
      description: Value(
        await _encryptNullableLocalText(
          _stringValue(group['description']),
          'system_groups',
          id,
          'description',
        ),
      ),
      emoji: Value(
        await _encryptNullableLocalText(
          _stringValue(group['emoji']),
          'system_groups',
          id,
          'emoji',
        ),
      ),
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
  ) async {
    final id = _requiredString(member, 'id');
    final displayName = _requiredString(member, 'display_name');
    final encryptedName = await _encryptMember(id, 'display_name', displayName);
    if (encryptedName == null) {
      throw StateError('Member name encryption returned no value.');
    }
    final companion = MembersCompanion.insert(
      id: id,
      systemId: localSystemId,
      displayName: encryptedName,
      displayNameHash: Value(await _blindIndex(displayName)),
      profileEncryptionVersion: const Value(2),
      pronouns: Value(
        await _encryptMember(id, 'pronouns', _stringValue(member['pronouns'])),
      ),
      colorHex: Value(
        await _encryptMember(
          id,
          'color_hex',
          _stringValue(member['color_hex']),
        ),
      ),
      birthday: Value(
        await _encryptMember(id, 'birthday', _stringValue(member['birthday'])),
      ),
      emoji: Value(
        await _encryptMember(id, 'emoji', _stringValue(member['emoji'])),
      ),
      privacy: Value(
        await _encryptMember(id, 'privacy', _stringValue(member['privacy'])),
      ),
      folderId: Value(_stringValue(member['folder_id'])),
      description: Value(
        await _encryptMember(
          id,
          'description',
          _stringValue(member['description']),
        ),
      ),
      avatarUrl: Value(
        await _encryptMember(
          id,
          'avatar_url',
          localAvatarUrl ?? _stringValue(member['avatar_url']),
        ),
      ),
      pluralKitId: Value(
        await _encryptMember(
          id,
          'pluralkit_id',
          _stringValue(member['pluralkit_id']),
        ),
      ),
      isCustomFront: Value(member['is_custom_front'] == true),
      archived: Value(member['archived'] == true),
      lexoRank: await _members.rankForImport(
        id,
        _stringValue(member['lexo_rank']),
      ),
      createdAt: _dateValue(member['created_at']) ?? now,
      updatedAt: strategy == ImportConflictStrategy.update
          ? now
          : (_dateValue(member['updated_at']) ?? now),
    );
    await _insertArchiveRow(database.members, companion, strategy);
  }

  Future<void> _importGroupMember(Map<String, Object?> link) {
    return database
        .into(database.groupMembers)
        .insert(
          GroupMembersCompanion.insert(
            groupId: _requiredString(link, 'group_id'),
            memberId: _requiredString(link, 'member_id'),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<void> _importNote(
    Map<String, Object?> note,
    ImportConflictStrategy strategy,
    DateTime now,
  ) async {
    final id = _requiredString(note, 'id');
    final title = _requiredString(note, 'title');
    final companion = NotesCompanion.insert(
      id: id,
      systemId: localSystemId,
      memberId: Value(_stringValue(note['member_id'])),
      title: await _encryptLocalText(title, 'notes', id, 'title'),
      body: await _encryptLocalText(
        _stringValue(note['body']) ?? '',
        'notes',
        id,
        'body',
      ),
      createdAt: _dateValue(note['created_at']) ?? now,
      updatedAt: strategy == ImportConflictStrategy.update
          ? now
          : (_dateValue(note['updated_at']) ?? now),
    );
    await _insertArchiveRow(database.notes, companion, strategy);
  }

  Future<void> _importMessage(
    Map<String, Object?> message,
    ImportConflictStrategy strategy,
    DateTime now,
  ) async {
    final id = _requiredString(message, 'id');
    final body = _requiredString(message, 'body');
    final companion = MessagesCompanion.insert(
      id: id,
      systemId: localSystemId,
      memberId: Value(_stringValue(message['member_id'])),
      body: await _encryptLocalText(body, 'messages', id, 'body'),
      boardKind: Value(_stringValue(message['board_kind']) ?? 'system'),
      boardMemberId: Value(_stringValue(message['board_member_id'])),
      parentMessageId: Value(_stringValue(message['parent_message_id'])),
      channelId: Value(_stringValue(message['channel_id'])),
      deletedAt: Value(_dateValue(message['deleted_at'])),
      archived: Value(message['archived'] == true),
      createdAt: _dateValue(message['created_at']) ?? now,
      updatedAt: strategy == ImportConflictStrategy.update
          ? now
          : (_dateValue(message['updated_at']) ?? now),
    );
    await _insertArchiveRow(database.messages, companion, strategy);
  }

  Future<void> _importChatCategory(
    Map<String, Object?> category,
    ImportConflictStrategy strategy,
    DateTime now,
  ) async {
    final id = _requiredString(category, 'id');
    final companion = ChatCategoriesCompanion.insert(
      id: id,
      systemId: localSystemId,
      name: await _encryptLocalText(
        _requiredString(category, 'name'),
        'chat_categories',
        id,
        'name',
      ),
      description: Value(
        await _encryptNullableLocalText(
          _stringValue(category['description']),
          'chat_categories',
          id,
          'description',
        ),
      ),
      position: Value(_intValue(category['position']) ?? 0),
      createdAt: _dateValue(category['created_at']) ?? now,
      updatedAt: strategy == ImportConflictStrategy.update
          ? now
          : (_dateValue(category['updated_at']) ?? now),
    );
    await _insertArchiveRow(database.chatCategories, companion, strategy);
  }

  Future<void> _importChatChannel(
    Map<String, Object?> channel,
    ImportConflictStrategy strategy,
    DateTime now,
  ) async {
    final id = _requiredString(channel, 'id');
    final companion = ChatChannelsCompanion.insert(
      id: id,
      systemId: localSystemId,
      categoryId: Value(_stringValue(channel['category_id'])),
      name: await _encryptLocalText(
        _requiredString(channel, 'name'),
        'chat_channels',
        id,
        'name',
      ),
      description: Value(
        await _encryptNullableLocalText(
          _stringValue(channel['description']),
          'chat_channels',
          id,
          'description',
        ),
      ),
      colorHex: Value(
        await _encryptNullableLocalText(
          normalizeHexColor(_stringValue(channel['color_hex'])),
          'chat_channels',
          id,
          'color_hex',
        ),
      ),
      position: Value(_intValue(channel['position']) ?? 0),
      createdAt: _dateValue(channel['created_at']) ?? now,
      updatedAt: strategy == ImportConflictStrategy.update
          ? now
          : (_dateValue(channel['updated_at']) ?? now),
    );
    await _insertArchiveRow(database.chatChannels, companion, strategy);
  }

  Future<void> _importReminder(
    Map<String, Object?> reminder,
    ImportConflictStrategy strategy,
    DateTime now,
  ) async {
    final id = _requiredString(reminder, 'id');
    final title = _requiredString(reminder, 'title');
    final scheduleText = _requiredString(reminder, 'schedule_text');
    final companion = RemindersCompanion.insert(
      id: id,
      systemId: localSystemId,
      title: await _encryptLocalText(title, 'reminders', id, 'title'),
      body: Value(
        await _encryptNullableLocalText(
          _stringValue(reminder['body']),
          'reminders',
          id,
          'body',
        ),
      ),
      scheduleText: await _encryptLocalText(
        scheduleText,
        'reminders',
        id,
        'schedule_text',
      ),
      triggerType: Value(_stringValue(reminder['trigger_type']) ?? 'repeated'),
      triggerMemberId: Value(_stringValue(reminder['trigger_member_id'])),
      triggerEvent: Value(
        await _encryptNullableLocalText(
          _stringValue(reminder['trigger_event']),
          'reminders',
          id,
          'trigger_event',
        ),
      ),
      scheduleKind: Value(
        await _encryptNullableLocalText(
          _stringValue(reminder['schedule_kind']),
          'reminders',
          id,
          'schedule_kind',
        ),
      ),
      scheduleTime: Value(
        await _encryptNullableLocalText(
          _stringValue(reminder['schedule_time']),
          'reminders',
          id,
          'schedule_time',
        ),
      ),
      scheduleDowMask: Value(_intValue(reminder['schedule_dow_mask'])),
      scheduleDom: Value(_intValue(reminder['schedule_dom'])),
      delaySeconds: Value(_intValue(reminder['delay_seconds'])),
      enabled: Value(reminder['enabled'] != false),
      lastFiredAt: Value(_dateValue(reminder['last_fired_at'])),
      createdAt: _dateValue(reminder['created_at']) ?? now,
      updatedAt: strategy == ImportConflictStrategy.update
          ? now
          : (_dateValue(reminder['updated_at']) ?? now),
    );
    await _insertArchiveRow(database.reminders, companion, strategy);
  }

  Future<void> _importTag(
    Map<String, Object?> tag,
    ImportConflictStrategy strategy,
    DateTime now,
  ) async {
    final id = _requiredString(tag, 'id');
    final companion = TagsCompanion.insert(
      id: id,
      systemId: localSystemId,
      name: await _encryptLocalText(
        _requiredString(tag, 'name'),
        'tags',
        id,
        'name',
      ),
      colorHex: Value(
        await _encryptNullableLocalText(
          _stringValue(tag['color_hex']),
          'tags',
          id,
          'color_hex',
        ),
      ),
      createdAt: _dateValue(tag['created_at']) ?? now,
      updatedAt: strategy == ImportConflictStrategy.update
          ? now
          : (_dateValue(tag['updated_at']) ?? now),
    );
    await _insertArchiveRow(database.tags, companion, strategy);
  }

  Future<void> _importMemberTag(Map<String, Object?> link) {
    return database
        .into(database.memberTags)
        .insert(
          MemberTagsCompanion.insert(
            tagId: _requiredString(link, 'tag_id'),
            memberId: _requiredString(link, 'member_id'),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<void> _importJournal(
    Map<String, Object?> journal,
    ImportConflictStrategy strategy,
    DateTime now,
  ) async {
    final id = _requiredString(journal, 'id');
    final companion = JournalEntriesCompanion.insert(
      id: id,
      systemId: localSystemId,
      memberId: Value(_stringValue(journal['member_id'])),
      title: Value(
        await _encryptNullableLocalText(
          _stringValue(journal['title']),
          'journal_entries',
          id,
          'title',
        ),
      ),
      body: await _encryptLocalText(
        _stringValue(journal['body']) ?? '',
        'journal_entries',
        id,
        'body',
      ),
      visibility: Value(_stringValue(journal['visibility']) ?? 'system'),
      createdAt: _dateValue(journal['created_at']) ?? now,
      updatedAt: strategy == ImportConflictStrategy.update
          ? now
          : (_dateValue(journal['updated_at']) ?? now),
    );
    await _insertArchiveRow(database.journalEntries, companion, strategy);
  }

  Future<void> _importContentRevision(
    Map<String, Object?> revision,
    ImportConflictStrategy strategy,
    DateTime now,
  ) async {
    final id = _requiredString(revision, 'id');
    final companion = ContentRevisionsCompanion.insert(
      id: id,
      targetType: _requiredString(revision, 'target_type'),
      targetId: _requiredString(revision, 'target_id'),
      title: Value(
        await _encryptNullableLocalText(
          _stringValue(revision['title']),
          'content_revisions',
          id,
          'title',
        ),
      ),
      body: await _encryptLocalText(
        _stringValue(revision['body']) ?? '',
        'content_revisions',
        id,
        'body',
      ),
      pinnedAt: Value(_dateValue(revision['pinned_at'])),
      createdAt: _dateValue(revision['created_at']) ?? now,
    );
    await _insertArchiveRow(database.contentRevisions, companion, strategy);
  }

  Future<void> _importCustomField(
    Map<String, Object?> field,
    ImportConflictStrategy strategy,
    DateTime now,
  ) async {
    final id = _requiredString(field, 'id');
    final name = _requiredString(field, 'name');
    final companion = CustomFieldDefinitionsCompanion.insert(
      id: id,
      systemId: localSystemId,
      name: await _encryptLocalText(
        name,
        'custom_field_definitions',
        id,
        'name',
      ),
      fieldType: Value(_stringValue(field['field_type']) ?? 'text'),
      privacy: Value(
        await _encryptNullableLocalText(
          _stringValue(field['privacy']),
          'custom_field_definitions',
          id,
          'privacy',
        ),
      ),
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
  ) async {
    final id = _requiredString(value, 'id');
    final fieldId = _requiredString(value, 'field_id');
    final companion = CustomFieldValuesCompanion.insert(
      id: id,
      fieldId: fieldId,
      memberId: Value(_stringValue(value['member_id'])),
      value: await _encryptLocalText(
        _stringValue(value['value']) ?? '',
        'custom_field_values',
        id,
        'value',
      ),
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
  ) async {
    final id = _requiredString(poll, 'id');
    final question = _requiredString(poll, 'question');
    final companion = PollsCompanion.insert(
      id: id,
      systemId: localSystemId,
      question: await _encryptLocalText(question, 'polls', id, 'question'),
      description: Value(
        await _encryptNullableLocalText(
          _stringValue(poll['description']),
          'polls',
          id,
          'description',
        ),
      ),
      kind: Value(
        PollKind.fromStorage(_stringValue(poll['kind'])).storageValue,
      ),
      closed: Value(poll['closed'] == true),
      createdAt: _dateValue(poll['created_at']) ?? now,
      updatedAt: strategy == ImportConflictStrategy.update
          ? now
          : (_dateValue(poll['updated_at']) ?? now),
    );
    await _insertArchiveRow(database.polls, companion, strategy);
  }

  Future<void> _importPollOption(
    Map<String, Object?> option,
    ImportConflictStrategy strategy,
  ) async {
    final id = _requiredString(option, 'id');
    final companion = PollOptionsCompanion.insert(
      id: id,
      pollId: _requiredString(option, 'poll_id'),
      body: await _encryptLocalText(
        _requiredString(option, 'body'),
        'poll_options',
        id,
        'body',
      ),
      position: _intValue(option['position']) ?? 0,
    );
    await _insertArchiveRow(database.pollOptions, companion, strategy);
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

  Future<void> _importPollVoteEvent(
    Map<String, Object?> event,
    ImportConflictStrategy strategy,
    DateTime now,
  ) {
    final id = _requiredString(event, 'id');
    final companion = PollVoteEventsCompanion.insert(
      id: id,
      pollId: _requiredString(event, 'poll_id'),
      optionId: _requiredString(event, 'option_id'),
      action: _requiredString(event, 'action'),
      createdAt: _dateValue(event['created_at']) ?? now,
    );
    return _insertArchiveRow(database.pollVoteEvents, companion, strategy);
  }

  Future<void> _importFront(
    Map<String, Object?> front,
    ImportConflictStrategy strategy,
    DateTime now,
  ) async {
    final id = _requiredString(front, 'id');
    final companion = FrontSessionsCompanion.insert(
      id: id,
      systemId: localSystemId,
      label: Value(
        await _encryptNullableLocalText(
          _stringValue(front['label']),
          'front_sessions',
          id,
          'label',
        ),
      ),
      statusNote: Value(
        await _encryptNullableLocalText(
          _stringValue(front['status_note']),
          'front_sessions',
          id,
          'status_note',
        ),
      ),
      startedAt: _dateValue(front['started_at']) ?? now,
      endedAt: Value(_dateValue(front['ended_at'])),
      createdAt: _dateValue(front['created_at']) ?? now,
      updatedAt: strategy == ImportConflictStrategy.update
          ? now
          : (_dateValue(front['updated_at']) ?? now),
    );
    await _insertArchiveRow(database.frontSessions, companion, strategy);
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

  Future<void> _importFrontAuditEvent(
    Map<String, Object?> event,
    ImportConflictStrategy strategy,
    DateTime now,
  ) async {
    final id = _requiredString(event, 'id');
    final companion = FrontAuditEventsCompanion.insert(
      id: id,
      frontId: _requiredString(event, 'front_id'),
      beforeSnapshot: Value(
        await _encryptNullableLocalText(
          _stringValue(event['before_snapshot']),
          'front_audit_events',
          id,
          'before_snapshot',
        ),
      ),
      afterSnapshot: Value(
        await _encryptNullableLocalText(
          _stringValue(event['after_snapshot']),
          'front_audit_events',
          id,
          'after_snapshot',
        ),
      ),
      createdAt: _dateValue(event['created_at']) ?? now,
    );
    await _insertArchiveRow(database.frontAuditEvents, companion, strategy);
  }

  Future<void> _importNamedFront(
    Map<String, Object?> front,
    ImportConflictStrategy strategy,
    DateTime now,
    String? localAvatarUrl,
  ) async {
    final frontId = _requiredString(front, 'id');
    final companion = NamedFrontsCompanion.insert(
      id: frontId,
      systemId: localSystemId,
      name: await _encryptLocalText(
        _requiredString(front, 'name'),
        'named_fronts',
        frontId,
        'name',
      ),
      customLabel: Value(
        await _encryptNullableLocalText(
          _stringValue(front['custom_label']),
          'named_fronts',
          frontId,
          'custom_label',
        ),
      ),
      colorHex: Value(
        await _encryptNullableLocalText(
          _stringValue(front['color_hex']),
          'named_fronts',
          frontId,
          'color_hex',
        ),
      ),
      avatarUrl: Value(
        await _encryptNullableLocalText(
          localAvatarUrl ?? _stringValue(front['avatar_url']),
          'named_fronts',
          frontId,
          'avatar_url',
        ),
      ),
      description: Value(
        await _encryptNullableLocalText(
          _stringValue(front['description']),
          'named_fronts',
          frontId,
          'description',
        ),
      ),
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

  Future<void> _importPrivacyBucket(
    Map<String, Object?> bucket,
    ImportConflictStrategy strategy,
    DateTime now,
  ) async {
    final id = _requiredString(bucket, 'id');
    final companion = PrivacyBucketsCompanion.insert(
      id: id,
      systemId: localSystemId,
      name: await _encryptLocalText(
        _requiredString(bucket, 'name'),
        'privacy_buckets',
        id,
        'name',
      ),
      description: Value(
        await _encryptNullableLocalText(
          _stringValue(bucket['description']),
          'privacy_buckets',
          id,
          'description',
        ),
      ),
      colorHex: Value(
        await _encryptNullableLocalText(
          normalizeHexColor(_stringValue(bucket['color_hex'])),
          'privacy_buckets',
          id,
          'color_hex',
        ),
      ),
      position: Value(_intValue(bucket['position']) ?? 0),
      createdAt: _dateValue(bucket['created_at']) ?? now,
      updatedAt: strategy == ImportConflictStrategy.update
          ? now
          : (_dateValue(bucket['updated_at']) ?? now),
    );
    return _insertArchiveRow(database.privacyBuckets, companion, strategy);
  }

  Future<void> _importPrivacyBucketMember(Map<String, Object?> link) {
    return database
        .into(database.privacyBucketMembers)
        .insert(
          PrivacyBucketMembersCompanion.insert(
            bucketId: _requiredString(link, 'bucket_id'),
            memberId: _requiredString(link, 'member_id'),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<void> _importNotificationEvent(
    Map<String, Object?> event,
    ImportConflictStrategy strategy,
    DateTime now,
  ) async {
    final id = _requiredString(event, 'id');
    final companion = NotificationEventsCompanion.insert(
      id: id,
      systemId: localSystemId,
      kind: _requiredString(event, 'kind'),
      title: await _encryptLocalText(
        _requiredString(event, 'title'),
        'notification_events',
        id,
        'title',
      ),
      body: await _encryptLocalText(
        _requiredString(event, 'body'),
        'notification_events',
        id,
        'body',
      ),
      readAt: Value(_dateValue(event['read_at'])),
      createdAt: _dateValue(event['created_at']) ?? now,
    );
    await _insertArchiveRow(database.notificationEvents, companion, strategy);
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
  ) async {
    final id = _requiredString(payload, 'id');
    final companion = ImportPayloadsCompanion.insert(
      id: id,
      importRecordId: importRecordId,
      systemId: localSystemId,
      source: _stringValue(payload['source']) ?? source.jobSource,
      collection: _requiredString(payload, 'collection'),
      payloadJson: await _encryptLocalText(
        _requiredString(payload, 'payload_json'),
        'import_payloads',
        id,
        'payload_json',
      ),
      importedAt: _dateValue(payload['imported_at']) ?? now,
    );
    await _insertArchiveRow(database.importPayloads, companion, strategy);
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

  // Tags

  @override
  Stream<List<Tag>> watchTags() => _tags.watch();

  @override
  Future<void> saveTag(Tag tag) => _tags.save(tag);

  @override
  Future<void> deleteTag(String tagId) => _tags.delete(tagId);

  @override
  Stream<List<Tag>> watchTagsForMember(String memberId) =>
      _tags.watchForMember(memberId);

  @override
  Future<void> setMemberTags(String memberId, List<String> tagIds) =>
      _tags.setForMember(memberId, tagIds);

  // Journals

  @override
  Stream<List<JournalEntry>> watchJournals({String? memberId}) =>
      _journals.watch(memberId: memberId);

  @override
  Future<void> saveJournal(JournalEntry entry) => _journals.save(entry);

  @override
  Future<void> deleteJournal(String entryId) => _journals.delete(entryId);

  // Content revisions

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
    return query.watch().asyncMap(
      (rows) async => [
        for (final row in rows)
          row.copyWith(
            title: Value(
              await _decryptLocalText(
                row.title,
                'content_revisions',
                row.id,
                'title',
              ),
            ),
            body:
                (await _decryptLocalText(
                  row.body,
                  'content_revisions',
                  row.id,
                  'body',
                )) ??
                '',
          ),
      ],
    );
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
    final revisionTitle = await _decryptLocalText(
      revision.title,
      'content_revisions',
      revision.id,
      'title',
    );
    final revisionBody = await _decryptLocalText(
      revision.body,
      'content_revisions',
      revision.id,
      'body',
    );
    if (revisionBody == null) {
      throw StateError('Protected revision body is unexpectedly null.');
    }

    switch (targetType) {
      case 'member_bio':
        await (database.update(
          database.members,
        )..where((m) => m.id.equals(targetId))).write(
          MembersCompanion(
            description: Value(
              await _encryptMember(targetId, 'description', revisionBody),
            ),
            profileEncryptionVersion: const Value(2),
            updatedAt: Value(now),
          ),
        );
      case 'note':
        await (database.update(
          database.notes,
        )..where((n) => n.id.equals(targetId))).write(
          NotesCompanion(
            title: Value(
              await _encryptLocalText(
                revisionTitle ?? '',
                'notes',
                targetId,
                'title',
              ),
            ),
            body: Value(
              await _encryptLocalText(revisionBody, 'notes', targetId, 'body'),
            ),
            updatedAt: Value(now),
          ),
        );
      case 'journal':
        await (database.update(
          database.journalEntries,
        )..where((j) => j.id.equals(targetId))).write(
          JournalEntriesCompanion(
            title: Value(
              await _encryptNullableLocalText(
                revisionTitle,
                'journal_entries',
                targetId,
                'title',
              ),
            ),
            body: Value(
              await _encryptLocalText(
                revisionBody,
                'journal_entries',
                targetId,
                'body',
              ),
            ),
            updatedAt: Value(now),
          ),
        );
      case 'message':
        await (database.update(
          database.messages,
        )..where((m) => m.id.equals(targetId))).write(
          MessagesCompanion(
            body: Value(
              await _encryptLocalText(
                revisionBody,
                'messages',
                targetId,
                'body',
              ),
            ),
            updatedAt: Value(now),
          ),
        );
    }
  }

  // Front audit events

  @override
  Stream<List<FrontAuditEvent>> watchFrontAuditEvents(String frontSessionId) {
    final query = database.select(database.frontAuditEvents)
      ..where((e) => e.frontId.equals(frontSessionId))
      ..orderBy([
        (e) => OrderingTerm(expression: e.createdAt, mode: OrderingMode.desc),
      ]);
    return query.watch().asyncMap(
      (rows) async => [
        for (final row in rows)
          row.copyWith(
            beforeSnapshot: Value(
              await _decryptLocalText(
                row.beforeSnapshot,
                'front_audit_events',
                row.id,
                'before_snapshot',
              ),
            ),
            afterSnapshot: Value(
              await _decryptLocalText(
                row.afterSnapshot,
                'front_audit_events',
                row.id,
                'after_snapshot',
              ),
            ),
          ),
      ],
    );
  }

  // Poll vote events

  @override
  Stream<List<PollVoteEvent>> watchPollVoteEvents(String pollId) =>
      _polls.watchVoteEvents(pollId);

  // Named fronts

  @override
  Stream<List<NamedFront>> watchNamedFronts() {
    final query = database.select(database.namedFronts)
      ..where((nf) => nf.systemId.equals(localSystemId))
      ..orderBy([(nf) => OrderingTerm(expression: nf.createdAt)]);
    return query.watch().asyncMap(
      (rows) async => [
        for (final row in rows)
          row.copyWith(
            name:
                (await _decryptLocalText(
                  row.name,
                  'named_fronts',
                  row.id,
                  'name',
                )) ??
                '',
            customLabel: Value(
              await _decryptLocalText(
                row.customLabel,
                'named_fronts',
                row.id,
                'custom_label',
              ),
            ),
            colorHex: Value(
              await _decryptLocalText(
                row.colorHex,
                'named_fronts',
                row.id,
                'color_hex',
              ),
            ),
            avatarUrl: Value(
              await _decryptLocalText(
                row.avatarUrl,
                'named_fronts',
                row.id,
                'avatar_url',
              ),
            ),
            description: Value(
              await _decryptLocalText(
                row.description,
                'named_fronts',
                row.id,
                'description',
              ),
            ),
          ),
      ],
    );
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
              name: await _encryptLocalText(
                front.name,
                'named_fronts',
                front.id,
                'name',
              ),
              customLabel: Value(
                await _encryptNullableLocalText(
                  front.customLabel,
                  'named_fronts',
                  front.id,
                  'custom_label',
                ),
              ),
              colorHex: Value(
                await _encryptNullableLocalText(
                  front.colorHex,
                  'named_fronts',
                  front.id,
                  'color_hex',
                ),
              ),
              avatarUrl: Value(
                await _encryptNullableLocalText(
                  front.avatarUrl,
                  'named_fronts',
                  front.id,
                  'avatar_url',
                ),
              ),
              description: Value(
                await _encryptNullableLocalText(
                  front.description,
                  'named_fronts',
                  front.id,
                  'description',
                ),
              ),
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
  Future<List<ReminderSummary>> applyNamedFront(String namedFrontId) async {
    final namedFront = await (database.select(
      database.namedFronts,
    )..where((front) => front.id.equals(namedFrontId))).getSingleOrNull();
    final members = await (database.select(
      database.namedFrontMembers,
    )..where((nfm) => nfm.namedFrontId.equals(namedFrontId))).get();
    final label = _nullIfBlank(
      await _decryptLocalText(
        namedFront?.customLabel,
        'named_fronts',
        namedFrontId,
        'custom_label',
      ),
    );
    if (members.isEmpty && label != null) {
      return setCustomFront(label);
    }
    return setFrontMembers(members.map((m) => m.memberId).toList());
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

  // Pending actions

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

  // Lexorank reordering

  @override
  Future<void> reorderMember(
    String memberId,
    String? prevRank,
    String? nextRank,
  ) => _members.reorder(memberId, prevRank, nextRank);

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

  Future<void> _endFrontSession(String sessionId, DateTime endedAt) {
    return (database.update(database.frontSessions)..where(
          (session) =>
              session.systemId.equals(localSystemId) &
              session.id.equals(sessionId) &
              session.endedAt.isNull(),
        ))
        .write(
          FrontSessionsCompanion(
            endedAt: Value(endedAt),
            updatedAt: Value(endedAt),
          ),
        );
  }

  bool _groupParentChainHasCycle(
    String? groupId,
    String parentId,
    List<Map<String, Object?>> groups,
  ) {
    if (groupId == null) {
      return false;
    }

    final parentByGroupId = <String, String?>{
      for (final group in groups)
        if (_stringValue(group['id']) != null)
          _stringValue(group['id'])!: _stringValue(group['parent_group_id']),
    };
    final seen = <String>{groupId};
    var cursor = parentId;
    while (true) {
      if (!seen.add(cursor)) {
        return true;
      }
      final next = parentByGroupId[cursor];
      if (next == null || next.isEmpty) {
        return false;
      }
      cursor = next;
    }
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

  Future<Map<String, Object?>> _systemToJson(PluralSystem system) async => {
    'id': system.id,
    'name':
        (await _decryptLocalText(
          system.name,
          'plural_systems',
          system.id,
          'name',
        )) ??
        'Local system',
    'color_hex': await _decryptLocalText(
      system.colorHex,
      'plural_systems',
      system.id,
      'color_hex',
    ),
    'avatar_url': await _decryptLocalText(
      system.avatarUrl,
      'plural_systems',
      system.id,
      'avatar_url',
    ),
    'description': await _decryptLocalText(
      system.description,
      'plural_systems',
      system.id,
      'description',
    ),
    'created_at': system.createdAt.toIso8601String(),
    'updated_at': system.updatedAt.toIso8601String(),
  };

  Future<Map<String, Object?>> _memberToJson(Member member) async {
    final displayName = await _decryptMember(
      member,
      'display_name',
      member.displayName,
    );
    if (displayName == null) {
      throw StateError('Protected member name could not be exported.');
    }
    final pronouns = await _decryptMember(member, 'pronouns', member.pronouns);
    final colorHex = await _decryptMember(member, 'color_hex', member.colorHex);
    final birthday = await _decryptMember(member, 'birthday', member.birthday);
    final emoji = await _decryptMember(member, 'emoji', member.emoji);
    final privacy = await _decryptMember(member, 'privacy', member.privacy);
    final description = await _decryptMember(
      member,
      'description',
      member.description,
    );
    final avatarUrl = await _decryptMember(
      member,
      'avatar_url',
      member.avatarUrl,
    );
    final pluralKitId = await _decryptMember(
      member,
      'pluralkit_id',
      member.pluralKitId,
    );
    return {
      'id': member.id,
      'display_name': displayName,
      'pronouns': pronouns,
      'color_hex': colorHex,
      'birthday': birthday,
      'emoji': emoji,
      'privacy': privacy,
      'folder_id': member.folderId,
      'description': description,
      'avatar_url': avatarUrl,
      'pluralkit_id': pluralKitId,
      'is_custom_front': member.isCustomFront,
      'archived': member.archived,
      'created_at': member.createdAt.toIso8601String(),
      'updated_at': member.updatedAt.toIso8601String(),
    };
  }

  Future<Map<String, Object?>> _groupToJson(SystemGroup group) async => {
    'id': group.id,
    'parent_group_id': group.parentGroupId,
    'name':
        (await _decryptLocalText(
          group.name,
          'system_groups',
          group.id,
          'name',
        )) ??
        '',
    'color_hex': await _decryptLocalText(
      group.colorHex,
      'system_groups',
      group.id,
      'color_hex',
    ),
    'description': await _decryptLocalText(
      group.description,
      'system_groups',
      group.id,
      'description',
    ),
    'emoji': await _decryptLocalText(
      group.emoji,
      'system_groups',
      group.id,
      'emoji',
    ),
    'created_at': group.createdAt.toIso8601String(),
    'updated_at': group.updatedAt.toIso8601String(),
  };

  Map<String, Object?> _groupMemberToJson(GroupMember link) => {
    'group_id': link.groupId,
    'member_id': link.memberId,
  };

  Future<Map<String, Object?>> _noteToJson(Note note) async => {
    'id': note.id,
    'member_id': note.memberId,
    'title':
        (await _decryptLocalText(note.title, 'notes', note.id, 'title')) ?? '',
    'body':
        (await _decryptLocalText(note.body, 'notes', note.id, 'body')) ?? '',
    'created_at': note.createdAt.toIso8601String(),
    'updated_at': note.updatedAt.toIso8601String(),
  };

  Future<Map<String, Object?>> _messageToJson(Message message) async => {
    'id': message.id,
    'member_id': message.memberId,
    'body':
        (await _decryptLocalText(
          message.body,
          'messages',
          message.id,
          'body',
        )) ??
        '',
    'board_kind': message.boardKind,
    'board_member_id': message.boardMemberId,
    'parent_message_id': message.parentMessageId,
    'channel_id': message.channelId,
    'deleted_at': message.deletedAt?.toIso8601String(),
    'archived': message.archived,
    'created_at': message.createdAt.toIso8601String(),
    'updated_at': message.updatedAt.toIso8601String(),
  };

  Future<Map<String, Object?>> _chatCategoryToJson(
    ChatCategory category,
  ) async => {
    'id': category.id,
    'name':
        (await _decryptLocalText(
          category.name,
          'chat_categories',
          category.id,
          'name',
        )) ??
        '',
    'description': await _decryptLocalText(
      category.description,
      'chat_categories',
      category.id,
      'description',
    ),
    'position': category.position,
    'created_at': category.createdAt.toIso8601String(),
    'updated_at': category.updatedAt.toIso8601String(),
  };

  Future<Map<String, Object?>> _chatChannelToJson(ChatChannel channel) async =>
      {
        'id': channel.id,
        'category_id': channel.categoryId,
        'name':
            (await _decryptLocalText(
              channel.name,
              'chat_channels',
              channel.id,
              'name',
            )) ??
            '',
        'description': await _decryptLocalText(
          channel.description,
          'chat_channels',
          channel.id,
          'description',
        ),
        'color_hex': await _decryptLocalText(
          channel.colorHex,
          'chat_channels',
          channel.id,
          'color_hex',
        ),
        'position': channel.position,
        'created_at': channel.createdAt.toIso8601String(),
        'updated_at': channel.updatedAt.toIso8601String(),
      };

  Future<Map<String, Object?>> _reminderToJson(Reminder reminder) async => {
    'id': reminder.id,
    'title':
        (await _decryptLocalText(
          reminder.title,
          'reminders',
          reminder.id,
          'title',
        )) ??
        '',
    'body': await _decryptLocalText(
      reminder.body,
      'reminders',
      reminder.id,
      'body',
    ),
    'schedule_text':
        (await _decryptLocalText(
          reminder.scheduleText,
          'reminders',
          reminder.id,
          'schedule_text',
        )) ??
        '',
    'trigger_type': reminder.triggerType,
    'trigger_member_id': reminder.triggerMemberId,
    'trigger_event': await _decryptLocalText(
      reminder.triggerEvent,
      'reminders',
      reminder.id,
      'trigger_event',
    ),
    'schedule_kind': await _decryptLocalText(
      reminder.scheduleKind,
      'reminders',
      reminder.id,
      'schedule_kind',
    ),
    'schedule_time': await _decryptLocalText(
      reminder.scheduleTime,
      'reminders',
      reminder.id,
      'schedule_time',
    ),
    'schedule_dow_mask': reminder.scheduleDowMask,
    'schedule_dom': reminder.scheduleDom,
    'delay_seconds': reminder.delaySeconds,
    'enabled': reminder.enabled,
    'last_fired_at': reminder.lastFiredAt?.toIso8601String(),
    'created_at': reminder.createdAt.toIso8601String(),
    'updated_at': reminder.updatedAt.toIso8601String(),
  };

  Future<Map<String, Object?>> _tagToJson(Tag tag) async => {
    'id': tag.id,
    'name': (await _decryptLocalText(tag.name, 'tags', tag.id, 'name')) ?? '',
    'color_hex': await _decryptLocalText(
      tag.colorHex,
      'tags',
      tag.id,
      'color_hex',
    ),
    'created_at': tag.createdAt.toIso8601String(),
    'updated_at': tag.updatedAt.toIso8601String(),
  };

  Map<String, Object?> _memberTagToJson(MemberTag link) => {
    'tag_id': link.tagId,
    'member_id': link.memberId,
  };

  Future<Map<String, Object?>> _journalToJson(JournalEntry journal) async => {
    'id': journal.id,
    'member_id': journal.memberId,
    'title': await _decryptLocalText(
      journal.title,
      'journal_entries',
      journal.id,
      'title',
    ),
    'body':
        (await _decryptLocalText(
          journal.body,
          'journal_entries',
          journal.id,
          'body',
        )) ??
        '',
    'visibility': journal.visibility,
    'created_at': journal.createdAt.toIso8601String(),
    'updated_at': journal.updatedAt.toIso8601String(),
  };

  Future<Map<String, Object?>> _contentRevisionToJson(
    ContentRevision revision,
  ) async => {
    'id': revision.id,
    'target_type': revision.targetType,
    'target_id': revision.targetId,
    'title': await _decryptLocalText(
      revision.title,
      'content_revisions',
      revision.id,
      'title',
    ),
    'body':
        (await _decryptLocalText(
          revision.body,
          'content_revisions',
          revision.id,
          'body',
        )) ??
        '',
    'pinned_at': revision.pinnedAt?.toIso8601String(),
    'created_at': revision.createdAt.toIso8601String(),
  };

  Future<Map<String, Object?>> _customFieldToJson(
    CustomFieldDefinition field,
  ) async => {
    'id': field.id,
    'name':
        (await _decryptLocalText(
          field.name,
          'custom_field_definitions',
          field.id,
          'name',
        )) ??
        '',
    'field_type': field.fieldType,
    'privacy': await _decryptLocalText(
      field.privacy,
      'custom_field_definitions',
      field.id,
      'privacy',
    ),
    'position': field.position,
    'created_at': field.createdAt.toIso8601String(),
    'updated_at': field.updatedAt.toIso8601String(),
  };

  Future<Map<String, Object?>> _customFieldValueToJson(
    CustomFieldValue value,
  ) async => {
    'id': value.id,
    'field_id': value.fieldId,
    'member_id': value.memberId,
    'value':
        (await _decryptLocalText(
          value.value,
          'custom_field_values',
          value.id,
          'value',
        )) ??
        '',
    'created_at': value.createdAt.toIso8601String(),
    'updated_at': value.updatedAt.toIso8601String(),
  };

  Future<Map<String, Object?>> _pollToJson(Poll poll) async => {
    'id': poll.id,
    'question':
        (await _decryptLocalText(
          poll.question,
          'polls',
          poll.id,
          'question',
        )) ??
        '',
    'description': await _decryptLocalText(
      poll.description,
      'polls',
      poll.id,
      'description',
    ),
    'kind': poll.kind,
    'closed': poll.closed,
    'created_at': poll.createdAt.toIso8601String(),
    'updated_at': poll.updatedAt.toIso8601String(),
  };

  Future<Map<String, Object?>> _pollOptionToJson(PollOption option) async => {
    'id': option.id,
    'poll_id': option.pollId,
    'body':
        (await _decryptLocalText(
          option.body,
          'poll_options',
          option.id,
          'body',
        )) ??
        '',
    'position': option.position,
  };

  Map<String, Object?> _pollVoteToJson(PollVote vote) => {
    'poll_id': vote.pollId,
    'option_id': vote.optionId,
    'created_at': vote.createdAt.toIso8601String(),
  };

  Map<String, Object?> _pollVoteEventToJson(PollVoteEvent event) => {
    'id': event.id,
    'poll_id': event.pollId,
    'option_id': event.optionId,
    'action': event.action,
    'created_at': event.createdAt.toIso8601String(),
  };

  Future<Map<String, Object?>> _frontToJson(FrontSession front) async => {
    'id': front.id,
    'label': await _decryptLocalText(
      front.label,
      'front_sessions',
      front.id,
      'label',
    ),
    'status_note': await _decryptLocalText(
      front.statusNote,
      'front_sessions',
      front.id,
      'status_note',
    ),
    'started_at': front.startedAt.toIso8601String(),
    'ended_at': front.endedAt?.toIso8601String(),
    'created_at': front.createdAt.toIso8601String(),
    'updated_at': front.updatedAt.toIso8601String(),
  };

  Map<String, Object?> _frontMemberToJson(FrontSessionMember link) => {
    'session_id': link.sessionId,
    'member_id': link.memberId,
  };

  Future<Map<String, Object?>> _frontAuditEventToJson(
    FrontAuditEvent event,
  ) async => {
    'id': event.id,
    'front_id': event.frontId,
    'before_snapshot': await _decryptLocalText(
      event.beforeSnapshot,
      'front_audit_events',
      event.id,
      'before_snapshot',
    ),
    'after_snapshot': await _decryptLocalText(
      event.afterSnapshot,
      'front_audit_events',
      event.id,
      'after_snapshot',
    ),
    'created_at': event.createdAt.toIso8601String(),
  };

  Future<Map<String, Object?>> _namedFrontToJson(NamedFront front) async => {
    'id': front.id,
    'name':
        (await _decryptLocalText(
          front.name,
          'named_fronts',
          front.id,
          'name',
        )) ??
        '',
    'custom_label': await _decryptLocalText(
      front.customLabel,
      'named_fronts',
      front.id,
      'custom_label',
    ),
    'color_hex': await _decryptLocalText(
      front.colorHex,
      'named_fronts',
      front.id,
      'color_hex',
    ),
    'avatar_url': await _decryptLocalText(
      front.avatarUrl,
      'named_fronts',
      front.id,
      'avatar_url',
    ),
    'description': await _decryptLocalText(
      front.description,
      'named_fronts',
      front.id,
      'description',
    ),
    'created_at': front.createdAt.toIso8601String(),
    'updated_at': front.updatedAt.toIso8601String(),
  };

  Map<String, Object?> _namedFrontMemberToJson(NamedFrontMember link) => {
    'named_front_id': link.namedFrontId,
    'member_id': link.memberId,
  };

  Future<Map<String, Object?>> _privacyBucketToJson(
    PrivacyBucket bucket,
  ) async => {
    'id': bucket.id,
    'name':
        (await _decryptLocalText(
          bucket.name,
          'privacy_buckets',
          bucket.id,
          'name',
        )) ??
        '',
    'description': await _decryptLocalText(
      bucket.description,
      'privacy_buckets',
      bucket.id,
      'description',
    ),
    'color_hex': await _decryptLocalText(
      bucket.colorHex,
      'privacy_buckets',
      bucket.id,
      'color_hex',
    ),
    'position': bucket.position,
    'created_at': bucket.createdAt.toIso8601String(),
    'updated_at': bucket.updatedAt.toIso8601String(),
  };

  Map<String, Object?> _privacyBucketMemberToJson(PrivacyBucketMember link) => {
    'bucket_id': link.bucketId,
    'member_id': link.memberId,
  };

  Future<Map<String, Object?>> _importRecordToJson(ImportRecord record) async =>
      {
        'id': record.id,
        'source': record.source,
        'file_name': await _decryptLocalText(
          record.fileName,
          'import_records',
          record.id,
          'file_name',
        ),
        'summary_json': await _decryptLocalText(
          record.summaryJson,
          'import_records',
          record.id,
          'summary_json',
        ),
        'imported_at': record.importedAt.toIso8601String(),
      };

  Future<Map<String, Object?>> _importPayloadToJson(
    ImportPayload payload,
  ) async => {
    'id': payload.id,
    'import_record_id': payload.importRecordId,
    'source': payload.source,
    'collection': payload.collection,
    'payload_json':
        (await _decryptLocalText(
          payload.payloadJson,
          'import_payloads',
          payload.id,
          'payload_json',
        )) ??
        '',
    'imported_at': payload.importedAt.toIso8601String(),
  };

  Future<Map<String, Object?>> _notificationEventToJson(
    NotificationEvent event,
  ) async => {
    'id': event.id,
    'kind': event.kind,
    'title':
        (await _decryptLocalText(
          event.title,
          'notification_events',
          event.id,
          'title',
        )) ??
        '',
    'body':
        (await _decryptLocalText(
          event.body,
          'notification_events',
          event.id,
          'body',
        )) ??
        '',
    'read_at': event.readAt?.toIso8601String(),
    'created_at': event.createdAt.toIso8601String(),
  };

  Map<String, Object?> _preferenceToJson(AppPreference preference) => {
    'key': preference.key,
    'value': preference.value,
    'updated_at': preference.updatedAt.toIso8601String(),
  };
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
  final mimeExtension = switch (mimeType) {
    'image/png' => '.png',
    'image/jpeg' => '.jpg',
    'image/webp' => '.webp',
    'image/gif' => '.gif',
    'image/svg+xml' => '.svg',
    _ => null,
  };
  if (mimeExtension != null) {
    return mimeExtension;
  }

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
  if (lowerName.endsWith('.svg')) {
    return '.svg';
  }

  return '.bin';
}

String _safeFilePart(String value) {
  final cleaned = value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9._-]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^[-.]+|[-.]+$'), '');
  return cleaned.isEmpty ? 'avatar' : cleaned;
}

String? _trimToNull(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

const _allowedCustomFieldTypes = {
  'text',
  'number',
  'date',
  'boolean',
  'select',
};
