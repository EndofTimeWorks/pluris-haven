part of 'home_page.dart';

class FrontHistoryPage extends StatelessWidget {
  const FrontHistoryPage({
    super.key,
    required this.snapshot,
    required this.repository,
  });

  final HomeSnapshot? snapshot;
  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FrontHistoryEntry>>(
      stream: repository.watchFrontHistory(),
      initialData: const [],
      builder: (context, historySnapshot) {
        final entries = historySnapshot.data ?? const <FrontHistoryEntry>[];

        return SpPage(
          children: [
            CurrentFrontEntry(snapshot: snapshot, repository: repository),
            const SizedBox(height: 12),
            const SpFilterRow(filters: ['Today', 'Week', 'Month', 'All']),
            const SizedBox(height: 12),
            SpCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SpSectionHeader(
                    title: 'Front history',
                    trailing: StatusPill(
                      text: '${snapshot?.frontHistoryCount ?? 0} entries',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (entries.isEmpty)
                    const SpEmptyState(
                      title: 'No front history yet',
                      body: 'Set a front or import an archive to fill this in.',
                    )
                  else
                    for (final entry in entries) ...[
                      FrontHistoryTile(entry: entry),
                      if (entry != entries.last)
                        const Divider(height: 1, color: _spLine),
                    ],
                  const SizedBox(height: 14),
                  SpActionRow(
                    primary: 'Add entry',
                    secondary: 'Filter',
                    onPrimary: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      backgroundColor: _spSurface,
                      builder: (context) =>
                          CustomFrontSheet(repository: repository),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class FrontHistoryTile extends StatelessWidget {
  const FrontHistoryTile({super.key, required this.entry});

  final FrontHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: SpIconBubble(
        icon: entry.isActive
            ? Icons.radio_button_checked_rounded
            : Icons.history_rounded,
      ),
      title: Text(
        entry.label,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        _frontTimingLabel(entry),
        style: const TextStyle(color: _spMuted),
      ),
    );
  }
}

String _frontTimingLabel(FrontHistoryEntry entry) {
  final started = _shortDateTime(entry.startedAt);
  if (entry.endedAt == null) {
    return 'started $started - active';
  }

  return 'started $started - ended ${_shortDateTime(entry.endedAt!)}';
}

String _shortDateTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.month}/${local.day} $hour:$minute';
}
