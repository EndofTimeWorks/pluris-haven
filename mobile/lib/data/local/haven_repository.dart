import 'package:drift/drift.dart';

import 'app_database.dart';

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

abstract interface class HavenRepository {
  Stream<HomeSnapshot> watchHomeSnapshot();

  Future<void> setCustomFront(String label);

  Future<void> clearCurrentFront();
}

class LocalHavenRepository implements HavenRepository {
  LocalHavenRepository(this.database);

  final AppDatabase database;

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

  Future<HomeSnapshot> loadHomeSnapshot() async {
    final row = await database
        .customSelect(_homeSnapshotSql, variables: _homeSnapshotVariables)
        .getSingle();

    return _mapHomeSnapshot(row);
  }

  String get _homeSnapshotSql => '''
SELECT
  COALESCE((SELECT name FROM plural_systems WHERE id = ? LIMIT 1), 'Local system') AS system_name,
  (SELECT COUNT(*) FROM members WHERE system_id = ? AND archived = 0) AS member_count,
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
}
