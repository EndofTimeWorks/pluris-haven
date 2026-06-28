part of 'home_page.dart';

class FrontHistoryPage extends StatefulWidget {
  const FrontHistoryPage({
    super.key,
    required this.snapshot,
    required this.repository,
  });

  final HomeSnapshot? snapshot;
  final HavenRepository repository;

  @override
  State<FrontHistoryPage> createState() => _FrontHistoryPageState();
}

class _FrontHistoryPageState extends State<FrontHistoryPage> {
  final _searchController = TextEditingController();
  String _filter = 'All';
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FrontHistoryEntry>>(
      stream: widget.repository.watchFrontHistory(),
      initialData: const [],
      builder: (context, historySnapshot) {
        final entries = historySnapshot.data ?? const <FrontHistoryEntry>[];
        final filteredEntries = entries.where(_matchesEntry).toList();

        return SpPage(
          children: [
            CurrentFrontEntry(
              snapshot: widget.snapshot,
              repository: widget.repository,
            ),
            const SizedBox(height: 12),
            SpSearchField(
              key: const ValueKey('front-history-search-field'),
              hintText: 'Search front history',
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            SpFilterRow(
              filters: const ['All', 'Today', 'Week', 'Month'],
              selected: _filter,
              onSelected: (value) => setState(() => _filter = value),
            ),
            const SizedBox(height: 12),
            SpCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SpSectionHeader(
                    title: 'Front history',
                    trailing: StatusPill(
                      text: '${filteredEntries.length}/${entries.length}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (entries.isEmpty)
                    const SpEmptyState(
                      title: 'No front history yet',
                      body: 'Set a front or import an archive to fill this in.',
                    )
                  else if (filteredEntries.isEmpty)
                    const SpEmptyState(
                      title: 'No matching fronts',
                      body: 'Try a wider date range or a shorter search.',
                    )
                  else
                    for (final entry in filteredEntries) ...[
                      FrontHistoryTile(
                        entry: entry,
                        repository: widget.repository,
                      ),
                      if (entry != filteredEntries.last)
                        const Divider(height: 1, color: _spLine),
                    ],
                  const SizedBox(height: 14),
                  SpActionRow(
                    primary: 'Add entry',
                    secondary: 'Reset',
                    onPrimary: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      backgroundColor: _spSurface,
                      builder: (context) =>
                          CustomFrontSheet(repository: widget.repository),
                    ),
                    onSecondary: () {
                      _searchController.clear();
                      setState(() {
                        _query = '';
                        _filter = 'All';
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  bool _matchesEntry(FrontHistoryEntry entry) {
    if (!_matchesFrontDateFilter(entry)) {
      return false;
    }
    return _matchesQuery(_query, [
      entry.label,
      entry.statusNote,
      _frontTimingLabel(entry),
    ]);
  }

  bool _matchesFrontDateFilter(FrontHistoryEntry entry) {
    if (_filter == 'All') {
      return true;
    }

    final now = DateTime.now();
    final local = entry.startedAt.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final start = switch (_filter) {
      'Today' => today,
      'Week' => today.subtract(const Duration(days: 7)),
      'Month' => DateTime(now.year, now.month - 1, now.day),
      _ => DateTime.fromMillisecondsSinceEpoch(0),
    };
    return !local.isBefore(start);
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
