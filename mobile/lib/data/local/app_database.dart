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

class Messages extends Table {
  TextColumn get id => text()();
  TextColumn get systemId => text().references(PluralSystems, #id)();
  TextColumn get memberId => text().nullable()();
  TextColumn get body => text()();
  TextColumn get boardKind => text().withDefault(const Constant('system'))();
  TextColumn get boardMemberId => text().nullable()();
  TextColumn get parentMessageId => text().nullable()();
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
  int get schemaVersion => 15;

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
        await migrator.addColumn(members, members.isCustomFront);
        await migrator.createTable(customFieldDefinitions);
        await migrator.createTable(customFieldValues);
      }
      if (from < 8) {
        // Members: add blind-index hash + frame shape + lexo rank for ordering.
        await migrator.addColumn(members, members.displayNameHash);
        await migrator.addColumn(members, members.frameShape);
        await migrator.addColumn(members, members.lexoRank);
        // Messages: two-board model + reply chain + soft delete.
        await migrator.addColumn(messages, messages.boardKind);
        await migrator.addColumn(messages, messages.boardMemberId);
        await migrator.addColumn(messages, messages.parentMessageId);
        await migrator.addColumn(messages, messages.deletedAt);
        // Reminders: structured scheduling columns (alongside existing scheduleText).
        await migrator.addColumn(reminders, reminders.triggerType);
        await migrator.addColumn(reminders, reminders.triggerMemberId);
        await migrator.addColumn(reminders, reminders.triggerEvent);
        await migrator.addColumn(reminders, reminders.delaySeconds);
        await migrator.addColumn(reminders, reminders.scheduleKind);
        await migrator.addColumn(reminders, reminders.scheduleTime);
        await migrator.addColumn(reminders, reminders.scheduleDowMask);
        await migrator.addColumn(reminders, reminders.scheduleDom);
        await migrator.addColumn(reminders, reminders.lastFiredAt);
        // Polls: restrict-to-fronters + deadline + retention.
        await migrator.addColumn(polls, polls.restrictVotingToFronters);
        await migrator.addColumn(polls, polls.closesAt);
        await migrator.addColumn(polls, polls.retentionDays);
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
        await migrator.addColumn(namedFronts, namedFronts.colorHex);
        await migrator.addColumn(namedFronts, namedFronts.avatarUrl);
        await migrator.addColumn(namedFronts, namedFronts.description);
      }
      if (from < 10) {
        await migrator.addColumn(frontSessions, frontSessions.statusNote);
      }
      if (from < 11) {
        await migrator.addColumn(members, members.birthday);
        await migrator.addColumn(members, members.emoji);
        await migrator.addColumn(members, members.privacy);
      }
      if (from < 12) {
        await migrator.createTable(groupMembers);
      }
      if (from < 13) {
        await migrator.addColumn(systemGroups, systemGroups.isSubsystem);
      }
      if (from < 14) {
        await migrator.addColumn(pluralSystems, pluralSystems.colorHex);
        await migrator.addColumn(pluralSystems, pluralSystems.avatarUrl);
        await migrator.addColumn(pluralSystems, pluralSystems.description);
      }
      if (from < 15) {
        await migrator.createTable(privacyBuckets);
        await migrator.createTable(privacyBucketMembers);
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
