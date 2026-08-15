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
  String get plurisHavenAppName => 'Pluris Haven';

  @override
  String get privateReminderNotificationTitle => 'Pluris Haven reminder';

  @override
  String get privateNotificationBody => 'Open Pluris Haven to view.';

  @override
  String get currentlyFrontingNotificationTitle => 'Currently fronting';

  @override
  String get remindersChannelName => 'Reminders';

  @override
  String get remindersChannelDescription =>
      'Front check-ins and custom reminders';

  @override
  String get frontStatusChannelName => 'Front status';

  @override
  String get frontStatusChannelDescription =>
      'Persistent currently-fronting status';

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

  @override
  String get syncOffTitle => 'Sync is off';

  @override
  String get localStatusPill => 'local';

  @override
  String get syncOffDescription =>
      'Pluris Haven keeps data on this device unless sync is turned on.';

  @override
  String get encryptedSyncLabel => 'Encrypted sync';

  @override
  String get encryptedSyncValue => 'not configured';

  @override
  String get friendsLabel => 'Friends';

  @override
  String get friendsValue => 'not shared';

  @override
  String get backupsLabel => 'Backups';

  @override
  String get backupsValue => 'manual for now';

  @override
  String get notificationHistoryTitle => 'Notification history';

  @override
  String get noNotificationsYetTitle => 'No notifications yet';

  @override
  String get noNotificationsYetBody =>
      'Front notifications and reminders will be recorded here.';

  @override
  String get newStatusPill => 'new';

  @override
  String get appTagline =>
      'Offline-first system, identity, and journaling tools.';

  @override
  String get madeBySystemsStatement =>
      'Made by systems. Welcoming systems, collectives, individuals, and anyone who finds these tools useful.';

  @override
  String get aboutGroupTitle => 'About';

  @override
  String get storageLabel => 'Storage';

  @override
  String get storageValue => 'saved on device';

  @override
  String get compatibilityLabel => 'Compatibility';

  @override
  String get sourceLabel => 'Source';

  @override
  String get optionalSupportTitle => 'Optional support';

  @override
  String get copyMoneroTooltip => 'Copy Monero address';

  @override
  String get moneroAddressCopied => 'Monero address copied';

  @override
  String couldNotOpenUrl(String url) {
    return 'Could not open $url';
  }

  @override
  String get cancelButtonLabel => 'Cancel';

  @override
  String get deleteButtonLabel => 'Delete';

  @override
  String get dashboardMainSectionTitle => 'Main';

  @override
  String get noDashboardShortcutsTitle => 'No dashboard shortcuts';

  @override
  String get noDashboardShortcutsBody =>
      'Open Customise to add shortcuts back.';

  @override
  String dashboardShortcutSemanticLabel(String title) {
    return '$title dashboard shortcut';
  }

  @override
  String get dashboardShortcutMembersTitle => 'Members';

  @override
  String get dashboardShortcutFrontHistoryTitle => 'Front History';

  @override
  String get dashboardShortcutCustomFrontsTitle => 'Custom Fronts';

  @override
  String get dashboardShortcutCustomFrontsSubtitle => 'saved states';

  @override
  String get dashboardShortcutGroupsTitle => 'Groups';

  @override
  String get dashboardShortcutNotesTitle => 'Notes';

  @override
  String get dashboardShortcutJournalsTitle => 'Journals';

  @override
  String get dashboardShortcutJournalsSubtitle => 'long entries';

  @override
  String get dashboardShortcutImportExportTitle => 'Import / Export';

  @override
  String get dashboardShortcutImportExportSubtitle => 'local archive';

  @override
  String get dashboardShortcutSyncSubtitle => 'off by default';

  @override
  String get dashboardShortcutCustomizeSubtitle => 'layout and theme';

  @override
  String get dashboardShortcutAnalyticsTitle => 'Analytics';

  @override
  String get dashboardShortcutAnalyticsSubtitle => 'local stats';

  @override
  String get dashboardShortcutRemindersTitle => 'Reminders';

  @override
  String get dashboardShortcutRemindersSubtitle => '0 scheduled';

  @override
  String get dashboardShortcutCustomFieldsTitle => 'Custom Fields';

  @override
  String get dashboardShortcutCustomFieldsSubtitle => 'profile fields';

  @override
  String get dashboardShortcutFriendsSubtitle => 'sync required';

  @override
  String get dashboardShortcutChatTitle => 'Chat';

  @override
  String get dashboardShortcutChatSubtitle => 'offline board';

  @override
  String get dashboardShortcutPollsTitle => 'Polls';

  @override
  String get dashboardShortcutPollsSubtitle => '0 active';

  @override
  String get dashboardShortcutUsefulLinksTitle => 'Useful Links';

  @override
  String get dashboardShortcutUsefulLinksSubtitle => 'help and links';

  @override
  String get dashboardShortcutPrivacyBucketsTitle => 'Privacy Buckets';

  @override
  String get dashboardShortcutPrivacyBucketsSubtitle => 'local visibility';

  @override
  String get dashboardShortcutTokensTitle => 'Tokens';

  @override
  String get dashboardShortcutTokensSubtitle => 'sync later';

  @override
  String get dashboardShortcutUserReportTitle => 'User Report';

  @override
  String get dashboardShortcutUserReportSubtitle => 'diagnostics';

  @override
  String get dashboardShortcutNotificationHistoryTitle =>
      'Notification History';

  @override
  String get dashboardShortcutNotificationHistorySubtitle => 'local log';

  @override
  String get dashboardShortcutHowtosTitle => 'How-to\'s';

  @override
  String get dashboardShortcutHowtosSubtitle => 'offline guides';

  @override
  String get dashboardShortcutAccountSettingsTitle => 'Account Settings';

  @override
  String get dashboardShortcutAccountSettingsSubtitle => 'local profile';

  @override
  String frontHistoryCountSubtitle(int count) {
    return '$count entries';
  }

  @override
  String groupCountSubtitle(int count) {
    return '$count groups';
  }

  @override
  String noteCountSubtitle(int count) {
    return '$count notes';
  }

  @override
  String get serverAccountsUnavailable =>
      'Server accounts are unavailable in this app session.';

  @override
  String get optionalServerAccountTitle => 'Optional server account';

  @override
  String get serverConnectDescription =>
      'Connect an HTTPS server to use encrypted online backups and account features. Local use stays independent.';

  @override
  String get serverUrlLabel => 'Server URL';

  @override
  String get connectServerButton => 'Check and connect';

  @override
  String get connectedServerFallback => 'Connected server';

  @override
  String get signInButton => 'Sign in';

  @override
  String get createAccountButton => 'Create account';

  @override
  String get disconnectButton => 'Disconnect';

  @override
  String get accountFallback => 'Account';

  @override
  String get thisDeviceLabel => 'This device';

  @override
  String get activeServerSessionLabel => 'Active server session';

  @override
  String get revokeSessionTooltip => 'Revoke session';

  @override
  String get securityHistoryTitle => 'Security history';

  @override
  String get securityHistoryDescription =>
      'Recent security-sensitive account actions. This history never includes IP addresses, email addresses, device names, tokens, backup names, or archive content.';

  @override
  String get securityHistoryEmpty => 'No security actions recorded yet.';

  @override
  String get securityEventSignedOut => 'A device signed out';

  @override
  String get securityEventPasswordChanged => 'Password changed';

  @override
  String get securityEventSessionRevoked => 'A device session was revoked';

  @override
  String get securityEventBackupRecoveryStarted =>
      'Encrypted backup recovery started';

  @override
  String get securityEventBackupDeleted => 'Encrypted backup deleted';

  @override
  String get securityEventAccountDeleted => 'Server account deleted';

  @override
  String get securityEventUnknown => 'Security action recorded';

  @override
  String get refreshButton => 'Refresh';

  @override
  String get signOutButton => 'Sign out';

  @override
  String get deleteServerAccountButton => 'Delete server account';

  @override
  String get deleteServerAccountTitle => 'Delete server account?';

  @override
  String get deleteServerAccountBody =>
      'This permanently removes server sessions, friend data, and uploaded encrypted backups. Local app data stays on this device.';

  @override
  String get currentPasswordLabel => 'Current password';

  @override
  String get changePasswordButton => 'Change password';

  @override
  String get changePasswordTitle => 'Change server password';

  @override
  String get newPasswordLabel => 'New password';

  @override
  String get confirmNewPasswordLabel => 'Confirm new password';

  @override
  String get passwordsDoNotMatchError => 'Passwords do not match.';

  @override
  String get passwordChangedMessage =>
      'Password changed. Other device sessions were signed out.';

  @override
  String get deleteAccountButton => 'Delete account';

  @override
  String get createServerAccountTitle => 'Create server account';

  @override
  String get displayNameLabel => 'Display name';

  @override
  String get emailLabel => 'Email';

  @override
  String get invalidEmailError => 'Enter a valid email address.';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordLengthError => 'Use at least 12 characters.';

  @override
  String get deviceNameLabel => 'Device name';

  @override
  String get requiredFieldError => 'This field is required.';

  @override
  String get onlineBackupUnavailable =>
      'Online backup is unavailable in this app session.';

  @override
  String get encryptedOnlineBackupTitle => 'Encrypted online backup';

  @override
  String get backupEncryptionDescription =>
      'Snapshots are encrypted on this device before upload.';

  @override
  String get backupSignInDescription =>
      'Connect and sign in from Account Settings first.';

  @override
  String get backupUploadProgressLabel => 'Encrypted backup upload progress';

  @override
  String backupUploadProgressValue(int completed, int total) {
    return '$completed of $total chunks';
  }

  @override
  String get createUploadSnapshotButton => 'Create and upload snapshot';

  @override
  String backupSnapshotProgress(
    int uploadedChunks,
    int chunkCount,
    int uploadedBytes,
    int totalBytes,
  ) {
    return '$uploadedChunks/$chunkCount chunks, $uploadedBytes/$totalBytes bytes';
  }

  @override
  String get deleteEncryptedBackupTooltip => 'Delete encrypted backup';

  @override
  String get deleteEncryptedBackupTitle => 'Delete encrypted backup?';

  @override
  String get deleteEncryptedBackupBody =>
      'This server copy will be permanently removed.';

  @override
  String get friendsSignInBody =>
      'Connect and sign in to a server from Account Settings first.';

  @override
  String get localDataLabel => 'Local data';

  @override
  String get notSharedValue => 'not shared';

  @override
  String get requestsLabel => 'Requests';

  @override
  String get offValue => 'off';

  @override
  String get friendsDisabledBody =>
      'This server has friend connections disabled.';

  @override
  String get serverDisabledValue => 'server disabled';

  @override
  String get friendCodeTitle => 'Friend code';

  @override
  String get rotateFriendCodePrompt => 'Rotate to create a new code';

  @override
  String get rotateFriendCodeButton => 'Rotate friend code';

  @override
  String get someoneElsesCodeLabel => 'Someone else’s code';

  @override
  String get sendRequestButton => 'Send request';

  @override
  String get pendingRequestsTitle => 'Pending requests';

  @override
  String get noPendingRequests => 'No pending requests.';

  @override
  String get acceptRequestTooltip => 'Accept request';

  @override
  String get declineRequestTooltip => 'Decline request';

  @override
  String get cancelRequestTooltip => 'Cancel request';

  @override
  String get noFriendsYet => 'No friends yet.';

  @override
  String get nothingShared => 'Nothing shared';

  @override
  String permissionsShared(int count) {
    return '$count permissions shared';
  }

  @override
  String get removeFriendTitle => 'Remove friend?';

  @override
  String get removeFriendBody =>
      'The friendship and its sharing permissions will be removed.';

  @override
  String blockUserTitle(String displayName) {
    return 'Block $displayName?';
  }

  @override
  String get blockUserBody =>
      'This removes the friendship, pending requests, and every sharing permission in both directions.';

  @override
  String get sharingPermissionsLabel => 'Sharing permissions';

  @override
  String get removeFriendButton => 'Remove friend';

  @override
  String get blockUserButton => 'Block user';

  @override
  String get blockedUsersTitle => 'Blocked users';

  @override
  String get noBlockedUsers => 'No blocked users.';

  @override
  String get unblockButton => 'Unblock';

  @override
  String shareWithTitle(String displayName) {
    return 'Share with $displayName';
  }

  @override
  String get saveButtonLabel => 'Save';

  @override
  String get friendGrantCurrentFront => 'Current front';

  @override
  String get friendGrantMemberList => 'Member list';

  @override
  String get friendGrantMemberDetails => 'Member details';

  @override
  String get friendGrantFrontHistory => 'Front history';

  @override
  String get friendGrantGroups => 'Groups';

  @override
  String get friendGrantNotes => 'Notes';

  @override
  String get friendGrantPolls => 'Polls';

  @override
  String get remindersTitle => 'Reminders';

  @override
  String get noRemindersYetTitle => 'No reminders yet';

  @override
  String get noRemindersYetBody =>
      'Create a daily, weekly, or monthly notification reminder.';

  @override
  String get addReminderButton => 'Add reminder';

  @override
  String get notificationSettingsButton => 'Notification settings';

  @override
  String get onStatus => 'on';

  @override
  String reminderSemanticLabel(String title) {
    return 'Reminder $title';
  }

  @override
  String get deleteReminderTooltip => 'Delete reminder';

  @override
  String get deleteReminderTitle => 'Delete reminder?';

  @override
  String get deleteReminderBody => 'This reminder will be permanently removed.';

  @override
  String get dailySchedule => 'Daily';

  @override
  String get weeklySchedule => 'Weekly';

  @override
  String get monthlySchedule => 'Monthly';

  @override
  String get afterFrontSchedule => 'After member fronts';

  @override
  String get titleFieldLabel => 'Title';

  @override
  String get scheduleFieldLabel => 'Schedule';

  @override
  String get dayFieldLabel => 'Day';

  @override
  String get dayOfMonthFieldLabel => 'Day of month';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String get memberOrFrontLabel => 'Member or front label';

  @override
  String get memberOrFrontHelper => 'Queued until this member or label fronts';

  @override
  String get afterFrontTargetLabel => 'Who should trigger it?';

  @override
  String get afterFrontTargetHelper =>
      'Choose one member, or trigger for any newly started front.';

  @override
  String get anyFrontStartsOption => 'Any front starts';

  @override
  String get timeFieldLabel => 'Time';

  @override
  String get timeFieldHelper => '24-hour local time, like 09:00';

  @override
  String get noteFieldLabel => 'Note';

  @override
  String dailyScheduleAt(String time) {
    return 'Daily at $time';
  }

  @override
  String weeklyScheduleAt(String weekday, String time) {
    return 'Weekly on $weekday at $time';
  }

  @override
  String monthlyScheduleAt(int day, String time) {
    return 'Monthly on day $day at $time';
  }

  @override
  String get afterSelectedFrontStarts => 'After a selected front starts';

  @override
  String afterFrontLabel(String detail) {
    return 'After $detail fronts';
  }

  @override
  String get importTitle => 'Import';

  @override
  String get previewFirstStatus => 'preview first';

  @override
  String get preparingImportPreviewStatus => 'Preparing import preview...';

  @override
  String get importDescription =>
      'Upload an export, check what was found, then import it into local storage.';

  @override
  String get exportTitle => 'Export';

  @override
  String get exportLocalArchiveTitle => 'Export local archive';

  @override
  String get portableJsonValue => 'portable JSON';

  @override
  String get encryptedExportTitle => 'Encrypted export';

  @override
  String get passwordProtectedFileValue => 'password protected file';

  @override
  String get backupFolderTitle => 'Backup folder';

  @override
  String get manualArchiveSaveValue => 'manual save from archive sheet';

  @override
  String get waitingForFilePicker => 'Waiting for file picker...';

  @override
  String get chooseImportFileTitle => 'Choose import file';

  @override
  String get noFileSelected => 'No file selected.';

  @override
  String readingFileStatus(String fileName) {
    return 'Reading $fileName...';
  }

  @override
  String couldNotReadImportFile(String fileName) {
    return 'Could not read an import JSON from $fileName.';
  }

  @override
  String get couldNotOpenFilePicker => 'Could not open the file picker.';

  @override
  String get importFileEmpty => 'The selected import file is empty.';

  @override
  String get importFileTooLarge =>
      'The import file is larger than the 32 MiB safety limit. If this is a legitimate export, report it so the limit can be reviewed.';

  @override
  String get importFileInvalidUtf8 =>
      'The import file is not valid UTF-8 text.';

  @override
  String get importFileInvalidZip =>
      'The selected ZIP file is invalid or damaged.';

  @override
  String get importZipTooManyEntries =>
      'The ZIP contains too many entries to import safely. If this is a legitimate export, report it so the limit can be reviewed.';

  @override
  String get importZipExpansionTooLarge =>
      'The ZIP expands beyond the safe import limit. If this is a legitimate export, report it so the limit can be reviewed.';

  @override
  String get importZipUnsupported =>
      'The ZIP contains no supported JSON or avatar files.';

  @override
  String get reportImportIssueButton => 'Report import issue';

  @override
  String get couldNotReadPastedJson => 'Could not read the pasted JSON.';

  @override
  String get exportJsonLabel => 'Export JSON';

  @override
  String get pasteJsonSizeHelp =>
      'Paste up to 256 KiB. Choose a file for larger exports.';

  @override
  String get previewPastedJson => 'Preview pasted JSON';

  @override
  String get waitingForAvatarZip => 'Waiting for avatar ZIP...';

  @override
  String get chooseAvatarZipTitle => 'Choose avatar ZIP';

  @override
  String get noAvatarFileSelected => 'No avatar file selected.';

  @override
  String readingAvatarsStatus(String fileName) {
    return 'Reading avatars from $fileName...';
  }

  @override
  String noAvatarsFoundStatus(String fileName) {
    return 'No avatar images found in $fileName.';
  }

  @override
  String avatarsAttachedStatus(int count, String fileName, String nextStep) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count avatars',
      one: '1 avatar',
    );
    return 'Attached $_temp0 from $fileName. $nextStep';
  }

  @override
  String get chooseJsonNext => 'Choose the JSON export next.';

  @override
  String get refreshOrImportNext => 'Refresh or import when ready.';

  @override
  String get encryptedArchiveLoaded =>
      'Encrypted archive loaded. Enter its passphrase, then preview.';

  @override
  String previewReadyStatus(String summary) {
    return 'Preview ready: $summary.';
  }

  @override
  String get chooseFileBeforePreview =>
      'Choose or paste a file before previewing.';

  @override
  String get decryptArchiveFailed =>
      'Could not decrypt archive. Check the passphrase.';

  @override
  String get fetchingPluralKitData => 'Fetching PluralKit data...';

  @override
  String pluralKitImportFailed(String error) {
    return 'PluralKit import failed: $error';
  }

  @override
  String get chooseFileBeforeRehearsal =>
      'Choose or paste a file before rehearsing restore.';

  @override
  String get rehearsingRestoreStatus =>
      'Rehearsing restore in a temporary local database...';

  @override
  String restoreRehearsalPassedStatus(String summary) {
    return 'Restore rehearsal passed: $summary.';
  }

  @override
  String get restoreRehearsalFailedStatus =>
      'Restore rehearsal failed. Nothing was imported.';

  @override
  String preparingImportStatus(String source) {
    return 'Preparing $source import...';
  }

  @override
  String writingImportStatus(String summary) {
    return 'Writing $summary...';
  }

  @override
  String get importCancelledStatus => 'Import cancelled.';

  @override
  String importingStatus(String summary) {
    return 'Importing $summary...';
  }

  @override
  String importCompleteStatus(String summary) {
    return 'Import complete: $summary.';
  }

  @override
  String get importFailedJobsStatus =>
      'Import failed. Check recent jobs below.';

  @override
  String importFailedStatus(String error) {
    return 'Import failed: $error';
  }

  @override
  String sourceImportComplete(String source) {
    return '$source import complete';
  }

  @override
  String get enterExportPassphrase => 'Enter the export passphrase first.';

  @override
  String get importSetupTitle => 'Import setup';

  @override
  String get uploadFileButton => 'Upload file';

  @override
  String get chooseAnotherFileButton => 'Choose another file';

  @override
  String get pasteJsonTooltip => 'Paste JSON';

  @override
  String get attachAvatarsButton => 'Attach avatars';

  @override
  String avatarsAttachedButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count avatars attached',
      one: '1 avatar attached',
    );
    return '$_temp0';
  }

  @override
  String get serviceFieldLabel => 'Service';

  @override
  String get matchStrategyFieldLabel => 'When a match exists';

  @override
  String get pluralKitTokenHelper =>
      'Used for this fetch only. It is not saved or logged.';

  @override
  String get passphraseFieldLabel => 'Passphrase';

  @override
  String get importPassphraseHelper =>
      'Used locally to decrypt the preview and import.';

  @override
  String get retainRawImportPayloadsTitle => 'Keep original source collections';

  @override
  String get retainRawImportPayloadsDescription =>
      'Keeps encrypted copies of unsupported source collections for future export or debugging. Leave off to import only mapped records.';

  @override
  String get inputLabel => 'Input';

  @override
  String get jobLabel => 'Job';

  @override
  String get dedupeLabel => 'Dedupe';

  @override
  String get previewImportButton => 'Preview import';

  @override
  String get refreshPreviewButton => 'Refresh preview';

  @override
  String get chooseServiceStatus => 'Choose service';

  @override
  String serviceDetectedStatus(String service) {
    return '$service detected';
  }

  @override
  String get waitingForDetection => 'waiting for detection';

  @override
  String get importSourcePlurisHavenArchive => 'Pluris Haven archive';

  @override
  String get importSourceSimplyPlural => 'Simply Plural';

  @override
  String get importSourcePluralKitFile => 'PluralKit file';

  @override
  String get importSourcePluralKitLive => 'PluralKit live';

  @override
  String get importSourceTupperbox => 'Tupperbox';

  @override
  String get importSourcePluralSpace => 'PluralSpace';

  @override
  String get importSourcePrism => 'Prism';

  @override
  String get importInputFile => 'File';

  @override
  String get importInputLiveToken => 'Live token';

  @override
  String get importInputEncryptedFile => 'Encrypted file';

  @override
  String get importDedupePlurisHaven =>
      'local IDs, PluralKit IDs, normalized names';

  @override
  String get importDedupeSimplyPlural =>
      'Simply Plural IDs, PluralKit IDs, normalized names';

  @override
  String get importDedupePluralKitFile =>
      'PluralKit UUIDs, PluralKit short IDs, normalized names';

  @override
  String get importDedupePluralKitLive =>
      'PluralKit UUIDs, PluralKit short IDs';

  @override
  String get importDedupeTupperbox => 'Tupperbox IDs, normalized names';

  @override
  String get importDedupePluralSpace => 'PluralSpace IDs, normalized names';

  @override
  String get importDedupePrism => 'Prism IDs, normalized names';

  @override
  String get importConflictPrompt => 'Ask for each match';

  @override
  String get importConflictCreate => 'Create new records';

  @override
  String get importConflictSkip => 'Skip existing matches';

  @override
  String get importConflictUpdate => 'Update existing matches';

  @override
  String get importPlanStatusReady => 'ready';

  @override
  String get importPlanStatusNext => 'next';

  @override
  String get importPlanStatusPlanned => 'planned';

  @override
  String importPlanTitle(String source) {
    return '$source plan';
  }

  @override
  String get importPlanOfflinePreview => 'offline preview';

  @override
  String get importPlanNeedsNetwork => 'needs network';

  @override
  String get importReasonPrismExtension => '.prism file extension';

  @override
  String get importReasonPlurisFileName =>
      'filename looks like a Pluris Haven archive';

  @override
  String get importReasonSimplyPluralFileName =>
      'filename looks like a Simply Plural export';

  @override
  String get importReasonPluralKitFileName =>
      'filename looks like a PluralKit export';

  @override
  String get importReasonTupperboxFileName =>
      'filename looks like a Tupperbox export';

  @override
  String get importReasonPluralSpaceFileName =>
      'filename looks like a PluralSpace export';

  @override
  String get importReasonChooseAfterUpload => 'pick a service after upload';

  @override
  String get importReasonEncryptedPlurisArchive =>
      'file is an encrypted Pluris Haven archive';

  @override
  String get importReasonLocalPlurisArchive =>
      'file is a Pluris Haven local archive';

  @override
  String get importReasonTupperboxFields =>
      'file contains Tupperbox-style roster fields';

  @override
  String get importReasonPluralKitFields =>
      'file contains PluralKit-style members and switches';

  @override
  String get importReasonSimplyPluralFields =>
      'file contains Simply Plural fronting fields';

  @override
  String get importReasonPluralSpaceMarkers =>
      'file contains PluralSpace markers';

  @override
  String get importReasonAmbiguousMemberGroupJson =>
      'member/group JSON found, choose the source to confirm';

  @override
  String get importReasonUnrecognised => 'could not recognize this file yet';

  @override
  String get importCountMembers => 'members';

  @override
  String get importCountGroups => 'groups';

  @override
  String get importCountNotes => 'notes';

  @override
  String get importCountJournals => 'journals';

  @override
  String get importCountMessages => 'messages';

  @override
  String get importCountReminders => 'reminders';

  @override
  String get importCountTags => 'tags';

  @override
  String get importCountCustomFields => 'custom fields';

  @override
  String get importCountPolls => 'polls';

  @override
  String get importCountFrontHistory => 'front history';

  @override
  String get importCountNotifications => 'notifications';

  @override
  String get importCountPreferences => 'preferences';

  @override
  String get importCountCustomFronts => 'custom fronts';

  @override
  String get importCountSwitches => 'switches';

  @override
  String get importCountFrontIntervals => 'front intervals';

  @override
  String get importCountTuppers => 'tuppers';

  @override
  String get importCountAvatars => 'avatars';

  @override
  String get importCountFronts => 'fronts';

  @override
  String get importStepReadArchiveTitle => 'Read archive';

  @override
  String get importStepReadPlurisArchiveDetail =>
      'Accept a Pluris Haven local archive JSON export.';

  @override
  String get importStepValidateFormatTitle => 'Validate format';

  @override
  String get importStepValidatePlurisArchiveDetail =>
      'Require format pluris_haven.local_archive and a supported version.';

  @override
  String get importStepReviewContentsTitle => 'Review contents';

  @override
  String get importStepReviewPlurisArchiveDetail =>
      'Show local members, groups, journals, notes, fronts, tags, polls, and preferences before writing.';

  @override
  String get importStepRestoreLocallyTitle => 'Restore locally';

  @override
  String get importStepRestorePlurisArchiveDetail =>
      'Apply selected records and keep an import record for future dedupe.';

  @override
  String get importStepReadExportTitle => 'Read export';

  @override
  String get importStepReadSimplyPluralDetail =>
      'Accept a Simply Plural JSON export or backup archive.';

  @override
  String get importStepNormalizeFieldsTitle => 'Normalize fields';

  @override
  String get importStepNormalizeSimplyPluralDetail =>
      'Map members, groups, custom fields, custom fronts, and notes into local records.';

  @override
  String get importStepPrepareAvatarsTitle => 'Prepare avatars';

  @override
  String get importStepPrepareSimplyPluralAvatarsDetail =>
      'Use attached avatar ZIP bytes first, then keep or localize remote avatar URLs during import.';

  @override
  String get importStepReviewMatchesTitle => 'Review matches';

  @override
  String get importStepReviewSimplyPluralDetail =>
      'Show creates, skips, and updates before writing.';

  @override
  String get importStepWriteLocallyTitle => 'Write locally';

  @override
  String get importStepWriteSimplyPluralDetail =>
      'Save records and keep an import record for future dedupe.';

  @override
  String get importStepReadPluralKitFileDetail =>
      'Accept a PluralKit JSON export file.';

  @override
  String get importStepBuildRosterTitle => 'Build roster';

  @override
  String get importStepBuildPluralKitRosterDetail =>
      'Stage members, groups, avatars, descriptions, and proxy metadata.';

  @override
  String get importStepConvertSwitchesTitle => 'Convert switches';

  @override
  String get importStepConvertPluralKitSwitchesDetail =>
      'Turn PK switches into local front history.';

  @override
  String get importStepReviewPluralKitFileDetail =>
      'Dedupe by PK UUID, short ID, then normalized name.';

  @override
  String get importStepValidateTokenTitle => 'Validate token';

  @override
  String get importStepValidatePluralKitTokenDetail =>
      'Call GET /systems/@me with the token as Authorization.';

  @override
  String get importStepFetchRosterTitle => 'Fetch roster';

  @override
  String get importStepFetchPluralKitRosterDetail =>
      'Read members and groups from the PluralKit API.';

  @override
  String get importStepFetchSwitchesTitle => 'Fetch switches';

  @override
  String get importStepFetchPluralKitSwitchesDetail =>
      'Page switches with a delay to avoid rate limits.';

  @override
  String get importStepReviewPluralKitLiveDetail =>
      'Dedupe by PK UUID and short ID before saving.';

  @override
  String get importStepReadRosterTitle => 'Read roster';

  @override
  String get importStepReadTupperboxDetail => 'Accept a Tupperbox export file.';

  @override
  String get importStepMapTuppersTitle => 'Map tuppers';

  @override
  String get importStepMapTupperboxDetail =>
      'Convert tuppers to members with names, avatars, brackets, and descriptions.';

  @override
  String get importStepReviewTupperboxDetail =>
      'Dedupe by Tupperbox ID, then normalized name.';

  @override
  String get importStepReadPluralSpaceDetail =>
      'Accept a PluralSpace export file.';

  @override
  String get importStepMapRecordsTitle => 'Map records';

  @override
  String get importStepMapPluralSpaceDetail =>
      'Stage members, groups, notes, and fronting data when present.';

  @override
  String get importStepReviewPluralSpaceDetail =>
      'Dedupe by source ID, then normalized name.';

  @override
  String get importStepChoosePrismTitle => 'Choose .prism file';

  @override
  String get importStepChoosePrismDetail => 'Accept an encrypted Prism export.';

  @override
  String get importStepDecryptPreviewTitle => 'Decrypt preview';

  @override
  String get importStepDecryptPrismDetail =>
      'Use the passphrase locally and avoid storing it.';

  @override
  String get importStepReviewPrismDetail =>
      'Dedupe by Prism ID, then normalized name.';

  @override
  String get importPrivacyPreviewBeforeWrite =>
      'Preview happens before records are saved.';

  @override
  String get importPrivacyLocalBackupRestore =>
      'This is the backup and restore path for local data.';

  @override
  String get importPrivacySimplyPluralDedupe =>
      'Re-imports match by Simply Plural ID, PluralKit ID, then normalized name.';

  @override
  String get importPrivacySimplyPluralAvatars =>
      'Avatar ZIPs stay offline. Remote avatar URLs may be fetched during import so they can be stored locally.';

  @override
  String get importPrivacyPluralKitIdentifiers =>
      'PluralKit IDs are kept as import identifiers for dedupe and optional sync.';

  @override
  String get importPrivacyPluralKitSwitches =>
      'Switch logs become local front history intervals.';

  @override
  String get importPrivacyPluralKitTokenEphemeral =>
      'The pk;token is used for the import request only.';

  @override
  String get importPrivacyPluralKitLiveNetwork =>
      'Live import needs network access, but the preview and write still happen locally.';

  @override
  String get importPrivacyTupperboxIdentifiers =>
      'Tupperbox IDs are retained only for dedupe and future re-imports.';

  @override
  String get importPrivacyTupperboxProxyMetadata =>
      'Proxy patterns can be imported later as optional metadata.';

  @override
  String get importPrivacyPluralSpaceIdentifiers =>
      'PluralSpace source IDs are kept as import identifiers.';

  @override
  String get importPrivacyPluralSpaceUnknownFields =>
      'Unknown fields are kept in the preview until a mapper exists.';

  @override
  String get importPrivacyPrismPassphraseMemoryOnly =>
      'The passphrase is only used to decrypt the import in memory.';

  @override
  String get importPrivacyPrismIdentifiers =>
      'Prism source IDs are kept for re-import dedupe.';

  @override
  String get importStageParse => 'parse';

  @override
  String get importStageDecrypt => 'decrypt';

  @override
  String get importStageValidate => 'validate';

  @override
  String get importStagePreview => 'preview';

  @override
  String get importStageNormalize => 'normalize';

  @override
  String get importStagePreserve => 'preserve';

  @override
  String get importStageAvatars => 'avatars';

  @override
  String importDiagnosticJsonParseFailed(String error) {
    return 'Could not parse JSON: $error';
  }

  @override
  String get importDiagnosticExpectedTopLevelObject =>
      'Expected a JSON object at the top level.';

  @override
  String get importDiagnosticPrismNeedsDecryption =>
      'Prism preview needs encrypted file decryption first.';

  @override
  String get importDiagnosticNotPlurisArchive =>
      'This is not a Pluris Haven local archive.';

  @override
  String importDiagnosticUnsupportedArchiveVersion(String version) {
    return 'Unsupported archive version: $version.';
  }

  @override
  String importDiagnosticFoundMembersAndFronts(int members, int fronts) {
    return 'Found $members members and $fronts fronts.';
  }

  @override
  String get importDiagnosticRecognizedRecords =>
      'Recognized records can be imported into the local archive.';

  @override
  String get importDiagnosticNoImportableRecords =>
      'No importable records were recognized.';

  @override
  String importDiagnosticPreservedRawPayloads(int count, String collections) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count original source collections',
      one: '1 original source collection',
    );
    return 'Preserved $_temp0 as raw payloads for export/debug$collections. Mapped records still import normally; raw copies do not create notes, messages, or members.';
  }

  @override
  String importDiagnosticCollectionNames(String names) {
    return ': $names';
  }

  @override
  String importDiagnosticCollectionNamesWithMore(String names, int count) {
    return ': $names, +$count more';
  }

  @override
  String get importDiagnosticRemoteAvatarsWithoutZip =>
      'Avatar links may be downloaded during import so they can be kept locally. Attach the Simply Plural avatar ZIP to avoid remote avatar fetches.';

  @override
  String importDiagnosticBestEffort(String source) {
    return '$source import is best-effort. Review after import.';
  }

  @override
  String importDiagnosticSkippedExpectedObject(String record, int index) {
    return 'Skipped $record #$index: expected an object.';
  }

  @override
  String importDiagnosticSkippedMissingFields(
    String record,
    int index,
    String fields,
  ) {
    return 'Skipped $record #$index: missing $fields.';
  }

  @override
  String importDiagnosticIgnoredMissingRelation(
    String ownerKind,
    String owner,
    String relationKind,
    String relation,
  ) {
    return '$ownerKind \"$owner\" ignored missing $relationKind \"$relation\".';
  }

  @override
  String importDiagnosticIgnoredSelfParent(String group) {
    return 'Group \"$group\" ignored itself as its parent.';
  }

  @override
  String importDiagnosticReminderMissingMember(int index) {
    return 'Reminder #$index references a member that was not imported; the reminder was disabled.';
  }

  @override
  String importDiagnosticPollTooFewOptions(String question) {
    return 'Skipped poll \"$question\": fewer than two usable options.';
  }

  @override
  String importDiagnosticIgnoredMissingReference(
    String record,
    String relation,
    String value,
  ) {
    return 'Ignored missing $relation reference \"$value\" in $record.';
  }

  @override
  String importDiagnosticFrontReversed(int index) {
    return 'Front #$index ended before it started; swapped start and end.';
  }

  @override
  String importDiagnosticStringClamped(int count, String field, int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ${field}s will be shortened',
      one: '1 $field will be shortened',
    );
    return '$_temp0 to $limit characters.';
  }

  @override
  String importDiagnosticListClamped(int count, String field, int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ${field}s will be trimmed',
      one: '1 $field will be trimmed',
    );
    return '$_temp0 to $limit entries.';
  }

  @override
  String get previewTitle => 'Preview';

  @override
  String get validShapeStatus => 'valid shape';

  @override
  String get needsAttentionStatus => 'needs attention';

  @override
  String get noRecordsFound => 'no records found';

  @override
  String get rehearsingButton => 'Rehearsing...';

  @override
  String get runRestoreRehearsalButton => 'Run restore rehearsal';

  @override
  String get importingButton => 'Importing...';

  @override
  String get importArchiveButton => 'Import archive';

  @override
  String get restoreRehearsalPassed => 'Restore rehearsal passed';

  @override
  String get restoreRehearsalFailed => 'Restore rehearsal failed';

  @override
  String get restoreRehearsalPassedBody =>
      'Imported into a temporary local database. Nothing was written to your app data.';

  @override
  String get restoreRehearsalFailedBody =>
      'The archive could not be restored safely.';

  @override
  String restoreStatusSemanticLabel(String title, String body, String counts) {
    return 'Restore status: $title. $body$counts';
  }

  @override
  String get importReadyStatus => 'Import ready.';

  @override
  String importStatusSemanticLabel(String status) {
    return 'Import status: $status';
  }

  @override
  String get recentJobsTitle => 'Recent jobs';

  @override
  String get noneStatus => 'none';

  @override
  String get noImportsQueued => 'No imports queued yet.';

  @override
  String get tapForDetails => 'tap for details';

  @override
  String importJobSemanticLabel(String title, String status) {
    return 'Import job $title, $status. Double tap for details.';
  }

  @override
  String get encryptedArchiveLockedPreview =>
      'Enter the export passphrase, then preview the archive.';

  @override
  String couldNotDecryptArchive(String error) {
    return 'Could not decrypt archive: $error';
  }

  @override
  String get conflictsFoundTitle => 'Conflicts found';

  @override
  String memberConflictCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String groupConflictCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count groups',
      one: '1 group',
    );
    return '$_temp0';
  }

  @override
  String get listAnd => ' and ';

  @override
  String importConflictsBody(String conflicts, String source) {
    return '$conflicts from this $source import already exist in your local data.\n\nHow should Pluris Haven handle them?';
  }

  @override
  String get skipMatchesButton => 'Skip matches';

  @override
  String get createDuplicatesButton => 'Create duplicates';

  @override
  String get updateExistingButton => 'Update existing';

  @override
  String get encryptedExportDescription =>
      'Saves an encrypted archive protected by a recovery code generated on this device. The code is not stored, so a lost code cannot be recovered.';

  @override
  String get generatedRecoveryCodeFieldLabel => 'Generated recovery code';

  @override
  String get confirmRecoveryCodeFieldLabel => 'Re-enter recovery code';

  @override
  String get generateRecoveryCodeButton => 'Generate recovery code';

  @override
  String get generateRecoveryCodeFirst => 'Generate a recovery code first.';

  @override
  String get generatedRecoveryCodeStatus =>
      'Generated locally with 192 bits of randomness. Save it in your password manager, then re-enter it below. Pluris Haven cannot recover it.';

  @override
  String get showRecoveryCodeTooltip => 'Show recovery code';

  @override
  String get hideRecoveryCodeTooltip => 'Hide recovery code';

  @override
  String encryptedExportStatusSemanticLabel(String status) {
    return 'Encrypted export status: $status';
  }

  @override
  String get encryptingArchiveButton => 'Encrypting...';

  @override
  String get saveEncryptedFileButton => 'Save encrypted file';

  @override
  String get recoveryCodesDoNotMatch => 'Recovery codes do not match.';

  @override
  String get buildingArchiveStatus => 'Building archive...';

  @override
  String get encryptingArchiveStatus => 'Encrypting archive...';

  @override
  String get saveEncryptedArchiveDialogTitle =>
      'Save encrypted Pluris Haven archive';

  @override
  String get encryptedArchiveSaved => 'Encrypted archive saved.';

  @override
  String get saveCancelled => 'Save cancelled.';

  @override
  String couldNotSaveEncryptedArchive(String error) {
    return 'Could not save encrypted archive: $error';
  }

  @override
  String get localArchiveTitle => 'Local archive';

  @override
  String get localArchiveDescription =>
      'Unencrypted JSON export for backup or migration. It includes local members, groups, journals, notes, fronts, tags, polls, custom fields, and app preferences.';

  @override
  String get buildingLocalArchiveSemanticLabel =>
      'Building local archive. Please wait.';

  @override
  String get buildingLocalArchiveStatus => 'Building local archive...';

  @override
  String archiveErrorSemanticLabel(String error) {
    return 'Archive error: $error';
  }

  @override
  String couldNotBuildArchive(String error) {
    return 'Could not build archive: $error';
  }

  @override
  String get saveJsonFileButton => 'Save JSON file';

  @override
  String get copyJsonButton => 'Copy JSON';

  @override
  String get copyPlainArchiveWarningTitle => 'Copy unencrypted archive?';

  @override
  String get copyPlainArchiveWarningBody =>
      'This archive contains your local data in plain text. Clipboard history, keyboards, and other apps may retain it. Save an encrypted file instead if you need to keep it private.';

  @override
  String get copyPlainArchiveConfirmButton => 'Copy unencrypted archive';

  @override
  String get savePlainArchiveWarningTitle => 'Save unencrypted archive?';

  @override
  String get savePlainArchiveWarningBody =>
      'Anyone who gets this file can read your local data. Save an encrypted file instead if you need to keep it private.';

  @override
  String get savePlainArchiveConfirmButton => 'Save unencrypted archive';

  @override
  String get archiveCopied => 'Archive copied';

  @override
  String get saveArchiveDialogTitle => 'Save Pluris Haven archive';

  @override
  String get archiveSaved => 'Archive saved';

  @override
  String couldNotSaveArchive(String error) {
    return 'Could not save archive: $error';
  }

  @override
  String get typeFieldLabel => 'Type';

  @override
  String get sourceFieldLabel => 'Source';

  @override
  String get createdFieldLabel => 'Created';

  @override
  String get updatedFieldLabel => 'Updated';

  @override
  String get noJobErrorRecorded => 'No error recorded for this job.';

  @override
  String get errorTitle => 'Error';

  @override
  String get fullErrorCopied => 'Full error copied';

  @override
  String get copyFullButton => 'Copy full';

  @override
  String get jobErrorPreviewTruncated =>
      'Showing a safe preview. The full error is too large to render here.';

  @override
  String truncatedCharacters(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count characters',
      one: '1 character',
    );
    return '...truncated $_temp0';
  }

  @override
  String get searchNotesHint => 'Search notes';

  @override
  String get notesTitle => 'Notes';

  @override
  String get allFilter => 'All';

  @override
  String get memberFilter => 'Member';

  @override
  String get systemFilter => 'System';

  @override
  String get noNotesYet => 'No notes yet';

  @override
  String get noMatchingNotes => 'No matching notes';

  @override
  String get notesEmptyBody =>
      'Local notes can be attached to members or kept general.';

  @override
  String get tryAnotherSearchOrFilter => 'Try another search or filter.';

  @override
  String get addNoteButton => 'Add note';

  @override
  String get deleteNoteTooltip => 'Delete note';

  @override
  String get deleteNoteTitle => 'Delete note?';

  @override
  String get deleteNoteBody => 'This note will be permanently removed.';

  @override
  String get systemNoteLabel => 'System note';

  @override
  String get unknownMemberNoteLabel => 'Unknown member note';

  @override
  String memberNoteLabel(String name) {
    return '$name note';
  }

  @override
  String get editNoteTitle => 'Edit note';

  @override
  String get forFieldLabel => 'For';

  @override
  String get saveNoteButton => 'Save note';

  @override
  String get pollsTitle => 'Polls';

  @override
  String openPollCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count open',
      one: '1 open',
      zero: 'none open',
    );
    return '$_temp0';
  }

  @override
  String get noPollsYet => 'No polls yet';

  @override
  String get pollsEmptyBody => 'Create a local vote for system decisions.';

  @override
  String get createPollButton => 'Create poll';

  @override
  String pollOptionSemanticLabel(String option, String status) {
    return '$option, $status';
  }

  @override
  String get selectedStatus => 'selected';

  @override
  String get notSelectedStatus => 'not selected';

  @override
  String pollSelectionSummary(String kind, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '1 selected',
    );
    return '$kind - $_temp0';
  }

  @override
  String get closeButton => 'Close';

  @override
  String get deletePollTooltip => 'Delete poll';

  @override
  String get deletePollTitle => 'Delete poll?';

  @override
  String get deletePollBody =>
      'This poll and its local responses will be removed.';

  @override
  String get questionFieldLabel => 'Question';

  @override
  String get descriptionFieldLabel => 'Description';

  @override
  String get pollDescriptionHelper => 'Optional context for the vote';

  @override
  String get votingFieldLabel => 'Voting';

  @override
  String pollOptionFieldLabel(int number) {
    return 'Option $number';
  }

  @override
  String get addPollOptionButton => 'Add option';

  @override
  String get savePollButton => 'Save poll';

  @override
  String get singleChoicePollKind => 'Single choice';

  @override
  String get multipleChoicePollKind => 'Multiple choice';

  @override
  String get searchJournalsHint => 'Search journals';

  @override
  String get journalsTitle => 'Journals';

  @override
  String get noJournalEntriesYet => 'No journal entries yet';

  @override
  String get noMatchingJournals => 'No matching journals';

  @override
  String get journalsEmptyBody =>
      'Write longer dated entries here. Use Notes for short scratchpad items.';

  @override
  String get addJournalEntryButton => 'Add journal entry';

  @override
  String get untitledEntry => 'Untitled entry';

  @override
  String get emptyJournal => 'empty journal';

  @override
  String get deleteJournalEntryTooltip => 'Delete journal entry';

  @override
  String get deleteJournalEntryTitle => 'Delete journal entry?';

  @override
  String get deleteJournalEntryBody =>
      'This entry will be permanently removed from this device.';

  @override
  String get editJournalEntryTitle => 'Edit journal entry';

  @override
  String get entryFieldLabel => 'Entry';

  @override
  String get saveEntryButton => 'Save entry';

  @override
  String get createEntryButton => 'Create entry';

  @override
  String get writeBeforeSaving => 'Write something before saving.';

  @override
  String get searchGroupsHint => 'Search groups';

  @override
  String get groupsTitle => 'Groups';

  @override
  String get noGroupsYet => 'No groups yet';

  @override
  String get noMatchingGroups => 'No matching groups';

  @override
  String get groupsEmptyBody =>
      'Groups keep members organised without needing sync.';

  @override
  String get tryAnotherSearch => 'Try another search.';

  @override
  String get addGroupButton => 'Add group';

  @override
  String groupMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String groupSemanticLabel(String name, String members) {
    return '$name, $members';
  }

  @override
  String nestedGroupSemanticLabel(String name, int depth, String members) {
    return '$name, nested group level $depth, $members';
  }

  @override
  String groupAvatarSemanticLabel(String name) {
    return 'Avatar for group $name';
  }

  @override
  String get groupActionsTooltip => 'Group actions';

  @override
  String get deleteGroupTitle => 'Delete group?';

  @override
  String get deleteGroupBody =>
      'Members stay saved. Child groups move up one level.';

  @override
  String get editButton => 'Edit';

  @override
  String get deleteButton => 'Delete';

  @override
  String get editGroupTitle => 'Edit group';

  @override
  String get nameFieldLabel => 'Name';

  @override
  String get emojiFieldLabel => 'Emoji';

  @override
  String get parentGroupFieldLabel => 'Parent group';

  @override
  String get noParentOption => 'No parent';

  @override
  String get colorHexFieldLabel => 'Colour hex';

  @override
  String get subsystemToggleTitle => 'Subgroup / subsystem';

  @override
  String get subsystemToggleBody =>
      'Subsystem members can overlap with the main group.';

  @override
  String get saveChangesButton => 'Save changes';

  @override
  String get saveGroupButton => 'Save group';

  @override
  String get invalidHexColorError => 'Use 6 hex digits, like #F2C75C.';

  @override
  String get purpleColorLabel => 'Purple';

  @override
  String get goldColorLabel => 'Gold';

  @override
  String get tealColorLabel => 'Teal';

  @override
  String get roseColorLabel => 'Rose';

  @override
  String get searchMessagesHint => 'Search messages';

  @override
  String get messagesTitle => 'Messages';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get noMatchingMessages => 'No matching messages';

  @override
  String get messagesEmptyBody => 'Leave local notes for the system here.';

  @override
  String get addMessageButton => 'Add message';

  @override
  String get systemMessageLabel => 'System message';

  @override
  String get unknownSenderLabel => 'Unknown sender';

  @override
  String get unknownMemberLabel => 'Unknown member';

  @override
  String messageMetadata(String sender, String date, String replyMarker) {
    return '$sender - $date$replyMarker';
  }

  @override
  String memberBoardMessageMetadata(
    String board,
    String sender,
    String date,
    String replyMarker,
  ) {
    return '$board board - $sender - $date$replyMarker';
  }

  @override
  String get messageReplyMarker => ' - reply';

  @override
  String get messageActionsTooltip => 'Message actions';

  @override
  String get replyButton => 'Reply';

  @override
  String get deleteMessageTitle => 'Delete message?';

  @override
  String get deleteMessageBody =>
      'This message will be hidden from the local board.';

  @override
  String get editMessageTitle => 'Edit message';

  @override
  String get fromFieldLabel => 'From';

  @override
  String get boardFieldLabel => 'Board';

  @override
  String get systemBoardLabel => 'System board';

  @override
  String get memberBoardLabel => 'Member board';

  @override
  String replyingToMessage(String message) {
    return 'Replying to: $message';
  }

  @override
  String get messageFieldLabel => 'Message';

  @override
  String get saveMessageButton => 'Save message';

  @override
  String get chooseMemberBoardFirst => 'Choose a member board first.';

  @override
  String get offlineStatusPill => 'offline';

  @override
  String get localSystemName => 'Local system';

  @override
  String systemAvatarSemanticLabel(String systemName) {
    return 'System avatar for $systemName';
  }

  @override
  String systemMemberGroupCount(int memberCount, int groupCount) {
    String _temp0 = intl.Intl.pluralLogic(
      memberCount,
      locale: localeName,
      other: '$memberCount members',
      one: '1 member',
    );
    String _temp1 = intl.Intl.pluralLogic(
      groupCount,
      locale: localeName,
      other: '$groupCount groups',
      one: '1 group',
    );
    return '$_temp0 - $_temp1';
  }

  @override
  String get navigationDashboard => 'Dashboard';

  @override
  String get navigationMembers => 'Members';

  @override
  String get navigationFrontHistory => 'Front History';

  @override
  String get navigationCustomFronts => 'Custom Fronts';

  @override
  String get navigationGroups => 'Groups';

  @override
  String get navigationNotes => 'Notes';

  @override
  String get navigationJournals => 'Journals';

  @override
  String get navigationAnalytics => 'Analytics';

  @override
  String get navigationChat => 'Chat';

  @override
  String get navigationPolls => 'Polls';

  @override
  String get navigationFriends => 'Friends';

  @override
  String get navigationUsefulLinks => 'Useful Links';

  @override
  String get navigationReminders => 'Reminders';

  @override
  String get navigationPrivacyBuckets => 'Privacy buckets';

  @override
  String get navigationTokens => 'Tokens';

  @override
  String get navigationUserReport => 'User Report';

  @override
  String get navigationNotificationHistory => 'Notification History';

  @override
  String get navigationHowTos => 'How-tos';

  @override
  String get navigationCustomFields => 'Custom Fields';

  @override
  String get navigationAccountSettings => 'Account Settings';

  @override
  String get navigationImportExport => 'Import / Export';

  @override
  String get navigationSync => 'Sync';

  @override
  String get navigationAppOptions => 'App options';

  @override
  String get navigationAbout => 'About';

  @override
  String get frontingFilter => 'Fronting';

  @override
  String get archivedFilter => 'Archived';

  @override
  String get searchMembersHint => 'Search members';

  @override
  String get noMembersSavedLocally => 'No members saved locally';

  @override
  String get noMatchingMembers => 'No matching members';

  @override
  String get membersEmptyBody =>
      'Add members here or import a Simply Plural export.';

  @override
  String get addMemberButton => 'Add member';

  @override
  String get memberActionsTooltip => 'Member actions';

  @override
  String get deleteMemberTitle => 'Delete member?';

  @override
  String deleteMemberBody(String name) {
    return '$name will be permanently removed from this local system.';
  }

  @override
  String get setFrontButton => 'Set front';

  @override
  String get duplicateButton => 'Duplicate';

  @override
  String get restoreButton => 'Restore';

  @override
  String get archiveButton => 'Archive';

  @override
  String get noPronounsLabel => 'no pronouns';

  @override
  String get archivedStatus => 'archived';

  @override
  String get activeStatus => 'active';

  @override
  String get noDescriptionYet => 'No description yet.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get pronounsFieldLabel => 'Pronouns';

  @override
  String get birthdayFieldLabel => 'Birthday';

  @override
  String get privacyFieldLabel => 'Privacy';

  @override
  String get pluralKitIdFieldLabel => 'PluralKit ID';

  @override
  String get notLinkedLabel => 'not linked';

  @override
  String get avatarFieldLabel => 'Avatar';

  @override
  String get defaultLabel => 'default';

  @override
  String get tagsTitle => 'Tags';

  @override
  String get memberTagsTitle => 'Member tags';

  @override
  String get noneLabel => 'none';

  @override
  String get memberTagsDescription =>
      'Use tags for roles, statuses, subsystems, or any slices that do not need a full group.';

  @override
  String get noTagsYet => 'No tags yet.';

  @override
  String get newTagFieldLabel => 'New tag';

  @override
  String get tagColourFieldLabel => 'Tag colour';

  @override
  String get createTagButton => 'Create tag';

  @override
  String get saveTagsButton => 'Save tags';

  @override
  String get nameTagFirstError => 'Name the tag first.';

  @override
  String get dataTitle => 'Data';

  @override
  String get notSetLabel => 'not set';

  @override
  String get valueFieldLabel => 'Value';

  @override
  String get leaveBlankToClearHint => 'Leave blank to clear';

  @override
  String get saveValueButton => 'Save value';

  @override
  String get clearButton => 'Clear';

  @override
  String duplicateMemberName(String name) {
    return '$name copy';
  }

  @override
  String memberAvatarSemanticLabel(String name) {
    return 'Avatar for $name';
  }

  @override
  String get memberPreviewName => 'Preview';

  @override
  String get alterProfileTitle => 'Alter profile';

  @override
  String get birthdayFieldHint => 'YYYY-MM-DD, MM-DD, or free text';

  @override
  String get privacyFieldHint => 'private, friends, public, or bucket name';

  @override
  String get avatarReferenceFieldLabel => 'Avatar URL or local ref';

  @override
  String get chooseImageButton => 'Choose image';

  @override
  String get primaryGroupFieldLabel => 'Primary group';

  @override
  String get noPrimaryGroupOption => 'No primary group';

  @override
  String get memberGroupsTitle => 'Member groups';

  @override
  String get saveAlterButton => 'Save alter';

  @override
  String get createAlterButton => 'Create alter';

  @override
  String get openingImagePickerStatus => 'Opening image picker...';

  @override
  String get chooseMemberAvatarTitle => 'Choose member avatar';

  @override
  String get noImageSelectedStatus => 'No image selected.';

  @override
  String get selectedImageEmptyError => 'Selected image was empty.';

  @override
  String get selectedImageTooLargeError =>
      'Choose an image smaller than 10 MB.';

  @override
  String get selectedImageUnsupportedTypeError =>
      'Choose a PNG, JPEG, WebP, or GIF image.';

  @override
  String get avatarSavedStatus => 'Avatar saved on device.';

  @override
  String couldNotSaveAvatar(Object error) {
    return 'Could not save avatar: $error';
  }

  @override
  String get avatarClearedStatus => 'Avatar cleared.';

  @override
  String get todayFilter => 'Today';

  @override
  String get weekFilter => 'Week';

  @override
  String get monthFilter => 'Month';

  @override
  String get searchFrontHistoryHint => 'Search front history';

  @override
  String get frontHistoryTitle => 'Front history';

  @override
  String get noFrontHistoryYet => 'No front history yet';

  @override
  String get frontHistoryEmptyBody =>
      'Set a front or import an archive to fill this in.';

  @override
  String get noMatchingFronts => 'No matching fronts';

  @override
  String get noMatchingFrontsBody =>
      'Try a wider date range or a shorter search.';

  @override
  String get addEntryButton => 'Add entry';

  @override
  String get resetButton => 'Reset';

  @override
  String get statusNoteFieldLabel => 'Status note';

  @override
  String get statusNoteFieldHint => 'Add context for this front';

  @override
  String get editEntryButton => 'Edit entry';

  @override
  String get deleteFrontEntryTitle => 'Delete front entry?';

  @override
  String get deleteFrontEntryBody =>
      'This removes this front history entry from the archive.';

  @override
  String get deleteEntryButton => 'Delete entry';

  @override
  String get addFrontHistoryTitle => 'Add front history';

  @override
  String get editFrontHistoryTitle => 'Edit front history';

  @override
  String get startedFieldLabel => 'Started';

  @override
  String get endedFieldLabel => 'Ended';

  @override
  String get customLabelFieldLabel => 'Custom label';

  @override
  String get customLabelFieldHelp => 'Used when no members are selected';

  @override
  String get endBeforeStartError => 'End time must be after the start time.';

  @override
  String get chooseMembersOrLabelError =>
      'Choose members or enter a custom label.';

  @override
  String activeFrontTiming(String started) {
    return 'started $started - active';
  }

  @override
  String endedFrontTiming(String started, String ended) {
    return 'started $started - ended $ended';
  }

  @override
  String get customFieldsImportDescription =>
      'Import a Simply Plural export to bring custom profile fields into the local archive.';

  @override
  String customFieldsWithValues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fields have imported values.',
      one: '1 field has imported values.',
    );
    return '$_temp0';
  }

  @override
  String get noCustomFieldsYet => 'No custom fields yet';

  @override
  String get customFieldsEmptyBody =>
      'SP custom fields will show here after import.';

  @override
  String get addFieldButton => 'Add field';

  @override
  String valueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count values',
      one: '1 value',
    );
    return '$_temp0';
  }

  @override
  String get customFieldActionsTooltip => 'Custom field actions';

  @override
  String get deleteCustomFieldTitle => 'Delete custom field?';

  @override
  String deleteCustomFieldBody(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saved values',
      one: '1 saved value',
    );
    return 'This removes “$name” and $_temp0 from this device.';
  }

  @override
  String customFieldValueSummary(String type, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count values',
      one: '1 value',
    );
    return '$type - $_temp0';
  }

  @override
  String get systemLabel => 'System';

  @override
  String get noMemberValuesYet => 'No member values yet';

  @override
  String get memberValuesEmptyBody =>
      'Imported per-alter values for this field will show here.';

  @override
  String get customFieldTitle => 'Custom field';

  @override
  String get editCustomFieldDescription =>
      'Edit the field definition. Existing values stay attached.';

  @override
  String get createCustomFieldDescription =>
      'Create a field that can hold member or system data.';

  @override
  String get textType => 'Text';

  @override
  String get numberType => 'Number';

  @override
  String get dateType => 'Date';

  @override
  String get booleanType => 'Boolean';

  @override
  String get selectType => 'Select';

  @override
  String get privacyOptionsHint => 'private, friends, public';

  @override
  String get saveFieldButton => 'Save field';

  @override
  String get createFieldButton => 'Create field';

  @override
  String get searchCustomFrontsHint => 'Search custom fronts';

  @override
  String get customFrontsTitle => 'Custom fronts';

  @override
  String get customFrontsDescription =>
      'Statuses like Asleep, Away, or Lost time live here. They can front without becoming members.';

  @override
  String get addCustomFrontButton => 'Add custom front';

  @override
  String get noCustomFronts => 'No custom fronts';

  @override
  String get noMatches => 'No matches';

  @override
  String get customFrontsEmptyBody =>
      'Add one here, or import them from SimplyPlural.';

  @override
  String get tryDifferentSearch => 'Try a different search.';

  @override
  String get namedCombinationsTitle => 'Named combinations';

  @override
  String get memberShortcutLabel => 'member shortcut';

  @override
  String get setNamedFrontTooltip => 'Set named front';

  @override
  String get deleteNamedFrontTooltip => 'Delete named front';

  @override
  String setFrontConfirmation(String name) {
    return 'Set $name as front';
  }

  @override
  String get deleteCustomFrontTitle => 'Delete custom front?';

  @override
  String get deleteNamedFrontTitle => 'Delete named front?';

  @override
  String get deleteSavedFrontBody =>
      'This only removes the saved shortcut. Front history stays.';

  @override
  String customFrontSemanticLabel(String name) {
    return 'Custom front $name';
  }

  @override
  String get customFrontLabel => 'custom front';

  @override
  String get setCustomFrontTooltip => 'Set custom front';

  @override
  String get editCustomFrontTooltip => 'Edit custom front';

  @override
  String get deleteCustomFrontTooltip => 'Delete custom front';

  @override
  String get editCustomFrontTitle => 'Edit custom front';

  @override
  String get customFrontEditorDescription =>
      'Custom fronts can be used from the front picker without changing member counts.';

  @override
  String get colourFieldLabel => 'Colour';

  @override
  String get importedAvatarReferenceFieldLabel =>
      'Avatar URL or imported local reference';

  @override
  String get createButton => 'Create';

  @override
  String get chooseCustomFrontAvatarTitle => 'Choose custom front avatar';

  @override
  String get localStatusLabel => 'local';

  @override
  String get offlineStatusLabel => 'offline';

  @override
  String get usefulLinksDescription =>
      'Quick places for importing, backing up, support, and project links.';

  @override
  String get inThisAppTitle => 'In this app';

  @override
  String get importFromSimplyPluralTitle => 'Import from Simply Plural';

  @override
  String get openImportSetupSubtitle => 'open import setup';

  @override
  String get backUpLocalDataTitle => 'Back up local data';

  @override
  String get exportDeviceArchiveSubtitle => 'export a device archive';

  @override
  String get customizeDashboardTitle => 'Customise dashboard';

  @override
  String get dashboardOptionsSubtitle => 'tiles, theme, and language';

  @override
  String get howToGuidesTitle => 'How-to guides';

  @override
  String get shortOfflineNotesSubtitle => 'short offline notes';

  @override
  String get projectTitle => 'Project';

  @override
  String get sourceTitle => 'Source';

  @override
  String get whatsNewTitle => 'What\'s new';

  @override
  String get apkReleasesTitle => 'APK releases';

  @override
  String get githubSponsorsTitle => 'GitHub Sponsors';

  @override
  String get patreonTitle => 'Patreon';

  @override
  String get howTosDescription =>
      'Short local notes for the flows people usually need first.';

  @override
  String get howToImportSimplyPluralStep1 =>
      'Export your Simply Plural data as JSON.';

  @override
  String get howToImportSimplyPluralStep2 =>
      'Open Import / Export and choose the file or paste JSON.';

  @override
  String get howToImportSimplyPluralStep3 =>
      'Review the preview, then apply it to the local archive.';

  @override
  String get howToImportSimplyPluralStep4 =>
      'Check members, groups, fronts, notes, and avatars after import.';

  @override
  String get openImportAction => 'Open import';

  @override
  String get trackFrontTitle => 'Track a front';

  @override
  String get howToTrackFrontStep1 => 'Open Dashboard or Front History.';

  @override
  String get howToTrackFrontStep2 =>
      'Use Set front to pick members or a saved custom front.';

  @override
  String get howToTrackFrontStep3 =>
      'Use Clear when nobody is fronting or the state ended.';

  @override
  String get howToTrackFrontStep4 => 'Front History keeps the local timeline.';

  @override
  String get openHistoryAction => 'Open history';

  @override
  String get saveCustomFrontsTitle => 'Save custom fronts';

  @override
  String get howToCustomFrontsStep1 => 'Open Custom Fronts.';

  @override
  String get howToCustomFrontsStep2 =>
      'Add statuses like Asleep, Away, or blended front states.';

  @override
  String get howToCustomFrontsStep3 =>
      'Set them from the dashboard without creating extra members.';

  @override
  String get openCustomFrontsAction => 'Open custom fronts';

  @override
  String get backUpDeviceTitle => 'Back up this device';

  @override
  String get howToBackupStep1 => 'Open Import / Export.';

  @override
  String get howToBackupStep2 => 'Create a Pluris Haven archive.';

  @override
  String get howToBackupStep3 =>
      'Keep the file somewhere outside this phone too.';

  @override
  String get openExportAction => 'Open export';

  @override
  String get useCustomFieldsTitle => 'Use custom fields';

  @override
  String get howToCustomFieldsStep1 => 'Open Custom Fields.';

  @override
  String get howToCustomFieldsStep2 =>
      'Add a field like “age”, “role”, or “species”.';

  @override
  String get howToCustomFieldsStep3 =>
      'Set values per member from their profile.';

  @override
  String get howToCustomFieldsStep4 =>
      'Fields import from Simply Plural automatically.';

  @override
  String get openCustomFieldsAction => 'Open custom fields';

  @override
  String get setRemindersTitle => 'Set reminders';

  @override
  String get howToRemindersStep1 => 'Open Reminders.';

  @override
  String get howToRemindersStep2 =>
      'Pick a daily, weekly, or monthly schedule.';

  @override
  String get howToRemindersStep3 => 'Notifications will fire at the set time.';

  @override
  String get howToRemindersStep4 =>
      'Turn any reminder off without deleting it.';

  @override
  String get openRemindersAction => 'Open reminders';

  @override
  String get voteOnDecisionsTitle => 'Vote on system decisions';

  @override
  String get howToPollsStep1 => 'Open Polls and create a new poll.';

  @override
  String get howToPollsStep2 =>
      'Add options and choose single or multiple choice.';

  @override
  String get howToPollsStep3 =>
      'Share the poll with members in the same space.';

  @override
  String get howToPollsStep4 =>
      'Results stay on this device until you delete them.';

  @override
  String get openPollsAction => 'Open polls';

  @override
  String get importOtherAppsTitle => 'Import from other apps';

  @override
  String get howToOtherImportsStep1 =>
      'Export JSON from PluralKit, Tupperbox, or PluralSpace.';

  @override
  String get howToOtherImportsStep2 =>
      'Open Import / Export and upload the file.';

  @override
  String get howToOtherImportsStep3 =>
      'Select the matching service from the dropdown.';

  @override
  String get howToOtherImportsStep4 =>
      'Preview the records, then import into local storage.';

  @override
  String get useSubsystemsTitle => 'Use subsystems';

  @override
  String get howToSubsystemsStep1 => 'Open Groups and add or edit a group.';

  @override
  String get howToSubsystemsStep2 => 'Turn on “Subgroup / subsystem”.';

  @override
  String get howToSubsystemsStep3 =>
      'Members in subsystems can also be in the main group.';

  @override
  String get howToSubsystemsStep4 =>
      'The layers icon shows which groups are subsystems.';

  @override
  String get openGroupsAction => 'Open groups';

  @override
  String get analyticsTitle => 'Analytics';

  @override
  String get analyticsDescription => 'Fronting patterns from local history.';

  @override
  String get noAnalyticsTitle => 'No analytics yet';

  @override
  String get noAnalyticsBody =>
      'Set fronts or import Simply Plural front history to fill this in.';

  @override
  String get totalFrontTimeLabel => 'Total front time';

  @override
  String get sessionsLabel => 'Sessions';

  @override
  String get averageLabel => 'Average';

  @override
  String get longestLabel => 'Longest';

  @override
  String get topFrontsTitle => 'Top fronts';

  @override
  String get hourOfDayTitle => 'Hour of day';

  @override
  String get unknownLabel => 'Unknown';

  @override
  String get analyticsSevenDays => '7d';

  @override
  String get analyticsThirtyDays => '30d';

  @override
  String get analyticsNinetyDays => '90d';

  @override
  String get analyticsOneYear => '1y';

  @override
  String sessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions',
      one: '1 session',
    );
    return '$_temp0';
  }

  @override
  String frontAnalyticsSemantic(String label, String duration, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions',
      one: '1 session',
    );
    return '$label, $duration, $_temp0';
  }

  @override
  String hourAnalyticsSemantic(int hour, String duration) {
    return '$hour:00, $duration';
  }

  @override
  String durationMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String durationHours(int hours) {
    return '${hours}h';
  }

  @override
  String durationDays(int days) {
    return '${days}d';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String durationDaysHours(int days, int hours) {
    return '${days}d ${hours}h';
  }

  @override
  String get noMembersYetTitle => 'No members yet';

  @override
  String get noMembersFrontPickerBody =>
      'Add members first, or set a custom front below.';

  @override
  String selectedMembersSummary(String names) {
    return 'Selected: $names';
  }

  @override
  String get noMatchingMembersTitle => 'No matching members';

  @override
  String get noMatchingMembersBody =>
      'Try a different name, pronoun, or PluralKit ID.';

  @override
  String get clearSelectionButton => 'Clear selection';

  @override
  String get setSelectedButton => 'Set selected';

  @override
  String get setCofrontButton => 'Set co-front';

  @override
  String get saveSelectedNamedFrontButton => 'Save selected as named front';

  @override
  String get savedFrontsTitle => 'Saved fronts';

  @override
  String get searchSavedFrontsHint => 'Search saved fronts';

  @override
  String get noMatchingSavedFrontsTitle => 'No matching saved fronts';

  @override
  String get noMatchingSavedFrontsBody =>
      'Try another saved front name or status.';

  @override
  String get namedCombinationLabel => 'named combination';

  @override
  String get setSavedFrontTooltip => 'Set saved front';

  @override
  String get deleteSavedFrontTooltip => 'Delete saved front';

  @override
  String get labelFieldLabel => 'Label';

  @override
  String get setButtonLabel => 'Set';

  @override
  String get frontChangedTitle => 'Front changed';

  @override
  String get frontClearedTitle => 'Front cleared';

  @override
  String memberIsFronting(String name) {
    return '$name is fronting.';
  }

  @override
  String get noOneFrontingBody => 'No one is marked as fronting.';

  @override
  String get saveNamedFrontTitle => 'Save named front';

  @override
  String get frontingDefaultName => 'Fronting';

  @override
  String get cofrontDefaultName => 'Co-front';

  @override
  String savedNamedFront(String name) {
    return 'Saved “$name”';
  }

  @override
  String avatarForLabel(String name) {
    return 'Avatar for $name';
  }

  @override
  String get privacyBucketsDescription =>
      'Group members by who may see them. Sharing stays off until sync is configured.';

  @override
  String get noPrivacyBucketsTitle => 'No privacy buckets';

  @override
  String get noPrivacyBucketsBody =>
      'Create one to prepare member visibility rules.';

  @override
  String memberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String bucketDescriptionMembers(String description, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$description - $_temp0';
  }

  @override
  String deleteNamedItem(String name) {
    return 'Delete $name';
  }

  @override
  String get deletePrivacyBucketTitle => 'Delete privacy bucket?';

  @override
  String deletePrivacyBucketBody(String name) {
    return 'Member assignments to $name will be removed.';
  }

  @override
  String get addBucketButton => 'Add bucket';

  @override
  String get relatedVisibilityTitle => 'Related visibility';

  @override
  String get memberVisibilityTitle => 'Member visibility';

  @override
  String get memberVisibilitySubtitle => 'edit privacy on member profiles';

  @override
  String get customFieldsPrivacyTitle => 'Custom fields privacy';

  @override
  String get customFieldsPrivacySubtitle => 'edit field-level labels';

  @override
  String get addPrivacyBucketTitle => 'Add privacy bucket';

  @override
  String get editPrivacyBucketTitle => 'Edit privacy bucket';

  @override
  String get membersTitle => 'Members';

  @override
  String get nameRequiredError => 'Name is required.';

  @override
  String get disabledStatusLabel => 'disabled';

  @override
  String get tokensDescription =>
      'There is no local API token surface yet. Imports do not need a Pluris Haven token.';

  @override
  String get tokenStatusTitle => 'Token status';

  @override
  String get localTokenStoreTitle => 'Local token store';

  @override
  String get emptyStatusLabel => 'empty';

  @override
  String get pluralKitLiveImportTitle => 'PluralKit live import';

  @override
  String get pasteTokenDuringImportSubtitle => 'paste a token during import';

  @override
  String get syncTokensTitle => 'Sync tokens';

  @override
  String get requiresSyncSetupSubtitle => 'requires sync setup';

  @override
  String get userReportDescription =>
      'A small local snapshot you can copy before filing a bug. It excludes system and front names.';

  @override
  String get copyReportButton => 'Copy report';

  @override
  String get relatedTitle => 'Related';

  @override
  String get importJobsTitle => 'Import jobs';

  @override
  String get importJobsSubtitle => 'open import details and errors';

  @override
  String get retainedImportPayloadsTitle => 'Retained import sources';

  @override
  String get retainedImportPayloadsDescription =>
      'These encrypted source collections are not used by the app. You can remove them without deleting mapped members, notes, or other imported records.';

  @override
  String retainedImportPayloadSummary(String source, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count collections',
      one: '1 collection',
    );
    return '$source: $_temp0';
  }

  @override
  String get deleteRetainedImportPayloadsTooltip =>
      'Delete retained source collections';

  @override
  String get deleteRetainedImportPayloadsTitle =>
      'Delete retained source collections?';

  @override
  String deleteRetainedImportPayloadsDescription(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count encrypted source collections',
      one: '1 encrypted source collection',
    );
    return 'This permanently removes $_temp0. Mapped imported records stay in the app.';
  }

  @override
  String get retainedImportPayloadsDeleted =>
      'Retained source collections deleted';

  @override
  String get localEventLogSubtitle => 'local event log';

  @override
  String get localReportHeading => 'Pluris Haven local report';

  @override
  String get localReportStage => 'stage: pre-alpha';

  @override
  String localReportMembers(int count) {
    return 'members: $count';
  }

  @override
  String localReportGroups(int count) {
    return 'groups: $count';
  }

  @override
  String localReportNotes(int count) {
    return 'notes: $count';
  }

  @override
  String localReportFrontHistory(int count) {
    return 'front history: $count';
  }

  @override
  String get localReportStorage => 'storage: device';

  @override
  String get localReportSync => 'sync: off by default';

  @override
  String get reportCopiedMessage => 'Report copied';

  @override
  String get localSystemFallback => 'Local system';

  @override
  String systemAvatarFor(String name) {
    return 'System avatar for $name';
  }

  @override
  String get savedOnDeviceSubtitle => 'saved on device';

  @override
  String get editSystemProfileTooltip => 'Edit system profile';

  @override
  String get moveDataSubtitle => 'move data in or out';

  @override
  String get appOptionsSubtitle => 'theme, language, dashboard';

  @override
  String get offByDefaultSubtitle => 'off by default';

  @override
  String get deviceDatabaseSubtitle => 'device database';

  @override
  String get memberNameEncryptionTitle => 'Member name encryption';

  @override
  String get secureStorageKeySubtitle => 'key stored in device secure storage';

  @override
  String get destructiveActionsTitle => 'Destructive actions';

  @override
  String get confirmedWithDialogsSubtitle => 'confirmed with dialogs';

  @override
  String get systemProfileTitle => 'System profile';

  @override
  String get removeButton => 'Remove';

  @override
  String get systemNameFieldLabel => 'System name';

  @override
  String get savingStatus => 'Saving...';

  @override
  String get chooseSystemAvatarTitle => 'Choose system avatar';

  @override
  String couldNotSaveImage(String error) {
    return 'Could not save image: $error';
  }

  @override
  String plannedFeatureBody(String detail) {
    return '$detail\n\nThis part is not built yet. It is planned for a later pre-alpha build.';
  }

  @override
  String get okButtonLabel => 'OK';

  @override
  String statusSemanticLabel(String status) {
    return 'Status $status';
  }

  @override
  String get appName => 'Pluris Haven';

  @override
  String get importCompatibilityValue => 'Simply Plural and PluralKit';

  @override
  String get moneroTitle => 'Monero';

  @override
  String get noneTitle => 'None';

  @override
  String systemCounts(int members, int groups) {
    String _temp0 = intl.Intl.pluralLogic(
      members,
      locale: localeName,
      other: '$members members',
      one: '1 member',
    );
    String _temp1 = intl.Intl.pluralLogic(
      groups,
      locale: localeName,
      other: '$groups groups',
      one: '1 group',
    );
    return '$_temp0 - $_temp1';
  }
}

/// The translations for English, as used in the United States (`en_US`).
class AppLocalizationsEnUs extends AppLocalizationsEn {
  AppLocalizationsEnUs() : super('en_US');

  @override
  String get customizeTitle => 'Customize';

  @override
  String get accentColorLabel => 'Accent color';

  @override
  String get currentColorLabel => 'Current color';

  @override
  String get copyHexColorTooltip => 'Copy hex color';

  @override
  String get useCustomColorLabel => 'Use custom color';

  @override
  String get noDashboardShortcutsBody =>
      'Open Customize to add shortcuts back.';

  @override
  String get saveCancelled => 'Save canceled.';

  @override
  String get groupsEmptyBody =>
      'Groups keep members organized without needing sync.';

  @override
  String get colorHexFieldLabel => 'Color hex';

  @override
  String get tagColourFieldLabel => 'Tag color';

  @override
  String get colourFieldLabel => 'Color';

  @override
  String get customizeDashboardTitle => 'Customize dashboard';
}
