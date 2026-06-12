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
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pluris Haven',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  home?.systemName ?? 'saved on device',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFC7C3D0),
                  ),
                ),
              ],
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              CurrentFrontPanel(snapshot: home),
              const SizedBox(height: 12),
              CustomFrontCard(repository: repository),
              const SizedBox(height: 12),
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
      HomeModule(
        'Members',
        '${home?.memberCount ?? 0} saved',
        Icons.groups_rounded,
      ),
      HomeModule(
        'Front History',
        '${home?.frontHistoryCount ?? 0} entries',
        Icons.history_rounded,
      ),
      HomeModule(
        'Groups',
        '${home?.groupCount ?? 0} groups',
        Icons.folder_rounded,
      ),
      HomeModule('Notes', '${home?.noteCount ?? 0} notes', Icons.notes_rounded),
      const HomeModule(
        'Import / Export',
        'local archive',
        Icons.import_export_rounded,
      ),
      const HomeModule('Sync', 'off by default', Icons.sync_disabled_rounded),
    ];
  }
}

class CurrentFrontPanel extends StatelessWidget {
  const CurrentFrontPanel({super.key, required this.snapshot});

  final HomeSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final home = snapshot;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
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
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    home?.currentFrontText ?? 'None',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            StatusPill(text: home?.currentFrontStatus ?? 'none'),
          ],
        ),
      ),
    );
  }
}

class CustomFrontCard extends StatefulWidget {
  const CustomFrontCard({super.key, required this.repository});

  final HavenRepository repository;

  @override
  State<CustomFrontCard> createState() => _CustomFrontCardState();
}

class _CustomFrontCardState extends State<CustomFrontCard> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Custom front',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.done,
              onSubmitted: _setFront,
              decoration: const InputDecoration(
                labelText: 'Label',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton(
                  onPressed: () => _setFront(_controller.text),
                  child: const Text('Set'),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () async {
                    _controller.clear();
                    await widget.repository.clearCurrentFront();
                  },
                  child: const Text('Clear'),
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
    _controller.clear();
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Icon(module.icon, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(width: 14),
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
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFC7C3D0)),
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
  const HomeModule(this.title, this.subtitle, this.icon);

  final String title;
  final String subtitle;
  final IconData icon;
}
