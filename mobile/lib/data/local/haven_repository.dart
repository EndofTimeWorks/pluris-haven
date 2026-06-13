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
  });

  final HavenThemeMode themeMode;
  final HavenAccentColor accentColor;
  final bool compactDashboard;
  final bool showDashboardSubtitles;

  static const defaults = AppCustomization(
    themeMode: HavenThemeMode.dark,
    accentColor: HavenAccentColor.purple,
    compactDashboard: false,
    showDashboardSubtitles: true,
  );

  AppCustomization copyWith({
    HavenThemeMode? themeMode,
    HavenAccentColor? accentColor,
    bool? compactDashboard,
    bool? showDashboardSubtitles,
  }) {
    return AppCustomization(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      compactDashboard: compactDashboard ?? this.compactDashboard,
      showDashboardSubtitles:
          showDashboardSubtitles ?? this.showDashboardSubtitles,
    );
  }
}

abstract interface class HavenRepository {
  Stream<HomeSnapshot> watchHomeSnapshot();

  Stream<AppCustomization> watchCustomization();

  Future<AppCustomization> loadCustomization();

  Future<void> setThemeMode(HavenThemeMode mode);

  Future<void> setAccentColor(HavenAccentColor color);

  Future<void> setCompactDashboard(bool compact);

  Future<void> setShowDashboardSubtitles(bool show);

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
    );
  }

  bool _readBool(String? value, {bool defaultValue = false}) {
    if (value == null) {
      return defaultValue;
    }

    return value == 'true';
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
}

const _themeModeKey = 'theme_mode';
const _accentColorKey = 'accent_color';
const _compactDashboardKey = 'compact_dashboard';
const _showDashboardSubtitlesKey = 'show_dashboard_subtitles';
