import 'dart:convert';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/avatar/avatar_file_policy.dart';
import '../../data/avatar/local_avatar_store.dart';
import '../../data/import/import_archive_mapper.dart';
import '../../data/import/import_diagnostic.dart';
import '../../data/import/import_file_decoder.dart';
import '../../data/import/import_plan.dart';
import '../../data/import/import_preview.dart';
import '../../data/import/import_sources.dart';
import '../../data/import/member_dedupe.dart';
import '../../data/import/pluralkit_live_client.dart';
import '../../data/backup/repository_backup.dart';
import '../../data/local/app_database.dart'
    show
        ContentRevision,
        FrontAuditEvent,
        JournalEntry,
        NamedFront,
        PollVoteEvent,
        Tag,
        localSystemId;
import '../../data/local/custom_field_store.dart'
    show maximumCustomFieldConfigurationCharacters;
import '../../data/notifications/notification_service.dart';
import '../../data/local/haven_repository.dart';
import '../../data/local/local_id.dart';
import '../../data/local/supported_language.dart';
import '../../data/local_api/local_api_controller.dart';
import '../../data/security/archive_encryption.dart';
import '../../data/server/server_account_controller.dart';
import '../../data/server/server_api.dart' show ServerBackupSnapshot;
import '../../debug/debug_log.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/import_diagnostic_localizations.dart';
import '../../l10n/import_plan_localizations.dart';
import '../../platform/native_file_dialog.dart';
import '../../platform/app_lock.dart';
import '../../platform/sensitive_clipboard.dart';

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

