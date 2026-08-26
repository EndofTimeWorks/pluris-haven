import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:cryptography/cryptography.dart';

import '../../debug/debug_log.dart';
import '../avatar/avatar_file_policy.dart';
import '../avatar/local_avatar_store.dart';
import '../import/remote_avatar_policy.dart';
import '../import/import_sources.dart';
import '../security/haven_crypto.dart';
import 'app_customization.dart';
import 'app_database.dart';
import 'chat_store.dart';
import 'content_revision_store.dart';
import 'custom_field_store.dart';
import 'front_audit_store.dart';
import 'group_store.dart';
import 'journal_store.dart';
import 'local_id.dart';
import 'member_store.dart';
import 'message_store.dart';
import 'note_store.dart';
import 'notification_event_store.dart';
import 'pending_action_store.dart';
import 'poll_store.dart';
import 'privacy_bucket_store.dart';
import 'rehearsal_database_connection.dart';
import 'reminder_store.dart';
import 'tag_store.dart';

export 'app_customization.dart'
    show
        AppCustomization,
        HavenAppearanceOverrides,
        HavenAccentColor,
        HavenThemeMode,
        HavenVisualTheme,
        HavenVisualThemeExtension,
        defaultDashboardShortcutIds;
export 'chat_store.dart'
    show
        ChatCategoryDraft,
        ChatCategorySummary,
        ChatChannelDraft,
        ChatChannelSummary;
export 'custom_field_store.dart'
    show CustomFieldDraft, CustomFieldSummary, CustomFieldValueSummary;
export 'group_store.dart' show GroupDraft, GroupSummary;
export 'note_store.dart' show NoteDraft, NoteSummary;
export 'message_store.dart' show MessageDraft, MessageSummary;
export 'member_store.dart' show MemberDraft, MemberSummary;
export 'notification_event_store.dart'
    show NotificationEventDraft, NotificationEventSummary;
export 'poll_store.dart'
    show PollDraft, PollKind, PollOptionSummary, PollSummary;
export 'privacy_bucket_store.dart'
    show PrivacyBucketDraft, PrivacyBucketSummary;
export 'reminder_store.dart' show ReminderDraft, ReminderSummary;

part 'archive_store.dart';
part 'front_store.dart';
part 'home_store.dart';
part 'named_front_store.dart';
part 'member_security_store.dart';
part 'local_text_store.dart';
part 'archive_codec_store.dart';
part 'background_job_store.dart';
part 'revision_restore_store.dart';
part 'repository_contract.dart';

const _localEncryptedTextPrefix = 'ph2:';
const _memberEncryptionSweepPreference =
    'internal.member_encryption_sweep_version';
const _memberEncryptionSweepVersion = '2';
const _emptyCiphertextSweepPreference =
    'internal.empty_ciphertext_sweep_version';
const _emptyCiphertextSweepVersion = '1';
const _remoteAvatarRepairPreference = 'internal.remote_avatar_repair_version';
const _remoteAvatarRepairVersion = '1';
const _localAvatarEncryptionPreference =
    'internal.local_avatar_encryption_version';
const _localAvatarEncryptionVersion = '1';

class LocalHavenRepository implements HavenRepository {
  LocalHavenRepository(
    this.database, {
    required this.crypto,
    LocalAvatarStore? avatarStore,
  }) : _avatarStore = avatarStore ?? LocalAvatarStore(),
       _customization = LocalAppCustomizationStore(database) {
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
    _customFields = LocalCustomFieldStore(
      database,
      encryptText: _encryptLocalText,
      encryptNullableText: _encryptNullableLocalText,
      decryptText: _decryptLocalText,
    );
    _privacyBuckets = LocalPrivacyBucketStore(
      database,
      encryptText: _encryptLocalText,
      encryptNullableText: _encryptNullableLocalText,
      decryptText: _decryptLocalText,
    );
    _pendingActions = LocalPendingActionStore(
      database,
      deleteMember: deleteMember,
      deleteNote: deleteNote,
      deleteReminder: deleteReminder,
      deletePoll: deletePoll,
      deleteJournal: deleteJournal,
      deleteTag: deleteTag,
      deleteNamedFront: deleteNamedFront,
    );
    _notificationEvents = LocalNotificationEventStore(
      database,
      encryptText: _encryptLocalText,
      decryptText: _decryptLocalText,
    );
    _frontAudit = LocalFrontAuditStore(
      database,
      decryptText: _decryptLocalText,
    );
    _revisions = LocalContentRevisionStore(
      database,
      decryptText: _decryptLocalText,
    );
  }

  final AppDatabase database;
  final HavenCrypto crypto;
  final LocalAvatarStore _avatarStore;
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
  late final LocalCustomFieldStore _customFields;
  late final LocalPrivacyBucketStore _privacyBuckets;
  late final LocalPendingActionStore _pendingActions;
  late final LocalNotificationEventStore _notificationEvents;
  late final LocalFrontAuditStore _frontAudit;
  late final LocalContentRevisionStore _revisions;
  final Map<(String, String), ({String? ciphertext, String? plaintext})>
  _memberDecryptCache = {};

