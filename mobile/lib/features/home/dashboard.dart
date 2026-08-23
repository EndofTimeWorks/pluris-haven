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
    final l10n = AppLocalizations.of(context);
    final items = _dashboardItems(
      snapshot,
      customization.dashboardShortcutIds,
      l10n,
    );
    return switch (customization.visualTheme) {
      HavenVisualTheme.simplyPlural => _SimplyPluralDashboard(
        snapshot: snapshot,
        repository: repository,
        items: items,
        onSelect: onSelect,
      ),
      HavenVisualTheme.ampersand => _AmpersandDashboard(
        snapshot: snapshot,
        repository: repository,
        items: items,
        onSelect: onSelect,
      ),
      _ => _OriginalDashboard(
        snapshot: snapshot,
        customization: customization,
        repository: repository,
        items: items,
        onSelect: onSelect,
      ),
    };
  }

  List<HomeNavigationItem> _dashboardItems(
    HomeSnapshot? home,
    List<String> ids,
    AppLocalizations l10n,
  ) {
    final definitions = {for (final item in dashboardShortcuts) item.id: item};

    return [
      for (final id in ids)
        if (definitions[id] case final definition?) definition.item(home, l10n),
    ];
  }
}

class _OriginalDashboard extends StatelessWidget {
  const _OriginalDashboard({
    required this.snapshot,
    required this.customization,
    required this.repository,
    required this.items,
    required this.onSelect,
  });

  final HomeSnapshot? snapshot;
  final AppCustomization customization;
  final HavenRepository repository;
  final List<HomeNavigationItem> items;
  final ValueChanged<SpSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 24),
      children: [
        SystemListEntry(snapshot: snapshot),
        const SizedBox(height: 10),
        CurrentFrontEntry(snapshot: snapshot, repository: repository),
        const SizedBox(height: 18),
        DashboardSectionTitle(l10n.dashboardMainSectionTitle),
        const SizedBox(height: 8),
        DashboardActionGrid(
          items: items,
          customization: customization,
          onSelect: onSelect,
        ),
        if (customization.dashboardShortcutIds.isEmpty) ...[
          const SizedBox(height: 10),
          SpEmptyState(
            title: l10n.noDashboardShortcutsTitle,
            body: l10n.noDashboardShortcutsBody,
          ),
        ],
      ],
    );
  }
}

class _SimplyPluralDashboard extends StatelessWidget {
  const _SimplyPluralDashboard({
    required this.snapshot,
    required this.repository,
    required this.items,
    required this.onSelect,
  });

  final HomeSnapshot? snapshot;
  final HavenRepository repository;
  final List<HomeNavigationItem> items;
  final ValueChanged<SpSection> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 20),
      itemCount: items.length + 2,
      separatorBuilder: (_, index) => SizedBox(height: index == 0 ? 12 : 8),
      itemBuilder: (context, index) {
        if (index == 0) {
          return CurrentFrontEntry(snapshot: snapshot, repository: repository);
        }
        if (index == 1) {
          return DashboardSystemHeader(snapshot: snapshot);
        }
        final item = items[index - 2];
        return SpNavigationEntry(
          item: item,
          onTap: () => onSelect(item.section),
        );
      },
    );
  }
}

class _AmpersandDashboard extends StatelessWidget {
  const _AmpersandDashboard({
    required this.snapshot,
    required this.repository,
    required this.items,
    required this.onSelect,
  });

  final HomeSnapshot? snapshot;
  final HavenRepository repository;
  final List<HomeNavigationItem> items;
  final ValueChanged<SpSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<List<FrontHistoryEntry>>(
      stream: repository.watchRecentFrontHistory(limit: 5),
      initialData: const [],
      builder: (context, historySnapshot) {
        final history = historySnapshot.data ?? const <FrontHistoryEntry>[];
        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
          children: [
            DashboardSystemHeader(snapshot: snapshot),
            CurrentFrontEntry(snapshot: snapshot, repository: repository),
            const SizedBox(height: 20),
            DashboardSectionTitle(l10n.currentlyFrontingNotificationTitle),
            const SizedBox(height: 8),
            SpNavigationEntry(
              item: HomeNavigationItem(
                l10n.navigationMembers,
                '${snapshot?.memberCount ?? 0}',
                SpSection.members,
                Icons.people_alt_rounded,
              ),
              onTap: () => onSelect(SpSection.members),
            ),
            if (history.isNotEmpty) ...[
              const SizedBox(height: 20),
              DashboardSectionTitle(l10n.frontHistoryTitle),
              const SizedBox(height: 8),
              for (final entry in history)
                SpCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  onTap: () => onSelect(SpSection.frontHistory),
                  child: FrontHistoryTile(entry: entry, repository: repository),
                ),
            ],
            const SizedBox(height: 16),
            for (final item in items.where(
              (item) =>
                  item.section != SpSection.members &&
                  item.section != SpSection.frontHistory,
            ))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SpNavigationEntry(
                  item: item,
                  onTap: () => onSelect(item.section),
                ),
              ),
          ],
        );
      },
    );
  }
}

