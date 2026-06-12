import 'package:flutter/material.dart';

import '../../data/local/haven_repository.dart';

const _spSurface = Color(0xFF232532);
const _spCard = Color(0xFF2B2E3D);
const _spLine = Color(0xFF3A3E50);
const _spText = Color(0xFFECEAF2);
const _spMuted = Color(0xFFC4C0CE);
const _spPurple = Color(0xFF7B61FF);
const _spGold = Color(0xFFF2C75C);

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.repository});

  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<HomeSnapshot>(
      stream: repository.watchHomeSnapshot(),
      builder: (context, snapshot) {
        final home = snapshot.data;

        return Scaffold(
          drawer: SpDrawer(snapshot: home),
          appBar: AppBar(
            toolbarHeight: 86,
            titleSpacing: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pluris Haven',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  home?.systemName ?? 'saved on device',
                  style: const TextStyle(
                    color: _spMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 24),
            children: [
              SystemListEntry(snapshot: home),
              const SizedBox(height: 12),
              CurrentFrontEntry(snapshot: home, repository: repository),
              const SizedBox(height: 14),
              for (final item in _items(home)) ...[
                SpNavigationEntry(item: item),
                const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
  }

  List<HomeNavigationItem> _items(HomeSnapshot? home) {
    return [
      HomeNavigationItem('Members', '${home?.memberCount ?? 0} saved'),
      HomeNavigationItem(
        'Front History',
        '${home?.frontHistoryCount ?? 0} entries',
      ),
      HomeNavigationItem('Groups', '${home?.groupCount ?? 0} groups'),
      HomeNavigationItem('Notes', '${home?.noteCount ?? 0} notes'),
      const HomeNavigationItem('Import / Export', 'local archive'),
      const HomeNavigationItem('Sync', 'off by default'),
    ];
  }
}

class SpDrawer extends StatelessWidget {
  const SpDrawer({super.key, required this.snapshot});

  final HomeSnapshot? snapshot;

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
                  const SpAvatar(size: 52, color: _spPurple),
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
            const DrawerEntry(label: 'Members'),
            const DrawerEntry(label: 'Front History'),
            const DrawerEntry(label: 'Groups'),
            const DrawerEntry(label: 'Notes'),
            const DrawerEntry(label: 'Import / Export'),
            const Divider(height: 24),
            const DrawerEntry(label: 'App options'),
            const DrawerEntry(label: 'About'),
          ],
        ),
      ),
    );
  }
}

class DrawerEntry extends StatelessWidget {
  const DrawerEntry({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Text('>', style: TextStyle(color: _spMuted)),
      onTap: () => Navigator.pop(context),
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
          const SpAvatar(size: 52, color: _spPurple),
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
              color: _spPurple,
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

class CustomFrontSheet extends StatefulWidget {
  const CustomFrontSheet({super.key, required this.repository});

  final HavenRepository repository;

  @override
  State<CustomFrontSheet> createState() => _CustomFrontSheetState();
}

class _CustomFrontSheetState extends State<CustomFrontSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          0,
          18,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Set custom front',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: _setFront,
              decoration: const InputDecoration(labelText: 'Label'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => _setFront(_controller.text),
                    child: const Text('Set'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await widget.repository.clearCurrentFront();
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Clear'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setFront(String label) async {
    await widget.repository.setCustomFront(label);
    if (mounted) {
      Navigator.pop(context);
    }
  }
}

class SpNavigationEntry extends StatelessWidget {
  const SpNavigationEntry({super.key, required this.item});

  final HomeNavigationItem item;

  @override
  Widget build(BuildContext context) {
    return SpCard(
      onTap: () {},
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Row(
        children: [
          const AccentDot(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: const TextStyle(color: _spMuted, fontSize: 14),
                ),
              ],
            ),
          ),
          const Text(
            '>',
            style: TextStyle(
              color: _spMuted,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class SpCard extends StatelessWidget {
  const SpCard({
    super.key,
    required this.child,
    this.onTap,
    this.outlined = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool outlined;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: _spCard,
        borderRadius: BorderRadius.circular(12),
        border: outlined ? Border.all(color: _spLine) : null,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class SpAvatar extends StatelessWidget {
  const SpAvatar({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class AccentDot extends StatelessWidget {
  const AccentDot({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: _spGold, shape: BoxShape.circle),
      child: SizedBox(width: 20, height: 20),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _spSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          text,
          style: const TextStyle(color: _spMuted, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class HomeNavigationItem {
  const HomeNavigationItem(this.title, this.subtitle);

  final String title;
  final String subtitle;
}