  Future<void> ensureLocalSystem() => _ensureLocalSystem();

  Future<void> migrateUnauthenticatedEmptyCiphertexts() =>
      _migrateUnauthenticatedEmptyCiphertexts();

  Future<void> migrateMemberNamesToEncryption() =>
      _migrateMemberNamesToEncryption();

  @override
  Stream<HomeSnapshot> watchHomeSnapshot() => _homeWatchSnapshot();

  @override
  Stream<List<BackgroundJobSummary>> watchBackgroundJobs() =>
      _backgroundWatchJobs();

  @override
  Stream<List<RetainedImportPayloadSummary>> watchRetainedImportPayloads() =>
      _backgroundWatchRetainedImportPayloads();

  @override
  Future<void> deleteRetainedImportPayloads(String importRecordId) =>
      _backgroundDeleteRetainedImportPayloads(importRecordId);

  @override
  Stream<List<MemberSummary>> watchMembers({
    bool includeArchived = false,
    bool includeCustomFronts = false,
    bool listOnly = false,
  }) => _members.watch(
    includeArchived: includeArchived,
    includeCustomFronts: includeCustomFronts,
    listOnly: listOnly,
  );

  @override
  Stream<List<MemberSummary>> watchCurrentFrontMembers() =>
      _members.watchCurrentFront();

  @override
  Stream<List<CustomFieldSummary>> watchCustomFields() =>
      _customFields.watchFields();

  @override
  Stream<List<CustomFieldValueSummary>> watchCustomFieldValues() =>
      _customFields.watchValues();

  @override
  Stream<List<GroupSummary>> watchGroups() => _groups.watch();

  @override
  Stream<List<PrivacyBucketSummary>> watchPrivacyBuckets() =>
      _privacyBuckets.watch();

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
  Stream<List<NotificationEventSummary>> watchNotificationEvents() =>
      _notificationEvents.watch();

  @override
  Stream<List<FrontHistoryEntry>> watchFrontHistory() => _frontWatchHistory();

  Stream<List<FrontHistoryEntry>> watchRecentFrontHistory({int limit = 250}) =>
      _frontWatchHistory(limit: limit);

  Future<HomeSnapshot> loadHomeSnapshot() => _homeLoadSnapshot();

  @override
  Stream<AppCustomization> watchCustomization() => _customization.watch();

  @override
  Future<AppCustomization> loadCustomization() => _customization.load();

  @override
  Future<void> updateSystemProfile(SystemProfileDraft draft) =>
      _homeUpdateSystemProfile(draft);

  @override
  Future<void> setThemeMode(HavenThemeMode mode) =>
      _customization.setThemeMode(mode);

  @override
  Future<void> setVisualTheme(HavenVisualTheme theme) =>
      _customization.setVisualTheme(theme);

  @override
  Future<void> setAccentColor(HavenAccentColor color) =>
      _customization.setAccentColor(color);

  @override
  Future<void> setCustomAccentColor(String? colorHex) =>
      _customization.setCustomAccentColor(colorHex);

  @override
  Future<void> setAppearanceOverrides(HavenAppearanceOverrides overrides) =>
      _customization.setAppearanceOverrides(overrides);

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
  Future<void> setFrontStatusShowOnLockScreen(bool showOnLockScreen) =>
      _customization.setFrontStatusShowOnLockScreen(showOnLockScreen);

  @override
  Future<void> setFrontStatusRevealMemberName(bool revealMemberName) =>
      _customization.setFrontStatusRevealMemberName(revealMemberName);

  @override
  Future<void> setScreenshotBlockingEnabled(bool enabled) =>
      _customization.setScreenshotBlockingEnabled(enabled);

  @override
  Future<void> setAppLockEnabled(bool enabled) =>
      _customization.setAppLockEnabled(enabled);

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
  Future<Uint8List?> readAvatar(String reference) =>
      _avatarStore.read(reference);

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

  @override
  Future<void> restoreMember(String memberId) =>
      _members.archive(memberId, archived: false);

  @override
  Future<void> deleteMember(String memberId) => _members.delete(memberId);

  @override
  Future<List<ReminderSummary>> setFrontMembers(List<String> memberIds) =>
      _frontSetFrontMembers(memberIds);

  @override
  Future<void> updateFrontStatusNote(String frontId, String? statusNote) =>
      _frontUpdateFrontStatusNote(frontId, statusNote);

  @override
  Future<void> saveFrontHistoryEntry(FrontHistoryDraft draft) =>
      _frontSaveFrontHistoryEntry(draft);

  @override
  Future<void> updateFrontHistoryEntry(
    String frontId,
    FrontHistoryDraft draft,
  ) => _frontUpdateFrontHistoryEntry(frontId, draft);

