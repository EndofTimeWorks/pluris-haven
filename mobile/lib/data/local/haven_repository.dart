import 'dart:convert';

import 'package:drift/drift.dart';

import '../import/import_sources.dart';
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

class MemberSummary {
  const MemberSummary({
    required this.id,
    required this.displayName,
    this.pronouns,
    this.colorHex,
    this.description,
    this.archived = false,
  });

  final String id;
  final String displayName;
  final String? pronouns;
  final String? colorHex;
  final String? description;
  final bool archived;
}

class MemberDraft {
  const MemberDraft({
    required this.displayName,
    this.pronouns,
    this.colorHex,
    this.description,
  });

  final String displayName;
  final String? pronouns;
  final String? colorHex;
  final String? description;
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
    required this.compactDashboard,
    required this.showDashboardSubtitles,
    required this.dashboardShortcutIds,
    required this.languageCode,
  });

  final HavenThemeMode themeMode;
  final HavenAccentColor accentColor;
  final bool compactDashboard;
  final bool showDashboardSubtitles;
  final List<String> dashboardShortcutIds;
  final String languageCode;

  static AppCustomization get defaults => AppCustomization(
    themeMode: HavenThemeMode.dark,
    accentColor: HavenAccentColor.purple,
    compactDashboard: false,
    showDashboardSubtitles: true,
    dashboardShortcutIds: defaultDashboardShortcutIds,
    languageCode: systemLanguageCode,
  );

  AppCustomization copyWith({
    HavenThemeMode? themeMode,
    HavenAccentColor? accentColor,
    bool? compactDashboard,
    bool? showDashboardSubtitles,
    List<String>? dashboardShortcutIds,
    String? languageCode,
  }) {
    return AppCustomization(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
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

  Stream<List<MemberSummary>> watchMembers({bool includeArchived = false});

  Stream<List<GroupSummary>> watchGroups();

  Stream<List<NoteSummary>> watchNotes();

  Stream<List<FrontHistoryEntry>> watchFrontHistory();

  Stream<AppCustomization> watchCustomization();

  Future<AppCustomization> loadCustomization();

  Future<void> setThemeMode(HavenThemeMode mode);

  Future<void> setAccentColor(HavenAccentColor color);

  Future<void> setCompactDashboard(bool compact);

  Future<void> setShowDashboardSubtitles(bool show);

  Future<void> setDashboardShortcutIds(List<String> shortcutIds);

  Future<void> setLanguageCode(String languageCode);

  Future<void> setDashboardShortcutVisible(String shortcutId, bool visible);

  Future<void> moveDashboardShortcut(String shortcutId, int delta);

  Future<void> resetDashboardShortcuts();

  Future<void> saveMember(MemberDraft draft);

  Future<void> archiveMember(String memberId);

  Future<void> setFrontMembers(List<String> memberIds);

  Future<void> saveGroup(GroupDraft draft);

  Future<void> saveNote(NoteDraft draft);

  Future<void> setCustomFront(String label);

  Future<void> clearCurrentFront();

  Future<String> buildLocalArchiveJson();

  Future<void> importLocalArchiveJson(
    String archiveJson, {
    ImportConflictStrategy strategy = ImportConflictStrategy.skip,
    String? fileName,
  });
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

  @override
  Stream<List<MemberSummary>> watchMembers({bool includeArchived = false}) {
    final query = database.select(database.members)
      ..orderBy([
        (member) => OrderingTerm(
          expression: member.displayName,
          mode: OrderingMode.asc,
        ),
      ]);

    query.where((member) => member.systemId.equals(localSystemId));
    if (!includeArchived) {
      query.where((member) => member.archived.equals(false));
    }

    return query.watch().map(
      (rows) => [
        for (final row in rows)
          MemberSummary(
            id: row.id,
            displayName: row.displayName,
            pronouns: row.pronouns,
            colorHex: row.colorHex,
            description: row.description,
            archived: row.archived,
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
  Stream<List<FrontHistoryEntry>> watchFrontHistory() {
    final query = database.select(database.frontSessions)
      ..where((session) => session.systemId.equals(localSystemId))
      ..orderBy([
        (session) => OrderingTerm(
          expression: session.startedAt,
          mode: OrderingMode.desc,
        ),
      ]);

    return query.watch().map(
      (rows) => [
        for (final row in rows)
          FrontHistoryEntry(
            id: row.id,
            label: _frontLabel(row.label),
            startedAt: row.startedAt,
            endedAt: row.endedAt,
          ),
      ],
    );
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

  String _frontLabel(String? label) {
    final trimmed = label?.trim();
    return trimmed == null || trimmed.isEmpty ? 'Unknown front' : trimmed;
  }

  AppCustomization _mapCustomizationRows(List<AppPreference> rows) {
    final values = {for (final row in rows) row.key: row.value};

    return AppCustomization(
      themeMode: HavenThemeMode.fromStorage(values[_themeModeKey]),
      accentColor: HavenAccentColor.fromStorage(values[_accentColorKey]),
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
    if (value == null || value.trim().isEmpty) {
      return defaultDashboardShortcutIds;
    }

    final ids = value
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
  Future<void> setAccentColor(HavenAccentColor color) {
    return _writePreference(_accentColorKey, color.storageValue);
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
    await database
        .into(database.members)
        .insert(
          MembersCompanion.insert(
            id: 'member-${now.microsecondsSinceEpoch}',
            systemId: localSystemId,
            displayName: displayName,
            pronouns: Value(_nullIfBlank(draft.pronouns)),
            colorHex: Value(_nullIfBlank(draft.colorHex)),
            description: Value(_nullIfBlank(draft.description)),
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
    return ids.join(',');
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
    final fronts = await (database.select(
      database.frontSessions,
    )..where((front) => front.systemId.equals(localSystemId))).get();
    final frontIds = fronts.map((front) => front.id).toSet();
    final frontMembers = await database
        .select(database.frontSessionMembers)
        .get();
    final importRecords = await (database.select(
      database.importRecords,
    )..where((record) => record.systemId.equals(localSystemId))).get();
    final preferences = await database.select(database.appPreferences).get();

    final archive = {
      'format': 'pluris_haven.local_archive',
      'version': 1,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'system': systems.isEmpty ? null : _systemToJson(systems.single),
      'members': [for (final member in members) _memberToJson(member)],
      'groups': [for (final group in groups) _groupToJson(group)],
      'notes': [for (final note in notes) _noteToJson(note)],
      'fronts': [for (final front in fronts) _frontToJson(front)],
      'front_members': [
        for (final link in frontMembers)
          if (frontIds.contains(link.sessionId)) _frontMemberToJson(link),
      ],
      'import_records': [
        for (final record in importRecords) _importRecordToJson(record),
      ],
      'preferences': [
        for (final preference in preferences) _preferenceToJson(preference),
      ],
    };

    return const JsonEncoder.withIndent('  ').convert(archive);
  }

  @override
  Future<void> importLocalArchiveJson(
    String archiveJson, {
    ImportConflictStrategy strategy = ImportConflictStrategy.skip,
    String? fileName,
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
    final fronts = _jsonObjectList(decoded['fronts']);
    final frontMembers = _jsonObjectList(decoded['front_members']);
    final preferences = _jsonObjectList(decoded['preferences']);

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
        await _importMember(member, strategy, now);
      }
      for (final note in notes) {
        await _importNote(note, strategy, now);
      }
      for (final front in fronts) {
        await _importFront(front, strategy, now);
      }
      for (final link in frontMembers) {
        await _importFrontMember(link);
      }
      for (final preference in preferences) {
        await _importPreference(preference, strategy, now);
      }

      await database
          .into(database.importRecords)
          .insert(
            ImportRecordsCompanion.insert(
              id: 'import-${now.microsecondsSinceEpoch}',
              systemId: localSystemId,
              source: ImportSource.plurisHavenArchive.jobSource,
              fileName: Value(_nullIfBlank(fileName)),
              summaryJson: Value(
                jsonEncode({
                  'members': members.length,
                  'groups': groups.length,
                  'notes': notes.length,
                  'fronts': fronts.length,
                  'front_members': frontMembers.length,
                  'preferences': preferences.length,
                }),
              ),
              importedAt: now,
            ),
          );
    });
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
      avatarUrl: Value(_stringValue(member['avatar_url'])),
      pluralKitId: Value(_stringValue(member['pluralkit_id'])),
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

  List<Map<String, Object?>> _jsonObjectList(Object? value) {
    if (value == null) {
      return const [];
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

  Map<String, Object?> _importRecordToJson(ImportRecord record) => {
    'id': record.id,
    'source': record.source,
    'file_name': record.fileName,
    'summary_json': record.summaryJson,
    'imported_at': record.importedAt.toIso8601String(),
  };

  Map<String, Object?> _preferenceToJson(AppPreference preference) => {
    'key': preference.key,
    'value': preference.value,
    'updated_at': preference.updatedAt.toIso8601String(),
  };
}

const _themeModeKey = 'theme_mode';
const _accentColorKey = 'accent_color';
const _compactDashboardKey = 'compact_dashboard';
const _showDashboardSubtitlesKey = 'show_dashboard_subtitles';
const _dashboardShortcutIdsKey = 'dashboard_shortcut_ids';
const _languageCodeKey = 'language_code';
