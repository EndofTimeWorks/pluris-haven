import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

const localSystemId = 'local-system';

class PluralSystems extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
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
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Members extends Table {
  TextColumn get id => text()();
  TextColumn get systemId => text().references(PluralSystems, #id)();
  TextColumn get displayName => text()();
  TextColumn get pronouns => text().nullable()();
  TextColumn get colorHex => text().nullable()();
  TextColumn get folderId => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get pluralKitId => text().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
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
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class FrontSessions extends Table {
  TextColumn get id => text()();
  TextColumn get systemId => text().references(PluralSystems, #id)();
  TextColumn get label => text().nullable()();
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

@DriftDatabase(
  tables: [
    PluralSystems,
    SystemGroups,
    Members,
    Notes,
    Messages,
    Reminders,
    FrontSessions,
    FrontSessionMembers,
    ImportRecords,
    ImportPayloads,
    NotificationEvents,
    AppPreferences,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 4;

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
