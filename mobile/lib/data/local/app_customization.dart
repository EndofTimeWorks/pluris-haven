import 'dart:convert';

import 'package:flutter/material.dart';

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

enum HavenVisualTheme {
  original('original', 'Pluris Haven'),
  simplyPlural('simply_plural', 'Simply Plural style'),
  ampersand('ampersand', 'Ampersand style'),
  materialYou('material_you', 'Material You');

  const HavenVisualTheme(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static HavenVisualTheme fromStorage(String? value) {
    return HavenVisualTheme.values.firstWhere(
      (theme) => theme.storageValue == value,
      orElse: () => HavenVisualTheme.original,
    );
  }
}

class HavenVisualThemeExtension
    extends ThemeExtension<HavenVisualThemeExtension> {
  const HavenVisualThemeExtension(
    this.theme, {
    this.cardRadius,
    this.spacingScale,
  });

  final HavenVisualTheme theme;
  final double? cardRadius;
  final double? spacingScale;

  @override
  HavenVisualThemeExtension copyWith({
    HavenVisualTheme? theme,
    double? cardRadius,
    double? spacingScale,
  }) => HavenVisualThemeExtension(
    theme ?? this.theme,
    cardRadius: cardRadius ?? this.cardRadius,
    spacingScale: spacingScale ?? this.spacingScale,
  );

  @override
  HavenVisualThemeExtension lerp(
    covariant HavenVisualThemeExtension? other,
    double t,
  ) => other == null || t < 0.5 ? this : other;
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

class HavenAppearanceOverrides {
  const HavenAppearanceOverrides({
    this.backgroundHex,
    this.surfaceHex,
    this.cardHex,
    this.textHex,
    this.mutedTextHex,
    this.outlineHex,
    this.cardRadius,
    this.textScale,
    this.spacingScale,
    this.borderWidth,
    this.cardElevation,
  });

  final String? backgroundHex;
  final String? surfaceHex;
  final String? cardHex;
  final String? textHex;
  final String? mutedTextHex;
  final String? outlineHex;
  final double? cardRadius;
  final double? textScale;
  final double? spacingScale;
  final double? borderWidth;
  final double? cardElevation;

  Color? get backgroundColor => _color(backgroundHex);
  Color? get surfaceColor => _color(surfaceHex);
  Color? get cardColor => _color(cardHex);
  Color? get textColor => _color(textHex);
  Color? get mutedTextColor => _color(mutedTextHex);
  Color? get outlineColor => _color(outlineHex);

  bool get isEmpty =>
      backgroundHex == null &&
      surfaceHex == null &&
      cardHex == null &&
      textHex == null &&
      mutedTextHex == null &&
      outlineHex == null &&
      cardRadius == null &&
      textScale == null &&
      spacingScale == null &&
      borderWidth == null &&
      cardElevation == null;

  bool get hasColorOverrides =>
      backgroundHex != null ||
      surfaceHex != null ||
      cardHex != null ||
      textHex != null ||
      mutedTextHex != null ||
      outlineHex != null;

  Map<String, Object> toJson() => {
    'background': ?backgroundHex,
    'surface': ?surfaceHex,
    'card': ?cardHex,
    'text': ?textHex,
    'mutedText': ?mutedTextHex,
    'outline': ?outlineHex,
    'cardRadius': ?cardRadius,
    'textScale': ?textScale,
    'spacingScale': ?spacingScale,
    'borderWidth': ?borderWidth,
    'cardElevation': ?cardElevation,
  };

  static HavenAppearanceOverrides fromJson(String? value) {
    if (value == null || value.trim().isEmpty) {
      return const HavenAppearanceOverrides();
    }
    try {
      final map = jsonDecode(value) as Map<String, Object?>;
      double? number(String key, {double? minimum, double? maximum}) {
        final value = (map[key] as num?)?.toDouble();
        if (value == null ||
            (minimum != null && value < minimum) ||
            (maximum != null && value > maximum)) {
          return null;
        }
        return value;
      }

      return HavenAppearanceOverrides(
        backgroundHex: normalizeHexColor(map['background'] as String?),
        surfaceHex: normalizeHexColor(map['surface'] as String?),
        cardHex: normalizeHexColor(map['card'] as String?),
        textHex: normalizeHexColor(map['text'] as String?),
        mutedTextHex: normalizeHexColor(map['mutedText'] as String?),
        outlineHex: normalizeHexColor(map['outline'] as String?),
        cardRadius: number('cardRadius', minimum: 0, maximum: 48),
        textScale: number('textScale', minimum: 0.8, maximum: 2),
        spacingScale: number('spacingScale', minimum: 0.8, maximum: 1.4),
        borderWidth: number('borderWidth', minimum: 0, maximum: 4),
        cardElevation: number('cardElevation', minimum: 0, maximum: 12),
      );
    } on FormatException {
      return const HavenAppearanceOverrides();
    } on TypeError {
      return const HavenAppearanceOverrides();
    }
  }

  static Color? _color(String? value) {
    final argb = _argbFromHex(value);
    return argb == null ? null : Color(argb);
  }
}

class AppCustomization {
  const AppCustomization({
    required this.themeMode,
    required this.visualTheme,
    required this.accentColor,
    required this.customAccentHex,
    required this.appearance,
    required this.compactDashboard,
    required this.showDashboardSubtitles,
    required this.reducedMotion,
    required this.frontStatusNotification,
    required this.frontStatusShowOnLockScreen,
    required this.frontStatusRevealMemberName,
    required this.screenshotBlockingEnabled,
    required this.appLockEnabled,
    required this.highContrast,
    required this.largeText,
    required this.compactLists,
    required this.dashboardShortcutIds,
    required this.languageCode,
  });

  final HavenThemeMode themeMode;
  final HavenVisualTheme visualTheme;
  final HavenAccentColor accentColor;
  final String? customAccentHex;
  final HavenAppearanceOverrides appearance;
  final bool compactDashboard;
  final bool showDashboardSubtitles;
  final bool reducedMotion;
  final bool frontStatusNotification;
  final bool frontStatusShowOnLockScreen;
  final bool frontStatusRevealMemberName;
  final bool screenshotBlockingEnabled;
  final bool appLockEnabled;
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
    visualTheme: HavenVisualTheme.original,
    accentColor: HavenAccentColor.purple,
    customAccentHex: null,
    appearance: const HavenAppearanceOverrides(),
    compactDashboard: false,
    showDashboardSubtitles: true,
    reducedMotion: false,
    frontStatusNotification: false,
    frontStatusShowOnLockScreen: false,
    frontStatusRevealMemberName: false,
    screenshotBlockingEnabled: true,
    appLockEnabled: false,
    highContrast: false,
    largeText: false,
    compactLists: false,
    dashboardShortcutIds: defaultDashboardShortcutIds,
    languageCode: systemLanguageCode,
  );

  AppCustomization copyWith({
    HavenThemeMode? themeMode,
    HavenVisualTheme? visualTheme,
    HavenAccentColor? accentColor,
    Object? customAccentHex = _unchanged,
    HavenAppearanceOverrides? appearance,
    bool? compactDashboard,
    bool? showDashboardSubtitles,
    bool? reducedMotion,
    bool? frontStatusNotification,
    bool? frontStatusShowOnLockScreen,
    bool? frontStatusRevealMemberName,
    bool? screenshotBlockingEnabled,
    bool? appLockEnabled,
    bool? highContrast,
    bool? largeText,
    bool? compactLists,
    List<String>? dashboardShortcutIds,
    String? languageCode,
  }) {
    return AppCustomization(
      themeMode: themeMode ?? this.themeMode,
      visualTheme: visualTheme ?? this.visualTheme,
      accentColor: accentColor ?? this.accentColor,
      customAccentHex: identical(customAccentHex, _unchanged)
          ? this.customAccentHex
          : customAccentHex as String?,
      appearance: appearance ?? this.appearance,
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
      screenshotBlockingEnabled:
          screenshotBlockingEnabled ?? this.screenshotBlockingEnabled,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
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

  Future<void> setVisualTheme(HavenVisualTheme theme) =>
      _write(_visualThemeKey, theme.storageValue);

  Future<void> setAccentColor(HavenAccentColor color) async {
    await _write(_accentColorKey, color.storageValue);
    await _write(_customAccentHexKey, '');
  }

  Future<void> setCustomAccentColor(String? colorHex) =>
      _write(_customAccentHexKey, normalizeHexColor(colorHex) ?? '');

  Future<void> setAppearanceOverrides(HavenAppearanceOverrides overrides) =>
      _write(
        _appearanceOverridesKey,
        overrides.isEmpty ? '' : jsonEncode(overrides.toJson()),
      );

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

  Future<void> setScreenshotBlockingEnabled(bool value) =>
      _write(_screenshotBlockingEnabledKey, value.toString());

  Future<void> setAppLockEnabled(bool value) =>
      _write(_appLockEnabledKey, value.toString());

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
      visualTheme: HavenVisualTheme.fromStorage(values[_visualThemeKey]),
      accentColor: HavenAccentColor.fromStorage(values[_accentColorKey]),
      customAccentHex: normalizeHexColor(values[_customAccentHexKey]),
      appearance: HavenAppearanceOverrides.fromJson(
        values[_appearanceOverridesKey],
      ),
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
      screenshotBlockingEnabled: _readBool(
        values[_screenshotBlockingEnabledKey],
        defaultValue: true,
      ),
      appLockEnabled: _readBool(values[_appLockEnabledKey]),
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
const _visualThemeKey = 'visual_theme';
const _accentColorKey = 'accent_color';
const _customAccentHexKey = 'custom_accent_hex';
const _appearanceOverridesKey = 'appearance_overrides';
const _compactDashboardKey = 'compact_dashboard';
const _showDashboardSubtitlesKey = 'show_dashboard_subtitles';
const _reducedMotionKey = 'reduced_motion';
const _frontStatusNotificationKey = 'front_status_notification';
const _frontStatusShowOnLockScreenKey = 'front_status_show_on_lock_screen';
const _frontStatusRevealMemberNameKey = 'front_status_reveal_member_name';
const _screenshotBlockingEnabledKey = 'screenshot_blocking_enabled';
const _appLockEnabledKey = 'app_lock_enabled';
const _highContrastKey = 'high_contrast';
const _largeTextKey = 'large_text';
const _compactListsKey = 'compact_lists';
const _dashboardShortcutIdsKey = 'dashboard_shortcut_ids';
const _emptyShortcutIdsValue = '__empty__';
const _languageCodeKey = 'language_code';
