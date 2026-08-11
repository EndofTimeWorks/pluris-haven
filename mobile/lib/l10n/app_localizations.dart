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
  /// **'Offline-first plural system tracker.'**
  String get appTagline;

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
  /// **'This permanently removes server sessions, friend data, and uploaded encrypted backups. Local app data stays on this device.'**
  String get deleteServerAccountBody;

  /// No description provided for @currentPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPasswordLabel;

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