final _localAvatarStore = LocalAvatarStore();

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
  const HomePage({
    super.key,
    required this.repository,
    this.serverAccount,
    this.localApi,
  });

  final HavenRepository repository;
  final ServerAccountController? serverAccount;
  final LocalApiController? localApi;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Stream<HomeSnapshot> _homeStream;
  late final Stream<AppCustomization> _customizationStream;
  SpSection _section = SpSection.dashboard;
  final _sectionHistory = <SpSection>[];

  @override
  void initState() {
    super.initState();
    _homeStream = widget.repository.watchHomeSnapshot();
    _customizationStream = widget.repository.watchCustomization();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<HomeSnapshot>(
      stream: _homeStream,
      builder: (context, snapshot) {
        final home = snapshot.data;
        final l10n = AppLocalizations.of(context);

        return StreamBuilder<AppCustomization>(
          stream: _customizationStream,
          initialData: AppCustomization.defaults,
          builder: (context, customizationSnapshot) {
            final customization =
                customizationSnapshot.data ?? AppCustomization.defaults;
            return PopScope(
              canPop: _sectionHistory.isEmpty,
              onPopInvokedWithResult: (didPop, result) {
                if (!didPop && _sectionHistory.isNotEmpty) {
                  _popSection();
                }
              },
              child: Scaffold(
                drawer: SpDrawer(
                  snapshot: home,
                  selected: _section,
                  onSelect: _selectPrimarySection,
                ),
                appBar: _buildAppBar(context, customization, home, l10n),
                body: SafeArea(
                  top: false,
                  child: _buildSection(home, customization),
                ),
                bottomNavigationBar: _profileNavigation(customization, l10n),
              ),
            );
          },
        );
      },
    );
  }

  Widget? _profileNavigation(
    AppCustomization customization,
    AppLocalizations l10n,
  ) {
    return switch (customization.navigationLayout) {
      HavenNavigationLayout.drawer => null,
      HavenNavigationLayout.bottom => _customBottomNavigation(
        l10n,
        customization.bottomNavigationShortcutIds,
      ),
      HavenNavigationLayout.automatic => _ampersandNavigation(l10n),
    };
  }

  Widget _customBottomNavigation(
    AppLocalizations l10n,
    List<String> shortcutIds,
  ) {
    final definitions = {
      for (final shortcut in dashboardShortcuts) shortcut.id: shortcut,
    };
    final shortcuts = [for (final id in shortcutIds) ?definitions[id]];
    final menuIndex = shortcuts.length + 1;
    final shortcutIndex = shortcuts.indexWhere(
      (item) => item.section == _section,
    );
    final selectedIndex = _section == SpSection.dashboard
        ? 0
        : shortcutIndex == -1
        ? menuIndex
        : shortcutIndex + 1;
    return Builder(
      builder: (context) => NavigationBar(
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          if (index == 0) {
            _selectPrimarySection(SpSection.dashboard);
          } else if (index == menuIndex) {
            Scaffold.of(context).openDrawer();
          } else {
            _selectPrimarySection(shortcuts[index - 1].section);
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: l10n.navigationDashboard,
          ),
          for (final shortcut in shortcuts)
            NavigationDestination(
              icon: Icon(shortcut.icon),
              selectedIcon: Icon(shortcut.icon),
              label: shortcut.title(l10n),
            ),
          NavigationDestination(
            icon: const Icon(Icons.menu_rounded),
            label: MaterialLocalizations.of(context).openAppDrawerTooltip,
          ),
        ],
      ),
    );
  }

  Widget _ampersandNavigation(AppLocalizations l10n) {
    return NavigationBar(
      selectedIndex: switch (_section) {
        SpSection.members => 1,
        SpSection.frontHistory => 2,
        SpSection.analytics => 3,
        _ => 0,
      },
      onDestinationSelected: (index) => _selectPrimarySection(switch (index) {
        1 => SpSection.members,
        2 => SpSection.frontHistory,
        3 => SpSection.analytics,
        _ => SpSection.dashboard,
      }),
      destinations: [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: l10n.primaryNavigationHome,
        ),
        NavigationDestination(
          icon: Icon(Icons.group_outlined),
          selectedIcon: Icon(Icons.group_rounded),
          label: l10n.primaryNavigationMembers,
        ),
        NavigationDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history_rounded),
          label: l10n.primaryNavigationHistory,
        ),
        NavigationDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics_rounded),
          label: l10n.primaryNavigationInsights,
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AppCustomization customization,
    HomeSnapshot? snapshot,
    AppLocalizations l10n,
  ) {
    if (customization.visualTheme != HavenVisualTheme.simplyPlural) {
      return AppBar(
        toolbarHeight: 48,
        titleSpacing: 0,
        title: Text(
          _section.label(l10n),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      );
    }

    final systemName = snapshot?.systemName.trim() ?? '';
    return AppBar(
      toolbarHeight: 64,
      title: const SizedBox.shrink(),
      leading: Builder(
        builder: (context) => IconButton(
          tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
          onPressed: Scaffold.of(context).openDrawer,
          icon: const Icon(Icons.menu_rounded),
        ),
      ),
      actions: [
        IconButton(
          tooltip: l10n.navigationAccountSettings,
          onPressed: () => _selectSection(SpSection.accountSettings),
          icon: StoredAvatar(
            size: 38,
            color: _colorFromHex(
              snapshot?.systemColorHex,
              fallback: Theme.of(context).colorScheme.primary,
            ),
            avatarUrl: snapshot?.systemAvatarUrl,
            label: systemName.isEmpty ? 'PH' : systemName.characters.first,
            semanticLabel: l10n.systemAvatarSemanticLabel(
              systemName.isEmpty ? l10n.localSystemFallback : systemName,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _selectSection(SpSection section) {
    if (section == _section) return;
    setState(() {
      _sectionHistory.add(_section);
      _section = section;
    });
  }

  void _selectPrimarySection(SpSection section) {
    if (section == _section) return;
    setState(() {
      _sectionHistory.clear();
      _section = section;
    });
  }

  void _popSection() {
    setState(() => _section = _sectionHistory.removeLast());
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
          onNotificationSettings: () => _selectSection(SpSection.appOptions),
        );
      case SpSection.privacyBuckets:
        return LocalPrivacyPage(
          repository: widget.repository,
          onSelect: _selectSection,
        );
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
          snapshot: home,
          customization: customization,
          repository: widget.repository,
        );
      case SpSection.about:
        return const AboutPage();
    }
  }
}
