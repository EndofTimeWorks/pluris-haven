part of 'home_page.dart';

class DashboardSystemHeader extends StatelessWidget {
  const DashboardSystemHeader({super.key, required this.snapshot});

  final HomeSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final home = snapshot;

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
                style: const TextStyle(fontSize: 16, color: _spText),
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
    return AspectRatio(
      aspectRatio: 1,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _spCard,
          foregroundColor: _spText,
          elevation: 0,
          padding: const EdgeInsets.all(10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: _spGold, size: 22),
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
                style: const TextStyle(color: _spMuted, fontSize: 11),
              ),
            ],
          ],
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
    return Text(
      label,
      style: const TextStyle(
        color: _spMuted,
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
    final home = snapshot;

    return SpCard(
      child: Row(
        children: [
          SpAvatar(
            size: 52,
            color: Theme.of(context).colorScheme.primary,
            label: 'PH',
            semanticLabel:
                'System avatar for ${home?.systemName ?? 'Local system'}',
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
                  style: const TextStyle(color: _spMuted, fontSize: 15),
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
    final home = snapshot;

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
                const Text(
                  'Currently fronting',
                  style: TextStyle(
                    color: _spMuted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  home?.currentFrontText ?? 'None',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _spText,
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
                                label:
                                    '${member.displayName} is currently fronting',
                                child: MemberAvatar(
                                  member: member,
                                  color: _colorFromHex(member.colorHex),
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
              const Text(
                'set front',
                style: TextStyle(color: _spMuted, fontWeight: FontWeight.w700),
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
      showDragHandle: true,
      backgroundColor: _spSurface,
      builder: (context) => CustomFrontSheet(repository: repository),
    );
  }
}
