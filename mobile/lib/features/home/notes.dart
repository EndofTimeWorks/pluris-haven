part of 'home_page.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({
    super.key,
    required this.snapshot,
    required this.repository,
    required this.onImport,
  });

  final HomeSnapshot? snapshot;
  final HavenRepository repository;
  final VoidCallback onImport;

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
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
    return StreamBuilder<List<NoteSummary>>(
      stream: widget.repository.watchNotes(),
      initialData: const [],
      builder: (context, noteSnapshot) {
        final notes = _filteredNotes(
          noteSnapshot.data ?? const <NoteSummary>[],
        );

        return SpPage(
          children: [
            SpSearchField(
              hintText: 'Search notes',
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
                    title: 'Notes',
                    trailing: StatusPill(
                      text: '${widget.snapshot?.noteCount ?? 0}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (notes.isEmpty)
                    SpEmptyState(
                      title: _query.trim().isEmpty && _filter == 'All'
                          ? 'No notes yet'
                          : 'No matching notes',
                      body: _query.trim().isEmpty && _filter == 'All'
                          ? 'Local notes can be attached to members or kept general.'
                          : 'Try another search or filter.',
                    )
                  else
                    for (final note in notes) ...[
                      NoteListTile(note: note, repository: widget.repository),
                      if (note != notes.last)
                        const Divider(height: 1, color: _spLine),
                    ],
                  const SizedBox(height: 14),
                  SpActionRow(
                    primary: 'Add note',
                    secondary: 'Import',
                    onPrimary: () => showNoteSheet(context, widget.repository),
                    onSecondary: widget.onImport,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  List<NoteSummary> _filteredNotes(List<NoteSummary> notes) {
    return [
      for (final note in notes)
        if (_matchesQuery(_query, [note.title, note.body]) &&
            switch (_filter) {
              'Member' => note.memberId != null,
              'System' => note.memberId == null,
              _ => true,
            })
          note,
    ];
  }
}

class NoteListTile extends StatelessWidget {
  const NoteListTile({super.key, required this.note, required this.repository});

  final NoteSummary note;
  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
    final body = note.body.trim();

    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const SpIconBubble(icon: Icons.sticky_note_2_outlined),
        title: Text(
          note.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          body.isEmpty ? 'empty note' : body,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: _spMuted),
        ),
        trailing: IconButton(
          tooltip: 'Delete note',
          onPressed: () => confirmDelete(
            context,
            title: 'Delete note?',
            body: 'This note will be permanently removed.',
            onDelete: () => repository.deleteNote(note.id),
          ),
          icon: const Icon(Icons.delete_outline_rounded),
        ),
        onTap: () => showNoteSheet(context, repository, note: note),
      ),
    );
  }
}

void showNoteSheet(
  BuildContext context,
  HavenRepository repository, {
  NoteSummary? note,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: _spSurface,
    builder: (context) => NoteSheet(repository: repository, note: note),
  );
}

class NoteSheet extends StatefulWidget {
  const NoteSheet({super.key, required this.repository, this.note});

  final HavenRepository repository;
  final NoteSummary? note;

  @override
  State<NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<NoteSheet> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    if (note == null) {
      return;
    }
    _titleController.text = note.title;
    _bodyController.text = note.body;
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
              _isEditing ? 'Edit note' : 'Add note',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('note-title-field'),
              controller: _titleController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('note-body-field'),
              controller: _bodyController,
              minLines: 5,
              maxLines: 8,
              decoration: const InputDecoration(labelText: 'Note'),
            ),
            const SizedBox(height: 14),
            FilledButton(
              key: const ValueKey('save-note-button'),
              onPressed: _save,
              child: const Text('Save note'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final draft = NoteDraft(
      title: _titleController.text,
      body: _bodyController.text,
    );
    final note = widget.note;
    if (note == null) {
      await widget.repository.saveNote(draft);
    } else {
      await widget.repository.updateNote(note.id, draft);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }
}
