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
    final l10n = AppLocalizations.of(context);
    return SpPage(
      children: [
        SpCard(
          outlined: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SpSectionHeader(
                title: title,
                trailing: StatusPill(text: l10n.offlineStatusPill),
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
    final l10n = AppLocalizations.of(context);
    final systemName = (home?.systemName ?? '').trim().isEmpty
        ? l10n.localSystemName
        : home!.systemName.trim();

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
              child: Row(
                children: [
                  StoredAvatar(
                    size: 52,
                    color: _colorFromHex(
                      home?.systemColorHex,
                      fallback: Theme.of(context).colorScheme.primary,
                    ),
                    avatarUrl: home?.systemAvatarUrl,
                    label: (home?.systemName ?? '').trim().isEmpty
                        ? 'PH'
                        : home!.systemName.trim().substring(0, 1),
                    semanticLabel: l10n.systemAvatarSemanticLabel(systemName),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          systemName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.systemMemberGroupCount(
                            home?.memberCount ?? 0,
                            home?.groupCount ?? 0,
                          ),
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
              label: SpSection.dashboard.label(l10n),
              section: SpSection.dashboard,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: SpSection.members.label(l10n),
              section: SpSection.members,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: SpSection.frontHistory.label(l10n),
              section: SpSection.frontHistory,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: SpSection.customFronts.label(l10n),
              section: SpSection.customFronts,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: SpSection.groups.label(l10n),
              section: SpSection.groups,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: SpSection.notes.label(l10n),
              section: SpSection.notes,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: SpSection.journals.label(l10n),
              section: SpSection.journals,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: SpSection.analytics.label(l10n),
              section: SpSection.analytics,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: SpSection.chat.label(l10n),
              section: SpSection.chat,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: SpSection.polls.label(l10n),
              section: SpSection.polls,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: SpSection.customFields.label(l10n),
              section: SpSection.customFields,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: SpSection.friends.label(l10n),
              section: SpSection.friends,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: SpSection.usefulLinks.label(l10n),
              section: SpSection.usefulLinks,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: SpSection.privacyBuckets.label(l10n),
              section: SpSection.privacyBuckets,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: SpSection.tokens.label(l10n),
              section: SpSection.tokens,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: SpSection.userReport.label(l10n),
              section: SpSection.userReport,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: SpSection.notificationHistory.label(l10n),
              section: SpSection.notificationHistory,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: SpSection.howtos.label(l10n),
              section: SpSection.howtos,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: SpSection.reminders.label(l10n),
              section: SpSection.reminders,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: SpSection.importExport.label(l10n),
              section: SpSection.importExport,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: SpSection.sync.label(l10n),
              section: SpSection.sync,
              selected: selected,
              onSelect: onSelect,
            ),
            const Divider(height: 24),
            DrawerEntry(
              label: SpSection.appOptions.label(l10n),
              section: SpSection.appOptions,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: SpSection.accountSettings.label(l10n),
              section: SpSection.accountSettings,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: SpSection.about.label(l10n),
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
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        child: Material(
          color: isSelected
              ? scheme.surfaceContainerHighest
              : Colors.transparent,
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
                        color: isSelected ? scheme.onSurface : null,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text('>', style: TextStyle(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
