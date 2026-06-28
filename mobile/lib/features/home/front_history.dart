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
                      FrontHistoryTile(entry: entry, repository: repository),
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
  const FrontHistoryTile({
    super.key,
    required this.entry,
    required this.repository,
  });

  final FrontHistoryEntry entry;
  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: () => showFrontHistoryDetailSheet(context, repository, entry),
        leading: SpIconBubble(
          icon: entry.isActive
              ? Icons.radio_button_checked_rounded
              : Icons.history_rounded,
        ),
        title: Text(
          entry.label,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _frontTimingLabel(entry),
              style: const TextStyle(color: _spMuted),
            ),
            if ((entry.statusNote ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                entry.statusNote!.trim(),
                style: const TextStyle(color: _spText),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

void showFrontHistoryDetailSheet(
  BuildContext context,
  HavenRepository repository,
  FrontHistoryEntry entry,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: _spSurface,
    builder: (context) =>
        FrontHistoryDetailSheet(repository: repository, entry: entry),
  );
}

class FrontHistoryDetailSheet extends StatefulWidget {
  const FrontHistoryDetailSheet({
    super.key,
    required this.repository,
    required this.entry,
  });

  final HavenRepository repository;
  final FrontHistoryEntry entry;

  @override
  State<FrontHistoryDetailSheet> createState() =>
      _FrontHistoryDetailSheetState();
}

class _FrontHistoryDetailSheetState extends State<FrontHistoryDetailSheet> {
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.entry.statusNote);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, 6, 18, 18 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SpIconBubble(
                  icon: widget.entry.isActive
                      ? Icons.radio_button_checked_rounded
                      : Icons.history_rounded,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.entry.label,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _frontTimingLabel(widget.entry),
                        style: const TextStyle(color: _spMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              key: const ValueKey('front-status-note-field'),
              controller: _noteController,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Status note',
                hintText: 'Add context for this front',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const ValueKey('save-front-status-note-button'),
              onPressed: () async {
                await widget.repository.updateFrontStatusNote(
                  widget.entry.id,
                  _noteController.text,
                );
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save note'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => confirmDelete(
                context,
                title: 'Delete front entry?',
                body: 'This removes this front history entry from the archive.',
                onDelete: () async {
                  await widget.repository.deleteFrontSession(widget.entry.id);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Delete entry'),
            ),
          ],
        ),
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
