part of 'home_page.dart';

class NotesPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return StreamBuilder<List<NoteSummary>>(
      stream: repository.watchNotes(),
      initialData: const [],
      builder: (context, noteSnapshot) {
        final notes = noteSnapshot.data ?? const <NoteSummary>[];

        return SpPage(
          children: [
            const SpSearchField(hintText: 'Search notes'),
            const SizedBox(height: 12),
            const SpFilterRow(filters: ['All', 'Member', 'System']),
            const SizedBox(height: 12),
            SpCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SpSectionHeader(
                    title: 'Notes',
                    trailing: StatusPill(text: '${snapshot?.noteCount ?? 0}'),
                  ),
                  const SizedBox(height: 12),
                  if (notes.isEmpty)
                    const SpEmptyState(
                      title: 'No notes yet',
                      body:
                          'Local notes can be attached to members or kept general.',
                    )
                  else
                    for (final note in notes) ...[
                      NoteListTile(note: note, repository: repository),
                      if (note != notes.last)
                        const Divider(height: 1, color: _spLine),
                    ],
                  const SizedBox(height: 14),
                  SpActionRow(
                    primary: 'Add note',
                    secondary: 'Import',
                    onPrimary: () => showAddNoteSheet(context, repository),
                    onSecondary: onImport,
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

class NoteListTile extends StatelessWidget {
  const NoteListTile({super.key, required this.note, required this.repository});

  final NoteSummary note;
  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
    final body = note.body.trim();

    return ListTile(
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
    );
  }
}

void showAddNoteSheet(BuildContext context, HavenRepository repository) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: _spSurface,
    builder: (context) => AddNoteSheet(repository: repository),
  );
}

class AddNoteSheet extends StatefulWidget {
  const AddNoteSheet({super.key, required this.repository});

  final HavenRepository repository;

  @override
  State<AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends State<AddNoteSheet> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

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
            const Text(
              'Add note',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
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
    await widget.repository.saveNote(
      NoteDraft(title: _titleController.text, body: _bodyController.text),
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }
}
