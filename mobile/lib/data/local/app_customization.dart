import 'app_database.dart';
import 'supported_language.dart';

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
    required this.customAccentHex,
    required this.compactDashboard,
    required this.showDashboardSubtitles,
    required this.reducedMotion,
    required this.frontStatusNotification,
    required this.frontStatusShowOnLockScreen,
    required this.frontStatusRevealMemberName,
    required this.highContrast,
    required this.largeText,
    required this.compactLists,
    required this.dashboardShortcutIds,
    required this.languageCode,
  });

  final HavenThemeMode themeMode;
  final HavenAccentColor accentColor;
  final String? customAccentHex;
  final bool compactDashboard;
  final bool showDashboardSubtitles;
  final bool reducedMotion;
  final bool frontStatusNotification;
  final bool frontStatusShowOnLockScreen;
  final bool frontStatusRevealMemberName;
  final bool highContrast;
  final bool largeText;
  final bool compactLists;
  final List<String> dashboardShortcutIds;
  final String languageCode;

  int get effectiveAccentArgb =>
      _argbFromHex(customAccentHex) ?? accentColor.argb;

  String get accentLabel => customAccentHex == null
      ? accentColor.label
      : 'Custom ${customAccentHex!.toUpperCase()}';

  static AppCustomization get defaults => AppCustomization(
    themeMode: HavenThemeMode.dark,
    accentColor: HavenAccentColor.purple,
    customAccentHex: null,
    compactDashboard: false,
    showDashboardSubtitles: true,
    reducedMotion: false,
    frontStatusNotification: false,
    frontStatusShowOnLockScreen: false,
    frontStatusRevealMemberName: false,
    highContrast: false,
    largeText: false,
    compactLists: false,
    dashboardShortcutIds: defaultDashboardShortcutIds,
    languageCode: systemLanguageCode,
  );

  AppCustomization copyWith({
    HavenThemeMode? themeMode,
    HavenAccentColor? accentColor,
    Object? customAccentHex = _unchanged,
    bool? compactDashboard,
    bool? showDashboardSubtitles,
    bool? reducedMotion,
    bool? frontStatusNotification,
    bool? frontStatusShowOnLockScreen,
    bool? frontStatusRevealMemberName,
    bool? highContrast,
    bool? largeText,
    bool? compactLists,
    List<String>? dashboardShortcutIds,
    String? languageCode,
  }) {
    return AppCustomization(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      customAccentHex: identical(customAccentHex, _unchanged)
          ? this.customAccentHex
          : customAccentHex as String?,
      compactDashboard: compactDashboard ?? this.compactDashboard,
      showDashboardSubtitles:
          showDashboardSubtitles ?? this.showDashboardSubtitles,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      frontStatusNotification:
          frontStatusNotification ?? this.frontStatusNotification,
      frontStatusShowOnLockScreen:
          frontStatusShowOnLockScreen ?? this.frontStatusShowOnLockScreen,
      frontStatusRevealMemberName:
          frontStatusRevealMemberName ?? this.frontStatusRevealMemberName,
      highContrast: highContrast ?? this.highContrast,
      largeText: largeText ?? this.largeText,
      compactLists: compactLists ?? this.compactLists,
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
  'journals',
  'import-export',
  'analytics',
  'reminders',
  'customize',
];

class LocalAppCustomizationStore {
  LocalAppCustomizationStore(this.database);

  final AppDatabase database;

  Stream<AppCustomization> watch() =>
      database.select(database.appPreferences).watch().map(_mapRows);

  Future<AppCustomization> load() async {
    return _mapRows(await database.select(database.appPreferences).get());
  }

  Future<void> setThemeMode(HavenThemeMode mode) =>
      _write(_themeModeKey, mode.storageValue);

  Future<void> setAccentColor(HavenAccentColor color) async {
    await _write(_accentColorKey, color.storageValue);
    await _write(_customAccentHexKey, '');
  }

  Future<void> setCustomAccentColor(String? colorHex) =>
      _write(_customAccentHexKey, normalizeHexColor(colorHex) ?? '');

  Future<void> setCompactDashboard(bool value) =>
      _write(_compactDashboardKey, value.toString());

  Future<void> setShowDashboardSubtitles(bool value) =>
      _write(_showDashboardSubtitlesKey, value.toString());

  Future<void> setReducedMotion(bool value) =>
      _write(_reducedMotionKey, value.toString());

  Future<void> setFrontStatusNotification(bool value) =>
      _write(_frontStatusNotificationKey, value.toString());

  Future<void> setFrontStatusShowOnLockScreen(bool value) =>
      _write(_frontStatusShowOnLockScreenKey, value.toString());

  Future<void> setFrontStatusRevealMemberName(bool value) =>
      _write(_frontStatusRevealMemberNameKey, value.toString());

  Future<void> setHighContrast(bool value) =>
      _write(_highContrastKey, value.toString());

  Future<void> setLargeText(bool value) =>
      _write(_largeTextKey, value.toString());

  Future<void> setCompactLists(bool value) =>
      _write(_compactListsKey, value.toString());

  Future<void> setDashboardShortcutIds(List<String> shortcutIds) =>
      _write(_dashboardShortcutIdsKey, _serializeIds(shortcutIds));

  Future<void> setLanguageCode(String languageCode) =>
      _write(_languageCodeKey, supportedLanguageForCode(languageCode).code);

  Future<void> setDashboardShortcutVisible(
    String shortcutId,
    bool visible,
  ) async {
    final ids = (await load()).dashboardShortcutIds.toList();
    final existingIndex = ids.indexOf(shortcutId);
    if (visible && existingIndex == -1) {
      ids.add(shortcutId);
    } else if (!visible && existingIndex != -1) {
      ids.removeAt(existingIndex);
    }
    await setDashboardShortcutIds(ids);
  }

  Future<void> moveDashboardShortcut(String shortcutId, int delta) async {
    if (delta == 0) return;
    final ids = (await load()).dashboardShortcutIds.toList();
    final index = ids.indexOf(shortcutId);
    if (index == -1) return;
    final newIndex = (index + delta).clamp(0, ids.length - 1);
    if (newIndex == index) return;
    final id = ids.removeAt(index);
    ids.insert(newIndex, id);
    await setDashboardShortcutIds(ids);
  }

  Future<void> resetDashboardShortcuts() =>
      setDashboardShortcutIds(defaultDashboardShortcutIds);

  AppCustomization _mapRows(List<AppPreference> rows) {
    final values = {for (final row in rows) row.key: row.value};
    return AppCustomization(
      themeMode: HavenThemeMode.fromStorage(values[_themeModeKey]),
      accentColor: HavenAccentColor.fromStorage(values[_accentColorKey]),
      customAccentHex: normalizeHexColor(values[_customAccentHexKey]),
      compactDashboard: _readBool(values[_compactDashboardKey]),
      showDashboardSubtitles: _readBool(
        values[_showDashboardSubtitlesKey],
        defaultValue: true,
      ),
      reducedMotion: _readBool(values[_reducedMotionKey]),
      frontStatusNotification: _readBool(values[_frontStatusNotificationKey]),
      frontStatusShowOnLockScreen: _readBool(
        values[_frontStatusShowOnLockScreenKey],
      ),
      frontStatusRevealMemberName: _readBool(
        values[_frontStatusRevealMemberNameKey],
      ),
      highContrast: _readBool(values[_highContrastKey]),
      largeText: _readBool(values[_largeTextKey]),
      compactLists: _readBool(values[_compactListsKey]),
      dashboardShortcutIds: _readShortcutIds(values[_dashboardShortcutIdsKey]),
      languageCode: supportedLanguageForCode(values[_languageCodeKey]).code,
    );
  }

  bool _readBool(String? value, {bool defaultValue = false}) =>
      value == null ? defaultValue : value == 'true';

  List<String> _readShortcutIds(String? value) {
    if (value == null) return defaultDashboardShortcutIds;
    final stored = value.trim();
    if (stored == _emptyShortcutIdsValue) return const [];
    if (stored.isEmpty) return defaultDashboardShortcutIds;
    final ids = stored
        .split(',')
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList();
    return ids.isEmpty ? defaultDashboardShortcutIds : List.unmodifiable(ids);
  }

  String _serializeIds(List<String> shortcutIds) {
    final seen = <String>{};
    final ids = <String>[];
    for (final id in shortcutIds) {
      final trimmed = id.trim();
      if (trimmed.isNotEmpty && seen.add(trimmed)) ids.add(trimmed);
    }
    return ids.isEmpty ? _emptyShortcutIdsValue : ids.join(',');
  }

  Future<void> _write(String key, String value) {
    return database
        .into(database.appPreferences)
        .insertOnConflictUpdate(
          AppPreferencesCompanion.insert(
            key: key,
            value: value,
            updatedAt: DateTime.now().toUtc(),
          ),
        );
  }
}

String? normalizeHexColor(String? value) {
  if (value == null) return null;
  final normalized = value.trim().replaceFirst('#', '');
  if (normalized.length != 6 ||
      !RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(normalized)) {
    return null;
  }
  return '#${normalized.toUpperCase()}';
}

int? _argbFromHex(String? value) {
  final normalized = normalizeHexColor(value);
  if (normalized == null) return null;
  return int.parse('FF${normalized.substring(1)}', radix: 16);
}

const Object _unchanged = Object();
const _themeModeKey = 'theme_mode';
const _accentColorKey = 'accent_color';
const _customAccentHexKey = 'custom_accent_hex';
const _compactDashboardKey = 'compact_dashboard';
const _showDashboardSubtitlesKey = 'show_dashboard_subtitles';
const _reducedMotionKey = 'reduced_motion';
const _frontStatusNotificationKey = 'front_status_notification';
const _frontStatusShowOnLockScreenKey = 'front_status_show_on_lock_screen';
const _frontStatusRevealMemberNameKey = 'front_status_reveal_member_name';
const _highContrastKey = 'high_contrast';
const _largeTextKey = 'large_text';
const _compactListsKey = 'compact_lists';
const _dashboardShortcutIdsKey = 'dashboard_shortcut_ids';
const _emptyShortcutIdsValue = '__empty__';
const _languageCodeKey = 'language_code';
