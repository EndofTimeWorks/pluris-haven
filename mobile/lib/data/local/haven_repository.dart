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
import 'content_revision_store.dart';
import 'custom_field_store.dart';
import 'front_audit_store.dart';
import 'group_store.dart';
import 'journal_store.dart';
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
        HavenAccentColor,
        HavenThemeMode,
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

const _legacyLocalEncryptedTextPrefix = 'ph1:';
const _localEncryptedTextPrefix = 'ph2:';
const _memberEncryptionSweepPreference =
    'internal.member_encryption_sweep_version';
const _localEncryptionSweepPreference =
    'internal.local_encryption_sweep_version';
const _memberEncryptionSweepVersion = '2';
const _localEncryptionSweepVersion = '2';

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

  Future<void> migrateMemberNamesToEncryption() =>
      _migrateMemberNamesToEncryption();

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
  }) => _members.watch(
    includeArchived: includeArchived,
    includeCustomFronts: includeCustomFronts,
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
