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

  /// No description provided for @visualThemeRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Visual style'**
  String get visualThemeRowTitle;

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

  /// No description provided for @frontStatusShowOnLockScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Show on lock screen'**
  String get frontStatusShowOnLockScreenTitle;

  /// No description provided for @frontStatusShowOnLockScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'reveal this notification before the device is unlocked'**
  String get frontStatusShowOnLockScreenSubtitle;

  /// No description provided for @frontStatusRevealMemberNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Show fronting member\'s name'**
  String get frontStatusRevealMemberNameTitle;

  /// No description provided for @frontStatusRevealMemberNameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'otherwise the notification only says Pluris Haven is active'**
  String get frontStatusRevealMemberNameSubtitle;

  /// No description provided for @appLockTitle.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get appLockTitle;

  /// No description provided for @appLockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'require your device screen lock or biometrics to open the app'**
  String get appLockSubtitle;

  /// No description provided for @screenshotBlockingTitle.
  ///
  /// In en, this message translates to:
  /// **'Block screenshots'**
  String get screenshotBlockingTitle;

  /// No description provided for @screenshotBlockingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'hide app content from screenshots and screen recordings'**
  String get screenshotBlockingSubtitle;

  /// No description provided for @appLockReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock Pluris Haven'**
  String get appLockReason;

  /// No description provided for @appLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Pluris Haven is locked'**
  String get appLockedTitle;

  /// No description provided for @appLockedBody.
  ///
  /// In en, this message translates to:
  /// **'Unlock your device to continue.'**
  String get appLockedBody;

  /// No description provided for @appLockUnlockButton.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get appLockUnlockButton;

  /// No description provided for @plurisHavenAppName.
  ///
  /// In en, this message translates to:
  /// **'Pluris Haven'**
  String get plurisHavenAppName;

  /// No description provided for @privateReminderNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Pluris Haven reminder'**
  String get privateReminderNotificationTitle;

  /// No description provided for @privateNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Open Pluris Haven to view.'**
  String get privateNotificationBody;

  /// No description provided for @currentlyFrontingNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Currently fronting'**
  String get currentlyFrontingNotificationTitle;

  /// No description provided for @remindersChannelName.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersChannelName;

  /// No description provided for @remindersChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Front check-ins and custom reminders'**
  String get remindersChannelDescription;

  /// No description provided for @frontStatusChannelName.
  ///
  /// In en, this message translates to:
  /// **'Front status'**
  String get frontStatusChannelName;

  /// No description provided for @frontStatusChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Persistent currently-fronting status'**
  String get frontStatusChannelDescription;

  /// No description provided for @notificationsUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications unavailable'**
  String get notificationsUnavailableTitle;

  /// No description provided for @notificationsUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'Pluris Haven could not start this device\'s notification service. Reminders stay saved, but they may not appear outside the app until it restarts successfully.'**
  String get notificationsUnavailableBody;

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

  /// No description provided for @syncOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync is off'**
  String get syncOffTitle;

  /// No description provided for @localStatusPill.
  ///
  /// In en, this message translates to:
  /// **'local'**
  String get localStatusPill;

  /// No description provided for @syncOffDescription.
  ///
  /// In en, this message translates to:
  /// **'Pluris Haven keeps data on this device unless sync is turned on.'**
  String get syncOffDescription;

  /// No description provided for @encryptedSyncLabel.
  ///
  /// In en, this message translates to:
  /// **'Encrypted sync'**
  String get encryptedSyncLabel;

  /// No description provided for @encryptedSyncValue.
  ///
  /// In en, this message translates to:
  /// **'not configured'**
  String get encryptedSyncValue;

  /// No description provided for @friendsLabel.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friendsLabel;

  /// No description provided for @friendsValue.
  ///
  /// In en, this message translates to:
  /// **'not shared'**
  String get friendsValue;

  /// No description provided for @backupsLabel.
  ///
  /// In en, this message translates to:
  /// **'Backups'**
  String get backupsLabel;

  /// No description provided for @backupsValue.
  ///
  /// In en, this message translates to:
  /// **'manual for now'**
  String get backupsValue;

  /// No description provided for @notificationHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification history'**
  String get notificationHistoryTitle;

  /// No description provided for @noNotificationsYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYetTitle;

  /// No description provided for @noNotificationsYetBody.
  ///
  /// In en, this message translates to:
  /// **'Front notifications and reminders will be recorded here.'**
  String get noNotificationsYetBody;

  /// No description provided for @newStatusPill.
  ///
  /// In en, this message translates to:
  /// **'new'**
  String get newStatusPill;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Offline-first system, identity, and journaling tools.'**
  String get appTagline;

  /// No description provided for @madeBySystemsStatement.
  ///
  /// In en, this message translates to:
  /// **'Made by systems. Welcoming systems, collectives, individuals, and anyone who finds these tools useful.'**
  String get madeBySystemsStatement;

  /// No description provided for @aboutGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutGroupTitle;

  /// No description provided for @storageLabel.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storageLabel;

  /// No description provided for @storageValue.
  ///
  /// In en, this message translates to:
  /// **'saved on device'**
  String get storageValue;

  /// No description provided for @compatibilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Compatibility'**
  String get compatibilityLabel;

  /// No description provided for @sourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get sourceLabel;

  /// No description provided for @optionalSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Optional support'**
  String get optionalSupportTitle;

  /// No description provided for @copyMoneroTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy Monero address'**
  String get copyMoneroTooltip;

  /// No description provided for @moneroAddressCopied.
  ///
  /// In en, this message translates to:
  /// **'Monero address copied'**
  String get moneroAddressCopied;

  /// No description provided for @couldNotOpenUrl.
  ///
  /// In en, this message translates to:
  /// **'Could not open {url}'**
  String couldNotOpenUrl(String url);

  /// No description provided for @cancelButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButtonLabel;

  /// No description provided for @deleteButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButtonLabel;

  /// No description provided for @dashboardMainSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get dashboardMainSectionTitle;

  /// No description provided for @noDashboardShortcutsTitle.
  ///
  /// In en, this message translates to:
  /// **'No dashboard shortcuts'**
  String get noDashboardShortcutsTitle;

  /// No description provided for @noDashboardShortcutsBody.
  ///
  /// In en, this message translates to:
  /// **'Open Customise to add shortcuts back.'**
  String get noDashboardShortcutsBody;

  /// No description provided for @dashboardShortcutSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'{title} dashboard shortcut'**
  String dashboardShortcutSemanticLabel(String title);

  /// No description provided for @dashboardShortcutMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get dashboardShortcutMembersTitle;

  /// No description provided for @dashboardShortcutFrontHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Front History'**
  String get dashboardShortcutFrontHistoryTitle;

  /// No description provided for @dashboardShortcutCustomFrontsTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom Fronts'**
  String get dashboardShortcutCustomFrontsTitle;

  /// No description provided for @dashboardShortcutCustomFrontsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'saved states'**
  String get dashboardShortcutCustomFrontsSubtitle;

  /// No description provided for @dashboardShortcutGroupsTitle.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get dashboardShortcutGroupsTitle;

  /// No description provided for @dashboardShortcutNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get dashboardShortcutNotesTitle;

  /// No description provided for @dashboardShortcutJournalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Journals'**
  String get dashboardShortcutJournalsTitle;

  /// No description provided for @dashboardShortcutJournalsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'long entries'**
  String get dashboardShortcutJournalsSubtitle;

  /// No description provided for @dashboardShortcutImportExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import / Export'**
  String get dashboardShortcutImportExportTitle;

  /// No description provided for @dashboardShortcutImportExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'local archive'**
  String get dashboardShortcutImportExportSubtitle;

  /// No description provided for @dashboardShortcutSyncSubtitle.
  ///
  /// In en, this message translates to:
  /// **'off by default'**
  String get dashboardShortcutSyncSubtitle;

  /// No description provided for @dashboardShortcutCustomizeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'layout and theme'**
  String get dashboardShortcutCustomizeSubtitle;

  /// No description provided for @dashboardShortcutAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get dashboardShortcutAnalyticsTitle;

  /// No description provided for @dashboardShortcutAnalyticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'local stats'**
  String get dashboardShortcutAnalyticsSubtitle;

  /// No description provided for @dashboardShortcutRemindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get dashboardShortcutRemindersTitle;

  /// No description provided for @dashboardShortcutRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'0 scheduled'**
  String get dashboardShortcutRemindersSubtitle;

  /// No description provided for @dashboardShortcutCustomFieldsTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom Fields'**
  String get dashboardShortcutCustomFieldsTitle;

  /// No description provided for @dashboardShortcutCustomFieldsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'profile fields'**
  String get dashboardShortcutCustomFieldsSubtitle;

  /// No description provided for @dashboardShortcutFriendsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'sync required'**
  String get dashboardShortcutFriendsSubtitle;

  /// No description provided for @dashboardShortcutChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get dashboardShortcutChatTitle;

  /// No description provided for @dashboardShortcutChatSubtitle.
  ///
  /// In en, this message translates to:
  /// **'offline board'**
  String get dashboardShortcutChatSubtitle;

  /// No description provided for @dashboardShortcutPollsTitle.
  ///
  /// In en, this message translates to:
  /// **'Polls'**
  String get dashboardShortcutPollsTitle;

  /// No description provided for @dashboardShortcutPollsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'0 active'**
  String get dashboardShortcutPollsSubtitle;

  /// No description provided for @dashboardShortcutUsefulLinksTitle.
  ///
  /// In en, this message translates to:
  /// **'Useful Links'**
  String get dashboardShortcutUsefulLinksTitle;

  /// No description provided for @dashboardShortcutUsefulLinksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'help and links'**
  String get dashboardShortcutUsefulLinksSubtitle;

  /// No description provided for @dashboardShortcutPrivacyBucketsTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Buckets'**
  String get dashboardShortcutPrivacyBucketsTitle;

  /// No description provided for @dashboardShortcutPrivacyBucketsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'local visibility'**
  String get dashboardShortcutPrivacyBucketsSubtitle;

  /// No description provided for @dashboardShortcutTokensTitle.
  ///
  /// In en, this message translates to:
  /// **'Tokens'**
  String get dashboardShortcutTokensTitle;

  /// No description provided for @dashboardShortcutTokensSubtitle.
  ///
  /// In en, this message translates to:
  /// **'sync later'**
  String get dashboardShortcutTokensSubtitle;

  /// No description provided for @dashboardShortcutUserReportTitle.
  ///
  /// In en, this message translates to:
  /// **'User Report'**
  String get dashboardShortcutUserReportTitle;

  /// No description provided for @dashboardShortcutUserReportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'diagnostics'**
  String get dashboardShortcutUserReportSubtitle;

  /// No description provided for @dashboardShortcutNotificationHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification History'**
  String get dashboardShortcutNotificationHistoryTitle;

  /// No description provided for @dashboardShortcutNotificationHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'local log'**
  String get dashboardShortcutNotificationHistorySubtitle;

  /// No description provided for @dashboardShortcutHowtosTitle.
  ///
  /// In en, this message translates to:
  /// **'How-to\'s'**
  String get dashboardShortcutHowtosTitle;

  /// No description provided for @dashboardShortcutHowtosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'offline guides'**
  String get dashboardShortcutHowtosSubtitle;

  /// No description provided for @dashboardShortcutAccountSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get dashboardShortcutAccountSettingsTitle;

  /// No description provided for @dashboardShortcutAccountSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'local profile'**
  String get dashboardShortcutAccountSettingsSubtitle;

  /// No description provided for @frontHistoryCountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} entries'**
  String frontHistoryCountSubtitle(int count);

  /// No description provided for @groupCountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} groups'**
  String groupCountSubtitle(int count);

  /// No description provided for @noteCountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} notes'**
  String noteCountSubtitle(int count);

  /// No description provided for @serverAccountsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Server accounts are unavailable in this app session.'**
  String get serverAccountsUnavailable;

  /// No description provided for @optionalServerAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Optional server account'**
  String get optionalServerAccountTitle;

  /// No description provided for @serverConnectDescription.
  ///
  /// In en, this message translates to:
  /// **'Connect an HTTPS server to use encrypted online backups and account features. Local use stays independent.'**
  String get serverConnectDescription;

  /// No description provided for @serverUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get serverUrlLabel;

  /// No description provided for @connectServerButton.
  ///
  /// In en, this message translates to:
  /// **'Check and connect'**
  String get connectServerButton;

  /// No description provided for @connectedServerFallback.
  ///
  /// In en, this message translates to:
  /// **'Connected server'**
  String get connectedServerFallback;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInButton;

  /// No description provided for @forgotPasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordButton;

  /// No description provided for @useResetTokenButton.
  ///
  /// In en, this message translates to:
  /// **'I have a reset token'**
  String get useResetTokenButton;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset server password'**
  String get resetPasswordTitle;

  /// No description provided for @resetTokenLabel.
  ///
  /// In en, this message translates to:
  /// **'Reset token'**
  String get resetTokenLabel;

  /// No description provided for @resetPasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordButton;

  /// No description provided for @createAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccountButton;

  /// No description provided for @disconnectButton.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnectButton;

  /// No description provided for @accountFallback.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountFallback;

  /// No description provided for @thisDeviceLabel.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get thisDeviceLabel;

  /// No description provided for @activeServerSessionLabel.
  ///
  /// In en, this message translates to:
  /// **'Active server session'**
  String get activeServerSessionLabel;

  /// No description provided for @revokeSessionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Revoke session'**
  String get revokeSessionTooltip;

  /// No description provided for @securityHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Security history'**
  String get securityHistoryTitle;

  /// No description provided for @securityHistoryDescription.
  ///
  /// In en, this message translates to:
  /// **'Recent security-sensitive account actions. This history never includes IP addresses, email addresses, device names, tokens, backup names, or archive content.'**
  String get securityHistoryDescription;

  /// No description provided for @securityHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No security actions recorded yet.'**
  String get securityHistoryEmpty;

  /// No description provided for @securityEventSignedOut.
  ///
  /// In en, this message translates to:
  /// **'A device signed out'**
  String get securityEventSignedOut;

  /// No description provided for @securityEventPasswordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed'**
  String get securityEventPasswordChanged;

  /// No description provided for @securityEventSessionRevoked.
  ///
  /// In en, this message translates to:
  /// **'A device session was revoked'**
  String get securityEventSessionRevoked;

  /// No description provided for @securityEventBackupRecoveryStarted.
  ///
  /// In en, this message translates to:
  /// **'Encrypted backup recovery started'**
  String get securityEventBackupRecoveryStarted;

  /// No description provided for @securityEventBackupDeleted.
  ///
  /// In en, this message translates to:
  /// **'Encrypted backup deleted'**
  String get securityEventBackupDeleted;

  /// No description provided for @securityEventAccountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Server account deleted'**
  String get securityEventAccountDeleted;

  /// No description provided for @securityEventAccountDeletionRequested.
  ///
  /// In en, this message translates to:
  /// **'Server account deletion scheduled'**
  String get securityEventAccountDeletionRequested;

  /// No description provided for @securityEventAccountRecovered.
  ///
  /// In en, this message translates to:
  /// **'Server account recovered'**
  String get securityEventAccountRecovered;

  /// No description provided for @securityEventUnknown.
  ///
  /// In en, this message translates to:
  /// **'Security action recorded'**
  String get securityEventUnknown;

  /// No description provided for @refreshButton.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshButton;

  /// No description provided for @signOutButton.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOutButton;

  /// No description provided for @deleteServerAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Delete server account'**
  String get deleteServerAccountButton;

  /// No description provided for @deleteServerAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete server account?'**
  String get deleteServerAccountTitle;

  /// No description provided for @deleteServerAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This signs you out and schedules server data for deletion in 30 days. Sign in with the same email and password within that time to recover it. Local app data stays on this device.'**
  String get deleteServerAccountBody;

  /// No description provided for @currentPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPasswordLabel;

  /// No description provided for @changePasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePasswordButton;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change server password'**
  String get changePasswordTitle;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPasswordLabel;

  /// No description provided for @confirmNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPasswordLabel;

  /// No description provided for @passwordsDoNotMatchError.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatchError;

  /// No description provided for @passwordChangedMessage.
  ///
  /// In en, this message translates to:
  /// **'Password changed. Other device sessions were signed out.'**
  String get passwordChangedMessage;

  /// No description provided for @deleteAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountButton;

  /// No description provided for @createServerAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create server account'**
  String get createServerAccountTitle;

  /// No description provided for @displayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayNameLabel;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @invalidEmailError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get invalidEmailError;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordLengthError.
  ///
  /// In en, this message translates to:
  /// **'Use at least 12 characters.'**
  String get passwordLengthError;

  /// No description provided for @deviceNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Device name'**
  String get deviceNameLabel;

  /// No description provided for @requiredFieldError.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get requiredFieldError;

  /// No description provided for @onlineBackupUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Online backup is unavailable in this app session.'**
  String get onlineBackupUnavailable;

  /// No description provided for @encryptedOnlineBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Encrypted online backup'**
  String get encryptedOnlineBackupTitle;

  /// No description provided for @backupEncryptionDescription.
  ///
  /// In en, this message translates to:
  /// **'Snapshots are encrypted on this device before upload.'**
  String get backupEncryptionDescription;

  /// No description provided for @backupSignInDescription.
  ///
  /// In en, this message translates to:
  /// **'Connect and sign in from Account Settings first.'**
  String get backupSignInDescription;

  /// No description provided for @backupUploadProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Encrypted backup upload progress'**
  String get backupUploadProgressLabel;

  /// No description provided for @backupUploadProgressValue.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} chunks'**
  String backupUploadProgressValue(int completed, int total);

  /// No description provided for @createUploadSnapshotButton.
  ///
  /// In en, this message translates to:
  /// **'Create and upload snapshot'**
  String get createUploadSnapshotButton;

  /// No description provided for @backupSnapshotProgress.
  ///
  /// In en, this message translates to:
  /// **'{uploadedChunks}/{chunkCount} chunks, {uploadedBytes}/{totalBytes} bytes'**
  String backupSnapshotProgress(
    int uploadedChunks,
    int chunkCount,
    int uploadedBytes,
    int totalBytes,
  );

  /// No description provided for @restoreEncryptedBackupButton.
  ///
  /// In en, this message translates to:
  /// **'Restore this backup'**
  String get restoreEncryptedBackupButton;

  /// No description provided for @restoreEncryptedBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore encrypted backup?'**
  String get restoreEncryptedBackupTitle;

  /// No description provided for @restoreEncryptedBackupBody.
  ///
  /// In en, this message translates to:
  /// **'This will merge the backup into local data and update matching records. Keep a local encrypted archive before continuing.'**
  String get restoreEncryptedBackupBody;

  /// No description provided for @restoreEncryptedBackupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Restore backup'**
  String get restoreEncryptedBackupConfirm;

  /// No description provided for @restoringEncryptedBackup.
  ///
  /// In en, this message translates to:
  /// **'Downloading and restoring encrypted backup...'**
  String get restoringEncryptedBackup;

  /// No description provided for @encryptedBackupRestored.
  ///
  /// In en, this message translates to:
  /// **'Encrypted backup restored.'**
  String get encryptedBackupRestored;

  /// No description provided for @encryptedBackupRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not restore encrypted backup: {error}'**
  String encryptedBackupRestoreFailed(String error);

  /// No description provided for @deleteEncryptedBackupTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete encrypted backup'**
  String get deleteEncryptedBackupTooltip;

  /// No description provided for @deleteEncryptedBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete encrypted backup?'**
  String get deleteEncryptedBackupTitle;

  /// No description provided for @deleteEncryptedBackupBody.
  ///
  /// In en, this message translates to:
  /// **'This server copy will be permanently removed.'**
  String get deleteEncryptedBackupBody;

  /// No description provided for @friendsSignInBody.
  ///
  /// In en, this message translates to:
  /// **'Connect and sign in to a server from Account Settings first.'**
  String get friendsSignInBody;

  /// No description provided for @localDataLabel.
  ///
  /// In en, this message translates to:
  /// **'Local data'**
  String get localDataLabel;

  /// No description provided for @notSharedValue.
  ///
  /// In en, this message translates to:
  /// **'not shared'**
  String get notSharedValue;

  /// No description provided for @requestsLabel.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requestsLabel;

  /// No description provided for @offValue.
  ///
  /// In en, this message translates to:
  /// **'off'**
  String get offValue;

  /// No description provided for @friendsDisabledBody.
  ///
  /// In en, this message translates to:
  /// **'This server has friend connections disabled.'**
  String get friendsDisabledBody;

  /// No description provided for @serverDisabledValue.
  ///
  /// In en, this message translates to:
  /// **'server disabled'**
  String get serverDisabledValue;

  /// No description provided for @friendCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Friend code'**
  String get friendCodeTitle;

  /// No description provided for @rotateFriendCodePrompt.
  ///
  /// In en, this message translates to:
  /// **'Rotate to create a new code'**
  String get rotateFriendCodePrompt;

  /// No description provided for @rotateFriendCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Rotate friend code'**
  String get rotateFriendCodeButton;

  /// No description provided for @someoneElsesCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Someone else’s code'**
  String get someoneElsesCodeLabel;

  /// No description provided for @sendRequestButton.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get sendRequestButton;

  /// No description provided for @pendingRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending requests'**
  String get pendingRequestsTitle;

  /// No description provided for @noPendingRequests.
  ///
  /// In en, this message translates to:
  /// **'No pending requests.'**
  String get noPendingRequests;

  /// No description provided for @acceptRequestTooltip.
  ///
  /// In en, this message translates to:
  /// **'Accept request'**
  String get acceptRequestTooltip;

  /// No description provided for @declineRequestTooltip.
  ///
  /// In en, this message translates to:
  /// **'Decline request'**
  String get declineRequestTooltip;

  /// No description provided for @cancelRequestTooltip.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get cancelRequestTooltip;

  /// No description provided for @noFriendsYet.
  ///
  /// In en, this message translates to:
  /// **'No friends yet.'**
  String get noFriendsYet;

  /// No description provided for @nothingShared.
  ///
  /// In en, this message translates to:
  /// **'Nothing shared'**
  String get nothingShared;

  /// No description provided for @permissionsShared.
  ///
  /// In en, this message translates to:
  /// **'{count} permissions shared'**
  String permissionsShared(int count);

  /// No description provided for @removeFriendTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove friend?'**
  String get removeFriendTitle;

  /// No description provided for @removeFriendBody.
  ///
  /// In en, this message translates to:
  /// **'The friendship and its sharing permissions will be removed.'**
  String get removeFriendBody;

  /// No description provided for @blockUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Block {displayName}?'**
  String blockUserTitle(String displayName);

  /// No description provided for @blockUserBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the friendship, pending requests, and every sharing permission in both directions.'**
  String get blockUserBody;

  /// No description provided for @sharingPermissionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Sharing permissions'**
  String get sharingPermissionsLabel;

  /// No description provided for @removeFriendButton.
  ///
  /// In en, this message translates to:
  /// **'Remove friend'**
  String get removeFriendButton;

  /// No description provided for @blockUserButton.
  ///
  /// In en, this message translates to:
  /// **'Block user'**
  String get blockUserButton;

  /// No description provided for @blockedUsersTitle.
  ///
  /// In en, this message translates to:
  /// **'Blocked users'**
  String get blockedUsersTitle;

  /// No description provided for @noBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'No blocked users.'**
  String get noBlockedUsers;

  /// No description provided for @unblockButton.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblockButton;

  /// No description provided for @shareWithTitle.
  ///
  /// In en, this message translates to:
  /// **'Share with {displayName}'**
  String shareWithTitle(String displayName);

  /// No description provided for @saveButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButtonLabel;

  /// No description provided for @friendGrantCurrentFront.
  ///
  /// In en, this message translates to:
  /// **'Current front'**
  String get friendGrantCurrentFront;

  /// No description provided for @friendGrantMemberList.
  ///
  /// In en, this message translates to:
  /// **'Member list'**
  String get friendGrantMemberList;

  /// No description provided for @friendGrantMemberDetails.
  ///
  /// In en, this message translates to:
  /// **'Member details'**
  String get friendGrantMemberDetails;

  /// No description provided for @friendGrantFrontHistory.
  ///
  /// In en, this message translates to:
  /// **'Front history'**
  String get friendGrantFrontHistory;

  /// No description provided for @friendGrantGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get friendGrantGroups;

  /// No description provided for @friendGrantNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get friendGrantNotes;

  /// No description provided for @friendGrantPolls.
  ///
  /// In en, this message translates to:
  /// **'Polls'**
  String get friendGrantPolls;

  /// No description provided for @remindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersTitle;

  /// No description provided for @noRemindersYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No reminders yet'**
  String get noRemindersYetTitle;

  /// No description provided for @noRemindersYetBody.
  ///
  /// In en, this message translates to:
  /// **'Create a daily, weekly, or monthly notification reminder.'**
  String get noRemindersYetBody;

  /// No description provided for @addReminderButton.
  ///
  /// In en, this message translates to:
  /// **'Add reminder'**
  String get addReminderButton;

  /// No description provided for @notificationSettingsButton.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get notificationSettingsButton;

  /// No description provided for @onStatus.
  ///
  /// In en, this message translates to:
  /// **'on'**
  String get onStatus;

  /// No description provided for @reminderSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminder {title}'**
  String reminderSemanticLabel(String title);

  /// No description provided for @deleteReminderTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete reminder'**
  String get deleteReminderTooltip;

  /// No description provided for @deleteReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete reminder?'**
  String get deleteReminderTitle;

  /// No description provided for @deleteReminderBody.
  ///
  /// In en, this message translates to:
  /// **'This reminder will be permanently removed.'**
  String get deleteReminderBody;

  /// No description provided for @dailySchedule.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get dailySchedule;

  /// No description provided for @weeklySchedule.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weeklySchedule;

  /// No description provided for @monthlySchedule.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthlySchedule;

  /// No description provided for @afterFrontSchedule.
  ///
  /// In en, this message translates to:
  /// **'After member fronts'**
  String get afterFrontSchedule;

  /// No description provided for @titleFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleFieldLabel;

  /// No description provided for @scheduleFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get scheduleFieldLabel;

  /// No description provided for @dayFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get dayFieldLabel;

  /// No description provided for @dayOfMonthFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Day of month'**
  String get dayOfMonthFieldLabel;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @memberOrFrontLabel.
  ///
  /// In en, this message translates to:
  /// **'Member or front label'**
  String get memberOrFrontLabel;

  /// No description provided for @memberOrFrontHelper.
  ///
  /// In en, this message translates to:
  /// **'Queued until this member or label fronts'**
  String get memberOrFrontHelper;

  /// No description provided for @afterFrontTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Who should trigger it?'**
  String get afterFrontTargetLabel;

  /// No description provided for @afterFrontTargetHelper.
  ///
  /// In en, this message translates to:
  /// **'Choose one member, or trigger for any newly started front.'**
  String get afterFrontTargetHelper;

  /// No description provided for @anyFrontStartsOption.
  ///
  /// In en, this message translates to:
  /// **'Any front starts'**
  String get anyFrontStartsOption;

  /// No description provided for @timeFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeFieldLabel;

  /// No description provided for @timeFieldHelper.
  ///
  /// In en, this message translates to:
  /// **'24-hour local time, like 09:00'**
  String get timeFieldHelper;

  /// No description provided for @noteFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get noteFieldLabel;

  /// No description provided for @dailyScheduleAt.
  ///
  /// In en, this message translates to:
  /// **'Daily at {time}'**
  String dailyScheduleAt(String time);

  /// No description provided for @weeklyScheduleAt.
  ///
  /// In en, this message translates to:
  /// **'Weekly on {weekday} at {time}'**
  String weeklyScheduleAt(String weekday, String time);

  /// No description provided for @monthlyScheduleAt.
  ///
  /// In en, this message translates to:
  /// **'Monthly on day {day} at {time}'**
  String monthlyScheduleAt(int day, String time);

  /// No description provided for @afterSelectedFrontStarts.
  ///
  /// In en, this message translates to:
  /// **'After a selected front starts'**
  String get afterSelectedFrontStarts;

  /// No description provided for @afterFrontLabel.
  ///
  /// In en, this message translates to:
  /// **'After {detail} fronts'**
  String afterFrontLabel(String detail);

  /// No description provided for @importTitle.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importTitle;

  /// No description provided for @previewFirstStatus.
  ///
  /// In en, this message translates to:
  /// **'preview first'**
  String get previewFirstStatus;

  /// No description provided for @preparingImportPreviewStatus.
  ///
  /// In en, this message translates to:
  /// **'Preparing import preview...'**
  String get preparingImportPreviewStatus;

  /// No description provided for @importDescription.
  ///
  /// In en, this message translates to:
  /// **'Upload an export, check what was found, then import it into local storage.'**
  String get importDescription;

  /// No description provided for @exportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportTitle;

  /// No description provided for @exportLocalArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Export local archive'**
  String get exportLocalArchiveTitle;

  /// No description provided for @portableJsonValue.
  ///
  /// In en, this message translates to:
  /// **'portable JSON'**
  String get portableJsonValue;

  /// No description provided for @encryptedExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Encrypted export'**
  String get encryptedExportTitle;

  /// No description provided for @passwordProtectedFileValue.
  ///
  /// In en, this message translates to:
  /// **'password protected file'**
  String get passwordProtectedFileValue;

  /// No description provided for @backupFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup folder'**
  String get backupFolderTitle;

  /// No description provided for @manualArchiveSaveValue.
  ///
  /// In en, this message translates to:
  /// **'manual save from archive sheet'**
  String get manualArchiveSaveValue;

  /// No description provided for @waitingForFilePicker.
  ///
  /// In en, this message translates to:
  /// **'Waiting for file picker...'**
  String get waitingForFilePicker;

  /// No description provided for @chooseImportFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose import file'**
  String get chooseImportFileTitle;

  /// No description provided for @noFileSelected.
  ///
  /// In en, this message translates to:
  /// **'No file selected.'**
  String get noFileSelected;

  /// No description provided for @readingFileStatus.
  ///
  /// In en, this message translates to:
  /// **'Reading {fileName}...'**
  String readingFileStatus(String fileName);

  /// No description provided for @couldNotReadImportFile.
  ///
  /// In en, this message translates to:
  /// **'Could not read an import JSON from {fileName}.'**
  String couldNotReadImportFile(String fileName);

  /// No description provided for @couldNotOpenFilePicker.
  ///
  /// In en, this message translates to:
  /// **'Could not open the file picker.'**
  String get couldNotOpenFilePicker;

  /// No description provided for @importFileEmpty.
  ///
  /// In en, this message translates to:
  /// **'The selected import file is empty.'**
  String get importFileEmpty;

  /// No description provided for @importFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The import file is larger than the 32 MiB safety limit. If this is a legitimate export, report it so the limit can be reviewed.'**
  String get importFileTooLarge;

  /// No description provided for @oversizedImportWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Import a file over 32 MiB?'**
  String get oversizedImportWarningTitle;

  /// No description provided for @oversizedImportWarningBody.
  ///
  /// In en, this message translates to:
  /// **'This file is larger than the recommended safety limit. Very large imports can run slowly or run out of memory, especially on older or low-memory devices. A higher 200 MiB limit will apply for this import, and you\'ll need to choose the file again on the next screen.'**
  String get oversizedImportWarningBody;

  /// No description provided for @oversizedImportConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Import anyway'**
  String get oversizedImportConfirmButton;

  /// No description provided for @importFileInvalidUtf8.
  ///
  /// In en, this message translates to:
  /// **'The import file is not valid UTF-8 text.'**
  String get importFileInvalidUtf8;

  /// No description provided for @importFileInvalidZip.
  ///
  /// In en, this message translates to:
  /// **'The selected ZIP file is invalid or damaged.'**
  String get importFileInvalidZip;

  /// No description provided for @importZipTooManyEntries.
  ///
  /// In en, this message translates to:
  /// **'The ZIP contains too many entries to import safely. If this is a legitimate export, report it so the limit can be reviewed.'**
  String get importZipTooManyEntries;

  /// No description provided for @importZipExpansionTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The ZIP expands beyond the safe import limit. If this is a legitimate export, report it so the limit can be reviewed.'**
  String get importZipExpansionTooLarge;

  /// No description provided for @importZipUnsupported.
  ///
  /// In en, this message translates to:
  /// **'The ZIP contains no supported JSON or avatar files.'**
  String get importZipUnsupported;

  /// No description provided for @reportImportIssueButton.
  ///
  /// In en, this message translates to:
  /// **'Report import issue'**
  String get reportImportIssueButton;

  /// No description provided for @couldNotReadPastedJson.
  ///
  /// In en, this message translates to:
  /// **'Could not read the pasted JSON.'**
  String get couldNotReadPastedJson;

  /// No description provided for @exportJsonLabel.
  ///
  /// In en, this message translates to:
  /// **'Export JSON'**
  String get exportJsonLabel;

  /// No description provided for @pasteJsonSizeHelp.
  ///
  /// In en, this message translates to:
  /// **'Paste up to 256 KiB. Choose a file for larger exports.'**
  String get pasteJsonSizeHelp;

  /// No description provided for @previewPastedJson.
  ///
  /// In en, this message translates to:
  /// **'Preview pasted JSON'**
  String get previewPastedJson;

  /// No description provided for @waitingForAvatarZip.
  ///
  /// In en, this message translates to:
  /// **'Waiting for avatar ZIP...'**
  String get waitingForAvatarZip;

  /// No description provided for @chooseAvatarZipTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose avatar ZIP'**
  String get chooseAvatarZipTitle;

  /// No description provided for @noAvatarFileSelected.
  ///
  /// In en, this message translates to:
  /// **'No avatar file selected.'**
  String get noAvatarFileSelected;

  /// No description provided for @readingAvatarsStatus.
  ///
  /// In en, this message translates to:
  /// **'Reading avatars from {fileName}...'**
  String readingAvatarsStatus(String fileName);

  /// No description provided for @noAvatarsFoundStatus.
  ///
  /// In en, this message translates to:
  /// **'No avatar images found in {fileName}.'**
  String noAvatarsFoundStatus(String fileName);

  /// No description provided for @avatarsAttachedStatus.
  ///
  /// In en, this message translates to:
  /// **'Attached {count, plural, =1{1 avatar} other{{count} avatars}} from {fileName}. {nextStep}'**
  String avatarsAttachedStatus(int count, String fileName, String nextStep);

  /// No description provided for @chooseJsonNext.
  ///
  /// In en, this message translates to:
  /// **'Choose the JSON export next.'**
  String get chooseJsonNext;

  /// No description provided for @refreshOrImportNext.
  ///
  /// In en, this message translates to:
  /// **'Refresh or import when ready.'**
  String get refreshOrImportNext;

  /// No description provided for @encryptedArchiveLoaded.
  ///
  /// In en, this message translates to:
  /// **'Encrypted archive loaded. Enter its passphrase, then preview.'**
  String get encryptedArchiveLoaded;

  /// No description provided for @previewReadyStatus.
  ///
  /// In en, this message translates to:
  /// **'Preview ready: {summary}.'**
  String previewReadyStatus(String summary);

  /// No description provided for @chooseFileBeforePreview.
  ///
  /// In en, this message translates to:
  /// **'Choose or paste a file before previewing.'**
  String get chooseFileBeforePreview;

  /// No description provided for @decryptArchiveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not decrypt archive. Check the passphrase.'**
  String get decryptArchiveFailed;

  /// No description provided for @fetchingPluralKitData.
  ///
  /// In en, this message translates to:
  /// **'Fetching PluralKit data...'**
  String get fetchingPluralKitData;

  /// No description provided for @pluralKitImportFailed.
  ///
  /// In en, this message translates to:
  /// **'PluralKit import failed: {error}'**
  String pluralKitImportFailed(String error);

  /// No description provided for @pluralKitResponseTooLarge.
  ///
  /// In en, this message translates to:
  /// **'PluralKit returned too much data. Import stopped before loading it into memory.'**
  String get pluralKitResponseTooLarge;

  /// No description provided for @chooseFileBeforeRehearsal.
  ///
  /// In en, this message translates to:
  /// **'Choose or paste a file before rehearsing restore.'**
  String get chooseFileBeforeRehearsal;

  /// No description provided for @rehearsingRestoreStatus.
  ///
  /// In en, this message translates to:
  /// **'Rehearsing restore in a temporary local database...'**
  String get rehearsingRestoreStatus;

  /// No description provided for @restoreRehearsalPassedStatus.
  ///
  /// In en, this message translates to:
  /// **'Restore rehearsal passed: {summary}.'**
  String restoreRehearsalPassedStatus(String summary);

  /// No description provided for @restoreRehearsalFailedStatus.
  ///
  /// In en, this message translates to:
  /// **'Restore rehearsal failed. Nothing was imported.'**
  String get restoreRehearsalFailedStatus;

  /// No description provided for @preparingImportStatus.
  ///
  /// In en, this message translates to:
  /// **'Preparing {source} import...'**
  String preparingImportStatus(String source);

  /// No description provided for @writingImportStatus.
  ///
  /// In en, this message translates to:
  /// **'Writing {summary}...'**
  String writingImportStatus(String summary);

  /// No description provided for @importCancelledStatus.
  ///
  /// In en, this message translates to:
  /// **'Import cancelled.'**
  String get importCancelledStatus;

  /// No description provided for @importingStatus.
  ///
  /// In en, this message translates to:
  /// **'Importing {summary}...'**
  String importingStatus(String summary);

  /// No description provided for @importCompleteStatus.
  ///
  /// In en, this message translates to:
  /// **'Import complete: {summary}.'**
  String importCompleteStatus(String summary);

  /// No description provided for @importFailedJobsStatus.
  ///
  /// In en, this message translates to:
  /// **'Import failed. Check recent jobs below.'**
  String get importFailedJobsStatus;

  /// No description provided for @importFailedStatus.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String importFailedStatus(String error);

  /// No description provided for @sourceImportComplete.
  ///
  /// In en, this message translates to:
  /// **'{source} import complete'**
  String sourceImportComplete(String source);

  /// No description provided for @enterExportPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Enter the export passphrase first.'**
  String get enterExportPassphrase;

  /// No description provided for @importSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Import setup'**
  String get importSetupTitle;

  /// No description provided for @uploadFileButton.
  ///
  /// In en, this message translates to:
  /// **'Upload file'**
  String get uploadFileButton;

  /// No description provided for @chooseAnotherFileButton.
  ///
  /// In en, this message translates to:
  /// **'Choose another file'**
  String get chooseAnotherFileButton;

  /// No description provided for @pasteJsonTooltip.
  ///
  /// In en, this message translates to:
  /// **'Paste JSON'**
  String get pasteJsonTooltip;

  /// No description provided for @attachAvatarsButton.
  ///
  /// In en, this message translates to:
  /// **'Attach avatars'**
  String get attachAvatarsButton;

  /// No description provided for @avatarsAttachedButton.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 avatar attached} other{{count} avatars attached}}'**
  String avatarsAttachedButton(int count);

  /// No description provided for @serviceFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get serviceFieldLabel;

  /// No description provided for @matchStrategyFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'When a match exists'**
  String get matchStrategyFieldLabel;

  /// No description provided for @pluralKitTokenHelper.
  ///
  /// In en, this message translates to:
  /// **'Used for this fetch only. It is not saved or logged.'**
  String get pluralKitTokenHelper;

  /// No description provided for @passphraseFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Passphrase'**
  String get passphraseFieldLabel;

  /// No description provided for @importPassphraseHelper.
  ///
  /// In en, this message translates to:
  /// **'Used locally to decrypt the preview and import.'**
  String get importPassphraseHelper;

  /// No description provided for @retainRawImportPayloadsTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep original source collections'**
  String get retainRawImportPayloadsTitle;

  /// No description provided for @retainRawImportPayloadsDescription.
  ///
  /// In en, this message translates to:
  /// **'Keeps encrypted copies of unsupported source collections for future export or debugging. Leave off to import only mapped records.'**
  String get retainRawImportPayloadsDescription;

  /// No description provided for @inputLabel.
  ///
  /// In en, this message translates to:
  /// **'Input'**
  String get inputLabel;

  /// No description provided for @jobLabel.
  ///
  /// In en, this message translates to:
  /// **'Job'**
  String get jobLabel;

  /// No description provided for @dedupeLabel.
  ///
  /// In en, this message translates to:
  /// **'Dedupe'**
  String get dedupeLabel;

  /// No description provided for @previewImportButton.
  ///
  /// In en, this message translates to:
  /// **'Preview import'**
  String get previewImportButton;

  /// No description provided for @refreshPreviewButton.
  ///
  /// In en, this message translates to:
  /// **'Refresh preview'**
  String get refreshPreviewButton;

  /// No description provided for @chooseServiceStatus.
  ///
  /// In en, this message translates to:
  /// **'Choose service'**
  String get chooseServiceStatus;

  /// No description provided for @serviceDetectedStatus.
  ///
  /// In en, this message translates to:
  /// **'{service} detected'**
  String serviceDetectedStatus(String service);

  /// No description provided for @waitingForDetection.
  ///
  /// In en, this message translates to:
  /// **'waiting for detection'**
  String get waitingForDetection;

  /// No description provided for @importSourcePlurisHavenArchive.
  ///
  /// In en, this message translates to:
  /// **'Pluris Haven archive'**
  String get importSourcePlurisHavenArchive;

  /// No description provided for @importSourceSimplyPlural.
  ///
  /// In en, this message translates to:
  /// **'Simply Plural'**
  String get importSourceSimplyPlural;

  /// No description provided for @importSourcePluralKitFile.
  ///
  /// In en, this message translates to:
  /// **'PluralKit file'**
  String get importSourcePluralKitFile;

  /// No description provided for @importSourcePluralKitLive.
  ///
  /// In en, this message translates to:
  /// **'PluralKit live'**
  String get importSourcePluralKitLive;

  /// No description provided for @importSourceTupperbox.
  ///
  /// In en, this message translates to:
  /// **'Tupperbox'**
  String get importSourceTupperbox;

  /// No description provided for @importSourcePluralSpace.
  ///
  /// In en, this message translates to:
  /// **'PluralSpace'**
  String get importSourcePluralSpace;

  /// No description provided for @importSourcePrism.
  ///
  /// In en, this message translates to:
  /// **'Prism'**
  String get importSourcePrism;

  /// No description provided for @importSourceAmpersand.
  ///
  /// In en, this message translates to:
  /// **'Ampersand'**
  String get importSourceAmpersand;

  /// No description provided for @importInputFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get importInputFile;

  /// No description provided for @importInputLiveToken.
  ///
  /// In en, this message translates to:
  /// **'Live token'**
  String get importInputLiveToken;

  /// No description provided for @importInputEncryptedFile.
  ///
  /// In en, this message translates to:
  /// **'Encrypted file'**
  String get importInputEncryptedFile;

  /// No description provided for @importDedupePlurisHaven.
  ///
  /// In en, this message translates to:
  /// **'local IDs, PluralKit IDs, normalized names'**
  String get importDedupePlurisHaven;

  /// No description provided for @importDedupeSimplyPlural.
  ///
  /// In en, this message translates to:
  /// **'Simply Plural IDs, PluralKit IDs, normalized names'**
  String get importDedupeSimplyPlural;

  /// No description provided for @importDedupePluralKitFile.
  ///
  /// In en, this message translates to:
  /// **'PluralKit UUIDs, PluralKit short IDs, normalized names'**
  String get importDedupePluralKitFile;

  /// No description provided for @importDedupePluralKitLive.
  ///
  /// In en, this message translates to:
  /// **'PluralKit UUIDs, PluralKit short IDs'**
  String get importDedupePluralKitLive;

  /// No description provided for @importDedupeTupperbox.
  ///
  /// In en, this message translates to:
  /// **'Tupperbox IDs, normalized names'**
  String get importDedupeTupperbox;

  /// No description provided for @importDedupePluralSpace.
  ///
  /// In en, this message translates to:
  /// **'PluralSpace IDs, normalized names'**
  String get importDedupePluralSpace;

  /// No description provided for @importDedupePrism.
  ///
  /// In en, this message translates to:
  /// **'Prism IDs, normalized names'**
  String get importDedupePrism;

  /// No description provided for @importDedupeAmpersand.
  ///
  /// In en, this message translates to:
  /// **'Ampersand UUIDs, normalized names'**
  String get importDedupeAmpersand;

  /// No description provided for @importConflictPrompt.
  ///
  /// In en, this message translates to:
  /// **'Ask for each match'**
  String get importConflictPrompt;

  /// No description provided for @importConflictCreate.
  ///
  /// In en, this message translates to:
  /// **'Create new records'**
  String get importConflictCreate;

  /// No description provided for @importConflictSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip existing matches'**
  String get importConflictSkip;

  /// No description provided for @importConflictUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update existing matches'**
  String get importConflictUpdate;

  /// No description provided for @importPlanStatusReady.
  ///
  /// In en, this message translates to:
  /// **'ready'**
  String get importPlanStatusReady;

  /// No description provided for @importPlanStatusNext.
  ///
  /// In en, this message translates to:
  /// **'next'**
  String get importPlanStatusNext;

  /// No description provided for @importPlanStatusPlanned.
  ///
  /// In en, this message translates to:
  /// **'planned'**
  String get importPlanStatusPlanned;

  /// No description provided for @importPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'{source} plan'**
  String importPlanTitle(String source);

  /// No description provided for @importPlanOfflinePreview.
  ///
  /// In en, this message translates to:
  /// **'offline preview'**
  String get importPlanOfflinePreview;

  /// No description provided for @importPlanNeedsNetwork.
  ///
  /// In en, this message translates to:
  /// **'needs network'**
  String get importPlanNeedsNetwork;

  /// No description provided for @importReasonPrismExtension.
  ///
  /// In en, this message translates to:
  /// **'.prism file extension'**
  String get importReasonPrismExtension;

  /// No description provided for @importReasonPlurisFileName.
  ///
  /// In en, this message translates to:
  /// **'filename looks like a Pluris Haven archive'**
  String get importReasonPlurisFileName;

  /// No description provided for @importReasonSimplyPluralFileName.
  ///
  /// In en, this message translates to:
  /// **'filename looks like a Simply Plural export'**
  String get importReasonSimplyPluralFileName;

  /// No description provided for @importReasonPluralKitFileName.
  ///
  /// In en, this message translates to:
  /// **'filename looks like a PluralKit export'**
  String get importReasonPluralKitFileName;

  /// No description provided for @importReasonTupperboxFileName.
  ///
  /// In en, this message translates to:
  /// **'filename looks like a Tupperbox export'**
  String get importReasonTupperboxFileName;

  /// No description provided for @importReasonPluralSpaceFileName.
  ///
  /// In en, this message translates to:
  /// **'filename looks like a PluralSpace export'**
  String get importReasonPluralSpaceFileName;

  /// No description provided for @importReasonChooseAfterUpload.
  ///
  /// In en, this message translates to:
  /// **'pick a service after upload'**
  String get importReasonChooseAfterUpload;

  /// No description provided for @importReasonEncryptedPlurisArchive.
  ///
  /// In en, this message translates to:
  /// **'file is an encrypted Pluris Haven archive'**
  String get importReasonEncryptedPlurisArchive;

  /// No description provided for @importReasonLocalPlurisArchive.
  ///
  /// In en, this message translates to:
  /// **'file is a Pluris Haven local archive'**
  String get importReasonLocalPlurisArchive;

  /// No description provided for @importReasonTupperboxFields.
  ///
  /// In en, this message translates to:
  /// **'file contains Tupperbox-style roster fields'**
  String get importReasonTupperboxFields;

  /// No description provided for @importReasonPluralKitFields.
  ///
  /// In en, this message translates to:
  /// **'file contains PluralKit-style members and switches'**
  String get importReasonPluralKitFields;

  /// No description provided for @importReasonSimplyPluralFields.
  ///
  /// In en, this message translates to:
  /// **'file contains Simply Plural fronting fields'**
  String get importReasonSimplyPluralFields;

  /// No description provided for @importReasonPluralSpaceMarkers.
  ///
  /// In en, this message translates to:
  /// **'file contains PluralSpace markers'**
  String get importReasonPluralSpaceMarkers;

  /// No description provided for @importReasonAmbiguousMemberGroupJson.
  ///
  /// In en, this message translates to:
  /// **'member/group JSON found, choose the source to confirm'**
  String get importReasonAmbiguousMemberGroupJson;

  /// No description provided for @importReasonUnrecognised.
  ///
  /// In en, this message translates to:
  /// **'could not recognize this file yet'**
  String get importReasonUnrecognised;

  /// No description provided for @importCountMembers.
  ///
  /// In en, this message translates to:
  /// **'members'**
  String get importCountMembers;

  /// No description provided for @importCountGroups.
  ///
  /// In en, this message translates to:
  /// **'groups'**
  String get importCountGroups;

  /// No description provided for @importCountNotes.
  ///
  /// In en, this message translates to:
  /// **'notes'**
  String get importCountNotes;

  /// No description provided for @importCountJournals.
  ///
  /// In en, this message translates to:
  /// **'journals'**
  String get importCountJournals;

  /// No description provided for @importCountMessages.
  ///
  /// In en, this message translates to:
  /// **'messages'**
  String get importCountMessages;

  /// No description provided for @importCountReminders.
  ///
  /// In en, this message translates to:
  /// **'reminders'**
  String get importCountReminders;

  /// No description provided for @importCountTags.
  ///
  /// In en, this message translates to:
  /// **'tags'**
  String get importCountTags;

  /// No description provided for @importCountCustomFields.
  ///
  /// In en, this message translates to:
  /// **'custom fields'**
  String get importCountCustomFields;

  /// No description provided for @importCountPolls.
  ///
  /// In en, this message translates to:
  /// **'polls'**
  String get importCountPolls;

  /// No description provided for @importCountFrontHistory.
  ///
  /// In en, this message translates to:
  /// **'front history'**
  String get importCountFrontHistory;

  /// No description provided for @importCountNotifications.
  ///
  /// In en, this message translates to:
  /// **'notifications'**
  String get importCountNotifications;

  /// No description provided for @importCountPreferences.
  ///
  /// In en, this message translates to:
  /// **'preferences'**
  String get importCountPreferences;

  /// No description provided for @importCountCustomFronts.
  ///
  /// In en, this message translates to:
  /// **'custom fronts'**
  String get importCountCustomFronts;

  /// No description provided for @importCountSwitches.
  ///
  /// In en, this message translates to:
  /// **'switches'**
  String get importCountSwitches;

  /// No description provided for @importCountFrontIntervals.
  ///
  /// In en, this message translates to:
  /// **'front intervals'**
  String get importCountFrontIntervals;

  /// No description provided for @importCountTuppers.
  ///
  /// In en, this message translates to:
  /// **'tuppers'**
  String get importCountTuppers;

  /// No description provided for @importCountAvatars.
  ///
  /// In en, this message translates to:
  /// **'avatars'**
  String get importCountAvatars;

  /// No description provided for @importCountFronts.
  ///
  /// In en, this message translates to:
  /// **'fronts'**
  String get importCountFronts;

  /// No description provided for @importCountGroupMembers.
  ///
  /// In en, this message translates to:
  /// **'group memberships'**
  String get importCountGroupMembers;

  /// No description provided for @importCountCustomFieldValues.
  ///
  /// In en, this message translates to:
  /// **'custom field values'**
  String get importCountCustomFieldValues;

  /// No description provided for @importCountChatCategories.
  ///
  /// In en, this message translates to:
  /// **'chat categories'**
  String get importCountChatCategories;

  /// No description provided for @importCountChatChannels.
  ///
  /// In en, this message translates to:
  /// **'chat channels'**
  String get importCountChatChannels;

  /// No description provided for @importCountMemberTags.
  ///
  /// In en, this message translates to:
  /// **'member tags'**
  String get importCountMemberTags;

  /// No description provided for @importCountContentRevisions.
  ///
  /// In en, this message translates to:
  /// **'content revisions'**
  String get importCountContentRevisions;

  /// No description provided for @importCountPollOptions.
  ///
  /// In en, this message translates to:
  /// **'poll options'**
  String get importCountPollOptions;

  /// No description provided for @importCountPollVotes.
  ///
  /// In en, this message translates to:
  /// **'poll votes'**
  String get importCountPollVotes;

  /// No description provided for @importCountPollVoteEvents.
  ///
  /// In en, this message translates to:
  /// **'poll vote events'**
  String get importCountPollVoteEvents;

  /// No description provided for @importCountFrontMembers.
  ///
  /// In en, this message translates to:
  /// **'front memberships'**
  String get importCountFrontMembers;

  /// No description provided for @importCountFrontAuditEvents.
  ///
  /// In en, this message translates to:
  /// **'front audit events'**
  String get importCountFrontAuditEvents;

  /// No description provided for @importCountNamedFrontMembers.
  ///
  /// In en, this message translates to:
  /// **'saved-front memberships'**
  String get importCountNamedFrontMembers;

  /// No description provided for @importCountPrivacyBuckets.
  ///
  /// In en, this message translates to:
  /// **'privacy buckets'**
  String get importCountPrivacyBuckets;

  /// No description provided for @importCountPrivacyBucketMembers.
  ///
  /// In en, this message translates to:
  /// **'privacy-bucket memberships'**
  String get importCountPrivacyBucketMembers;

  /// No description provided for @importCountAvatarReferences.
  ///
  /// In en, this message translates to:
  /// **'avatar references'**
  String get importCountAvatarReferences;

  /// No description provided for @importCountAvatarAssets.
  ///
  /// In en, this message translates to:
  /// **'avatar files'**
  String get importCountAvatarAssets;

  /// No description provided for @importCountImportRecords.
  ///
  /// In en, this message translates to:
  /// **'import records'**
  String get importCountImportRecords;

  /// No description provided for @importCountPreservedSourceCollections.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{preserved source collection} other{preserved source collections}}'**
  String importCountPreservedSourceCollections(int count);

  /// No description provided for @importCountNotificationEvents.
  ///
  /// In en, this message translates to:
  /// **'notification events'**
  String get importCountNotificationEvents;

  /// No description provided for @importCountOther.
  ///
  /// In en, this message translates to:
  /// **'{name}'**
  String importCountOther(String name);

  /// No description provided for @importCountPill.
  ///
  /// In en, this message translates to:
  /// **'{label}: {count}'**
  String importCountPill(String label, int count);

  /// No description provided for @importStepReadArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Read archive'**
  String get importStepReadArchiveTitle;

  /// No description provided for @importStepReadPlurisArchiveDetail.
  ///
  /// In en, this message translates to:
  /// **'Accept a Pluris Haven local archive JSON export.'**
  String get importStepReadPlurisArchiveDetail;

  /// No description provided for @importStepValidateFormatTitle.
  ///
  /// In en, this message translates to:
  /// **'Validate format'**
  String get importStepValidateFormatTitle;

  /// No description provided for @importStepValidatePlurisArchiveDetail.
  ///
  /// In en, this message translates to:
  /// **'Require format pluris_haven.local_archive and a supported version.'**
  String get importStepValidatePlurisArchiveDetail;

  /// No description provided for @importStepReviewContentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Review contents'**
  String get importStepReviewContentsTitle;

  /// No description provided for @importStepReviewPlurisArchiveDetail.
  ///
  /// In en, this message translates to:
  /// **'Show local members, groups, journals, notes, fronts, tags, polls, and preferences before writing.'**
  String get importStepReviewPlurisArchiveDetail;

  /// No description provided for @importStepRestoreLocallyTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore locally'**
  String get importStepRestoreLocallyTitle;

  /// No description provided for @importStepRestorePlurisArchiveDetail.
  ///
  /// In en, this message translates to:
  /// **'Apply selected records and keep an import record for future dedupe.'**
  String get importStepRestorePlurisArchiveDetail;

  /// No description provided for @importStepReadExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Read export'**
  String get importStepReadExportTitle;

  /// No description provided for @importStepReadSimplyPluralDetail.
  ///
  /// In en, this message translates to:
  /// **'Accept a Simply Plural JSON export or backup archive.'**
  String get importStepReadSimplyPluralDetail;

  /// No description provided for @importStepNormalizeFieldsTitle.
  ///
  /// In en, this message translates to:
  /// **'Normalize fields'**
  String get importStepNormalizeFieldsTitle;

  /// No description provided for @importStepNormalizeSimplyPluralDetail.
  ///
  /// In en, this message translates to:
  /// **'Map members, groups, custom fields, custom fronts, and notes into local records.'**
  String get importStepNormalizeSimplyPluralDetail;

  /// No description provided for @importStepPrepareAvatarsTitle.
  ///
  /// In en, this message translates to:
  /// **'Prepare avatars'**
  String get importStepPrepareAvatarsTitle;

  /// No description provided for @importStepPrepareSimplyPluralAvatarsDetail.
  ///
  /// In en, this message translates to:
  /// **'Use attached avatar ZIP bytes first, then keep or localize remote avatar URLs during import.'**
  String get importStepPrepareSimplyPluralAvatarsDetail;

  /// No description provided for @importStepReviewMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Review matches'**
  String get importStepReviewMatchesTitle;

  /// No description provided for @importStepReviewSimplyPluralDetail.
  ///
  /// In en, this message translates to:
  /// **'Show creates, skips, and updates before writing.'**
  String get importStepReviewSimplyPluralDetail;

  /// No description provided for @importStepWriteLocallyTitle.
  ///
  /// In en, this message translates to:
  /// **'Write locally'**
  String get importStepWriteLocallyTitle;

  /// No description provided for @importStepWriteSimplyPluralDetail.
  ///
  /// In en, this message translates to:
  /// **'Save records and keep an import record for future dedupe.'**
  String get importStepWriteSimplyPluralDetail;

  /// No description provided for @importStepReadPluralKitFileDetail.
  ///
  /// In en, this message translates to:
  /// **'Accept a PluralKit JSON export file.'**
  String get importStepReadPluralKitFileDetail;

  /// No description provided for @importStepBuildRosterTitle.
  ///
  /// In en, this message translates to:
  /// **'Build roster'**
  String get importStepBuildRosterTitle;

  /// No description provided for @importStepBuildPluralKitRosterDetail.
  ///
  /// In en, this message translates to:
  /// **'Stage members, groups, avatars, descriptions, and proxy metadata.'**
  String get importStepBuildPluralKitRosterDetail;

  /// No description provided for @importStepConvertSwitchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Convert switches'**
  String get importStepConvertSwitchesTitle;

  /// No description provided for @importStepConvertPluralKitSwitchesDetail.
  ///
  /// In en, this message translates to:
  /// **'Turn PK switches into local front history.'**
  String get importStepConvertPluralKitSwitchesDetail;

  /// No description provided for @importStepReviewPluralKitFileDetail.
  ///
  /// In en, this message translates to:
  /// **'Dedupe by PK UUID, short ID, then normalized name.'**
  String get importStepReviewPluralKitFileDetail;

  /// No description provided for @importStepValidateTokenTitle.
  ///
  /// In en, this message translates to:
  /// **'Validate token'**
  String get importStepValidateTokenTitle;

  /// No description provided for @importStepValidatePluralKitTokenDetail.
  ///
  /// In en, this message translates to:
  /// **'Call GET /systems/@me with the token as Authorization.'**
  String get importStepValidatePluralKitTokenDetail;

  /// No description provided for @importStepFetchRosterTitle.
  ///
  /// In en, this message translates to:
  /// **'Fetch roster'**
  String get importStepFetchRosterTitle;

  /// No description provided for @importStepFetchPluralKitRosterDetail.
  ///
  /// In en, this message translates to:
  /// **'Read members and groups from the PluralKit API.'**
  String get importStepFetchPluralKitRosterDetail;

  /// No description provided for @importStepFetchSwitchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Fetch switches'**
  String get importStepFetchSwitchesTitle;

  /// No description provided for @importStepFetchPluralKitSwitchesDetail.
  ///
  /// In en, this message translates to:
  /// **'Page switches with a delay to avoid rate limits.'**
  String get importStepFetchPluralKitSwitchesDetail;

  /// No description provided for @importStepReviewPluralKitLiveDetail.
  ///
  /// In en, this message translates to:
  /// **'Dedupe by PK UUID and short ID before saving.'**
  String get importStepReviewPluralKitLiveDetail;

  /// No description provided for @importStepReadRosterTitle.
  ///
  /// In en, this message translates to:
  /// **'Read roster'**
  String get importStepReadRosterTitle;

  /// No description provided for @importStepReadTupperboxDetail.
  ///
  /// In en, this message translates to:
  /// **'Accept a Tupperbox export file.'**
  String get importStepReadTupperboxDetail;

  /// No description provided for @importStepMapTuppersTitle.
  ///
  /// In en, this message translates to:
  /// **'Map tuppers'**
  String get importStepMapTuppersTitle;

  /// No description provided for @importStepMapTupperboxDetail.
  ///
  /// In en, this message translates to:
  /// **'Convert tuppers to members with names, avatars, brackets, and descriptions.'**
  String get importStepMapTupperboxDetail;

  /// No description provided for @importStepReviewTupperboxDetail.
  ///
  /// In en, this message translates to:
  /// **'Dedupe by Tupperbox ID, then normalized name.'**
  String get importStepReviewTupperboxDetail;

  /// No description provided for @importStepReadPluralSpaceDetail.
  ///
  /// In en, this message translates to:
  /// **'Accept a PluralSpace export file.'**
  String get importStepReadPluralSpaceDetail;

  /// No description provided for @importStepMapRecordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Map records'**
  String get importStepMapRecordsTitle;

  /// No description provided for @importStepMapPluralSpaceDetail.
  ///
  /// In en, this message translates to:
  /// **'Stage members, groups, notes, and fronting data when present.'**
  String get importStepMapPluralSpaceDetail;

  /// No description provided for @importStepReviewPluralSpaceDetail.
  ///
  /// In en, this message translates to:
  /// **'Dedupe by source ID, then normalized name.'**
  String get importStepReviewPluralSpaceDetail;

  /// No description provided for @importStepChoosePrismTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose .prism file'**
  String get importStepChoosePrismTitle;

  /// No description provided for @importStepChoosePrismDetail.
  ///
  /// In en, this message translates to:
  /// **'Accept an encrypted Prism export.'**
  String get importStepChoosePrismDetail;

  /// No description provided for @importStepDecryptPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Decrypt preview'**
  String get importStepDecryptPreviewTitle;

  /// No description provided for @importStepDecryptPrismDetail.
  ///
  /// In en, this message translates to:
  /// **'Use the passphrase locally and avoid storing it.'**
  String get importStepDecryptPrismDetail;

  /// No description provided for @importStepReviewPrismDetail.
  ///
  /// In en, this message translates to:
  /// **'Dedupe by Prism ID, then normalized name.'**
  String get importStepReviewPrismDetail;

  /// No description provided for @importStepReadAmpersandDetail.
  ///
  /// In en, this message translates to:
  /// **'Accept an Ampersand JSON database export.'**
  String get importStepReadAmpersandDetail;

  /// No description provided for @importStepMapAmpersandDetail.
  ///
  /// In en, this message translates to:
  /// **'Stage members, custom fields, fronting history, journals, and notes.'**
  String get importStepMapAmpersandDetail;

  /// No description provided for @importStepReviewAmpersandDetail.
  ///
  /// In en, this message translates to:
  /// **'Dedupe by Ampersand UUID, then normalized name.'**
  String get importStepReviewAmpersandDetail;

  /// No description provided for @importPrivacyPreviewBeforeWrite.
  ///
  /// In en, this message translates to:
  /// **'Preview happens before records are saved.'**
  String get importPrivacyPreviewBeforeWrite;

  /// No description provided for @importPrivacyLocalBackupRestore.
  ///
  /// In en, this message translates to:
  /// **'This is the backup and restore path for local data.'**
  String get importPrivacyLocalBackupRestore;

  /// No description provided for @importPrivacySimplyPluralDedupe.
  ///
  /// In en, this message translates to:
  /// **'Re-imports match by Simply Plural ID, PluralKit ID, then normalized name.'**
  String get importPrivacySimplyPluralDedupe;

  /// No description provided for @importPrivacySimplyPluralAvatars.
  ///
  /// In en, this message translates to:
  /// **'Avatar ZIPs stay offline. Remote avatar URLs may be fetched during import so they can be stored locally.'**
  String get importPrivacySimplyPluralAvatars;

  /// No description provided for @importPrivacyPluralKitIdentifiers.
  ///
  /// In en, this message translates to:
  /// **'PluralKit IDs are kept as import identifiers for dedupe and optional sync.'**
  String get importPrivacyPluralKitIdentifiers;

  /// No description provided for @importPrivacyPluralKitSwitches.
  ///
  /// In en, this message translates to:
  /// **'Switch logs become local front history intervals.'**
  String get importPrivacyPluralKitSwitches;

  /// No description provided for @importPrivacyPluralKitTokenEphemeral.
  ///
  /// In en, this message translates to:
  /// **'The pk;token is used for the import request only.'**
  String get importPrivacyPluralKitTokenEphemeral;

  /// No description provided for @importPrivacyPluralKitLiveNetwork.
  ///
  /// In en, this message translates to:
  /// **'Live import needs network access, but the preview and write still happen locally.'**
  String get importPrivacyPluralKitLiveNetwork;

  /// No description provided for @importPrivacyTupperboxIdentifiers.
  ///
  /// In en, this message translates to:
  /// **'Tupperbox IDs are retained only for dedupe and future re-imports.'**
  String get importPrivacyTupperboxIdentifiers;

  /// No description provided for @importPrivacyTupperboxProxyMetadata.
  ///
  /// In en, this message translates to:
  /// **'Proxy patterns can be imported later as optional metadata.'**
  String get importPrivacyTupperboxProxyMetadata;

  /// No description provided for @importPrivacyPluralSpaceIdentifiers.
  ///
  /// In en, this message translates to:
  /// **'PluralSpace source IDs are kept as import identifiers.'**
  String get importPrivacyPluralSpaceIdentifiers;

  /// No description provided for @importPrivacyPluralSpaceUnknownFields.
  ///
  /// In en, this message translates to:
  /// **'Unknown fields are kept in the preview until a mapper exists.'**
  String get importPrivacyPluralSpaceUnknownFields;

  /// No description provided for @importPrivacyPrismPassphraseMemoryOnly.
  ///
  /// In en, this message translates to:
  /// **'The passphrase is only used to decrypt the import in memory.'**
  String get importPrivacyPrismPassphraseMemoryOnly;

  /// No description provided for @importPrivacyPrismIdentifiers.
  ///
  /// In en, this message translates to:
  /// **'Prism source IDs are kept for re-import dedupe.'**
  String get importPrivacyPrismIdentifiers;

  /// No description provided for @importPrivacyAmpersandIdentifiers.
  ///
  /// In en, this message translates to:
  /// **'Ampersand UUIDs are kept as import identifiers.'**
  String get importPrivacyAmpersandIdentifiers;

  /// No description provided for @importPrivacyAmpersandCustomFields.
  ///
  /// In en, this message translates to:
  /// **'Custom field values are imported as plain text.'**
  String get importPrivacyAmpersandCustomFields;

  /// No description provided for @importStageParse.
  ///
  /// In en, this message translates to:
  /// **'parse'**
  String get importStageParse;

  /// No description provided for @importStageDecrypt.
  ///
  /// In en, this message translates to:
  /// **'decrypt'**
  String get importStageDecrypt;

  /// No description provided for @importStageValidate.
  ///
  /// In en, this message translates to:
  /// **'validate'**
  String get importStageValidate;

  /// No description provided for @importStagePreview.
  ///
  /// In en, this message translates to:
  /// **'preview'**
  String get importStagePreview;

  /// No description provided for @importStageNormalize.
  ///
  /// In en, this message translates to:
  /// **'normalize'**
  String get importStageNormalize;

  /// No description provided for @importStagePreserve.
  ///
  /// In en, this message translates to:
  /// **'preserve'**
  String get importStagePreserve;

  /// No description provided for @importStageAvatars.
  ///
  /// In en, this message translates to:
  /// **'avatars'**
  String get importStageAvatars;

  /// No description provided for @importDiagnosticJsonParseFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not parse JSON: {error}'**
  String importDiagnosticJsonParseFailed(String error);

  /// No description provided for @importDiagnosticExpectedTopLevelObject.
  ///
  /// In en, this message translates to:
  /// **'Expected a JSON object at the top level.'**
  String get importDiagnosticExpectedTopLevelObject;

  /// No description provided for @importDiagnosticPrismNeedsDecryption.
  ///
  /// In en, this message translates to:
  /// **'Prism preview needs encrypted file decryption first.'**
  String get importDiagnosticPrismNeedsDecryption;

  /// No description provided for @importDiagnosticNotPlurisArchive.
  ///
  /// In en, this message translates to:
  /// **'This is not a Pluris Haven local archive.'**
  String get importDiagnosticNotPlurisArchive;

  /// No description provided for @importDiagnosticUnsupportedArchiveVersion.
  ///
  /// In en, this message translates to:
  /// **'Unsupported archive version: {version}.'**
  String importDiagnosticUnsupportedArchiveVersion(String version);

  /// No description provided for @importDiagnosticFoundMembersAndFronts.
  ///
  /// In en, this message translates to:
  /// **'Found {members} members and {fronts} fronts.'**
  String importDiagnosticFoundMembersAndFronts(int members, int fronts);

  /// No description provided for @importDiagnosticRecognizedRecords.
  ///
  /// In en, this message translates to:
  /// **'Recognized records can be imported into the local archive.'**
  String get importDiagnosticRecognizedRecords;

  /// No description provided for @importDiagnosticNoImportableRecords.
  ///
  /// In en, this message translates to:
  /// **'No importable records were recognized.'**
  String get importDiagnosticNoImportableRecords;

  /// No description provided for @importDiagnosticPreservedRawPayloads.
  ///
  /// In en, this message translates to:
  /// **'Preserved {count, plural, =1{1 original source collection} other{{count} original source collections}} as raw payloads for export/debug{collections}. Mapped records still import normally; raw copies do not create notes, messages, or members.'**
  String importDiagnosticPreservedRawPayloads(int count, String collections);

  /// No description provided for @importDiagnosticCollectionNames.
  ///
  /// In en, this message translates to:
  /// **': {names}'**
  String importDiagnosticCollectionNames(String names);

  /// No description provided for @importDiagnosticCollectionNamesWithMore.
  ///
  /// In en, this message translates to:
  /// **': {names}, +{count} more'**
  String importDiagnosticCollectionNamesWithMore(String names, int count);

  /// No description provided for @importDiagnosticRemoteAvatarsWithoutZip.
  ///
  /// In en, this message translates to:
  /// **'Avatar links may be downloaded during import so they can be kept locally. Attach the Simply Plural avatar ZIP to avoid remote avatar fetches.'**
  String get importDiagnosticRemoteAvatarsWithoutZip;

  /// No description provided for @importDiagnosticBestEffort.
  ///
  /// In en, this message translates to:
  /// **'{source} import is best-effort. Review after import.'**
  String importDiagnosticBestEffort(String source);

  /// No description provided for @importDiagnosticSkippedExpectedObject.
  ///
  /// In en, this message translates to:
  /// **'Skipped {record} #{index}: expected an object.'**
  String importDiagnosticSkippedExpectedObject(String record, int index);

  /// No description provided for @importDiagnosticSkippedMissingFields.
  ///
  /// In en, this message translates to:
  /// **'Skipped {record} #{index}: missing {fields}.'**
  String importDiagnosticSkippedMissingFields(
    String record,
    int index,
    String fields,
  );

  /// No description provided for @importDiagnosticIgnoredMissingRelation.
  ///
  /// In en, this message translates to:
  /// **'{ownerKind} \"{owner}\" kept; missing {relationKind} \"{relation}\" link was dropped.'**
  String importDiagnosticIgnoredMissingRelation(
    String ownerKind,
    String owner,
    String relationKind,
    String relation,
  );

  /// No description provided for @importDiagnosticIgnoredSelfParent.
  ///
  /// In en, this message translates to:
  /// **'Group \"{group}\" ignored itself as its parent.'**
  String importDiagnosticIgnoredSelfParent(String group);

  /// No description provided for @importDiagnosticReminderMissingMember.
  ///
  /// In en, this message translates to:
  /// **'Reminder #{index} references a member that was not imported; the reminder was disabled.'**
  String importDiagnosticReminderMissingMember(int index);

  /// No description provided for @importDiagnosticPollTooFewOptions.
  ///
  /// In en, this message translates to:
  /// **'Skipped poll \"{question}\": fewer than two usable options.'**
  String importDiagnosticPollTooFewOptions(String question);

  /// No description provided for @importDiagnosticIgnoredMissingReference.
  ///
  /// In en, this message translates to:
  /// **'Ignored missing {relation} reference \"{value}\" in {record}.'**
  String importDiagnosticIgnoredMissingReference(
    String record,
    String relation,
    String value,
  );

  /// No description provided for @importDiagnosticNamedRecord.
  ///
  /// In en, this message translates to:
  /// **'{kind} \"{name}\"'**
  String importDiagnosticNamedRecord(String kind, String name);

  /// No description provided for @importTermMember.
  ///
  /// In en, this message translates to:
  /// **'member'**
  String get importTermMember;

  /// No description provided for @importTermMemberSentenceStart.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get importTermMemberSentenceStart;

  /// No description provided for @importTermPrivacyBucket.
  ///
  /// In en, this message translates to:
  /// **'privacy bucket'**
  String get importTermPrivacyBucket;

  /// No description provided for @importTermIdOrName.
  ///
  /// In en, this message translates to:
  /// **'ID or name'**
  String get importTermIdOrName;

  /// No description provided for @importTermName.
  ///
  /// In en, this message translates to:
  /// **'name'**
  String get importTermName;

  /// No description provided for @importTermGroup.
  ///
  /// In en, this message translates to:
  /// **'group'**
  String get importTermGroup;

  /// No description provided for @importTermGroupSentenceStart.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get importTermGroupSentenceStart;

  /// No description provided for @importTermCustomFront.
  ///
  /// In en, this message translates to:
  /// **'custom front'**
  String get importTermCustomFront;

  /// No description provided for @importTermLabel.
  ///
  /// In en, this message translates to:
  /// **'label'**
  String get importTermLabel;

  /// No description provided for @importTermCustomField.
  ///
  /// In en, this message translates to:
  /// **'custom field'**
  String get importTermCustomField;

  /// No description provided for @importTermCustomFieldValue.
  ///
  /// In en, this message translates to:
  /// **'custom field value'**
  String get importTermCustomFieldValue;

  /// No description provided for @importTermNote.
  ///
  /// In en, this message translates to:
  /// **'note'**
  String get importTermNote;

  /// No description provided for @importTermTitleAndBody.
  ///
  /// In en, this message translates to:
  /// **'title and body'**
  String get importTermTitleAndBody;

  /// No description provided for @importTermJournal.
  ///
  /// In en, this message translates to:
  /// **'journal'**
  String get importTermJournal;

  /// No description provided for @importTermChatChannel.
  ///
  /// In en, this message translates to:
  /// **'chat channel'**
  String get importTermChatChannel;

  /// No description provided for @importTermChatCategory.
  ///
  /// In en, this message translates to:
  /// **'chat category'**
  String get importTermChatCategory;

  /// No description provided for @importTermMessage.
  ///
  /// In en, this message translates to:
  /// **'message'**
  String get importTermMessage;

  /// No description provided for @importTermBody.
  ///
  /// In en, this message translates to:
  /// **'body'**
  String get importTermBody;

  /// No description provided for @importTermReminder.
  ///
  /// In en, this message translates to:
  /// **'reminder'**
  String get importTermReminder;

  /// No description provided for @importTermTitleOrSchedule.
  ///
  /// In en, this message translates to:
  /// **'title or schedule'**
  String get importTermTitleOrSchedule;

  /// No description provided for @importTermPoll.
  ///
  /// In en, this message translates to:
  /// **'poll'**
  String get importTermPoll;

  /// No description provided for @importTermQuestion.
  ///
  /// In en, this message translates to:
  /// **'question'**
  String get importTermQuestion;

  /// No description provided for @importTermFront.
  ///
  /// In en, this message translates to:
  /// **'front'**
  String get importTermFront;

  /// No description provided for @importTermFrontSentenceStart.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get importTermFrontSentenceStart;

  /// No description provided for @importTermStartTime.
  ///
  /// In en, this message translates to:
  /// **'start time'**
  String get importTermStartTime;

  /// No description provided for @importTermMemberIdsOrCustomLabel.
  ///
  /// In en, this message translates to:
  /// **'member IDs or custom label'**
  String get importTermMemberIdsOrCustomLabel;

  /// No description provided for @importTermImportedRecord.
  ///
  /// In en, this message translates to:
  /// **'the imported record'**
  String get importTermImportedRecord;

  /// No description provided for @importTermParent.
  ///
  /// In en, this message translates to:
  /// **'parent'**
  String get importTermParent;

  /// No description provided for @importTermSystemName.
  ///
  /// In en, this message translates to:
  /// **'system name'**
  String get importTermSystemName;

  /// No description provided for @importTermMemberName.
  ///
  /// In en, this message translates to:
  /// **'member name'**
  String get importTermMemberName;

  /// No description provided for @importTermMemberPronouns.
  ///
  /// In en, this message translates to:
  /// **'member pronouns'**
  String get importTermMemberPronouns;

  /// No description provided for @importTermMemberBirthday.
  ///
  /// In en, this message translates to:
  /// **'member birthday'**
  String get importTermMemberBirthday;

  /// No description provided for @importTermMemberEmoji.
  ///
  /// In en, this message translates to:
  /// **'member emoji'**
  String get importTermMemberEmoji;

  /// No description provided for @importTermMemberDescription.
  ///
  /// In en, this message translates to:
  /// **'member description'**
  String get importTermMemberDescription;

  /// No description provided for @importTermAvatarUrl.
  ///
  /// In en, this message translates to:
  /// **'avatar URL'**
  String get importTermAvatarUrl;

  /// No description provided for @importTermGroupName.
  ///
  /// In en, this message translates to:
  /// **'group name'**
  String get importTermGroupName;

  /// No description provided for @importTermCustomFieldName.
  ///
  /// In en, this message translates to:
  /// **'custom field name'**
  String get importTermCustomFieldName;

  /// No description provided for @importTermContentTitle.
  ///
  /// In en, this message translates to:
  /// **'content title'**
  String get importTermContentTitle;

  /// No description provided for @importTermLongTextField.
  ///
  /// In en, this message translates to:
  /// **'long text field'**
  String get importTermLongTextField;

  /// No description provided for @importTermJournalBody.
  ///
  /// In en, this message translates to:
  /// **'journal body'**
  String get importTermJournalBody;

  /// No description provided for @importTermMessageBody.
  ///
  /// In en, this message translates to:
  /// **'message body'**
  String get importTermMessageBody;

  /// No description provided for @importTermReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'reminder title'**
  String get importTermReminderTitle;

  /// No description provided for @importTermReminderBody.
  ///
  /// In en, this message translates to:
  /// **'reminder body'**
  String get importTermReminderBody;

  /// No description provided for @importTermReminderSchedule.
  ///
  /// In en, this message translates to:
  /// **'reminder schedule'**
  String get importTermReminderSchedule;

  /// No description provided for @importTermPollQuestion.
  ///
  /// In en, this message translates to:
  /// **'poll question'**
  String get importTermPollQuestion;

  /// No description provided for @importTermPollDescription.
  ///
  /// In en, this message translates to:
  /// **'poll description'**
  String get importTermPollDescription;

  /// No description provided for @importTermPollOption.
  ///
  /// In en, this message translates to:
  /// **'poll option'**
  String get importTermPollOption;

  /// No description provided for @importTermPollOptionList.
  ///
  /// In en, this message translates to:
  /// **'poll option list'**
  String get importTermPollOptionList;

  /// No description provided for @importTermFrontStatusNote.
  ///
  /// In en, this message translates to:
  /// **'front status note'**
  String get importTermFrontStatusNote;

  /// No description provided for @importDiagnosticFrontReversed.
  ///
  /// In en, this message translates to:
  /// **'Front #{index} ended before it started; swapped start and end.'**
  String importDiagnosticFrontReversed(int index);

  /// No description provided for @importDiagnosticStringClamped.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 {field} will be shortened} other{{count} {field}s will be shortened}} to {limit} characters.'**
  String importDiagnosticStringClamped(int count, String field, int limit);

  /// No description provided for @importDiagnosticListClamped.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 {field} will be trimmed} other{{count} {field}s will be trimmed}} to {limit} entries.'**
  String importDiagnosticListClamped(int count, String field, int limit);

  /// No description provided for @previewTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get previewTitle;

  /// No description provided for @validShapeStatus.
  ///
  /// In en, this message translates to:
  /// **'valid shape'**
  String get validShapeStatus;

  /// No description provided for @needsAttentionStatus.
  ///
  /// In en, this message translates to:
  /// **'needs attention'**
  String get needsAttentionStatus;

  /// No description provided for @noRecordsFound.
  ///
  /// In en, this message translates to:
  /// **'no records found'**
  String get noRecordsFound;

  /// No description provided for @rehearsingButton.
  ///
  /// In en, this message translates to:
  /// **'Rehearsing...'**
  String get rehearsingButton;

  /// No description provided for @runRestoreRehearsalButton.
  ///
  /// In en, this message translates to:
  /// **'Run restore rehearsal'**
  String get runRestoreRehearsalButton;

  /// No description provided for @importingButton.
  ///
  /// In en, this message translates to:
  /// **'Importing...'**
  String get importingButton;

  /// No description provided for @importArchiveButton.
  ///
  /// In en, this message translates to:
  /// **'Import archive'**
  String get importArchiveButton;

  /// No description provided for @restoreRehearsalPassed.
  ///
  /// In en, this message translates to:
  /// **'Restore rehearsal passed'**
  String get restoreRehearsalPassed;

  /// No description provided for @restoreRehearsalFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore rehearsal failed'**
  String get restoreRehearsalFailed;

  /// No description provided for @restoreRehearsalPassedBody.
  ///
  /// In en, this message translates to:
  /// **'Imported into a temporary local database. Nothing was written to your app data.'**
  String get restoreRehearsalPassedBody;

  /// No description provided for @restoreRehearsalFailedBody.
  ///
  /// In en, this message translates to:
  /// **'The archive could not be restored safely.'**
  String get restoreRehearsalFailedBody;

  /// No description provided for @restoreStatusSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Restore status: {title}. {body}{counts}'**
  String restoreStatusSemanticLabel(String title, String body, String counts);

  /// No description provided for @importReadyStatus.
  ///
  /// In en, this message translates to:
  /// **'Import ready.'**
  String get importReadyStatus;

  /// No description provided for @importStatusSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Import status: {status}'**
  String importStatusSemanticLabel(String status);

  /// No description provided for @recentJobsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent jobs'**
  String get recentJobsTitle;

  /// No description provided for @noneStatus.
  ///
  /// In en, this message translates to:
  /// **'none'**
  String get noneStatus;

  /// No description provided for @noImportsQueued.
  ///
  /// In en, this message translates to:
  /// **'No imports queued yet.'**
  String get noImportsQueued;

  /// No description provided for @tapForDetails.
  ///
  /// In en, this message translates to:
  /// **'tap for details'**
  String get tapForDetails;

  /// No description provided for @importJobSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Import job {title}, {status}. Double tap for details.'**
  String importJobSemanticLabel(String title, String status);

  /// No description provided for @encryptedArchiveLockedPreview.
  ///
  /// In en, this message translates to:
  /// **'Enter the export passphrase, then preview the archive.'**
  String get encryptedArchiveLockedPreview;

  /// No description provided for @couldNotDecryptArchive.
  ///
  /// In en, this message translates to:
  /// **'Could not decrypt archive: {error}'**
  String couldNotDecryptArchive(String error);

  /// No description provided for @conflictsFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Conflicts found'**
  String get conflictsFoundTitle;

  /// No description provided for @memberConflictCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String memberConflictCount(int count);

  /// No description provided for @groupConflictCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 group} other{{count} groups}}'**
  String groupConflictCount(int count);

  /// No description provided for @listAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get listAnd;

  /// No description provided for @importConflictsBody.
  ///
  /// In en, this message translates to:
  /// **'{conflicts} from this {source} import already exist in your local data.\n\nHow should Pluris Haven handle them?'**
  String importConflictsBody(String conflicts, String source);

  /// No description provided for @skipMatchesButton.
  ///
  /// In en, this message translates to:
  /// **'Skip matches'**
  String get skipMatchesButton;

  /// No description provided for @createDuplicatesButton.
  ///
  /// In en, this message translates to:
  /// **'Create duplicates'**
  String get createDuplicatesButton;

  /// No description provided for @updateExistingButton.
  ///
  /// In en, this message translates to:
  /// **'Update existing'**
  String get updateExistingButton;

  /// No description provided for @encryptedExportDescription.
  ///
  /// In en, this message translates to:
  /// **'Saves an encrypted archive protected by a recovery code generated on this device. The code is not stored, so a lost code cannot be recovered.'**
  String get encryptedExportDescription;

  /// No description provided for @generatedRecoveryCodeFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Generated recovery code'**
  String get generatedRecoveryCodeFieldLabel;

  /// No description provided for @confirmRecoveryCodeFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Re-enter recovery code'**
  String get confirmRecoveryCodeFieldLabel;

  /// No description provided for @generateRecoveryCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Generate recovery code'**
  String get generateRecoveryCodeButton;

  /// No description provided for @generateRecoveryCodeFirst.
  ///
  /// In en, this message translates to:
  /// **'Generate a recovery code first.'**
  String get generateRecoveryCodeFirst;

  /// No description provided for @generatedRecoveryCodeStatus.
  ///
  /// In en, this message translates to:
  /// **'Generated locally with 192 bits of randomness. Save it in your password manager, then re-enter it below. Pluris Haven cannot recover it.'**
  String get generatedRecoveryCodeStatus;

  /// No description provided for @showRecoveryCodeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show recovery code'**
  String get showRecoveryCodeTooltip;

  /// No description provided for @hideRecoveryCodeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Hide recovery code'**
  String get hideRecoveryCodeTooltip;

  /// No description provided for @encryptedExportStatusSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Encrypted export status: {status}'**
  String encryptedExportStatusSemanticLabel(String status);

  /// No description provided for @encryptingArchiveButton.
  ///
  /// In en, this message translates to:
  /// **'Encrypting...'**
  String get encryptingArchiveButton;

  /// No description provided for @saveEncryptedFileButton.
  ///
  /// In en, this message translates to:
  /// **'Save encrypted file'**
  String get saveEncryptedFileButton;

  /// No description provided for @recoveryCodesDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Recovery codes do not match.'**
  String get recoveryCodesDoNotMatch;

  /// No description provided for @buildingArchiveStatus.
  ///
  /// In en, this message translates to:
  /// **'Building archive...'**
  String get buildingArchiveStatus;

  /// No description provided for @encryptingArchiveStatus.
  ///
  /// In en, this message translates to:
  /// **'Encrypting archive...'**
  String get encryptingArchiveStatus;

  /// No description provided for @saveEncryptedArchiveDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Save encrypted Pluris Haven archive'**
  String get saveEncryptedArchiveDialogTitle;

  /// No description provided for @encryptedArchiveSaved.
  ///
  /// In en, this message translates to:
  /// **'Encrypted archive saved.'**
  String get encryptedArchiveSaved;

  /// No description provided for @saveCancelled.
  ///
  /// In en, this message translates to:
  /// **'Save cancelled.'**
  String get saveCancelled;

  /// No description provided for @couldNotSaveEncryptedArchive.
  ///
  /// In en, this message translates to:
  /// **'Could not save encrypted archive: {error}'**
  String couldNotSaveEncryptedArchive(String error);

  /// No description provided for @localArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Local archive'**
  String get localArchiveTitle;

  /// No description provided for @localArchiveDescription.
  ///
  /// In en, this message translates to:
  /// **'Unencrypted JSON export for backup or migration. It includes local members, groups, journals, notes, fronts, tags, polls, custom fields, and app preferences.'**
  String get localArchiveDescription;

  /// No description provided for @buildingLocalArchiveSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Building local archive. Please wait.'**
  String get buildingLocalArchiveSemanticLabel;

  /// No description provided for @buildingLocalArchiveStatus.
  ///
  /// In en, this message translates to:
  /// **'Building local archive...'**
  String get buildingLocalArchiveStatus;

  /// No description provided for @archiveErrorSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Archive error: {error}'**
  String archiveErrorSemanticLabel(String error);

  /// No description provided for @couldNotBuildArchive.
  ///
  /// In en, this message translates to:
  /// **'Could not build archive: {error}'**
  String couldNotBuildArchive(String error);

  /// No description provided for @saveJsonFileButton.
  ///
  /// In en, this message translates to:
  /// **'Save JSON file'**
  String get saveJsonFileButton;

  /// No description provided for @copyJsonButton.
  ///
  /// In en, this message translates to:
  /// **'Copy JSON'**
  String get copyJsonButton;

  /// No description provided for @copyPlainArchiveWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Copy unencrypted archive?'**
  String get copyPlainArchiveWarningTitle;

  /// No description provided for @copyPlainArchiveWarningBody.
  ///
  /// In en, this message translates to:
  /// **'This archive contains your local data in plain text. Clipboard history, keyboards, and other apps may retain it. Save an encrypted file instead if you need to keep it private.'**
  String get copyPlainArchiveWarningBody;

  /// No description provided for @copyPlainArchiveConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Copy unencrypted archive'**
  String get copyPlainArchiveConfirmButton;

  /// No description provided for @savePlainArchiveWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Save unencrypted archive?'**
  String get savePlainArchiveWarningTitle;

  /// No description provided for @savePlainArchiveWarningBody.
  ///
  /// In en, this message translates to:
  /// **'Anyone who gets this file can read your local data. Save an encrypted file instead if you need to keep it private.'**
  String get savePlainArchiveWarningBody;

  /// No description provided for @savePlainArchiveConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Save unencrypted archive'**
  String get savePlainArchiveConfirmButton;

  /// No description provided for @archiveCopied.
  ///
  /// In en, this message translates to:
  /// **'Archive copied'**
  String get archiveCopied;

  /// No description provided for @saveArchiveDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Save Pluris Haven archive'**
  String get saveArchiveDialogTitle;

  /// No description provided for @archiveSaved.
  ///
  /// In en, this message translates to:
  /// **'Archive saved'**
  String get archiveSaved;

  /// No description provided for @couldNotSaveArchive.
  ///
  /// In en, this message translates to:
  /// **'Could not save archive: {error}'**
  String couldNotSaveArchive(String error);

  /// No description provided for @typeFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeFieldLabel;

  /// No description provided for @sourceFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get sourceFieldLabel;

  /// No description provided for @createdFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get createdFieldLabel;

  /// No description provided for @updatedFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updatedFieldLabel;

  /// No description provided for @noJobErrorRecorded.
  ///
  /// In en, this message translates to:
  /// **'No error recorded for this job.'**
  String get noJobErrorRecorded;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorTitle;

  /// No description provided for @fullErrorCopied.
  ///
  /// In en, this message translates to:
  /// **'Full error copied'**
  String get fullErrorCopied;

  /// No description provided for @copyFullButton.
  ///
  /// In en, this message translates to:
  /// **'Copy full'**
  String get copyFullButton;

  /// No description provided for @jobErrorPreviewTruncated.
  ///
  /// In en, this message translates to:
  /// **'Showing a safe preview. The full error is too large to render here.'**
  String get jobErrorPreviewTruncated;

  /// No description provided for @truncatedCharacters.
  ///
  /// In en, this message translates to:
  /// **'...truncated {count, plural, =1{1 character} other{{count} characters}}'**
  String truncatedCharacters(int count);

  /// No description provided for @searchNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Search notes'**
  String get searchNotesHint;

  /// No description provided for @notesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesTitle;

  /// No description provided for @allFilter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allFilter;

  /// No description provided for @memberFilter.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get memberFilter;

  /// No description provided for @systemFilter.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemFilter;

  /// No description provided for @noNotesYet.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get noNotesYet;

  /// No description provided for @noMatchingNotes.
  ///
  /// In en, this message translates to:
  /// **'No matching notes'**
  String get noMatchingNotes;

  /// No description provided for @notesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Local notes can be attached to members or kept general.'**
  String get notesEmptyBody;

  /// No description provided for @tryAnotherSearchOrFilter.
  ///
  /// In en, this message translates to:
  /// **'Try another search or filter.'**
  String get tryAnotherSearchOrFilter;

  /// No description provided for @addNoteButton.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get addNoteButton;

  /// No description provided for @deleteNoteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete note'**
  String get deleteNoteTooltip;

  /// No description provided for @deleteNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete note?'**
  String get deleteNoteTitle;

  /// No description provided for @deleteNoteBody.
  ///
  /// In en, this message translates to:
  /// **'This note will be permanently removed.'**
  String get deleteNoteBody;

  /// No description provided for @systemNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'System note'**
  String get systemNoteLabel;

  /// No description provided for @unknownMemberNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Unknown member note'**
  String get unknownMemberNoteLabel;

  /// No description provided for @memberNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'{name} note'**
  String memberNoteLabel(String name);

  /// No description provided for @editNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get editNoteTitle;

  /// No description provided for @forFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'For'**
  String get forFieldLabel;

  /// No description provided for @saveNoteButton.
  ///
  /// In en, this message translates to:
  /// **'Save note'**
  String get saveNoteButton;

  /// No description provided for @pollsTitle.
  ///
  /// In en, this message translates to:
  /// **'Polls'**
  String get pollsTitle;

  /// No description provided for @openPollCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{none open} =1{1 open} other{{count} open}}'**
  String openPollCount(int count);

  /// No description provided for @noPollsYet.
  ///
  /// In en, this message translates to:
  /// **'No polls yet'**
  String get noPollsYet;

  /// No description provided for @pollsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Create a local vote for system decisions.'**
  String get pollsEmptyBody;

  /// No description provided for @createPollButton.
  ///
  /// In en, this message translates to:
  /// **'Create poll'**
  String get createPollButton;

  /// No description provided for @pollOptionSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'{option}, {status}'**
  String pollOptionSemanticLabel(String option, String status);

  /// No description provided for @selectedStatus.
  ///
  /// In en, this message translates to:
  /// **'selected'**
  String get selectedStatus;

  /// No description provided for @notSelectedStatus.
  ///
  /// In en, this message translates to:
  /// **'not selected'**
  String get notSelectedStatus;

  /// No description provided for @pollSelectionSummary.
  ///
  /// In en, this message translates to:
  /// **'{kind} - {count, plural, =1{1 selected} other{{count} selected}}'**
  String pollSelectionSummary(String kind, int count);

  /// No description provided for @closeButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// No description provided for @deletePollTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete poll'**
  String get deletePollTooltip;

  /// No description provided for @deletePollTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete poll?'**
  String get deletePollTitle;

  /// No description provided for @deletePollBody.
  ///
  /// In en, this message translates to:
  /// **'This poll and its local responses will be removed.'**
  String get deletePollBody;

  /// No description provided for @questionFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get questionFieldLabel;

  /// No description provided for @descriptionFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionFieldLabel;

  /// No description provided for @pollDescriptionHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional context for the vote'**
  String get pollDescriptionHelper;

  /// No description provided for @votingFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Voting'**
  String get votingFieldLabel;

  /// No description provided for @pollOptionFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Option {number}'**
  String pollOptionFieldLabel(int number);

  /// No description provided for @addPollOptionButton.
  ///
  /// In en, this message translates to:
  /// **'Add option'**
  String get addPollOptionButton;

  /// No description provided for @savePollButton.
  ///
  /// In en, this message translates to:
  /// **'Save poll'**
  String get savePollButton;

  /// No description provided for @singleChoicePollKind.
  ///
  /// In en, this message translates to:
  /// **'Single choice'**
  String get singleChoicePollKind;

  /// No description provided for @multipleChoicePollKind.
  ///
  /// In en, this message translates to:
  /// **'Multiple choice'**
  String get multipleChoicePollKind;

  /// No description provided for @searchJournalsHint.
  ///
  /// In en, this message translates to:
  /// **'Search journals'**
  String get searchJournalsHint;

  /// No description provided for @journalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Journals'**
  String get journalsTitle;

  /// No description provided for @noJournalEntriesYet.
  ///
  /// In en, this message translates to:
  /// **'No journal entries yet'**
  String get noJournalEntriesYet;

  /// No description provided for @noMatchingJournals.
  ///
  /// In en, this message translates to:
  /// **'No matching journals'**
  String get noMatchingJournals;

  /// No description provided for @journalsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Write longer dated entries here. Use Notes for short scratchpad items.'**
  String get journalsEmptyBody;

  /// No description provided for @addJournalEntryButton.
  ///
  /// In en, this message translates to:
  /// **'Add journal entry'**
  String get addJournalEntryButton;

  /// No description provided for @untitledEntry.
  ///
  /// In en, this message translates to:
  /// **'Untitled entry'**
  String get untitledEntry;

  /// No description provided for @emptyJournal.
  ///
  /// In en, this message translates to:
  /// **'empty journal'**
  String get emptyJournal;

  /// No description provided for @deleteJournalEntryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete journal entry'**
  String get deleteJournalEntryTooltip;

  /// No description provided for @deleteJournalEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete journal entry?'**
  String get deleteJournalEntryTitle;

  /// No description provided for @deleteJournalEntryBody.
  ///
  /// In en, this message translates to:
  /// **'This entry will be permanently removed from this device.'**
  String get deleteJournalEntryBody;

  /// No description provided for @editJournalEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit journal entry'**
  String get editJournalEntryTitle;

  /// No description provided for @entryFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Entry'**
  String get entryFieldLabel;

  /// No description provided for @saveEntryButton.
  ///
  /// In en, this message translates to:
  /// **'Save entry'**
  String get saveEntryButton;

  /// No description provided for @createEntryButton.
  ///
  /// In en, this message translates to:
  /// **'Create entry'**
  String get createEntryButton;

  /// No description provided for @writeBeforeSaving.
  ///
  /// In en, this message translates to:
  /// **'Write something before saving.'**
  String get writeBeforeSaving;

  /// No description provided for @searchGroupsHint.
  ///
  /// In en, this message translates to:
  /// **'Search groups'**
  String get searchGroupsHint;

  /// No description provided for @groupsTitle.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groupsTitle;

  /// No description provided for @noGroupsYet.
  ///
  /// In en, this message translates to:
  /// **'No groups yet'**
  String get noGroupsYet;

  /// No description provided for @noMatchingGroups.
  ///
  /// In en, this message translates to:
  /// **'No matching groups'**
  String get noMatchingGroups;

  /// No description provided for @groupsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Groups keep members organised without needing sync.'**
  String get groupsEmptyBody;

  /// No description provided for @tryAnotherSearch.
  ///
  /// In en, this message translates to:
  /// **'Try another search.'**
  String get tryAnotherSearch;

  /// No description provided for @addGroupButton.
  ///
  /// In en, this message translates to:
  /// **'Add group'**
  String get addGroupButton;

  /// No description provided for @groupMemberCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String groupMemberCount(int count);

  /// No description provided for @groupSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'{name}, {members}'**
  String groupSemanticLabel(String name, String members);

  /// No description provided for @nestedGroupSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'{name}, nested group level {depth}, {members}'**
  String nestedGroupSemanticLabel(String name, int depth, String members);

  /// No description provided for @groupAvatarSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Avatar for group {name}'**
  String groupAvatarSemanticLabel(String name);

  /// No description provided for @groupActionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Group actions'**
  String get groupActionsTooltip;

  /// No description provided for @deleteGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete group?'**
  String get deleteGroupTitle;

  /// No description provided for @deleteGroupBody.
  ///
  /// In en, this message translates to:
  /// **'Members stay saved. Child groups move up one level.'**
  String get deleteGroupBody;

  /// No description provided for @editButton.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editButton;

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// No description provided for @editGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit group'**
  String get editGroupTitle;

  /// No description provided for @nameFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameFieldLabel;

  /// No description provided for @emojiFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get emojiFieldLabel;

  /// No description provided for @parentGroupFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Parent group'**
  String get parentGroupFieldLabel;

  /// No description provided for @noParentOption.
  ///
  /// In en, this message translates to:
  /// **'No parent'**
  String get noParentOption;

  /// No description provided for @colorHexFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Colour hex'**
  String get colorHexFieldLabel;

  /// No description provided for @subsystemToggleTitle.
  ///
  /// In en, this message translates to:
  /// **'Subgroup / subsystem'**
  String get subsystemToggleTitle;

  /// No description provided for @subsystemToggleBody.
  ///
  /// In en, this message translates to:
  /// **'Subsystem members can overlap with the main group.'**
  String get subsystemToggleBody;

  /// No description provided for @saveChangesButton.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChangesButton;

  /// No description provided for @saveGroupButton.
  ///
  /// In en, this message translates to:
  /// **'Save group'**
  String get saveGroupButton;

  /// No description provided for @invalidHexColorError.
  ///
  /// In en, this message translates to:
  /// **'Use 6 hex digits, like #F2C75C.'**
  String get invalidHexColorError;

  /// No description provided for @purpleColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get purpleColorLabel;

  /// No description provided for @goldColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get goldColorLabel;

  /// No description provided for @tealColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get tealColorLabel;

  /// No description provided for @roseColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Rose'**
  String get roseColorLabel;

  /// No description provided for @searchMessagesHint.
  ///
  /// In en, this message translates to:
  /// **'Search messages'**
  String get searchMessagesHint;

  /// No description provided for @messagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messagesTitle;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// No description provided for @noMatchingMessages.
  ///
  /// In en, this message translates to:
  /// **'No matching messages'**
  String get noMatchingMessages;

  /// No description provided for @messagesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Leave local notes for the system here.'**
  String get messagesEmptyBody;

  /// No description provided for @addMessageButton.
  ///
  /// In en, this message translates to:
  /// **'Add message'**
  String get addMessageButton;

  /// No description provided for @systemMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'System message'**
  String get systemMessageLabel;

  /// No description provided for @unknownSenderLabel.
  ///
  /// In en, this message translates to:
  /// **'Unknown sender'**
  String get unknownSenderLabel;

  /// No description provided for @unknownMemberLabel.
  ///
  /// In en, this message translates to:
  /// **'Unknown member'**
  String get unknownMemberLabel;

  /// No description provided for @messageMetadata.
  ///
  /// In en, this message translates to:
  /// **'{sender} - {date}{replyMarker}'**
  String messageMetadata(String sender, String date, String replyMarker);

  /// No description provided for @memberBoardMessageMetadata.
  ///
  /// In en, this message translates to:
  /// **'{board} board - {sender} - {date}{replyMarker}'**
  String memberBoardMessageMetadata(
    String board,
    String sender,
    String date,
    String replyMarker,
  );

  /// No description provided for @messageReplyMarker.
  ///
  /// In en, this message translates to:
  /// **' - reply'**
  String get messageReplyMarker;

  /// No description provided for @messageActionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Message actions'**
  String get messageActionsTooltip;

  /// No description provided for @replyButton.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get replyButton;

  /// No description provided for @deleteMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete message?'**
  String get deleteMessageTitle;

  /// No description provided for @deleteMessageBody.
  ///
  /// In en, this message translates to:
  /// **'This message will be hidden from the local board.'**
  String get deleteMessageBody;

  /// No description provided for @editMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit message'**
  String get editMessageTitle;

  /// No description provided for @fromFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get fromFieldLabel;

  /// No description provided for @boardFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get boardFieldLabel;

  /// No description provided for @systemBoardLabel.
  ///
  /// In en, this message translates to:
  /// **'System board'**
  String get systemBoardLabel;

  /// No description provided for @memberBoardLabel.
  ///
  /// In en, this message translates to:
  /// **'Member board'**
  String get memberBoardLabel;

  /// No description provided for @replyingToMessage.
  ///
  /// In en, this message translates to:
  /// **'Replying to: {message}'**
  String replyingToMessage(String message);

  /// No description provided for @messageFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageFieldLabel;

  /// No description provided for @saveMessageButton.
  ///
  /// In en, this message translates to:
  /// **'Save message'**
  String get saveMessageButton;

  /// No description provided for @chooseMemberBoardFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose a member board first.'**
  String get chooseMemberBoardFirst;

  /// No description provided for @offlineStatusPill.
  ///
  /// In en, this message translates to:
  /// **'offline'**
  String get offlineStatusPill;

  /// No description provided for @localSystemName.
  ///
  /// In en, this message translates to:
  /// **'Local system'**
  String get localSystemName;

  /// No description provided for @systemAvatarSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'System avatar for {systemName}'**
  String systemAvatarSemanticLabel(String systemName);

  /// No description provided for @systemMemberGroupCount.
  ///
  /// In en, this message translates to:
  /// **'{memberCount, plural, =1{1 member} other{{memberCount} members}} - {groupCount, plural, =1{1 group} other{{groupCount} groups}}'**
  String systemMemberGroupCount(int memberCount, int groupCount);

  /// No description provided for @navigationDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navigationDashboard;

  /// No description provided for @navigationMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get navigationMembers;

  /// No description provided for @navigationFrontHistory.
  ///
  /// In en, this message translates to:
  /// **'Front History'**
  String get navigationFrontHistory;

  /// No description provided for @navigationCustomFronts.
  ///
  /// In en, this message translates to:
  /// **'Custom Fronts'**
  String get navigationCustomFronts;

  /// No description provided for @navigationGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get navigationGroups;

  /// No description provided for @navigationNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get navigationNotes;

  /// No description provided for @navigationJournals.
  ///
  /// In en, this message translates to:
  /// **'Journals'**
  String get navigationJournals;

  /// No description provided for @navigationAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get navigationAnalytics;

  /// No description provided for @navigationChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get navigationChat;

  /// No description provided for @navigationPolls.
  ///
  /// In en, this message translates to:
  /// **'Polls'**
  String get navigationPolls;

  /// No description provided for @navigationFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get navigationFriends;

  /// No description provided for @navigationUsefulLinks.
  ///
  /// In en, this message translates to:
  /// **'Useful Links'**
  String get navigationUsefulLinks;

  /// No description provided for @navigationReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get navigationReminders;

  /// No description provided for @navigationPrivacyBuckets.
  ///
  /// In en, this message translates to:
  /// **'Privacy buckets'**
  String get navigationPrivacyBuckets;

  /// No description provided for @navigationTokens.
  ///
  /// In en, this message translates to:
  /// **'Tokens'**
  String get navigationTokens;

  /// No description provided for @navigationUserReport.
  ///
  /// In en, this message translates to:
  /// **'User Report'**
  String get navigationUserReport;

  /// No description provided for @navigationNotificationHistory.
  ///
  /// In en, this message translates to:
  /// **'Notification History'**
  String get navigationNotificationHistory;

  /// No description provided for @navigationHowTos.
  ///
  /// In en, this message translates to:
  /// **'How-tos'**
  String get navigationHowTos;

  /// No description provided for @navigationCustomFields.
  ///
  /// In en, this message translates to:
  /// **'Custom Fields'**
  String get navigationCustomFields;

  /// No description provided for @navigationAccountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get navigationAccountSettings;

  /// No description provided for @navigationImportExport.
  ///
  /// In en, this message translates to:
  /// **'Import / Export'**
  String get navigationImportExport;

  /// No description provided for @navigationSync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get navigationSync;

  /// No description provided for @navigationAppOptions.
  ///
  /// In en, this message translates to:
  /// **'App options'**
  String get navigationAppOptions;

  /// No description provided for @navigationAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get navigationAbout;

  /// No description provided for @frontingFilter.
  ///
  /// In en, this message translates to:
  /// **'Fronting'**
  String get frontingFilter;

  /// No description provided for @archivedFilter.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archivedFilter;

  /// No description provided for @searchMembersHint.
  ///
  /// In en, this message translates to:
  /// **'Search members'**
  String get searchMembersHint;

  /// No description provided for @noMembersSavedLocally.
  ///
  /// In en, this message translates to:
  /// **'No members saved locally'**
  String get noMembersSavedLocally;

  /// No description provided for @noMatchingMembers.
  ///
  /// In en, this message translates to:
  /// **'No matching members'**
  String get noMatchingMembers;

  /// No description provided for @membersEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add members here or import a Simply Plural export.'**
  String get membersEmptyBody;

  /// No description provided for @addMemberButton.
  ///
  /// In en, this message translates to:
  /// **'Add member'**
  String get addMemberButton;

  /// No description provided for @memberActionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Member actions'**
  String get memberActionsTooltip;

  /// No description provided for @deleteMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete member?'**
  String get deleteMemberTitle;

  /// No description provided for @deleteMemberBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will be permanently removed from this local system.'**
  String deleteMemberBody(String name);

  /// No description provided for @setFrontButton.
  ///
  /// In en, this message translates to:
  /// **'Set front'**
  String get setFrontButton;

  /// No description provided for @addToFrontButton.
  ///
  /// In en, this message translates to:
  /// **'Add to front'**
  String get addToFrontButton;

  /// No description provided for @setAsFrontButton.
  ///
  /// In en, this message translates to:
  /// **'Set as front'**
  String get setAsFrontButton;

  /// No description provided for @noActionButton.
  ///
  /// In en, this message translates to:
  /// **'No action'**
  String get noActionButton;

  /// No description provided for @duplicateButton.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicateButton;

  /// No description provided for @restoreButton.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreButton;

  /// No description provided for @archiveButton.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archiveButton;

  /// No description provided for @noPronounsLabel.
  ///
  /// In en, this message translates to:
  /// **'no pronouns'**
  String get noPronounsLabel;

  /// No description provided for @archivedStatus.
  ///
  /// In en, this message translates to:
  /// **'archived'**
  String get archivedStatus;

  /// No description provided for @activeStatus.
  ///
  /// In en, this message translates to:
  /// **'active'**
  String get activeStatus;

  /// No description provided for @noDescriptionYet.
  ///
  /// In en, this message translates to:
  /// **'No description yet.'**
  String get noDescriptionYet;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @pronounsFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Pronouns'**
  String get pronounsFieldLabel;

  /// No description provided for @birthdayFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get birthdayFieldLabel;

  /// No description provided for @privacyFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacyFieldLabel;

  /// No description provided for @pluralKitIdFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'PluralKit ID'**
  String get pluralKitIdFieldLabel;

  /// No description provided for @notLinkedLabel.
  ///
  /// In en, this message translates to:
  /// **'not linked'**
  String get notLinkedLabel;

  /// No description provided for @avatarFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Avatar'**
  String get avatarFieldLabel;

  /// No description provided for @defaultLabel.
  ///
  /// In en, this message translates to:
  /// **'default'**
  String get defaultLabel;

  /// No description provided for @tagsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tagsTitle;

  /// No description provided for @memberTagsTitle.
  ///
  /// In en, this message translates to:
  /// **'Member tags'**
  String get memberTagsTitle;

  /// No description provided for @noneLabel.
  ///
  /// In en, this message translates to:
  /// **'none'**
  String get noneLabel;

  /// No description provided for @memberTagsDescription.
  ///
  /// In en, this message translates to:
  /// **'Use tags for roles, statuses, subsystems, or any slices that do not need a full group.'**
  String get memberTagsDescription;

  /// No description provided for @noTagsYet.
  ///
  /// In en, this message translates to:
  /// **'No tags yet.'**
  String get noTagsYet;

  /// No description provided for @newTagFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'New tag'**
  String get newTagFieldLabel;

  /// No description provided for @tagColourFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Tag colour'**
  String get tagColourFieldLabel;

  /// No description provided for @createTagButton.
  ///
  /// In en, this message translates to:
  /// **'Create tag'**
  String get createTagButton;

  /// No description provided for @saveTagsButton.
  ///
  /// In en, this message translates to:
  /// **'Save tags'**
  String get saveTagsButton;

  /// No description provided for @nameTagFirstError.
  ///
  /// In en, this message translates to:
  /// **'Name the tag first.'**
  String get nameTagFirstError;

  /// No description provided for @dataTitle.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get dataTitle;

  /// No description provided for @notSetLabel.
  ///
  /// In en, this message translates to:
  /// **'not set'**
  String get notSetLabel;

  /// No description provided for @valueFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get valueFieldLabel;

  /// No description provided for @leaveBlankToClearHint.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to clear'**
  String get leaveBlankToClearHint;

  /// No description provided for @saveValueButton.
  ///
  /// In en, this message translates to:
  /// **'Save value'**
  String get saveValueButton;

  /// No description provided for @clearButton.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearButton;

  /// No description provided for @duplicateMemberName.
  ///
  /// In en, this message translates to:
  /// **'{name} copy'**
  String duplicateMemberName(String name);

  /// No description provided for @memberAvatarSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Avatar for {name}'**
  String memberAvatarSemanticLabel(String name);

  /// No description provided for @memberPreviewName.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get memberPreviewName;

  /// No description provided for @alterProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Alter profile'**
  String get alterProfileTitle;

  /// No description provided for @birthdayFieldHint.
  ///
  /// In en, this message translates to:
  /// **'YYYY-MM-DD, MM-DD, or free text'**
  String get birthdayFieldHint;

  /// No description provided for @privacyFieldHint.
  ///
  /// In en, this message translates to:
  /// **'private, friends, public, or bucket name'**
  String get privacyFieldHint;

  /// No description provided for @avatarReferenceFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Avatar URL or local ref'**
  String get avatarReferenceFieldLabel;

  /// No description provided for @chooseImageButton.
  ///
  /// In en, this message translates to:
  /// **'Choose image'**
  String get chooseImageButton;

  /// No description provided for @primaryGroupFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Primary group'**
  String get primaryGroupFieldLabel;

  /// No description provided for @noPrimaryGroupOption.
  ///
  /// In en, this message translates to:
  /// **'No primary group'**
  String get noPrimaryGroupOption;

  /// No description provided for @memberGroupsTitle.
  ///
  /// In en, this message translates to:
  /// **'Member groups'**
  String get memberGroupsTitle;

  /// No description provided for @saveAlterButton.
  ///
  /// In en, this message translates to:
  /// **'Save alter'**
  String get saveAlterButton;

  /// No description provided for @createAlterButton.
  ///
  /// In en, this message translates to:
  /// **'Create alter'**
  String get createAlterButton;

  /// No description provided for @openingImagePickerStatus.
  ///
  /// In en, this message translates to:
  /// **'Opening image picker...'**
  String get openingImagePickerStatus;

  /// No description provided for @chooseMemberAvatarTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose member avatar'**
  String get chooseMemberAvatarTitle;

  /// No description provided for @noImageSelectedStatus.
  ///
  /// In en, this message translates to:
  /// **'No image selected.'**
  String get noImageSelectedStatus;

  /// No description provided for @selectedImageEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Selected image was empty.'**
  String get selectedImageEmptyError;

  /// No description provided for @selectedImageTooLargeError.
  ///
  /// In en, this message translates to:
  /// **'Choose an image smaller than 10 MB.'**
  String get selectedImageTooLargeError;

  /// No description provided for @selectedImageUnsupportedTypeError.
  ///
  /// In en, this message translates to:
  /// **'Choose a PNG, JPEG, WebP, or GIF image.'**
  String get selectedImageUnsupportedTypeError;

  /// No description provided for @avatarSavedStatus.
  ///
  /// In en, this message translates to:
  /// **'Avatar saved on device.'**
  String get avatarSavedStatus;

  /// No description provided for @couldNotSaveAvatar.
  ///
  /// In en, this message translates to:
  /// **'Could not save avatar: {error}'**
  String couldNotSaveAvatar(Object error);

  /// No description provided for @avatarClearedStatus.
  ///
  /// In en, this message translates to:
  /// **'Avatar cleared.'**
  String get avatarClearedStatus;

  /// No description provided for @todayFilter.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayFilter;

  /// No description provided for @weekFilter.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get weekFilter;

  /// No description provided for @monthFilter.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get monthFilter;

  /// No description provided for @searchFrontHistoryHint.
  ///
  /// In en, this message translates to:
  /// **'Search front history'**
  String get searchFrontHistoryHint;

  /// No description provided for @frontHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Front history'**
  String get frontHistoryTitle;

  /// No description provided for @noFrontHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No front history yet'**
  String get noFrontHistoryYet;

  /// No description provided for @frontHistoryEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Set a front or import an archive to fill this in.'**
  String get frontHistoryEmptyBody;

  /// No description provided for @noMatchingFronts.
  ///
  /// In en, this message translates to:
  /// **'No matching fronts'**
  String get noMatchingFronts;

  /// No description provided for @noMatchingFrontsBody.
  ///
  /// In en, this message translates to:
  /// **'Try a wider date range or a shorter search.'**
  String get noMatchingFrontsBody;

  /// No description provided for @addEntryButton.
  ///
  /// In en, this message translates to:
  /// **'Add entry'**
  String get addEntryButton;

  /// No description provided for @resetButton.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetButton;

  /// No description provided for @statusNoteFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Status note'**
  String get statusNoteFieldLabel;

  /// No description provided for @statusNoteFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Add context for this front'**
  String get statusNoteFieldHint;

  /// No description provided for @editEntryButton.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get editEntryButton;

  /// No description provided for @deleteFrontEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete front entry?'**
  String get deleteFrontEntryTitle;

  /// No description provided for @deleteFrontEntryBody.
  ///
  /// In en, this message translates to:
  /// **'This removes this front history entry from the archive.'**
  String get deleteFrontEntryBody;

  /// No description provided for @deleteEntryButton.
  ///
  /// In en, this message translates to:
  /// **'Delete entry'**
  String get deleteEntryButton;

  /// No description provided for @addFrontHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Add front history'**
  String get addFrontHistoryTitle;

  /// No description provided for @editFrontHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit front history'**
  String get editFrontHistoryTitle;

  /// No description provided for @startedFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get startedFieldLabel;

  /// No description provided for @endedFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get endedFieldLabel;

  /// No description provided for @customLabelFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom label'**
  String get customLabelFieldLabel;

  /// No description provided for @customLabelFieldHelp.
  ///
  /// In en, this message translates to:
  /// **'Used when no members are selected'**
  String get customLabelFieldHelp;

  /// No description provided for @endBeforeStartError.
  ///
  /// In en, this message translates to:
  /// **'End time must be after the start time.'**
  String get endBeforeStartError;

  /// No description provided for @chooseMembersOrLabelError.
  ///
  /// In en, this message translates to:
  /// **'Choose members or enter a custom label.'**
  String get chooseMembersOrLabelError;

  /// No description provided for @activeFrontTiming.
  ///
  /// In en, this message translates to:
  /// **'started {started} - active'**
  String activeFrontTiming(String started);

  /// No description provided for @endedFrontTiming.
  ///
  /// In en, this message translates to:
  /// **'started {started} - ended {ended}'**
  String endedFrontTiming(String started, String ended);

  /// No description provided for @customFieldsImportDescription.
  ///
  /// In en, this message translates to:
  /// **'Import a Simply Plural export to bring custom profile fields into the local archive.'**
  String get customFieldsImportDescription;

  /// No description provided for @customFieldsWithValues.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 field has imported values.} other{{count} fields have imported values.}}'**
  String customFieldsWithValues(int count);

  /// No description provided for @noCustomFieldsYet.
  ///
  /// In en, this message translates to:
  /// **'No custom fields yet'**
  String get noCustomFieldsYet;

  /// No description provided for @customFieldsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'SP custom fields will show here after import.'**
  String get customFieldsEmptyBody;

  /// No description provided for @addFieldButton.
  ///
  /// In en, this message translates to:
  /// **'Add field'**
  String get addFieldButton;

  /// No description provided for @valueCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 value} other{{count} values}}'**
  String valueCount(int count);

  /// No description provided for @customFieldActionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Custom field actions'**
  String get customFieldActionsTooltip;

  /// No description provided for @deleteCustomFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete custom field?'**
  String get deleteCustomFieldTitle;

  /// No description provided for @deleteCustomFieldBody.
  ///
  /// In en, this message translates to:
  /// **'This removes “{name}” and {count, plural, =1{1 saved value} other{{count} saved values}} from this device.'**
  String deleteCustomFieldBody(String name, int count);

  /// No description provided for @customFieldValueSummary.
  ///
  /// In en, this message translates to:
  /// **'{type} - {count, plural, =1{1 value} other{{count} values}}'**
  String customFieldValueSummary(String type, int count);

  /// No description provided for @systemLabel.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemLabel;

  /// No description provided for @noMemberValuesYet.
  ///
  /// In en, this message translates to:
  /// **'No member values yet'**
  String get noMemberValuesYet;

  /// No description provided for @memberValuesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Imported per-alter values for this field will show here.'**
  String get memberValuesEmptyBody;

  /// No description provided for @customFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom field'**
  String get customFieldTitle;

  /// No description provided for @editCustomFieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Edit the field definition. Existing values stay attached.'**
  String get editCustomFieldDescription;

  /// No description provided for @createCustomFieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a field that can hold member or system data.'**
  String get createCustomFieldDescription;

  /// No description provided for @textType.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get textType;

  /// No description provided for @numberType.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get numberType;

  /// No description provided for @dateType.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateType;

  /// No description provided for @booleanType.
  ///
  /// In en, this message translates to:
  /// **'Boolean'**
  String get booleanType;

  /// No description provided for @selectType.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectType;

  /// No description provided for @privacyOptionsHint.
  ///
  /// In en, this message translates to:
  /// **'private, friends, public'**
  String get privacyOptionsHint;

  /// No description provided for @saveFieldButton.
  ///
  /// In en, this message translates to:
  /// **'Save field'**
  String get saveFieldButton;

  /// No description provided for @createFieldButton.
  ///
  /// In en, this message translates to:
  /// **'Create field'**
  String get createFieldButton;

  /// No description provided for @searchCustomFrontsHint.
  ///
  /// In en, this message translates to:
  /// **'Search custom fronts'**
  String get searchCustomFrontsHint;

  /// No description provided for @customFrontsTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom fronts'**
  String get customFrontsTitle;

  /// No description provided for @customFrontsDescription.
  ///
  /// In en, this message translates to:
  /// **'Statuses like Asleep, Away, or Lost time live here. They can front without becoming members.'**
  String get customFrontsDescription;

  /// No description provided for @addCustomFrontButton.
  ///
  /// In en, this message translates to:
  /// **'Add custom front'**
  String get addCustomFrontButton;

  /// No description provided for @noCustomFronts.
  ///
  /// In en, this message translates to:
  /// **'No custom fronts'**
  String get noCustomFronts;

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get noMatches;

  /// No description provided for @customFrontsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add one here, or import them from SimplyPlural.'**
  String get customFrontsEmptyBody;

  /// No description provided for @tryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different search.'**
  String get tryDifferentSearch;

  /// No description provided for @namedCombinationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Named combinations'**
  String get namedCombinationsTitle;

  /// No description provided for @memberShortcutLabel.
  ///
  /// In en, this message translates to:
  /// **'member shortcut'**
  String get memberShortcutLabel;

  /// No description provided for @setNamedFrontTooltip.
  ///
  /// In en, this message translates to:
  /// **'Set named front'**
  String get setNamedFrontTooltip;

  /// No description provided for @deleteNamedFrontTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete named front'**
  String get deleteNamedFrontTooltip;

  /// No description provided for @setFrontConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Set {name} as front'**
  String setFrontConfirmation(String name);

  /// No description provided for @deleteCustomFrontTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete custom front?'**
  String get deleteCustomFrontTitle;

  /// No description provided for @deleteNamedFrontTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete named front?'**
  String get deleteNamedFrontTitle;

  /// No description provided for @deleteSavedFrontBody.
  ///
  /// In en, this message translates to:
  /// **'This only removes the saved shortcut. Front history stays.'**
  String get deleteSavedFrontBody;

  /// No description provided for @customFrontSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom front {name}'**
  String customFrontSemanticLabel(String name);

  /// No description provided for @customFrontLabel.
  ///
  /// In en, this message translates to:
  /// **'custom front'**
  String get customFrontLabel;

  /// No description provided for @setCustomFrontTooltip.
  ///
  /// In en, this message translates to:
  /// **'Set custom front'**
  String get setCustomFrontTooltip;

  /// No description provided for @editCustomFrontTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit custom front'**
  String get editCustomFrontTooltip;

  /// No description provided for @deleteCustomFrontTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete custom front'**
  String get deleteCustomFrontTooltip;

  /// No description provided for @editCustomFrontTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit custom front'**
  String get editCustomFrontTitle;

  /// No description provided for @customFrontEditorDescription.
  ///
  /// In en, this message translates to:
  /// **'Custom fronts can be used from the front picker without changing member counts.'**
  String get customFrontEditorDescription;

  /// No description provided for @colourFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get colourFieldLabel;

  /// No description provided for @importedAvatarReferenceFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Avatar URL or imported local reference'**
  String get importedAvatarReferenceFieldLabel;

  /// No description provided for @createButton.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createButton;

  /// No description provided for @chooseCustomFrontAvatarTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose custom front avatar'**
  String get chooseCustomFrontAvatarTitle;

  /// No description provided for @localStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'local'**
  String get localStatusLabel;

  /// No description provided for @offlineStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'offline'**
  String get offlineStatusLabel;

  /// No description provided for @usefulLinksDescription.
  ///
  /// In en, this message translates to:
  /// **'Quick places for importing, backing up, support, and project links.'**
  String get usefulLinksDescription;

  /// No description provided for @inThisAppTitle.
  ///
  /// In en, this message translates to:
  /// **'In this app'**
  String get inThisAppTitle;

  /// No description provided for @importFromSimplyPluralTitle.
  ///
  /// In en, this message translates to:
  /// **'Import from Simply Plural'**
  String get importFromSimplyPluralTitle;

  /// No description provided for @openImportSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'open import setup'**
  String get openImportSetupSubtitle;

  /// No description provided for @backUpLocalDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Back up local data'**
  String get backUpLocalDataTitle;

  /// No description provided for @exportDeviceArchiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'export a device archive'**
  String get exportDeviceArchiveSubtitle;

  /// No description provided for @customizeDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Customise dashboard'**
  String get customizeDashboardTitle;

  /// No description provided for @dashboardOptionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'tiles, theme, and language'**
  String get dashboardOptionsSubtitle;

  /// No description provided for @howToGuidesTitle.
  ///
  /// In en, this message translates to:
  /// **'How-to guides'**
  String get howToGuidesTitle;

  /// No description provided for @shortOfflineNotesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'short offline notes'**
  String get shortOfflineNotesSubtitle;

  /// No description provided for @projectTitle.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get projectTitle;

  /// No description provided for @sourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get sourceTitle;

  /// No description provided for @whatsNewTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get whatsNewTitle;

  /// No description provided for @apkReleasesTitle.
  ///
  /// In en, this message translates to:
  /// **'APK releases'**
  String get apkReleasesTitle;

  /// No description provided for @githubSponsorsTitle.
  ///
  /// In en, this message translates to:
  /// **'GitHub Sponsors'**
  String get githubSponsorsTitle;

  /// No description provided for @patreonTitle.
  ///
  /// In en, this message translates to:
  /// **'Patreon'**
  String get patreonTitle;

  /// No description provided for @howTosDescription.
  ///
  /// In en, this message translates to:
  /// **'Short local notes for the flows people usually need first.'**
  String get howTosDescription;

  /// No description provided for @howToImportSimplyPluralStep1.
  ///
  /// In en, this message translates to:
  /// **'Export your Simply Plural data as JSON.'**
  String get howToImportSimplyPluralStep1;

  /// No description provided for @howToImportSimplyPluralStep2.
  ///
  /// In en, this message translates to:
  /// **'Open Import / Export and choose the file or paste JSON.'**
  String get howToImportSimplyPluralStep2;

  /// No description provided for @howToImportSimplyPluralStep3.
  ///
  /// In en, this message translates to:
  /// **'Review the preview, then apply it to the local archive.'**
  String get howToImportSimplyPluralStep3;

  /// No description provided for @howToImportSimplyPluralStep4.
  ///
  /// In en, this message translates to:
  /// **'Check members, groups, fronts, notes, and avatars after import.'**
  String get howToImportSimplyPluralStep4;

  /// No description provided for @openImportAction.
  ///
  /// In en, this message translates to:
  /// **'Open import'**
  String get openImportAction;

  /// No description provided for @trackFrontTitle.
  ///
  /// In en, this message translates to:
  /// **'Track a front'**
  String get trackFrontTitle;

  /// No description provided for @howToTrackFrontStep1.
  ///
  /// In en, this message translates to:
  /// **'Open Dashboard or Front History.'**
  String get howToTrackFrontStep1;

  /// No description provided for @howToTrackFrontStep2.
  ///
  /// In en, this message translates to:
  /// **'Use Set front to pick members or a saved custom front.'**
  String get howToTrackFrontStep2;

  /// No description provided for @howToTrackFrontStep3.
  ///
  /// In en, this message translates to:
  /// **'Use Clear when nobody is fronting or the state ended.'**
  String get howToTrackFrontStep3;

  /// No description provided for @howToTrackFrontStep4.
  ///
  /// In en, this message translates to:
  /// **'Front History keeps the local timeline.'**
  String get howToTrackFrontStep4;

  /// No description provided for @openHistoryAction.
  ///
  /// In en, this message translates to:
  /// **'Open history'**
  String get openHistoryAction;

  /// No description provided for @saveCustomFrontsTitle.
  ///
  /// In en, this message translates to:
  /// **'Save custom fronts'**
  String get saveCustomFrontsTitle;

  /// No description provided for @howToCustomFrontsStep1.
  ///
  /// In en, this message translates to:
  /// **'Open Custom Fronts.'**
  String get howToCustomFrontsStep1;

  /// No description provided for @howToCustomFrontsStep2.
  ///
  /// In en, this message translates to:
  /// **'Add statuses like Asleep, Away, or blended front states.'**
  String get howToCustomFrontsStep2;

  /// No description provided for @howToCustomFrontsStep3.
  ///
  /// In en, this message translates to:
  /// **'Set them from the dashboard without creating extra members.'**
  String get howToCustomFrontsStep3;

  /// No description provided for @openCustomFrontsAction.
  ///
  /// In en, this message translates to:
  /// **'Open custom fronts'**
  String get openCustomFrontsAction;

  /// No description provided for @backUpDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Back up this device'**
  String get backUpDeviceTitle;

  /// No description provided for @howToBackupStep1.
  ///
  /// In en, this message translates to:
  /// **'Open Import / Export.'**
  String get howToBackupStep1;

  /// No description provided for @howToBackupStep2.
  ///
  /// In en, this message translates to:
  /// **'Create a Pluris Haven archive.'**
  String get howToBackupStep2;

  /// No description provided for @howToBackupStep3.
  ///
  /// In en, this message translates to:
  /// **'Keep the file somewhere outside this phone too.'**
  String get howToBackupStep3;

  /// No description provided for @openExportAction.
  ///
  /// In en, this message translates to:
  /// **'Open export'**
  String get openExportAction;

  /// No description provided for @useCustomFieldsTitle.
  ///
  /// In en, this message translates to:
  /// **'Use custom fields'**
  String get useCustomFieldsTitle;

  /// No description provided for @howToCustomFieldsStep1.
  ///
  /// In en, this message translates to:
  /// **'Open Custom Fields.'**
  String get howToCustomFieldsStep1;

  /// No description provided for @howToCustomFieldsStep2.
  ///
  /// In en, this message translates to:
  /// **'Add a field like “age”, “role”, or “species”.'**
  String get howToCustomFieldsStep2;

  /// No description provided for @howToCustomFieldsStep3.
  ///
  /// In en, this message translates to:
  /// **'Set values per member from their profile.'**
  String get howToCustomFieldsStep3;

  /// No description provided for @howToCustomFieldsStep4.
  ///
  /// In en, this message translates to:
  /// **'Fields import from Simply Plural automatically.'**
  String get howToCustomFieldsStep4;

  /// No description provided for @openCustomFieldsAction.
  ///
  /// In en, this message translates to:
  /// **'Open custom fields'**
  String get openCustomFieldsAction;

  /// No description provided for @setRemindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Set reminders'**
  String get setRemindersTitle;

  /// No description provided for @howToRemindersStep1.
  ///
  /// In en, this message translates to:
  /// **'Open Reminders.'**
  String get howToRemindersStep1;

  /// No description provided for @howToRemindersStep2.
  ///
  /// In en, this message translates to:
  /// **'Pick a daily, weekly, or monthly schedule.'**
  String get howToRemindersStep2;

  /// No description provided for @howToRemindersStep3.
  ///
  /// In en, this message translates to:
  /// **'Notifications will fire at the set time.'**
  String get howToRemindersStep3;

  /// No description provided for @howToRemindersStep4.
  ///
  /// In en, this message translates to:
  /// **'Turn any reminder off without deleting it.'**
  String get howToRemindersStep4;

  /// No description provided for @openRemindersAction.
  ///
  /// In en, this message translates to:
  /// **'Open reminders'**
  String get openRemindersAction;

  /// No description provided for @voteOnDecisionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Vote on system decisions'**
  String get voteOnDecisionsTitle;

  /// No description provided for @howToPollsStep1.
  ///
  /// In en, this message translates to:
  /// **'Open Polls and create a new poll.'**
  String get howToPollsStep1;

  /// No description provided for @howToPollsStep2.
  ///
  /// In en, this message translates to:
  /// **'Add options and choose single or multiple choice.'**
  String get howToPollsStep2;

  /// No description provided for @howToPollsStep3.
  ///
  /// In en, this message translates to:
  /// **'Share the poll with members in the same space.'**
  String get howToPollsStep3;

  /// No description provided for @howToPollsStep4.
  ///
  /// In en, this message translates to:
  /// **'Results stay on this device until you delete them.'**
  String get howToPollsStep4;

  /// No description provided for @openPollsAction.
  ///
  /// In en, this message translates to:
  /// **'Open polls'**
  String get openPollsAction;

  /// No description provided for @importOtherAppsTitle.
  ///
  /// In en, this message translates to:
  /// **'Import from other apps'**
  String get importOtherAppsTitle;

  /// No description provided for @howToOtherImportsStep1.
  ///
  /// In en, this message translates to:
  /// **'Export JSON from PluralKit, Tupperbox, or PluralSpace.'**
  String get howToOtherImportsStep1;

  /// No description provided for @howToOtherImportsStep2.
  ///
  /// In en, this message translates to:
  /// **'Open Import / Export and upload the file.'**
  String get howToOtherImportsStep2;

  /// No description provided for @howToOtherImportsStep3.
  ///
  /// In en, this message translates to:
  /// **'Select the matching service from the dropdown.'**
  String get howToOtherImportsStep3;

  /// No description provided for @howToOtherImportsStep4.
  ///
  /// In en, this message translates to:
  /// **'Preview the records, then import into local storage.'**
  String get howToOtherImportsStep4;

  /// No description provided for @useSubsystemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Use subsystems'**
  String get useSubsystemsTitle;

  /// No description provided for @howToSubsystemsStep1.
  ///
  /// In en, this message translates to:
  /// **'Open Groups and add or edit a group.'**
  String get howToSubsystemsStep1;

  /// No description provided for @howToSubsystemsStep2.
  ///
  /// In en, this message translates to:
  /// **'Turn on “Subgroup / subsystem”.'**
  String get howToSubsystemsStep2;

  /// No description provided for @howToSubsystemsStep3.
  ///
  /// In en, this message translates to:
  /// **'Members in subsystems can also be in the main group.'**
  String get howToSubsystemsStep3;

  /// No description provided for @howToSubsystemsStep4.
  ///
  /// In en, this message translates to:
  /// **'The layers icon shows which groups are subsystems.'**
  String get howToSubsystemsStep4;

  /// No description provided for @openGroupsAction.
  ///
  /// In en, this message translates to:
  /// **'Open groups'**
  String get openGroupsAction;

  /// No description provided for @analyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analyticsTitle;

  /// No description provided for @analyticsDescription.
  ///
  /// In en, this message translates to:
  /// **'Fronting patterns from local history.'**
  String get analyticsDescription;

  /// No description provided for @frontTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Front timeline'**
  String get frontTimelineTitle;

  /// No description provided for @noAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'No analytics yet'**
  String get noAnalyticsTitle;

  /// No description provided for @noAnalyticsBody.
  ///
  /// In en, this message translates to:
  /// **'Set fronts or import Simply Plural front history to fill this in.'**
  String get noAnalyticsBody;

  /// No description provided for @totalFrontTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Total front time'**
  String get totalFrontTimeLabel;

  /// No description provided for @sessionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessionsLabel;

  /// No description provided for @averageLabel.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get averageLabel;

  /// No description provided for @longestLabel.
  ///
  /// In en, this message translates to:
  /// **'Longest'**
  String get longestLabel;

  /// No description provided for @topFrontsTitle.
  ///
  /// In en, this message translates to:
  /// **'Top fronts'**
  String get topFrontsTitle;

  /// No description provided for @hourOfDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Hour of day'**
  String get hourOfDayTitle;

  /// No description provided for @unknownLabel.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownLabel;

  /// No description provided for @analyticsSevenDays.
  ///
  /// In en, this message translates to:
  /// **'7d'**
  String get analyticsSevenDays;

  /// No description provided for @analyticsThirtyDays.
  ///
  /// In en, this message translates to:
  /// **'30d'**
  String get analyticsThirtyDays;

  /// No description provided for @analyticsNinetyDays.
  ///
  /// In en, this message translates to:
  /// **'90d'**
  String get analyticsNinetyDays;

  /// No description provided for @analyticsOneYear.
  ///
  /// In en, this message translates to:
  /// **'1y'**
  String get analyticsOneYear;

  /// No description provided for @sessionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 session} other{{count} sessions}}'**
  String sessionCount(int count);

  /// No description provided for @frontAnalyticsSemantic.
  ///
  /// In en, this message translates to:
  /// **'{label}, {duration}, {count, plural, =1{1 session} other{{count} sessions}}'**
  String frontAnalyticsSemantic(String label, String duration, int count);

  /// No description provided for @hourAnalyticsSemantic.
  ///
  /// In en, this message translates to:
  /// **'{hour}:00, {duration}'**
  String hourAnalyticsSemantic(int hour, String duration);

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String durationMinutes(int minutes);

  /// No description provided for @durationHours.
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String durationHours(int hours);

  /// No description provided for @durationDays.
  ///
  /// In en, this message translates to:
  /// **'{days}d'**
  String durationDays(int days);

  /// No description provided for @durationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String durationHoursMinutes(int hours, int minutes);

  /// No description provided for @durationDaysHours.
  ///
  /// In en, this message translates to:
  /// **'{days}d {hours}h'**
  String durationDaysHours(int days, int hours);

  /// No description provided for @noMembersYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No members yet'**
  String get noMembersYetTitle;

  /// No description provided for @noMembersFrontPickerBody.
  ///
  /// In en, this message translates to:
  /// **'Add members first, or set a custom front below.'**
  String get noMembersFrontPickerBody;

  /// No description provided for @selectedMembersSummary.
  ///
  /// In en, this message translates to:
  /// **'Selected: {names}'**
  String selectedMembersSummary(String names);

  /// No description provided for @noMatchingMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching members'**
  String get noMatchingMembersTitle;

  /// No description provided for @noMatchingMembersBody.
  ///
  /// In en, this message translates to:
  /// **'Try a different name, pronoun, or PluralKit ID.'**
  String get noMatchingMembersBody;

  /// No description provided for @clearSelectionButton.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get clearSelectionButton;

  /// No description provided for @setSelectedButton.
  ///
  /// In en, this message translates to:
  /// **'Set selected'**
  String get setSelectedButton;

  /// No description provided for @setCofrontButton.
  ///
  /// In en, this message translates to:
  /// **'Set co-front'**
  String get setCofrontButton;

  /// No description provided for @saveSelectedNamedFrontButton.
  ///
  /// In en, this message translates to:
  /// **'Save selected as named front'**
  String get saveSelectedNamedFrontButton;

  /// No description provided for @savedFrontsTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved fronts'**
  String get savedFrontsTitle;

  /// No description provided for @searchSavedFrontsHint.
  ///
  /// In en, this message translates to:
  /// **'Search saved fronts'**
  String get searchSavedFrontsHint;

  /// No description provided for @noMatchingSavedFrontsTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching saved fronts'**
  String get noMatchingSavedFrontsTitle;

  /// No description provided for @noMatchingSavedFrontsBody.
  ///
  /// In en, this message translates to:
  /// **'Try another saved front name or status.'**
  String get noMatchingSavedFrontsBody;

  /// No description provided for @namedCombinationLabel.
  ///
  /// In en, this message translates to:
  /// **'named combination'**
  String get namedCombinationLabel;

  /// No description provided for @setSavedFrontTooltip.
  ///
  /// In en, this message translates to:
  /// **'Set saved front'**
  String get setSavedFrontTooltip;

  /// No description provided for @deleteSavedFrontTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete saved front'**
  String get deleteSavedFrontTooltip;

  /// No description provided for @labelFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get labelFieldLabel;

  /// No description provided for @setButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get setButtonLabel;

  /// No description provided for @frontChangedTitle.
  ///
  /// In en, this message translates to:
  /// **'Front changed'**
  String get frontChangedTitle;

  /// No description provided for @frontClearedTitle.
  ///
  /// In en, this message translates to:
  /// **'Front cleared'**
  String get frontClearedTitle;

  /// No description provided for @memberIsFronting.
  ///
  /// In en, this message translates to:
  /// **'{name} is fronting.'**
  String memberIsFronting(String name);

  /// No description provided for @noOneFrontingBody.
  ///
  /// In en, this message translates to:
  /// **'No one is marked as fronting.'**
  String get noOneFrontingBody;

  /// No description provided for @saveNamedFrontTitle.
  ///
  /// In en, this message translates to:
  /// **'Save named front'**
  String get saveNamedFrontTitle;

  /// No description provided for @frontingDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Fronting'**
  String get frontingDefaultName;

  /// No description provided for @cofrontDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Co-front'**
  String get cofrontDefaultName;

  /// No description provided for @savedNamedFront.
  ///
  /// In en, this message translates to:
  /// **'Saved “{name}”'**
  String savedNamedFront(String name);

  /// No description provided for @avatarForLabel.
  ///
  /// In en, this message translates to:
  /// **'Avatar for {name}'**
  String avatarForLabel(String name);

  /// No description provided for @privacyBucketsDescription.
  ///
  /// In en, this message translates to:
  /// **'Group members by who may see them. Sharing stays off until sync is configured.'**
  String get privacyBucketsDescription;

  /// No description provided for @noPrivacyBucketsTitle.
  ///
  /// In en, this message translates to:
  /// **'No privacy buckets'**
  String get noPrivacyBucketsTitle;

  /// No description provided for @noPrivacyBucketsBody.
  ///
  /// In en, this message translates to:
  /// **'Create one to prepare member visibility rules.'**
  String get noPrivacyBucketsBody;

  /// No description provided for @memberCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String memberCount(int count);

  /// No description provided for @bucketDescriptionMembers.
  ///
  /// In en, this message translates to:
  /// **'{description} - {count, plural, =1{1 member} other{{count} members}}'**
  String bucketDescriptionMembers(String description, int count);

  /// No description provided for @deleteNamedItem.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}'**
  String deleteNamedItem(String name);

  /// No description provided for @deletePrivacyBucketTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete privacy bucket?'**
  String get deletePrivacyBucketTitle;

  /// No description provided for @deletePrivacyBucketBody.
  ///
  /// In en, this message translates to:
  /// **'Member assignments to {name} will be removed.'**
  String deletePrivacyBucketBody(String name);

  /// No description provided for @addBucketButton.
  ///
  /// In en, this message translates to:
  /// **'Add bucket'**
  String get addBucketButton;

  /// No description provided for @relatedVisibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Related visibility'**
  String get relatedVisibilityTitle;

  /// No description provided for @memberVisibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Member visibility'**
  String get memberVisibilityTitle;

  /// No description provided for @memberVisibilitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'edit privacy on member profiles'**
  String get memberVisibilitySubtitle;

  /// No description provided for @customFieldsPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom fields privacy'**
  String get customFieldsPrivacyTitle;

  /// No description provided for @customFieldsPrivacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'edit field-level labels'**
  String get customFieldsPrivacySubtitle;

  /// No description provided for @addPrivacyBucketTitle.
  ///
  /// In en, this message translates to:
  /// **'Add privacy bucket'**
  String get addPrivacyBucketTitle;

  /// No description provided for @editPrivacyBucketTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit privacy bucket'**
  String get editPrivacyBucketTitle;

  /// No description provided for @membersTitle.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get membersTitle;

  /// No description provided for @nameRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Name is required.'**
  String get nameRequiredError;

  /// No description provided for @disabledStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'disabled'**
  String get disabledStatusLabel;

  /// No description provided for @tokensDescription.
  ///
  /// In en, this message translates to:
  /// **'There is no local API token surface yet. Imports do not need a Pluris Haven token.'**
  String get tokensDescription;

  /// No description provided for @tokenStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Token status'**
  String get tokenStatusTitle;

  /// No description provided for @localTokenStoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Local token store'**
  String get localTokenStoreTitle;

  /// No description provided for @emptyStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'empty'**
  String get emptyStatusLabel;

  /// No description provided for @pluralKitLiveImportTitle.
  ///
  /// In en, this message translates to:
  /// **'PluralKit live import'**
  String get pluralKitLiveImportTitle;

  /// No description provided for @pasteTokenDuringImportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'paste a token during import'**
  String get pasteTokenDuringImportSubtitle;

  /// No description provided for @syncTokensTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync tokens'**
  String get syncTokensTitle;

  /// No description provided for @requiresSyncSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'requires sync setup'**
  String get requiresSyncSetupSubtitle;

  /// No description provided for @userReportDescription.
  ///
  /// In en, this message translates to:
  /// **'A small local snapshot you can copy before filing a bug. It excludes system and front names.'**
  String get userReportDescription;

  /// No description provided for @copyReportButton.
  ///
  /// In en, this message translates to:
  /// **'Copy report'**
  String get copyReportButton;

  /// No description provided for @reportBugButton.
  ///
  /// In en, this message translates to:
  /// **'Report a bug'**
  String get reportBugButton;

  /// No description provided for @relatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Related'**
  String get relatedTitle;

  /// No description provided for @importJobsTitle.
  ///
  /// In en, this message translates to:
  /// **'Import jobs'**
  String get importJobsTitle;

  /// No description provided for @importJobsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'open import details and errors'**
  String get importJobsSubtitle;

  /// No description provided for @retainedImportPayloadsTitle.
  ///
  /// In en, this message translates to:
  /// **'Retained import sources'**
  String get retainedImportPayloadsTitle;

  /// No description provided for @retainedImportPayloadsDescription.
  ///
  /// In en, this message translates to:
  /// **'These encrypted source collections are not used by the app. You can remove them without deleting mapped members, notes, or other imported records.'**
  String get retainedImportPayloadsDescription;

  /// No description provided for @retainedImportPayloadSummary.
  ///
  /// In en, this message translates to:
  /// **'{source}: {count, plural, =1{1 collection} other{{count} collections}}'**
  String retainedImportPayloadSummary(String source, int count);

  /// No description provided for @deleteRetainedImportPayloadsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete retained source collections'**
  String get deleteRetainedImportPayloadsTooltip;

  /// No description provided for @deleteRetainedImportPayloadsTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete retained source collections?'**
  String get deleteRetainedImportPayloadsTitle;

  /// No description provided for @deleteRetainedImportPayloadsDescription.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes {count, plural, =1{1 encrypted source collection} other{{count} encrypted source collections}}. Mapped imported records stay in the app.'**
  String deleteRetainedImportPayloadsDescription(int count);

  /// No description provided for @retainedImportPayloadsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Retained source collections deleted'**
  String get retainedImportPayloadsDeleted;

  /// No description provided for @localEventLogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'local event log'**
  String get localEventLogSubtitle;

  /// No description provided for @localReportHeading.
  ///
  /// In en, this message translates to:
  /// **'Pluris Haven local report'**
  String get localReportHeading;

  /// No description provided for @localReportStage.
  ///
  /// In en, this message translates to:
  /// **'stage: pre-alpha'**
  String get localReportStage;

  /// No description provided for @localReportMembers.
  ///
  /// In en, this message translates to:
  /// **'members: {count}'**
  String localReportMembers(int count);

  /// No description provided for @localReportGroups.
  ///
  /// In en, this message translates to:
  /// **'groups: {count}'**
  String localReportGroups(int count);

  /// No description provided for @localReportNotes.
  ///
  /// In en, this message translates to:
  /// **'notes: {count}'**
  String localReportNotes(int count);

  /// No description provided for @localReportFrontHistory.
  ///
  /// In en, this message translates to:
  /// **'front history: {count}'**
  String localReportFrontHistory(int count);

  /// No description provided for @localReportStorage.
  ///
  /// In en, this message translates to:
  /// **'storage: device'**
  String get localReportStorage;

  /// No description provided for @localReportSync.
  ///
  /// In en, this message translates to:
  /// **'sync: off by default'**
  String get localReportSync;

  /// No description provided for @reportCopiedMessage.
  ///
  /// In en, this message translates to:
  /// **'Report copied'**
  String get reportCopiedMessage;

  /// No description provided for @localSystemFallback.
  ///
  /// In en, this message translates to:
  /// **'Local system'**
  String get localSystemFallback;

  /// No description provided for @systemAvatarFor.
  ///
  /// In en, this message translates to:
  /// **'System avatar for {name}'**
  String systemAvatarFor(String name);

  /// No description provided for @savedOnDeviceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'saved on device'**
  String get savedOnDeviceSubtitle;

  /// No description provided for @editSystemProfileTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit system profile'**
  String get editSystemProfileTooltip;

  /// No description provided for @moveDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'move data in or out'**
  String get moveDataSubtitle;

  /// No description provided for @appOptionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'theme, language, dashboard'**
  String get appOptionsSubtitle;

  /// No description provided for @offByDefaultSubtitle.
  ///
  /// In en, this message translates to:
  /// **'off by default'**
  String get offByDefaultSubtitle;

  /// No description provided for @deviceDatabaseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'device database'**
  String get deviceDatabaseSubtitle;

  /// No description provided for @memberNameEncryptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Member name encryption'**
  String get memberNameEncryptionTitle;

  /// No description provided for @secureStorageKeySubtitle.
  ///
  /// In en, this message translates to:
  /// **'key stored in device secure storage'**
  String get secureStorageKeySubtitle;

  /// No description provided for @destructiveActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Destructive actions'**
  String get destructiveActionsTitle;

  /// No description provided for @confirmedWithDialogsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'confirmed with dialogs'**
  String get confirmedWithDialogsSubtitle;

  /// No description provided for @systemProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'System profile'**
  String get systemProfileTitle;

  /// No description provided for @removeButton.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeButton;

  /// No description provided for @systemNameFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'System name'**
  String get systemNameFieldLabel;

  /// No description provided for @savingStatus.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get savingStatus;

  /// No description provided for @chooseSystemAvatarTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose system avatar'**
  String get chooseSystemAvatarTitle;

  /// No description provided for @couldNotSaveImage.
  ///
  /// In en, this message translates to:
  /// **'Could not save image: {error}'**
  String couldNotSaveImage(String error);

  /// No description provided for @plannedFeatureBody.
  ///
  /// In en, this message translates to:
  /// **'{detail}\n\nThis part is not built yet. It is planned for a later pre-alpha build.'**
  String plannedFeatureBody(String detail);

  /// No description provided for @okButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okButtonLabel;

  /// No description provided for @statusSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Status {status}'**
  String statusSemanticLabel(String status);

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Pluris Haven'**
  String get appName;

  /// No description provided for @importCompatibilityValue.
  ///
  /// In en, this message translates to:
  /// **'Simply Plural and PluralKit'**
  String get importCompatibilityValue;

  /// No description provided for @moneroTitle.
  ///
  /// In en, this message translates to:
  /// **'Monero'**
  String get moneroTitle;

  /// No description provided for @noneTitle.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noneTitle;

  /// No description provided for @systemCounts.
  ///
  /// In en, this message translates to:
  /// **'{members, plural, =1{1 member} other{{members} members}} - {groups, plural, =1{1 group} other{{groups} groups}}'**
  String systemCounts(int members, int groups);
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
