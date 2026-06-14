import 'package:drift/drift.dart';

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
}

const _themeModeKey = 'theme_mode';
const _accentColorKey = 'accent_color';
const _compactDashboardKey = 'compact_dashboard';
const _showDashboardSubtitlesKey = 'show_dashboard_subtitles';
const _dashboardShortcutIdsKey = 'dashboard_shortcut_ids';
const _languageCodeKey = 'language_code';
