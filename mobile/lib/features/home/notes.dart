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
      builder: (context, noteSnapshot) {
        if (noteSnapshot.hasError && !noteSnapshot.hasData) {
          return SpPage(
            children: [
              SpDataLoadState(
                error: noteSnapshot.error,
                onRetry: () => setState(() {}),
              ),
            ],
          );
        }
        if (!noteSnapshot.hasData) {
          return const SpPage(children: [SpDataLoadState()]);
        }
        return StreamBuilder<List<MemberSummary>>(
          stream: widget.repository.watchMembers(includeArchived: true),
          builder: (context, memberSnapshot) {
            if (memberSnapshot.hasError && !memberSnapshot.hasData) {
              return SpPage(
                children: [
                  SpDataLoadState(
                    error: memberSnapshot.error,
                    onRetry: () => setState(() {}),
                  ),
                ],
              );
            }
            if (!memberSnapshot.hasData) {
              return const SpPage(children: [SpDataLoadState()]);
            }
            final memberNamesById = {
              for (final member in memberSnapshot.data!)
                member.id: member.displayName,
            };
            final notes = _filteredNotes(noteSnapshot.data!, memberNamesById);
            final titleCounts = <String, int>{};
            for (final note in notes) {
              final title = note.title.trim().toLowerCase();
              titleCounts[title] = (titleCounts[title] ?? 0) + 1;
            }

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
                            duplicateTitle:
                                (titleCounts[note.title.trim().toLowerCase()] ??
                                    0) >
                                1,
                            memberName: note.memberId == null
                                ? null
                                : memberNamesById[note.memberId],
                          ),
                          if (note != notes.last) const Divider(height: 1),
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
    required this.duplicateTitle,
    this.memberName,
  });

  final NoteSummary note;
  final HavenRepository repository;
  final bool duplicateTitle;
  final String? memberName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final body = _plainTextPreview(note.body);
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
          tooltip: duplicateTitle
              ? l10n.deleteNoteForTooltip(
                  note.title,
                  note.id.substring(
                    note.id.length > 8 ? note.id.length - 8 : 0,
                  ),
                )
              : l10n.deleteNoteForTitle(note.title),
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

String _plainTextPreview(String body) {
  if (body.trim().isEmpty) return '';
  final text = StringBuffer();

  void appendNodes(List<markdown.Node> nodes) {
    for (final node in nodes) {
      if (node is markdown.Text) {
        text.write(node.text);
      } else if (node is markdown.Element) {
        if (node.tag == 'img') continue;
        appendNodes(node.children ?? const []);
        if (const {
          'p',
          'li',
          'h1',
          'h2',
          'h3',
          'h4',
          'h5',
          'h6',
          'pre',
        }.contains(node.tag)) {
          text.write(' ');
        }
      }
    }
  }

  appendNodes(markdown.Document().parseLines(body.split('\n')));
  return text.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
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

enum _EditorDismissChoice { save, discard }

Future<_EditorDismissChoice?> _askAboutUnsavedChanges(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showDialog<_EditorDismissChoice>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.unsavedChangesTitle),
      content: Text(l10n.unsavedChangesBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l10n.keepEditingButton),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(dialogContext, _EditorDismissChoice.discard),
          child: Text(l10n.discardChangesButton),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(dialogContext, _EditorDismissChoice.save),
          child: Text(l10n.saveButtonLabel),
        ),
      ],
    ),
  );
}

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
    enableDrag: false,
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
  bool _preview = false;
  bool _isSaving = false;

  bool get _isEditing => widget.note != null;

  bool get _isDirty =>
      _titleController.text != (widget.note?.title ?? '') ||
      _bodyController.text != (widget.note?.body ?? '') ||
      _memberId != widget.note?.memberId;

  Future<void> _tryDismiss() async {
    if (!_isDirty) {
      Navigator.pop(context);
      return;
    }
    final choice = await _askAboutUnsavedChanges(context);
    if (!mounted) return;
    if (choice == _EditorDismissChoice.discard) Navigator.pop(context);
    if (choice == _EditorDismissChoice.save) await _save();
  }

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
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _tryDismiss();
    },
    child: _buildContents(context),
  );

  Widget _buildContents(BuildContext context) {
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
                final hasSelectedMember = members.any(
                  (member) => member.id == _memberId,
                );
                return KeyedSubtree(
                  key: ValueKey('note-for-${members.length}-$_memberId'),
                  child: DropdownButtonFormField<String>(
                    key: const ValueKey('note-member-field'),
                    initialValue: _memberId ?? _systemNoteValue,
                    decoration: InputDecoration(labelText: l10n.forFieldLabel),
                    items: [
                      DropdownMenuItem(
                        value: _systemNoteValue,
                        child: Text(l10n.systemNoteLabel),
                      ),
                      if (_memberId != null && !hasSelectedMember)
                        DropdownMenuItem(
                          value: _memberId,
                          child: Text(l10n.unknownMemberNoteLabel),
                        ),
                      for (final member in members)
                        DropdownMenuItem(
                          value: member.id,
                          child: Text(
                            _memberPickerLabel(member, members, l10n),
                          ),
                        ),
                    ],
                    onChanged: (value) => setState(() {
                      _memberId = value == _systemNoteValue ? null : value;
                    }),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(() => _preview = !_preview),
                icon: Icon(
                  _preview ? Icons.edit_outlined : Icons.preview_outlined,
                ),
                label: Text(
                  _preview
                      ? l10n.markdownEditButton
                      : l10n.markdownPreviewButton,
                ),
              ),
            ),
            if (_preview)
              _MarkdownPreview(body: _bodyController.text)
            else
              TextField(
                key: const ValueKey('note-body-field'),
                controller: _bodyController,
                minLines: 5,
                maxLines: 8,
                decoration: InputDecoration(labelText: l10n.noteFieldLabel),
              ),
            const SizedBox(height: 14),
            if (_isEditing)
              OutlinedButton.icon(
                onPressed: _showHistory,
                icon: const Icon(Icons.history_rounded),
                label: Text(l10n.revisionHistoryButton),
              ),
            if (_isEditing) const SizedBox(height: 10),
            FilledButton(
              key: const ValueKey('save-note-button'),
              onPressed: _isSaving ? null : _save,
              child: Text(l10n.saveNoteButton),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (_titleController.text.trim().isEmpty &&
        _bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).writeBeforeSaving)),
      );
      return;
    }
    final draft = NoteDraft(
      title: _titleController.text,
      body: _bodyController.text,
      memberId: _memberId,
    );
    final note = widget.note;
    setState(() => _isSaving = true);
    try {
      if (note == null) {
        await widget.repository.saveNote(draft);
      } else {
        await widget.repository.updateNote(note.id, draft);
      }
      if (mounted) Navigator.pop(context);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).couldNotSaveDraft),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _showHistory() async {
    final note = widget.note;
    if (note == null) return;
    final restored = await showContentRevisionSheet(
      context,
      repository: widget.repository,
      targetType: 'note',
      targetId: note.id,
    );
    if (restored && mounted) Navigator.pop(context);
  }
}
