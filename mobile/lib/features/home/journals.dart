part of 'home_page.dart';

class JournalsPage extends StatefulWidget {
  const JournalsPage({super.key, required this.repository});

  final HavenRepository repository;

  @override
  State<JournalsPage> createState() => _JournalsPageState();
}

class _JournalsPageState extends State<JournalsPage> {
  final _searchController = TextEditingController();
  String _query = '';
  String _filter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<JournalEntry>>(
      stream: widget.repository.watchJournals(),
      initialData: const [],
      builder: (context, snapshot) {
        final entries = _filteredEntries(
          snapshot.data ?? const <JournalEntry>[],
        );

        return SpPage(
          children: [
            SpSearchField(
              hintText: 'Search journals',
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            SpFilterRow(
              filters: const ['All', 'Member', 'System'],
              selected: _filter,
              onSelected: (filter) => setState(() => _filter = filter),
            ),
            const SizedBox(height: 12),
            SpCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SpSectionHeader(
                    title: 'Journals',
                    trailing: StatusPill(text: '${entries.length}'),
                  ),
                  const SizedBox(height: 12),
                  if (entries.isEmpty)
                    SpEmptyState(
                      title: _query.trim().isEmpty && _filter == 'All'
                          ? 'No journal entries yet'
                          : 'No matching journals',
                      body: _query.trim().isEmpty && _filter == 'All'
                          ? 'Write longer dated entries here. Use Notes for short scratchpad items.'
                          : 'Try another search or filter.',
                    )
                  else
                    for (final entry in entries) ...[
                      JournalEntryTile(
                        entry: entry,
                        repository: widget.repository,
                      ),
                      if (entry != entries.last)
                        const Divider(height: 1, color: _spLine),
                    ],
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    key: const ValueKey('add-journal-entry-button'),
                    onPressed: () =>
                        showJournalEntrySheet(context, widget.repository),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add journal entry'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  List<JournalEntry> _filteredEntries(List<JournalEntry> entries) {
    return [
      for (final entry in entries)
        if (_matchesQuery(_query, [entry.title, entry.body]) &&
            switch (_filter) {
              'Member' => entry.memberId != null,
              'System' => entry.memberId == null,
              _ => true,
            })
          entry,
    ];
  }
}

class JournalEntryTile extends StatelessWidget {
  const JournalEntryTile({
    super.key,
    required this.entry,
    required this.repository,
  });

  final JournalEntry entry;
  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
    final title = entry.title?.trim();
    final body = entry.body.trim();

    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const SpIconBubble(icon: Icons.menu_book_outlined),
        title: Text(
          title == null || title.isEmpty ? 'Untitled entry' : title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              body.isEmpty ? 'empty journal' : body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _spMuted),
            ),
            const SizedBox(height: 4),
            Text(
              _shortDateTime(entry.createdAt),
              style: const TextStyle(color: _spMuted, fontSize: 12),
            ),
          ],
        ),
        trailing: IconButton(
          tooltip: 'Delete journal entry',
          onPressed: () => confirmDelete(
            context,
            title: 'Delete journal entry?',
            body: 'This entry will be permanently removed from this device.',
            onDelete: () => repository.deleteJournal(entry.id),
          ),
          icon: const Icon(Icons.delete_outline_rounded),
        ),
        onTap: () => showJournalEntrySheet(context, repository, entry: entry),
      ),
    );
  }
}

void showJournalEntrySheet(
  BuildContext context,
  HavenRepository repository, {
  JournalEntry? entry,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: _spSurface,
    builder: (context) =>
        JournalEntrySheet(repository: repository, entry: entry),
  );
}

class JournalEntrySheet extends StatefulWidget {
  const JournalEntrySheet({super.key, required this.repository, this.entry});

  final HavenRepository repository;
  final JournalEntry? entry;

  @override
  State<JournalEntrySheet> createState() => _JournalEntrySheetState();
}

class _JournalEntrySheetState extends State<JournalEntrySheet> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    if (entry == null) {
      return;
    }
    _titleController.text = entry.title ?? '';
    _bodyController.text = entry.body;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          18,
          0,
          18,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? 'Edit journal entry' : 'Add journal entry',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('journal-title-field'),
              controller: _titleController,
              autofocus: !_isEditing,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('journal-body-field'),
              controller: _bodyController,
              minLines: 8,
              maxLines: 12,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(labelText: 'Entry'),
            ),
            const SizedBox(height: 14),
            FilledButton(
              key: const ValueKey('save-journal-entry-button'),
              onPressed: _save,
              child: Text(_isEditing ? 'Save entry' : 'Create entry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty) {
      return;
    }
    final now = DateTime.now().toUtc();
    final existing = widget.entry;
    await widget.repository.saveJournal(
      JournalEntry(
        id: existing?.id ?? 'journal-${now.microsecondsSinceEpoch}',
        systemId: localSystemId,
        memberId: existing?.memberId,
        title: _nullIfBlank(_titleController.text),
        body: _bodyController.text,
        visibility: existing?.visibility ?? 'system',
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      ),
    );
    if (mounted) {
      Navigator.pop(context);
    }
  }
}
