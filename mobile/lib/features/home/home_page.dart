import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/import/import_archive_mapper.dart';
import '../../data/import/import_file_decoder.dart';
import '../../data/import/import_plan.dart';
import '../../data/import/import_preview.dart';
import '../../data/import/import_sources.dart';
import '../../data/import/member_dedupe.dart';
import '../../data/import/pluralkit_live_client.dart';
import '../../data/backup/repository_backup.dart';
import '../../data/local/app_database.dart'
    show JournalEntry, NamedFront, Tag, localSystemId;
import '../../data/notifications/notification_service.dart';
import '../../data/local/haven_repository.dart';
import '../../data/local/supported_language.dart';
import '../../data/security/archive_encryption.dart';
import '../../data/server/server_account_controller.dart';
import '../../debug/debug_log.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/native_file_dialog.dart';

part 'dashboard.dart';
part 'members.dart';
part 'front_history.dart';
part 'groups.dart';
part 'notes.dart';
part 'journals.dart';
part 'messages.dart';
part 'analytics.dart';
part 'custom_fields.dart';
part 'polls.dart';
part 'reminders.dart';
part 'notifications.dart';
part 'useful_links.dart';
part 'status_pages.dart';
part 'import_export.dart';
part 'sync.dart';
part 'app_options.dart';
part 'about.dart';
part 'navigation.dart';
part 'dashboard_widgets.dart';
part 'custom_front.dart';
part 'custom_fronts_page.dart';
part 'sp_widgets.dart';
part 'server_account.dart';

const _spSurface = Color(0xFF232532);
const _spCard = Color(0xFF2B2E3D);
const _spLine = Color(0xFF3A3E50);
const _spText = Color(0xFFECEAF2);
const _spMuted = Color(0xFFC4C0CE);
const _spPurple = Color(0xFF7B61FF);
const _spGold = Color(0xFFF2C75C);

enum SpSection {
  dashboard,
  members,
  frontHistory,
  customFronts,
  groups,
  notes,
  journals,
  analytics,
  chat,
  polls,
  friends,
  usefulLinks,
  reminders,
  privacyBuckets,
  tokens,
  userReport,
  notificationHistory,
  howtos,
  customFields,
  accountSettings,
  importExport,
  sync,
  appOptions,
  about;

