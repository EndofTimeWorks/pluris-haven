// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get customizeTitle => 'Customise';

  @override
  String get themeRowTitle => 'Theme';

  @override
  String get accentColorLabel => 'Accent colour';

  @override
  String get compactDashboardTitle => 'Compact dashboard';

  @override
  String get compactDashboardSubtitle => 'smaller shortcuts, more room';

  @override
  String get dashboardSubtitlesTitle => 'Dashboard subtitles';

  @override
  String get dashboardSubtitlesSubtitle => 'show counts under shortcuts';

  @override
  String get languageRowTitle => 'Language';

  @override
  String get accessibilityGroupTitle => 'Accessibility';

  @override
  String get reducedMotionTitle => 'Reduced motion';

  @override
  String get reducedMotionSubtitle => 'request simpler, slower-moving UI';

  @override
  String get frontingNotificationTitle => 'Fronting notification';

  @override
  String get frontingNotificationSubtitle =>
      'keep the current front visible in Android status';

  @override
  String get highContrastTitle => 'High contrast';

  @override
  String get highContrastSubtitle => 'stronger text and clearer borders';

  @override
  String get largerAppTextTitle => 'Larger app text';

  @override
  String get largerAppTextSubtitle => 'increase Pluris Haven text sizing';

  @override
  String get compactListsTitle => 'Compact lists';

  @override
  String get compactListsSubtitle => 'denser controls and repeated rows';

  @override
  String get localDefaultsTitle => 'Local defaults';

  @override
  String get securityRowTitle => 'Security';

  @override
  String get securityRowValue => 'device storage';

  @override
  String get syncRowTitle => 'Sync';

  @override
  String get syncRowValue => 'off by default';

  @override
  String get currentColorLabel => 'Current colour';

  @override
  String get copyHexColorTooltip => 'Copy hex colour';

  @override
  String get customHexFieldLabel => 'Custom hex';

  @override
  String get useCustomColorLabel => 'Use custom colour';

  @override
  String usePresetLabel(String presetLabel) {
    return 'Use $presetLabel preset';
  }

  @override
  String customAccentChipLabel(String hex) {
    return 'Custom $hex';
  }

  @override
  String get hexDigitsErrorText => 'Use 6 hex digits, like #7B61FF.';

  @override
  String get chooseLanguageTitle => 'Choose your language';

  @override
  String get chooseLanguageSubtitle =>
      'Interface text stays English until translations are added.';

  @override
  String get dashboardShortcutsTitle => 'Dashboard shortcuts';

  @override
  String get shortcutShownLabel => 'shown on dashboard';

  @override
  String get shortcutHiddenLabel => 'hidden';

  @override
  String get moveUpTooltip => 'Move up';

  @override
  String get moveDownTooltip => 'Move down';

  @override
  String get resetDashboardTitle => 'Reset dashboard';

  @override
  String get resetDashboardValue => 'restore default shortcut order';
}

/// The translations for English, as used in the United States (`en_US`).
class AppLocalizationsEnUs extends AppLocalizationsEn {
  AppLocalizationsEnUs() : super('en_US');

  @override
  String get customizeTitle => 'Customize';

  @override
  String get themeRowTitle => 'Theme';

  @override
  String get accentColorLabel => 'Accent color';

  @override
  String get compactDashboardTitle => 'Compact dashboard';

  @override
  String get compactDashboardSubtitle => 'smaller shortcuts, more room';

  @override
  String get dashboardSubtitlesTitle => 'Dashboard subtitles';

  @override
  String get dashboardSubtitlesSubtitle => 'show counts under shortcuts';

  @override
  String get languageRowTitle => 'Language';

  @override
  String get accessibilityGroupTitle => 'Accessibility';

  @override
  String get reducedMotionTitle => 'Reduced motion';

  @override
  String get reducedMotionSubtitle => 'request simpler, slower-moving UI';

  @override
  String get frontingNotificationTitle => 'Fronting notification';

  @override
  String get frontingNotificationSubtitle =>
      'keep the current front visible in Android status';

  @override
  String get highContrastTitle => 'High contrast';

  @override
  String get highContrastSubtitle => 'stronger text and clearer borders';

  @override
  String get largerAppTextTitle => 'Larger app text';

  @override
  String get largerAppTextSubtitle => 'increase Pluris Haven text sizing';

  @override
  String get compactListsTitle => 'Compact lists';

  @override
  String get compactListsSubtitle => 'denser controls and repeated rows';

  @override
  String get localDefaultsTitle => 'Local defaults';

  @override
  String get securityRowTitle => 'Security';

  @override
  String get securityRowValue => 'device storage';

  @override
  String get syncRowTitle => 'Sync';

  @override
  String get syncRowValue => 'off by default';

  @override
  String get currentColorLabel => 'Current color';

  @override
  String get copyHexColorTooltip => 'Copy hex color';

  @override
  String get customHexFieldLabel => 'Custom hex';

  @override
  String get useCustomColorLabel => 'Use custom color';

  @override
  String usePresetLabel(String presetLabel) {
    return 'Use $presetLabel preset';
  }

  @override
  String customAccentChipLabel(String hex) {
    return 'Custom $hex';
  }

  @override
  String get hexDigitsErrorText => 'Use 6 hex digits, like #7B61FF.';

  @override
  String get chooseLanguageTitle => 'Choose your language';

  @override
  String get chooseLanguageSubtitle =>
      'Interface text stays English until translations are added.';

  @override
  String get dashboardShortcutsTitle => 'Dashboard shortcuts';

  @override
  String get shortcutShownLabel => 'shown on dashboard';

  @override
  String get shortcutHiddenLabel => 'hidden';

  @override
  String get moveUpTooltip => 'Move up';

  @override
  String get moveDownTooltip => 'Move down';

  @override
  String get resetDashboardTitle => 'Reset dashboard';

  @override
  String get resetDashboardValue => 'restore default shortcut order';
}