final dashboardShortcuts = [
  DashboardShortcutDefinition(
    id: 'members',
    title: (l10n) => l10n.dashboardShortcutMembersTitle,
    section: SpSection.members,
    icon: Icons.people_alt_rounded,
    countKind: DashboardCountKind.members,
  ),
  DashboardShortcutDefinition(
    id: 'front-history',
    title: (l10n) => l10n.dashboardShortcutFrontHistoryTitle,
    section: SpSection.frontHistory,
    icon: Icons.history_rounded,
    countKind: DashboardCountKind.frontHistory,
  ),
  DashboardShortcutDefinition(
    id: 'custom-fronts',
    title: (l10n) => l10n.dashboardShortcutCustomFrontsTitle,
    subtitle: (l10n) => l10n.dashboardShortcutCustomFrontsSubtitle,
    section: SpSection.customFronts,
    icon: Icons.label_rounded,
  ),
  DashboardShortcutDefinition(
    id: 'groups',
    title: (l10n) => l10n.dashboardShortcutGroupsTitle,
    section: SpSection.groups,
    icon: Icons.folder_rounded,
    countKind: DashboardCountKind.groups,
  ),
  DashboardShortcutDefinition(
    id: 'notes',
    title: (l10n) => l10n.dashboardShortcutNotesTitle,
    section: SpSection.notes,
    icon: Icons.sticky_note_2_rounded,
    countKind: DashboardCountKind.notes,
  ),
  DashboardShortcutDefinition(
    id: 'journals',
    title: (l10n) => l10n.dashboardShortcutJournalsTitle,
    subtitle: (l10n) => l10n.dashboardShortcutJournalsSubtitle,
    section: SpSection.journals,
    icon: Icons.menu_book_rounded,
  ),
  DashboardShortcutDefinition(
    id: 'import-export',
    title: (l10n) => l10n.dashboardShortcutImportExportTitle,
    subtitle: (l10n) => l10n.dashboardShortcutImportExportSubtitle,
    section: SpSection.importExport,
    icon: Icons.archive_rounded,
  ),
  DashboardShortcutDefinition(
    id: 'sync',
    title: (l10n) => l10n.syncRowTitle,
    subtitle: (l10n) => l10n.dashboardShortcutSyncSubtitle,
    section: SpSection.sync,
    icon: Icons.sync_disabled_rounded,
  ),
  DashboardShortcutDefinition(
    id: 'customize',
    title: (l10n) => l10n.customizeTitle,
    subtitle: (l10n) => l10n.dashboardShortcutCustomizeSubtitle,
    section: SpSection.appOptions,
    icon: Icons.tune_rounded,
  ),
  DashboardShortcutDefinition(
    id: 'analytics',
    title: (l10n) => l10n.dashboardShortcutAnalyticsTitle,
    subtitle: (l10n) => l10n.dashboardShortcutAnalyticsSubtitle,
    section: SpSection.analytics,
    icon: Icons.analytics_rounded,
  ),
  DashboardShortcutDefinition(
    id: 'reminders',
    title: (l10n) => l10n.dashboardShortcutRemindersTitle,
    subtitle: (l10n) => l10n.dashboardShortcutRemindersSubtitle,
    section: SpSection.reminders,
    icon: Icons.notification_add_rounded,
  ),
  DashboardShortcutDefinition(
    id: 'custom-fields',
    title: (l10n) => l10n.dashboardShortcutCustomFieldsTitle,
    subtitle: (l10n) => l10n.dashboardShortcutCustomFieldsSubtitle,
    section: SpSection.customFields,
    icon: Icons.table_rows_rounded,
  ),
  DashboardShortcutDefinition(
    id: 'friends',
    title: (l10n) => l10n.friendsLabel,
    subtitle: (l10n) => l10n.dashboardShortcutFriendsSubtitle,
    section: SpSection.friends,
    icon: Icons.people_rounded,
  ),
  DashboardShortcutDefinition(
    id: 'chat',
    title: (l10n) => l10n.dashboardShortcutChatTitle,
    subtitle: (l10n) => l10n.dashboardShortcutChatSubtitle,
    section: SpSection.chat,
    icon: Icons.chat_rounded,
  ),
  DashboardShortcutDefinition(
    id: 'polls',
    title: (l10n) => l10n.dashboardShortcutPollsTitle,
    subtitle: (l10n) => l10n.dashboardShortcutPollsSubtitle,
    section: SpSection.polls,
    icon: Icons.how_to_vote_rounded,
  ),
  DashboardShortcutDefinition(
    id: 'useful-links',
    title: (l10n) => l10n.dashboardShortcutUsefulLinksTitle,
    subtitle: (l10n) => l10n.dashboardShortcutUsefulLinksSubtitle,
    section: SpSection.usefulLinks,
    icon: Icons.star_rounded,
  ),
  DashboardShortcutDefinition(
    id: 'privacy-buckets',
    title: (l10n) => l10n.dashboardShortcutPrivacyBucketsTitle,
    subtitle: (l10n) => l10n.dashboardShortcutPrivacyBucketsSubtitle,
    section: SpSection.privacyBuckets,
    icon: Icons.privacy_tip_rounded,
  ),
  DashboardShortcutDefinition(
    id: 'tokens',
    title: (l10n) => l10n.dashboardShortcutTokensTitle,
    subtitle: (l10n) => l10n.dashboardShortcutTokensSubtitle,
    section: SpSection.tokens,
    icon: Icons.verified_user_rounded,
  ),
  DashboardShortcutDefinition(
    id: 'user-report',
    title: (l10n) => l10n.dashboardShortcutUserReportTitle,
    subtitle: (l10n) => l10n.dashboardShortcutUserReportSubtitle,
    section: SpSection.userReport,
    icon: Icons.picture_as_pdf_rounded,
  ),
  DashboardShortcutDefinition(
    id: 'notification-history',
    title: (l10n) => l10n.dashboardShortcutNotificationHistoryTitle,
    subtitle: (l10n) => l10n.dashboardShortcutNotificationHistorySubtitle,
    section: SpSection.notificationHistory,
    icon: Icons.notifications_active_rounded,
  ),
  DashboardShortcutDefinition(
    id: 'howtos',
    title: (l10n) => l10n.dashboardShortcutHowtosTitle,
    subtitle: (l10n) => l10n.dashboardShortcutHowtosSubtitle,
    section: SpSection.howtos,
    icon: Icons.school_rounded,
  ),
  DashboardShortcutDefinition(
    id: 'account-settings',
    title: (l10n) => l10n.dashboardShortcutAccountSettingsTitle,
    subtitle: (l10n) => l10n.dashboardShortcutAccountSettingsSubtitle,
    section: SpSection.accountSettings,
    icon: Icons.settings_rounded,
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
  final String Function(AppLocalizations l10n) title;
  final SpSection section;
  final IconData icon;
  final String Function(AppLocalizations l10n)? subtitle;
  final DashboardCountKind? countKind;

  HomeNavigationItem item(HomeSnapshot? home, AppLocalizations l10n) {
    return HomeNavigationItem(
      title(l10n),
      _subtitle(home, l10n),
      section,
      icon,
    );
  }

  String _subtitle(HomeSnapshot? home, AppLocalizations l10n) {
    return switch (countKind) {
      DashboardCountKind.members => '${home?.memberCount ?? 0}',
      DashboardCountKind.frontHistory => l10n.frontHistoryCountSubtitle(
        home?.frontHistoryCount ?? 0,
      ),
      DashboardCountKind.groups => l10n.groupCountSubtitle(
        home?.groupCount ?? 0,
      ),
      DashboardCountKind.notes => l10n.noteCountSubtitle(home?.noteCount ?? 0),
      null => subtitle?.call(l10n) ?? '',
    };
  }
}
