part of 'haven_repository.dart';

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
    bool listOnly = false,
  });

  Stream<List<MemberSummary>> watchCurrentFrontMembers();

  Stream<List<GroupSummary>> watchGroups();

  Stream<List<NoteSummary>> watchNotes();

  Stream<List<MessageSummary>> watchMessages();

  Stream<List<ChatCategorySummary>> watchChatCategories();

  Stream<List<ChatChannelSummary>> watchChatChannels();

  Stream<List<ReminderSummary>> watchReminders();

  Stream<List<CustomFieldSummary>> watchCustomFields();

  Stream<List<CustomFieldValueSummary>> watchCustomFieldValues({
    String? fieldId,
    String? memberId,
  });

  Stream<List<PollSummary>> watchPolls();

  Stream<List<NotificationEventSummary>> watchNotificationEvents();

  Stream<List<PrivacyBucketSummary>> watchPrivacyBuckets();

  Stream<List<FrontHistoryEntry>> watchFrontHistory();

  Stream<AppCustomization> watchCustomization();

  Future<AppCustomization> loadCustomization();

  Future<void> setThemeMode(HavenThemeMode mode);

  Future<void> setVisualTheme(HavenVisualTheme theme);

  Future<void> setNavigationLayout(HavenNavigationLayout layout);

  Future<void> setAccentColor(HavenAccentColor color);

  Future<void> setCustomAccentColor(String? colorHex);

  Future<void> setAppearanceOverrides(HavenAppearanceOverrides overrides);

  Future<void> setCompactDashboard(bool compact);

  Future<void> setShowDashboardSubtitles(bool show);

  Future<void> setReducedMotion(bool reduced);

  Future<void> setFrontStatusNotification(bool enabled);

  Future<void> setFrontStatusShowOnLockScreen(bool showOnLockScreen);

  Future<void> setFrontStatusRevealMemberName(bool revealMemberName);

  Future<void> setScreenshotBlockingEnabled(bool enabled);

  Future<void> setAppLockEnabled(bool enabled);

  Future<void> setHighContrast(bool highContrast);

  Future<void> setLargeText(bool largeText);

  Future<void> setCompactLists(bool compact);

  Future<void> setDashboardShortcutIds(List<String> shortcutIds);

  Future<Uint8List?> readAvatar(String reference);

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
    required Object? value,
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

extension HavenRepositoryRecentFrontHistory on HavenRepository {
  Stream<List<FrontHistoryEntry>> watchRecentFrontHistory({int limit = 250}) {
    final repository = this;
    if (repository is LocalHavenRepository) {
      return repository.watchRecentFrontHistory(limit: limit);
    }
    return repository.watchFrontHistory();
  }
}
