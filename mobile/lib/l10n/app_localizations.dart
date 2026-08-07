import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('en', 'US'),
  ];

  /// Title of the settings group for theme, accent colour, dashboard, and language.
  ///
  /// In en, this message translates to:
  /// **'Customise'**
  String get customizeTitle;

  /// No description provided for @themeRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeRowTitle;

  /// No description provided for @accentColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Accent colour'**
  String get accentColorLabel;

  /// No description provided for @compactDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Compact dashboard'**
  String get compactDashboardTitle;

  /// No description provided for @compactDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'smaller shortcuts, more room'**
  String get compactDashboardSubtitle;

  /// No description provided for @dashboardSubtitlesTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard subtitles'**
  String get dashboardSubtitlesTitle;

  /// No description provided for @dashboardSubtitlesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'show counts under shortcuts'**
  String get dashboardSubtitlesSubtitle;

  /// No description provided for @languageRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageRowTitle;

  /// No description provided for @accessibilityGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get accessibilityGroupTitle;

  /// No description provided for @reducedMotionTitle.
  ///
  /// In en, this message translates to:
  /// **'Reduced motion'**
  String get reducedMotionTitle;

  /// No description provided for @reducedMotionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'request simpler, slower-moving UI'**
  String get reducedMotionSubtitle;

  /// No description provided for @frontingNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Fronting notification'**
  String get frontingNotificationTitle;

  /// No description provided for @frontingNotificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'keep the current front visible in Android status'**
  String get frontingNotificationSubtitle;

  /// No description provided for @highContrastTitle.
  ///
  /// In en, this message translates to:
  /// **'High contrast'**
  String get highContrastTitle;

  /// No description provided for @highContrastSubtitle.
  ///
  /// In en, this message translates to:
  /// **'stronger text and clearer borders'**
  String get highContrastSubtitle;

  /// No description provided for @largerAppTextTitle.
  ///
  /// In en, this message translates to:
  /// **'Larger app text'**
  String get largerAppTextTitle;

  /// No description provided for @largerAppTextSubtitle.
  ///
  /// In en, this message translates to:
  /// **'increase Pluris Haven text sizing'**
  String get largerAppTextSubtitle;

  /// No description provided for @compactListsTitle.
  ///
  /// In en, this message translates to:
  /// **'Compact lists'**
  String get compactListsTitle;

  /// No description provided for @compactListsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'denser controls and repeated rows'**
  String get compactListsSubtitle;

  /// No description provided for @localDefaultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Local defaults'**
  String get localDefaultsTitle;

  /// No description provided for @securityRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securityRowTitle;

  /// No description provided for @securityRowValue.
  ///
  /// In en, this message translates to:
  /// **'device storage'**
  String get securityRowValue;

  /// No description provided for @syncRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get syncRowTitle;

  /// No description provided for @syncRowValue.
  ///
  /// In en, this message translates to:
  /// **'off by default'**
  String get syncRowValue;

  /// No description provided for @currentColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Current colour'**
  String get currentColorLabel;

  /// No description provided for @copyHexColorTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy hex colour'**
  String get copyHexColorTooltip;

  /// No description provided for @customHexFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom hex'**
  String get customHexFieldLabel;

  /// No description provided for @useCustomColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Use custom colour'**
  String get useCustomColorLabel;

  /// No description provided for @usePresetLabel.
  ///
  /// In en, this message translates to:
  /// **'Use {presetLabel} preset'**
  String usePresetLabel(String presetLabel);

  /// No description provided for @customAccentChipLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom {hex}'**
  String customAccentChipLabel(String hex);

  /// No description provided for @hexDigitsErrorText.
  ///
  /// In en, this message translates to:
  /// **'Use 6 hex digits, like #7B61FF.'**
  String get hexDigitsErrorText;

  /// No description provided for @chooseLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseLanguageTitle;

  /// No description provided for @chooseLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Interface text stays English until translations are added.'**
  String get chooseLanguageSubtitle;

  /// No description provided for @dashboardShortcutsTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard shortcuts'**
  String get dashboardShortcutsTitle;

  /// No description provided for @shortcutShownLabel.
  ///
  /// In en, this message translates to:
  /// **'shown on dashboard'**
  String get shortcutShownLabel;

  /// No description provided for @shortcutHiddenLabel.
  ///
  /// In en, this message translates to:
  /// **'hidden'**
  String get shortcutHiddenLabel;

  /// No description provided for @moveUpTooltip.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get moveUpTooltip;

  /// No description provided for @moveDownTooltip.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get moveDownTooltip;

  /// No description provided for @resetDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset dashboard'**
  String get resetDashboardTitle;

  /// No description provided for @resetDashboardValue.
  ///
  /// In en, this message translates to:
  /// **'restore default shortcut order'**
  String get resetDashboardValue;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'en':
      {
        switch (locale.countryCode) {
          case 'US':
            return AppLocalizationsEnUs();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
