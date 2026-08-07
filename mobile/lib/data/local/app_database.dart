import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

const localSystemId = 'local-system';

class PluralSystems extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get colorHex => text().nullable()();
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SystemGroups extends Table {
  TextColumn get id => text()();
  TextColumn get systemId => text().references(PluralSystems, #id)();
  TextColumn get parentGroupId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get colorHex => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get emoji => text().nullable()();
  BoolColumn get isSubsystem => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Members extends Table {
  TextColumn get id => text()();
  TextColumn get systemId => text().references(PluralSystems, #id)();
  TextColumn get displayName => text()();
  TextColumn get displayNameHash => text().nullable()();
  IntColumn get profileEncryptionVersion =>
      integer().withDefault(const Constant(0))();
  TextColumn get pronouns => text().nullable()();
  TextColumn get colorHex => text().nullable()();
  TextColumn get birthday => text().nullable()();
  TextColumn get emoji => text().nullable()();
  TextColumn get privacy => text().nullable()();
  TextColumn get folderId => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get pluralKitId => text().nullable()();
  TextColumn get frameShape => text().withDefault(const Constant('circle'))();
  TextColumn get lexoRank => text().withDefault(const Constant('0|zzzzzz'))();
  BoolColumn get isCustomFront =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class GroupMembers extends Table {
  TextColumn get groupId => text().references(SystemGroups, #id)();
  TextColumn get memberId => text().references(Members, #id)();

  @override
  Set<Column<Object>> get primaryKey => {groupId, memberId};
}

class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get systemId => text().references(PluralSystems, #id)();
  TextColumn get memberId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ChatCategories extends Table {
  TextColumn get id => text()();
  TextColumn get systemId => text().references(PluralSystems, #id)();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  IntColumn get position => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ChatChannels extends Table {
  TextColumn get id => text()();
  TextColumn get systemId => text().references(PluralSystems, #id)();
  TextColumn get categoryId =>
      text().nullable().references(ChatCategories, #id)();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get colorHex => text().nullable()();
  IntColumn get position => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Messages extends Table {
  TextColumn get id => text()();
  TextColumn get systemId => text().references(PluralSystems, #id)();
  TextColumn get memberId => text().nullable()();
  TextColumn get body => text()();
  TextColumn get boardKind => text().withDefault(const Constant('system'))();
  TextColumn get boardMemberId => text().nullable()();
  TextColumn get parentMessageId => text().nullable()();
  TextColumn get channelId => text().nullable().references(ChatChannels, #id)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Reminders extends Table {
  TextColumn get id => text()();
  TextColumn get systemId => text().references(PluralSystems, #id)();
  TextColumn get title => text()();
  TextColumn get body => text().nullable()();
  TextColumn get scheduleText => text()();
  TextColumn get triggerType =>
      text().withDefault(const Constant('repeated'))();
  TextColumn get triggerMemberId => text().nullable()();
  TextColumn get triggerEvent => text().nullable()();
  IntColumn get delaySeconds => integer().nullable()();
  TextColumn get scheduleKind => text().nullable()();
  TextColumn get scheduleTime => text().nullable()();
  IntColumn get scheduleDowMask => integer().nullable()();
  IntColumn get scheduleDom => integer().nullable()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastFiredAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CustomFieldDefinitions extends Table {
  TextColumn get id => text()();
  TextColumn get systemId => text().references(PluralSystems, #id)();
  TextColumn get name => text()();
  TextColumn get fieldType => text().withDefault(const Constant('text'))();
  TextColumn get privacy => text().nullable()();
  IntColumn get position => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CustomFieldValues extends Table {
  TextColumn get id => text()();
  TextColumn get fieldId => text().references(CustomFieldDefinitions, #id)();
  TextColumn get memberId => text().nullable().references(Members, #id)();
  TextColumn get value => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Polls extends Table {
  TextColumn get id => text()();
  TextColumn get systemId => text().references(PluralSystems, #id)();
  TextColumn get question => text()();
  TextColumn get description => text().nullable()();
  TextColumn get kind => text().withDefault(const Constant('single_choice'))();
  BoolColumn get restrictVotingToFronters =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get closesAt => dateTime().nullable()();
  IntColumn get retentionDays => integer().nullable()();
  BoolColumn get closed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class PollOptions extends Table {
  TextColumn get id => text()();
  TextColumn get pollId => text().references(Polls, #id)();
  TextColumn get body => text()();
  IntColumn get position => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class PollVotes extends Table {
  TextColumn get pollId => text().references(Polls, #id)();
  TextColumn get optionId => text().references(PollOptions, #id)();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {pollId, optionId};
}

class FrontSessions extends Table {
  TextColumn get id => text()();
  TextColumn get systemId => text().references(PluralSystems, #id)();
  TextColumn get label => text().nullable()();
  TextColumn get statusNote => text().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class FrontSessionMembers extends Table {
  TextColumn get sessionId => text().references(FrontSessions, #id)();
  TextColumn get memberId => text().references(Members, #id)();

  @override
  Set<Column<Object>> get primaryKey => {sessionId, memberId};
}

class ImportRecords extends Table {
  TextColumn get id => text()();
  TextColumn get systemId => text().references(PluralSystems, #id)();
  TextColumn get source => text()();
  TextColumn get fileName => text().nullable()();
  TextColumn get summaryJson => text().nullable()();
  DateTimeColumn get importedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ImportPayloads extends Table {
  TextColumn get id => text()();
  TextColumn get importRecordId => text().references(ImportRecords, #id)();
  TextColumn get systemId => text().references(PluralSystems, #id)();
  TextColumn get source => text()();
  TextColumn get collection => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get importedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class BackgroundJobs extends Table {
  TextColumn get id => text()();
  TextColumn get systemId => text().references(PluralSystems, #id)();
  TextColumn get type => text()();
  TextColumn get status => text()();
  TextColumn get source => text().nullable()();
  TextColumn get fileName => text().nullable()();
  TextColumn get payloadJson => text()();
  TextColumn get error => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get finishedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class NotificationEvents extends Table {
  TextColumn get id => text()();
  TextColumn get systemId => text().references(PluralSystems, #id)();
  TextColumn get kind => text()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  DateTimeColumn get readAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AppPreferences extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get systemId => text().references(PluralSystems, #id)();
  TextColumn get name => text()();
  TextColumn get colorHex => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class MemberTags extends Table {
  TextColumn get tagId => text().references(Tags, #id)();
  TextColumn get memberId => text().references(Members, #id)();

  @override
  Set<Column<Object>> get primaryKey => {tagId, memberId};
}

class JournalEntries extends Table {
  TextColumn get id => text()();
  TextColumn get systemId => text().references(PluralSystems, #id)();
  TextColumn get memberId => text().nullable().references(Members, #id)();
  TextColumn get title => text().nullable()();
  TextColumn get body => text()();
  TextColumn get visibility => text().withDefault(const Constant('system'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ContentRevisions extends Table {
  TextColumn get id => text()();
  TextColumn get targetType => text()();
  TextColumn get targetId => text()();
  TextColumn get title => text().nullable()();
  TextColumn get body => text()();
  DateTimeColumn get pinnedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class FrontAuditEvents extends Table {
  TextColumn get id => text()();
  TextColumn get frontId => text().references(FrontSessions, #id)();
  TextColumn get beforeSnapshot => text().nullable()();
  TextColumn get afterSnapshot => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class PollVoteEvents extends Table {
  TextColumn get id => text()();
  TextColumn get pollId => text().references(Polls, #id)();
  TextColumn get optionId => text().references(PollOptions, #id)();
  TextColumn get action => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class PendingActions extends Table {
  TextColumn get id => text()();
  TextColumn get systemId => text().references(PluralSystems, #id)();
  TextColumn get actionType => text()();
  TextColumn get targetId => text()();
  TextColumn get targetLabel => text().nullable()();
  DateTimeColumn get finalizeAfter => dateTime()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get cancelledAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class NamedFronts extends Table {
  TextColumn get id => text()();
  TextColumn get systemId => text().references(PluralSystems, #id)();
  TextColumn get name => text()();
  TextColumn get customLabel => text().nullable()();
  TextColumn get colorHex => text().nullable()();
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class NamedFrontMembers extends Table {
  TextColumn get namedFrontId => text().references(NamedFronts, #id)();
  TextColumn get memberId => text().references(Members, #id)();

  @override
  Set<Column<Object>> get primaryKey => {namedFrontId, memberId};
}

class PrivacyBuckets extends Table {
  TextColumn get id => text()();
  TextColumn get systemId => text().references(PluralSystems, #id)();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get colorHex => text().nullable()();
  IntColumn get position => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class PrivacyBucketMembers extends Table {
  TextColumn get bucketId => text().references(PrivacyBuckets, #id)();
  TextColumn get memberId => text().references(Members, #id)();

  @override
  Set<Column<Object>> get primaryKey => {bucketId, memberId};
}

@DriftDatabase(
  tables: [
    PluralSystems,
    SystemGroups,
    Members,
    GroupMembers,
    Notes,
    ChatCategories,
    ChatChannels,
    Messages,
    Reminders,
    CustomFieldDefinitions,
    CustomFieldValues,
    Polls,
    PollOptions,
    PollVotes,
    FrontSessions,
    FrontSessionMembers,
    ImportRecords,
    ImportPayloads,
    BackgroundJobs,
    NotificationEvents,
    AppPreferences,
    Tags,
    MemberTags,
    JournalEntries,
    ContentRevisions,
    FrontAuditEvents,
    PollVoteEvents,
    PendingActions,
    NamedFronts,
    NamedFrontMembers,
    PrivacyBuckets,
    PrivacyBucketMembers,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 17;

  // `migrator.createTable(x)` always creates `x` using its CURRENT (v17)
  // Dart column definition - there is no per-historical-version table shape
  // stored anywhere, and `CREATE TABLE IF NOT EXISTS` means it happily
  // no-ops if the table is already there. That has a sharp edge: if a
  // device jumps straight from an old version to the latest one in a single
  // upgrade (e.g. the app wasn't opened for a long time), a table created by
  // an early `if (from < N)` block already has every column the table has
  // today - including ones a *later* block tries to add with
  // `migrator.addColumn`. Without a guard, that second call fails with a
  // "duplicate column name" SqliteException and aborts the whole migration.
  // This helper makes `addColumn` idempotent so both single-step and
  // multi-version-jump upgrades succeed.
  static Future<void> _addColumnIfMissing(
    Migrator migrator,
    TableInfo<Table, dynamic> table,
    GeneratedColumn column,
  ) async {
    final existing = await migrator.database
        .customSelect('PRAGMA table_info(${table.actualTableName})')
        .get();
    final hasColumn = existing.any((row) => row.data['name'] == column.name);
    if (!hasColumn) {
      await migrator.addColumn(table, column);
    }
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(appPreferences);
      }
      if (from < 3) {
        await migrator.createTable(messages);
        await migrator.createTable(reminders);
        await migrator.createTable(notificationEvents);
      }
      if (from < 4) {
        await migrator.createTable(importPayloads);
      }
      if (from < 5) {
        await migrator.createTable(backgroundJobs);
      }
      if (from < 6) {
        await migrator.createTable(polls);
        await migrator.createTable(pollOptions);
        await migrator.createTable(pollVotes);
      }
      if (from < 7) {
        await _addColumnIfMissing(migrator, members, members.isCustomFront);
        await migrator.createTable(customFieldDefinitions);
        await migrator.createTable(customFieldValues);
      }
      if (from < 8) {
        // Members: add blind-index hash + frame shape + lexo rank for ordering.
        await _addColumnIfMissing(migrator, members, members.displayNameHash);
        await _addColumnIfMissing(migrator, members, members.frameShape);
        await _addColumnIfMissing(migrator, members, members.lexoRank);
        // Messages: two-board model + reply chain + soft delete.
        await _addColumnIfMissing(migrator, messages, messages.boardKind);
        await _addColumnIfMissing(migrator, messages, messages.boardMemberId);
        await _addColumnIfMissing(migrator, messages, messages.parentMessageId);
        await _addColumnIfMissing(migrator, messages, messages.deletedAt);
        // Reminders: structured scheduling columns (alongside existing scheduleText).
        await _addColumnIfMissing(migrator, reminders, reminders.triggerType);
        await _addColumnIfMissing(
          migrator,
          reminders,
          reminders.triggerMemberId,
        );
        await _addColumnIfMissing(migrator, reminders, reminders.triggerEvent);
        await _addColumnIfMissing(migrator, reminders, reminders.delaySeconds);
        await _addColumnIfMissing(migrator, reminders, reminders.scheduleKind);
        await _addColumnIfMissing(migrator, reminders, reminders.scheduleTime);
        await _addColumnIfMissing(
          migrator,
          reminders,
          reminders.scheduleDowMask,
        );
        await _addColumnIfMissing(migrator, reminders, reminders.scheduleDom);
        await _addColumnIfMissing(migrator, reminders, reminders.lastFiredAt);
        // Polls: restrict-to-fronters + deadline + retention.
        await _addColumnIfMissing(
          migrator,
          polls,
          polls.restrictVotingToFronters,
        );
        await _addColumnIfMissing(migrator, polls, polls.closesAt);
        await _addColumnIfMissing(migrator, polls, polls.retentionDays);
        // New tables.
        await migrator.createTable(tags);
        await migrator.createTable(memberTags);
        await migrator.createTable(journalEntries);
        await migrator.createTable(contentRevisions);
        await migrator.createTable(frontAuditEvents);
        await migrator.createTable(pollVoteEvents);
        await migrator.createTable(pendingActions);
        await migrator.createTable(namedFronts);
        await migrator.createTable(namedFrontMembers);
      }
      if (from < 9) {
        await _addColumnIfMissing(migrator, namedFronts, namedFronts.colorHex);
        await _addColumnIfMissing(migrator, namedFronts, namedFronts.avatarUrl);
        await _addColumnIfMissing(
          migrator,
          namedFronts,
          namedFronts.description,
        );
      }
      if (from < 10) {
        await _addColumnIfMissing(
          migrator,
          frontSessions,
          frontSessions.statusNote,
        );
      }
      if (from < 11) {
        await _addColumnIfMissing(migrator, members, members.birthday);
        await _addColumnIfMissing(migrator, members, members.emoji);
        await _addColumnIfMissing(migrator, members, members.privacy);
      }
      if (from < 12) {
        await migrator.createTable(groupMembers);
      }
      if (from < 13) {
        await _addColumnIfMissing(
          migrator,
          systemGroups,
          systemGroups.isSubsystem,
        );
      }
      if (from < 14) {
        await _addColumnIfMissing(
          migrator,
          pluralSystems,
          pluralSystems.colorHex,
        );
        await _addColumnIfMissing(
          migrator,
          pluralSystems,
          pluralSystems.avatarUrl,
        );
        await _addColumnIfMissing(
          migrator,
          pluralSystems,
          pluralSystems.description,
        );
      }
      if (from < 15) {
        await migrator.createTable(privacyBuckets);
        await migrator.createTable(privacyBucketMembers);
      }
      if (from < 16) {
        await migrator.createTable(chatCategories);
        await migrator.createTable(chatChannels);
        await _addColumnIfMissing(migrator, messages, messages.channelId);
      }
      if (from < 17) {
        await _addColumnIfMissing(
          migrator,
          members,
          members.profileEncryptionVersion,
        );
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'pluris_haven',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
