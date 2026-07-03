part of 'home_page.dart';

class OfflineFeaturePage extends StatelessWidget {
  const OfflineFeaturePage({
    super.key,
    required this.title,
    required this.body,
    required this.rows,
  });

  final String title;
  final String body;
  final List<SpSettingsRow> rows;

  @override
  Widget build(BuildContext context) {
    return SpPage(
      children: [
        SpCard(
          outlined: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SpSectionHeader(
                title: title,
                trailing: const StatusPill(text: 'offline'),
              ),
              const SizedBox(height: 8),
              Text(body, style: const TextStyle(color: _spMuted, height: 1.35)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SpSettingsGroup(title: title, rows: rows),
      ],
    );
  }
}

class SpDrawer extends StatelessWidget {
  const SpDrawer({
    super.key,
    required this.snapshot,
    required this.selected,
    required this.onSelect,
  });

  final HomeSnapshot? snapshot;
  final SpSection selected;
  final ValueChanged<SpSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final home = snapshot;

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
              child: Row(
                children: [
                  SpAvatar(
                    size: 52,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          home?.systemName ?? 'Local system',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${home?.memberCount ?? 0} members - ${home?.groupCount ?? 0} groups',
                          style: const TextStyle(color: _spMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            DrawerEntry(
              label: 'Dashboard',
              section: SpSection.dashboard,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: 'Members',
              section: SpSection.members,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: 'Front History',
              section: SpSection.frontHistory,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: 'Custom Fronts',
              section: SpSection.customFronts,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: 'Groups',
              section: SpSection.groups,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: 'Notes',
              section: SpSection.notes,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: 'Journals',
              section: SpSection.journals,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: 'Analytics',
              section: SpSection.analytics,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: 'Chat',
              section: SpSection.chat,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: 'Polls',
              section: SpSection.polls,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: 'Custom Fields',
              section: SpSection.customFields,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: 'Friends',
              section: SpSection.friends,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: 'Useful Links',
              section: SpSection.usefulLinks,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: 'Privacy buckets',
              section: SpSection.privacyBuckets,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: 'Tokens',
              section: SpSection.tokens,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: 'User Report',
              section: SpSection.userReport,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: 'Notification History',
              section: SpSection.notificationHistory,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: "How-to's",
              section: SpSection.howtos,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: 'Reminders',
              section: SpSection.reminders,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: 'Import / Export',
              section: SpSection.importExport,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: 'Sync',
              section: SpSection.sync,
              selected: selected,
              onSelect: onSelect,
            ),
            const Divider(height: 24),
            DrawerEntry(
              label: 'App options',
              section: SpSection.appOptions,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: 'Account Settings',
              section: SpSection.accountSettings,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: 'About',
              section: SpSection.about,
              selected: selected,
              onSelect: onSelect,
            ),
          ],
        ),
      ),
    );
  }
}

class DrawerEntry extends StatelessWidget {
  const DrawerEntry({
    super.key,
    required this.label,
    required this.section,
    required this.selected,
    required this.onSelect,
  });

  final String label;
  final SpSection section;
  final SpSection selected;
  final ValueChanged<SpSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == section;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: isSelected ? _spCard : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            Navigator.pop(context);
            onSelect(section);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? _spText : null,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Text('>', style: TextStyle(color: _spMuted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
