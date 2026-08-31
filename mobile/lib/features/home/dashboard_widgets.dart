part of 'home_page.dart';

class DashboardSystemHeader extends StatelessWidget {
  const DashboardSystemHeader({super.key, required this.snapshot});

  final HomeSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final home = snapshot;
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 58,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            StoredAvatar(
              size: 24,
              color: _colorFromHex(
                home?.systemColorHex,
                fallback: Theme.of(context).colorScheme.primary,
              ),
              avatarUrl: home?.systemAvatarUrl,
              label: 'PH',
              semanticLabel:
                  'System avatar for ${home?.systemName ?? 'Local system'}',
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                home?.systemName ?? 'Local system',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16, color: scheme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SpDashboardTile extends StatelessWidget {
  const SpDashboardTile({
    super.key,
    required this.item,
    required this.compact,
    required this.showSubtitle,
    required this.onTap,
  });

  final HomeNavigationItem item;
  final bool compact;
  final bool showSubtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3),
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: scheme.surfaceContainerHighest,
            foregroundColor: scheme.onSurface,
            elevation: 0,
            padding: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: scheme.primary, size: 22),
              SizedBox(height: compact ? 10 : 14),
              Text(
                item.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, height: 1.15),
              ),
              if (showSubtitle && !compact) ...[
                const SizedBox(height: 5),
                Text(
                  item.subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardSectionTitle extends StatelessWidget {
  const DashboardSectionTitle(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      label,
      style: TextStyle(
        color: scheme.onSurfaceVariant,
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class DashboardActionGrid extends StatelessWidget {
  const DashboardActionGrid({
    super.key,
    required this.items,
    required this.customization,
    required this.onSelect,
  });

  final List<HomeNavigationItem> items;
  final AppCustomization customization;
  final ValueChanged<SpSection> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 170,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.15,
      ),
      children: [
        for (final item in items)
          SpDashboardTile(
            item: item,
            compact: customization.compactDashboard,
            showSubtitle: customization.showDashboardSubtitles,
            onTap: () => onSelect(item.section),
          ),
      ],
    );
  }
}

class SystemListEntry extends StatelessWidget {
  const SystemListEntry({super.key, required this.snapshot});

  final HomeSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final home = snapshot;
    final scheme = Theme.of(context).colorScheme;

    return SpCard(
      child: Row(
        children: [
          SpAvatar(
            size: 52,
            color: Theme.of(context).colorScheme.primary,
            label: 'PH',
            semanticLabel: l10n.systemAvatarFor(
              home?.systemName ?? l10n.localSystemFallback,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  home?.systemName ?? l10n.localSystemFallback,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.systemCounts(
                    home?.memberCount ?? 0,
                    home?.groupCount ?? 0,
                  ),
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CurrentFrontEntry extends StatelessWidget {
  const CurrentFrontEntry({
    super.key,
    required this.snapshot,
    required this.repository,
  });

  final HomeSnapshot? snapshot;
  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final home = snapshot;
    final scheme = Theme.of(context).colorScheme;

    return SpCard(
      outlined: true,
      onTap: () => _showFrontSheet(context),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 56,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.currentlyFrontingNotificationTitle,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  home?.currentFrontText ?? l10n.noneTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                StreamBuilder<List<MemberSummary>>(
                  stream: repository.watchCurrentFrontMembers(),
                  initialData: const [],
                  builder: (context, snapshot) {
                    final members = snapshot.data ?? const <MemberSummary>[];
                    if (members.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          for (final member in members.take(4))
                            Tooltip(
                              message: member.displayName,
                              child: Semantics(
                                container: true,
                                excludeSemantics: true,
                                label: l10n.memberIsFronting(
                                  member.displayName,
                                ),
                                child: MemberAvatar(
                                  member: member,
                                  color: _colorFromHex(
                                    member.colorHex,
                                    fallback: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  label: _initialFor(member.displayName),
                                  size: 28,
                                ),
                              ),
                            ),
                          if (members.length > 4)
                            StatusPill(text: '+${members.length - 4}'),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusPill(text: home?.currentFrontStatus ?? 'none'),
              const SizedBox(height: 8),
              Text(
                l10n.setFrontButton,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showFrontSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => CustomFrontSheet(repository: repository),
    );
  }
}
