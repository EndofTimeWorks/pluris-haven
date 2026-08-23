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
  _NoteFilter _filter = _NoteFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<List<NoteSummary>>(
      stream: widget.repository.watchNotes(),
      initialData: const [],
      builder: (context, noteSnapshot) {
        return StreamBuilder<List<MemberSummary>>(
          stream: widget.repository.watchMembers(includeArchived: true),
          initialData: const [],
          builder: (context, memberSnapshot) {
            final memberNamesById = {
              for (final member
                  in memberSnapshot.data ?? const <MemberSummary>[])
                member.id: member.displayName,
            };
            final notes = _filteredNotes(
              noteSnapshot.data ?? const <NoteSummary>[],
              memberNamesById,
            );

            return SpPage(
              children: [
                SpSearchField(
                  hintText: l10n.searchNotesHint,
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 12),
                SpFilterRow(
                  filters: [
                    for (final filter in _NoteFilter.values) filter.label(l10n),
                  ],
                  selected: _filter.label(l10n),
                  onSelected: (label) => setState(() {
                    _filter = _NoteFilter.values.firstWhere(
                      (filter) => filter.label(l10n) == label,
                    );
                  }),
                ),
                const SizedBox(height: 12),
                SpCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SpSectionHeader(
                        title: l10n.notesTitle,
                        trailing: StatusPill(
                          text: '${widget.snapshot?.noteCount ?? 0}',
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (notes.isEmpty)
                        SpEmptyState(
                          title:
                              _query.trim().isEmpty &&
                                  _filter == _NoteFilter.all
                              ? l10n.noNotesYet
                              : l10n.noMatchingNotes,
                          body:
                              _query.trim().isEmpty &&
                                  _filter == _NoteFilter.all
                              ? l10n.notesEmptyBody
                              : l10n.tryAnotherSearchOrFilter,
                        )
                      else
                        for (final note in notes) ...[
                          NoteListTile(
                            note: note,
                            repository: widget.repository,
                            memberName: note.memberId == null
                                ? null
                                : memberNamesById[note.memberId],
                          ),
                          if (note != notes.last)
                            const Divider(height: 1, color: _spLine),
                        ],
                      const SizedBox(height: 14),
                      SpActionRow(
                        primary: l10n.addNoteButton,
                        secondary: l10n.importTitle,
                        onPrimary: () =>
                            showNoteSheet(context, widget.repository),
                        onSecondary: widget.onImport,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<NoteSummary> _filteredNotes(
    List<NoteSummary> notes,
    Map<String, String> memberNamesById,
  ) {
    return [
      for (final note in notes)
        if (_matchesQuery(_query, [
              note.title,
              note.body,
              _noteMemberLabel(
                note,
                memberNamesById[note.memberId],
                AppLocalizations.of(context),
              ),
            ]) &&
            switch (_filter) {
              _NoteFilter.member => note.memberId != null,
              _NoteFilter.system => note.memberId == null,
              _ => true,
            })
          note,
    ];
  }
}

class NoteListTile extends StatelessWidget {
  const NoteListTile({
    super.key,
    required this.note,
    required this.repository,
    this.memberName,
  });

  final NoteSummary note;
  final HavenRepository repository;
  final String? memberName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final body = note.body.trim();
    final ownerLabel = _noteMemberLabel(note, memberName, l10n);

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
          body.isEmpty ? ownerLabel : '$ownerLabel\n$body',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        trailing: IconButton(
          tooltip: l10n.deleteNoteTooltip,
          onPressed: () => confirmDelete(
            context,
            title: l10n.deleteNoteTitle,
            body: l10n.deleteNoteBody,
            onDelete: () => repository.deleteNote(note.id),
          ),
          icon: const Icon(Icons.delete_outline_rounded),
        ),
        onTap: () => showNoteSheet(context, repository, note: note),
      ),
    );
  }
}

String _noteMemberLabel(
  NoteSummary note,
  String? memberName,
  AppLocalizations l10n,
) {
  if (note.memberId == null) {
    return l10n.systemNoteLabel;
  }
  final name = memberName?.trim();
  return name == null || name.isEmpty
      ? l10n.unknownMemberNoteLabel
      : l10n.memberNoteLabel(name);
}

enum _NoteFilter { all, member, system }

extension on _NoteFilter {
  String label(AppLocalizations l10n) => switch (this) {
    _NoteFilter.all => l10n.allFilter,
    _NoteFilter.member => l10n.memberFilter,
    _NoteFilter.system => l10n.systemFilter,
  };
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
    backgroundColor: Theme.of(context).colorScheme.surface,
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
  static const _systemNoteValue = '__system_note__';

  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String? _memberId;

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
    _memberId = note.memberId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
              _isEditing ? l10n.editNoteTitle : l10n.addNoteButton,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('note-title-field'),
              controller: _titleController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: l10n.titleFieldLabel),
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<MemberSummary>>(
              stream: widget.repository.watchMembers(includeArchived: true),
              initialData: const [],
              builder: (context, snapshot) {
                final members = snapshot.data ?? const <MemberSummary>[];
                final value = _memberId == null
                    ? _systemNoteValue
                    : members.any((member) => member.id == _memberId)
                    ? _memberId!
                    : _systemNoteValue;
                return DropdownButtonFormField<String>(
                  key: const ValueKey('note-member-field'),
                  initialValue: value,
                  decoration: InputDecoration(labelText: l10n.forFieldLabel),
                  items: [
                    DropdownMenuItem(
                      value: _systemNoteValue,
                      child: Text(l10n.systemNoteLabel),
                    ),
                    for (final member in members)
                      DropdownMenuItem(
                        value: member.id,
                        child: Text(member.displayName),
                      ),
                  ],
                  onChanged: (value) => setState(() {
                    _memberId = value == _systemNoteValue ? null : value;
                  }),
                );
              },
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('note-body-field'),
              controller: _bodyController,
              minLines: 5,
              maxLines: 8,
              decoration: InputDecoration(labelText: l10n.noteFieldLabel),
            ),
            const SizedBox(height: 14),
            FilledButton(
              key: const ValueKey('save-note-button'),
              onPressed: _save,
              child: Text(l10n.saveNoteButton),
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
      memberId: _memberId,
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
