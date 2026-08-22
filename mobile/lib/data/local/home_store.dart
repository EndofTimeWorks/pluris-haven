part of 'haven_repository.dart';

extension LocalHavenRepositoryHome on LocalHavenRepository {
  Stream<HomeSnapshot> _homeWatchSnapshot() {
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
        .asyncMap(_homeMapSnapshot);
  }

  Future<HomeSnapshot> _homeLoadSnapshot() async {
    final row = await database
        .customSelect(_homeSnapshotSql, variables: _homeSnapshotVariables)
        .getSingle();
    return _homeMapSnapshot(row);
  }

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

  Future<HomeSnapshot> _homeMapSnapshot(QueryRow row) async {
    final data = row.data;
    final storedSystemName = data['system_name'] as String;

    return HomeSnapshot(
      systemName: storedSystemName.startsWith(_localEncryptedTextPrefix)
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
      currentFrontLabel: await _homeCurrentFrontLabel(),
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

  Future<void> _homeUpdateSystemProfile(SystemProfileDraft draft) async {
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

  Future<String?> _homeCurrentFrontLabel() async {
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
    if (sessions.isEmpty) return null;

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
      if (links.isEmpty) continue;

      final members =
          await (database.select(database.members)..where(
                (member) => member.id.isIn(
                  links.map((link) => link.memberId).toSet().toList(),
                ),
              ))
              .get();
      final namesById = <String, String>{};
      for (final member in members) {
        final name =
            (await _decryptMember(
              member,
              'display_name',
              member.displayName,
            ))?.trim() ??
            '';
        if (name.isNotEmpty) namesById[member.id] = name;
      }
      for (final link in links) {
        final name = namesById[link.memberId];
        if (name != null && name.isNotEmpty) labels.add(name);
      }
    }

    final uniqueLabels = <String>[];
    final seen = <String>{};
    for (final label in labels) {
      if (seen.add(label.toLowerCase())) uniqueLabels.add(label);
    }
    return uniqueLabels.isEmpty ? null : uniqueLabels.join(', ');
  }
}
