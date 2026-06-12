import 'package:flutter/material.dart';

import '../../data/local/haven_repository.dart';

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
          appBar: AppBar(
            toolbarHeight: 88,
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
                    fontSize: 13,
                    color: Color(0xFFC7C3D0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
            children: [
              SystemOverviewCard(snapshot: home),
              const SizedBox(height: 12),
              CurrentFrontPanel(snapshot: home, repository: repository),
              const SizedBox(height: 14),
              for (final module in _modules(home)) ...[
                ModuleRow(module: module),
                const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
  }

  List<HomeModule> _modules(HomeSnapshot? snapshot) {
    final home = snapshot;

    return [
      HomeModule('Members', '${home?.memberCount ?? 0} saved'),
      HomeModule('Front History', '${home?.frontHistoryCount ?? 0} entries'),
      HomeModule('Groups', '${home?.groupCount ?? 0} groups'),
      HomeModule('Notes', '${home?.noteCount ?? 0} notes'),
      const HomeModule('Import / Export', 'local archive'),
      const HomeModule('Sync', 'off by default'),
    ];
  }
}

class SystemOverviewCard extends StatelessWidget {
  const SystemOverviewCard({super.key, required this.snapshot});

  final HomeSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final home = snapshot;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
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
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${home?.memberCount ?? 0} members - ${home?.groupCount ?? 0} groups',
                    style: const TextStyle(
                      color: Color(0xFFC7C3D0),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CurrentFrontPanel extends StatelessWidget {
  const CurrentFrontPanel({
    super.key,
    required this.snapshot,
    required this.repository,
  });

  final HomeSnapshot? snapshot;
  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
    final home = snapshot;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showFrontSheet(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
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
                        color: Color(0xFFC7C3D0),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      home?.currentFrontText ?? 'None',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
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
                    style: TextStyle(
                      color: Color(0xFFC7C3D0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showFrontSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: _setFront,
                decoration: const InputDecoration(
                  labelText: 'Custom front',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: () => _setFront(_controller.text),
              child: const Text('Set'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () async {
                await widget.repository.clearCurrentFront();
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Clear'),
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

class ModuleRow extends StatelessWidget {
  const ModuleRow({super.key, required this.module});

  final HomeModule module;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      module.subtitle,
                      style: const TextStyle(
                        color: Color(0xFFC7C3D0),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                '>',
                style: TextStyle(
                  color: Color(0xFFC7C3D0),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFFC7C3D0),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class HomeModule {
  const HomeModule(this.title, this.subtitle);

  final String title;
  final String subtitle;
}