  @override
  Future<void> deleteFrontSession(String frontId) =>
      _frontDeleteFrontSession(frontId);
  @override
  Future<void> saveGroup(GroupDraft draft) => _groups.save(draft);

  @override
  Future<void> updateGroup(String groupId, GroupDraft draft) =>
      _groups.update(groupId, draft);

  @override
  Future<void> deleteGroup(String groupId) => _groups.delete(groupId);

  @override
  Future<void> savePrivacyBucket(PrivacyBucketDraft draft) =>
      _privacyBuckets.save(draft);

  @override
  Future<void> updatePrivacyBucket(String bucketId, PrivacyBucketDraft draft) =>
      _privacyBuckets.update(bucketId, draft);

  @override
  Future<void> deletePrivacyBucket(String bucketId) =>
      _privacyBuckets.delete(bucketId);

  @override
  Future<void> saveCustomField(CustomFieldDraft draft) =>
      _customFields.save(draft);

  @override
  Future<void> updateCustomField(String fieldId, CustomFieldDraft draft) =>
      _customFields.update(fieldId, draft);

  @override
  Future<void> deleteCustomField(String fieldId) =>
      _customFields.delete(fieldId);

  @override
  Future<void> setCustomFieldValue({
    required String fieldId,
    required String? memberId,
    required String value,
  }) => _customFields.setValue(
    fieldId: fieldId,
    memberId: memberId,
    value: value,
  );

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
  Future<void> recordNotificationEvent(NotificationEventDraft draft) =>
      _notificationEvents.record(draft);

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
  Future<List<ReminderSummary>> setCustomFront(String label) =>
      _frontSetCustomFront(label);

  @override
  Future<void> clearCurrentFront() => _frontClearCurrentFront();

  @override
  Future<String> buildLocalArchiveJson() => _archiveBuildLocalArchiveJson();

  @override
  Future<RestoreRehearsalSummary> rehearseLocalArchiveRestore(
    String archiveJson, {
    ImportConflictStrategy strategy = ImportConflictStrategy.prompt,
    String? fileName,
    ImportSource source = ImportSource.plurisHavenArchive,
  }) => _archiveRehearseLocalArchiveRestore(
    archiveJson,
    strategy: strategy,
    fileName: fileName,
    source: source,
  );

  @override
  Future<String> enqueueImportArchiveJob(
    String archiveJson, {
    required ImportConflictStrategy strategy,
    String? fileName,
    required ImportSource source,
  }) => _archiveEnqueueImportArchiveJob(
    archiveJson,
    strategy: strategy,
    fileName: fileName,
    source: source,
  );

  @override
  Future<bool> runBackgroundJob(String jobId) =>
      _archiveRunBackgroundJob(jobId);

  @override
  Future<void> importLocalArchiveJson(
    String archiveJson, {
    ImportConflictStrategy strategy = ImportConflictStrategy.prompt,
    String? fileName,
    ImportSource source = ImportSource.plurisHavenArchive,
    bool localizeAvatars = true,
  }) => _archiveImportLocalArchiveJson(
    archiveJson,
    strategy: strategy,
    fileName: fileName,
    source: source,
    localizeAvatars: localizeAvatars,
  );
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
  ) => _revisions.watch(targetType, targetId);

  @override
  Future<void> pinRevision(String revisionId) => _revisions.pin(revisionId);

  @override
  Future<void> unpinRevision(String revisionId) => _revisions.unpin(revisionId);

  @override
  Future<void> restoreRevision(
    String revisionId,
    String targetType,
    String targetId,
  ) => _restoreRevision(revisionId, targetType, targetId);

  // Front audit events

  @override
  Stream<List<FrontAuditEvent>> watchFrontAuditEvents(String frontSessionId) =>
      _frontAudit.watch(frontSessionId);

  // Poll vote events

  @override
  Stream<List<PollVoteEvent>> watchPollVoteEvents(String pollId) =>
      _polls.watchVoteEvents(pollId);

  // Named fronts

  @override
  Stream<List<NamedFront>> watchNamedFronts() => _namedFrontWatch();

  @override
  Future<void> saveNamedFront(NamedFront front, List<String> memberIds) =>
      _namedFrontSave(front, memberIds);

  @override
  Future<List<ReminderSummary>> applyNamedFront(String namedFrontId) =>
      _namedFrontApply(namedFrontId);

  @override
  Future<void> deleteNamedFront(String namedFrontId) =>
      _namedFrontDelete(namedFrontId);

  // Pending actions

  @override
  Stream<List<PendingAction>> watchPendingActions() => _pendingActions.watch();

  @override
  Future<void> cancelPendingAction(String actionId) =>
      _pendingActions.cancel(actionId);

  @override
  Future<void> finalizePendingActions() => _pendingActions.finalize();

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
}

String? _trimToNull(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
