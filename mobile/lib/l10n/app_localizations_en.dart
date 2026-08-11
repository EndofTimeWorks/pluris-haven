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
  String get appTagline => 'Offline-first plural system tracker.';

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
      'Saves a password-protected archive file. The password is not stored, so a lost password cannot be recovered.';

  @override
  String get confirmPassphraseFieldLabel => 'Confirm passphrase';

  @override
  String encryptedExportStatusSemanticLabel(String status) {
    return 'Encrypted export status: $status';
  }

  @override
  String get encryptingArchiveButton => 'Encrypting...';

  @override
  String get saveEncryptedFileButton => 'Save encrypted file';

  @override
  String get passphraseMinimumLength => 'Use at least 8 characters.';

  @override
  String get passphrasesDoNotMatch => 'Passphrases do not match.';

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
      'JSON export for backup or migration. It includes local members, groups, journals, notes, fronts, tags, polls, custom fields, and app preferences.';

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
  String get appTagline => 'Offline-first plural system tracker.';

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
      'Open Customize to add shortcuts back.';

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
      'Saves a password-protected archive file. The password is not stored, so a lost password cannot be recovered.';

  @override
  String get confirmPassphraseFieldLabel => 'Confirm passphrase';

  @override
  String encryptedExportStatusSemanticLabel(String status) {
    return 'Encrypted export status: $status';
  }

  @override
  String get encryptingArchiveButton => 'Encrypting...';

  @override
  String get saveEncryptedFileButton => 'Save encrypted file';

  @override
  String get passphraseMinimumLength => 'Use at least 8 characters.';

  @override
  String get passphrasesDoNotMatch => 'Passphrases do not match.';

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
  String get saveCancelled => 'Save canceled.';

  @override
  String couldNotSaveEncryptedArchive(String error) {
    return 'Could not save encrypted archive: $error';
  }

  @override
  String get localArchiveTitle => 'Local archive';

  @override
  String get localArchiveDescription =>
      'JSON export for backup or migration. It includes local members, groups, journals, notes, fronts, tags, polls, custom fields, and app preferences.';

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
}