  String label(AppLocalizations l10n) => switch (this) {
    SpSection.dashboard => l10n.navigationDashboard,
    SpSection.members => l10n.navigationMembers,
    SpSection.frontHistory => l10n.navigationFrontHistory,
    SpSection.customFronts => l10n.navigationCustomFronts,
    SpSection.groups => l10n.navigationGroups,
    SpSection.notes => l10n.navigationNotes,
    SpSection.journals => l10n.navigationJournals,
    SpSection.analytics => l10n.navigationAnalytics,
    SpSection.chat => l10n.navigationChat,
    SpSection.polls => l10n.navigationPolls,
    SpSection.friends => l10n.navigationFriends,
    SpSection.usefulLinks => l10n.navigationUsefulLinks,
    SpSection.reminders => l10n.navigationReminders,
    SpSection.privacyBuckets => l10n.navigationPrivacyBuckets,
    SpSection.tokens => l10n.navigationTokens,
    SpSection.userReport => l10n.navigationUserReport,
    SpSection.notificationHistory => l10n.navigationNotificationHistory,
    SpSection.howtos => l10n.navigationHowTos,
    SpSection.customFields => l10n.navigationCustomFields,
    SpSection.accountSettings => l10n.navigationAccountSettings,
    SpSection.importExport => l10n.navigationImportExport,
    SpSection.sync => l10n.navigationSync,
    SpSection.appOptions => l10n.navigationAppOptions,
    SpSection.about => l10n.navigationAbout,
  };
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.repository, this.serverAccount});

  final HavenRepository repository;
  final ServerAccountController? serverAccount;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  SpSection _section = SpSection.dashboard;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<HomeSnapshot>(
      stream: widget.repository.watchHomeSnapshot(),
      builder: (context, snapshot) {
        final home = snapshot.data;
        final l10n = AppLocalizations.of(context);

        return PopScope(
          canPop: _section == SpSection.dashboard,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && _section != SpSection.dashboard) {
              _selectSection(SpSection.dashboard);
            }
          },
          child: Scaffold(
            drawer: SpDrawer(
              snapshot: home,
              selected: _section,
              onSelect: _selectSection,
            ),
            appBar: AppBar(
              toolbarHeight: 48,
              titleSpacing: 0,
              title: Text(
                _section.label(l10n),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            body: SafeArea(
              top: false,
              child: StreamBuilder<AppCustomization>(
                stream: widget.repository.watchCustomization(),
                initialData: AppCustomization.defaults,
                builder: (context, customizationSnapshot) {
                  return _buildSection(
                    home,
                    customizationSnapshot.data ?? AppCustomization.defaults,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _selectSection(SpSection section) {
    setState(() {
      _section = section;
    });
  }

  Widget _buildSection(HomeSnapshot? home, AppCustomization customization) {
    switch (_section) {
      case SpSection.dashboard:
        return DashboardPage(
          snapshot: home,
          customization: customization,
          repository: widget.repository,
          onSelect: _selectSection,
        );
      case SpSection.members:
        return MembersPage(
          snapshot: home,
          repository: widget.repository,
          onImport: () => _selectSection(SpSection.importExport),
        );
      case SpSection.frontHistory:
        return FrontHistoryPage(snapshot: home, repository: widget.repository);
      case SpSection.customFronts:
        return CustomFrontsPage(repository: widget.repository);
      case SpSection.groups:
        return GroupsPage(
          snapshot: home,
          repository: widget.repository,
          onImport: () => _selectSection(SpSection.importExport),
        );
      case SpSection.notes:
        return NotesPage(
          snapshot: home,
          repository: widget.repository,
          onImport: () => _selectSection(SpSection.importExport),
        );
      case SpSection.journals:
        return JournalsPage(repository: widget.repository);
      case SpSection.analytics:
        return AnalyticsPage(repository: widget.repository);
      case SpSection.chat:
        return MessagesPage(
          repository: widget.repository,
          onImport: () => _selectSection(SpSection.importExport),
        );
      case SpSection.usefulLinks:
        return UsefulLinksPage(onSelect: _selectSection);
      case SpSection.polls:
        return PollsPage(
          repository: widget.repository,
          onImport: () => _selectSection(SpSection.importExport),
        );
      case SpSection.friends:
        return ServerFriendsPage(controller: widget.serverAccount);
      case SpSection.reminders:
        return RemindersPage(
          repository: widget.repository,
          onNotificationSettings: () =>
              _selectSection(SpSection.notificationHistory),
        );
      case SpSection.privacyBuckets:
        return LocalPrivacyPage(
          repository: widget.repository,
          onSelect: _selectSection,
        );
      case SpSection.tokens:
        return LocalTokensPage(onSelect: _selectSection);
      case SpSection.userReport:
        return UserReportPage(snapshot: home, onSelect: _selectSection);
      case SpSection.notificationHistory:
        return NotificationHistoryPage(repository: widget.repository);
      case SpSection.howtos:
        return HowTosPage(onSelect: _selectSection);
      case SpSection.customFields:
        return CustomFieldsPage(
          repository: widget.repository,
          onImport: () => _selectSection(SpSection.importExport),
        );
      case SpSection.accountSettings:
        return AccountSettingsPage(
          snapshot: home,
          repository: widget.repository,
          serverAccount: widget.serverAccount,
          onSelect: _selectSection,
        );
      case SpSection.importExport:
        return ImportExportPage(repository: widget.repository);
      case SpSection.sync:
        return SyncPage(
          repository: widget.repository,
          controller: widget.serverAccount,
        );
      case SpSection.appOptions:
        return AppOptionsPage(
          customization: customization,
          repository: widget.repository,
        );
      case SpSection.about:
        return const AboutPage();
    }
  }
}
