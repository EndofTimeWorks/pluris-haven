part of 'home_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.snapshot,
    required this.customization,
    required this.repository,
    required this.onSelect,
  });

  final HomeSnapshot? snapshot;
  final AppCustomization customization;
  final HavenRepository repository;
  final ValueChanged<SpSection> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 24),
      children: [
        SystemListEntry(snapshot: snapshot),
        const SizedBox(height: 10),
        CurrentFrontEntry(snapshot: snapshot, repository: repository),
        const SizedBox(height: 18),
        const DashboardSectionTitle('Main'),
        const SizedBox(height: 8),
        DashboardActionGrid(
          items: _dashboardItems(snapshot, customization.dashboardShortcutIds),
          customization: customization,
          onSelect: onSelect,
        ),
        if (customization.dashboardShortcutIds.isEmpty) ...[
          const SizedBox(height: 10),
          const SpEmptyState(
            title: 'No dashboard shortcuts',
            body: 'Open Customize to add shortcuts back.',
          ),
        ],
      ],
    );
  }

  List<HomeNavigationItem> _dashboardItems(
    HomeSnapshot? home,
    List<String> ids,
  ) {
    final definitions = {for (final item in dashboardShortcuts) item.id: item};

    return [
      for (final id in ids)
        if (definitions[id] case final definition?) definition.item(home),
    ];
  }
}

const dashboardShortcuts = [
  DashboardShortcutDefinition(
    id: 'members',
    title: 'Members',
    section: SpSection.members,
    icon: Icons.people_alt_rounded,
    countKind: DashboardCountKind.members,
  ),
  DashboardShortcutDefinition(
    id: 'front-history',
    title: 'Front History',
    section: SpSection.frontHistory,
    icon: Icons.history_rounded,
    countKind: DashboardCountKind.frontHistory,
  ),
  DashboardShortcutDefinition(
    id: 'custom-fronts',
    title: 'Custom Fronts',
    subtitle: 'saved states',
    section: SpSection.customFronts,
    icon: Icons.label_rounded,
  ),
  DashboardShortcutDefinition(
    id: 'groups',
    title: 'Groups',
    section: SpSection.groups,
    icon: Icons.folder_rounded,
    countKind: DashboardCountKind.groups,
  ),
  DashboardShortcutDefinition(
    id: 'notes',
    title: 'Notes',
    section: SpSection.notes,
    icon: Icons.sticky_note_2_rounded,
    countKind: DashboardCountKind.notes,
  ),
  DashboardShortcutDefinition(
    id: 'import-export',
    title: 'Import / Export',
    subtitle: 'local archive',
    section: SpSection.importExport,
    icon: Icons.archive_rounded,
  ),
  DashboardShortcutDefinition(
    id: 'sync',
    title: 'Sync',
    subtitle: 'off by default',
    section: SpSection.sync,
    icon: Icons.sync_disabled_rounded,
  ),
  DashboardShortcutDefinition(
    id: 'customize',
    title: 'Customize',
    subtitle: 'layout and theme',
    section: SpSection.appOptions,
    icon: Icons.tune_rounded,
  ),
  DashboardShortcutDefinition(
    id: 'analytics',
    title: 'Analytics',
    subtitle: 'local stats',
    section: SpSection.analytics,
    icon: Icons.analytics_rounded,
  ),
  DashboardShortcutDefinition(
    id: 'reminders',
    title: 'Reminders',
    subtitle: '0 scheduled',
    section: SpSection.reminders,
    icon: Icons.notification_add_rounded,
  ),
  DashboardShortcutDefinition(
    id: 'custom-fields',
    title: 'Custom Fields',
    subtitle: 'profile fields',
    section: SpSection.customFields,
    icon: Icons.table_rows_rounded,
  ),
  DashboardShortcutDefinition(
    id: 'friends',
    title: 'Friends',
    subtitle: 'sync required',
    section: SpSection.friends,
    icon: Icons.people_rounded,
  ),
  DashboardShortcutDefinition(
    id: 'chat',
    title: 'Chat',
    subtitle: 'offline board',
    section: SpSection.chat,
    icon: Icons.chat_rounded,
  ),
  DashboardShortcutDefinition(
    id: 'polls',
    title: 'Polls',
    subtitle: '0 active',
    section: SpSection.polls,
    icon: Icons.how_to_vote_rounded,
  ),
];

enum DashboardCountKind { members, frontHistory, groups, notes }

class DashboardShortcutDefinition {
  const DashboardShortcutDefinition({
    required this.id,
    required this.title,
    required this.section,
    required this.icon,
    this.subtitle,
    this.countKind,
  });

  final String id;
  final String title;
  final SpSection section;
  final IconData icon;
  final String? subtitle;
  final DashboardCountKind? countKind;

  HomeNavigationItem item(HomeSnapshot? home) {
    return HomeNavigationItem(title, _subtitle(home), section, icon);
  }

  String _subtitle(HomeSnapshot? home) {
    return switch (countKind) {
      DashboardCountKind.members => '${home?.memberCount ?? 0}',
      DashboardCountKind.frontHistory =>
        '${home?.frontHistoryCount ?? 0} entries',
      DashboardCountKind.groups => '${home?.groupCount ?? 0} groups',
      DashboardCountKind.notes => '${home?.noteCount ?? 0} notes',
      null => subtitle ?? '',
    };
  }
}
