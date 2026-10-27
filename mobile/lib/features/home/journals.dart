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
  _JournalFilter _filter = _JournalFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<List<MemberSummary>>(
      stream: widget.repository.watchMembers(includeArchived: true),
      initialData: const [],
      builder: (context, membersSnapshot) {
        final memberNames = {
          for (final member in membersSnapshot.data ?? const <MemberSummary>[])
            member.id: member.displayName,
        };
        return StreamBuilder<List<JournalEntry>>(
          stream: widget.repository.watchJournals(),
          builder: (context, snapshot) {
            if (snapshot.hasError && !snapshot.hasData) {
              return SpPage(
                children: [
                  SpDataLoadState(
                    error: snapshot.error,
                    onRetry: () => setState(() {}),
                  ),
                ],
              );
            }
            if (!snapshot.hasData) {
              return const SpPage(children: [SpDataLoadState()]);
            }
            final entries = _filteredEntries(snapshot.data!);
            final titleCounts = <String, int>{};
            for (final entry in entries) {
              final title = entry.title?.trim().toLowerCase() ?? '';
              titleCounts[title] = (titleCounts[title] ?? 0) + 1;
            }

            return SpPage(
              children: [
                SpSearchField(
                  hintText: l10n.searchJournalsHint,
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 12),
                SpFilterRow(
                  filters: [
                    for (final filter in _JournalFilter.values)
                      filter.label(l10n),
                  ],
                  selected: _filter.label(l10n),
                  onSelected: (label) => setState(() {
                    _filter = _JournalFilter.values.firstWhere(
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
                        title: l10n.journalsTitle,
                        trailing: StatusPill(text: '${entries.length}'),
                      ),
                      const SizedBox(height: 12),
                      if (entries.isEmpty)
                        SpEmptyState(
                          title:
                              _query.trim().isEmpty &&
                                  _filter == _JournalFilter.all
                              ? l10n.noJournalEntriesYet
                              : l10n.noMatchingJournals,
                          body:
                              _query.trim().isEmpty &&
                                  _filter == _JournalFilter.all
                              ? l10n.journalsEmptyBody
                              : l10n.tryAnotherSearchOrFilter,
                        )
                      else
                        for (final entry in entries) ...[
                          JournalEntryTile(
                            entry: entry,
                            repository: widget.repository,
                            duplicateTitle:
                                (titleCounts[entry.title
                                            ?.trim()
                                            .toLowerCase() ??
                                        ''] ??
                                    0) >
                                1,
                            authorName: memberNames[entry.authorMemberId],
                          ),
                          if (entry != entries.last) const Divider(height: 1),
                        ],
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        key: const ValueKey('add-journal-entry-button'),
                        onPressed: () =>
                            showJournalEntrySheet(context, widget.repository),
                        icon: const Icon(Icons.add_rounded),
                        label: Text(l10n.addJournalEntryButton),
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

  List<JournalEntry> _filteredEntries(List<JournalEntry> entries) {
    return [
      for (final entry in entries)
        if (_matchesQuery(_query, [entry.title, entry.body]) &&
            switch (_filter) {
              _JournalFilter.member => entry.memberId != null,
              _JournalFilter.system => entry.memberId == null,
              _ => true,
            })
          entry,
    ];
  }
}

enum _JournalFilter { all, member, system }

extension on _JournalFilter {
  String label(AppLocalizations l10n) => switch (this) {
    _JournalFilter.all => l10n.allFilter,
    _JournalFilter.member => l10n.aboutMemberFilter,
    _JournalFilter.system => l10n.systemJournalLabel,
  };
}

class JournalEntryTile extends StatelessWidget {
  const JournalEntryTile({
    super.key,
    required this.entry,
    required this.repository,
    required this.duplicateTitle,
    this.authorName,
  });

  final JournalEntry entry;
  final HavenRepository repository;
  final bool duplicateTitle;
  final String? authorName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final title = entry.title?.trim();
    final body = _plainTextPreview(entry.body);

    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const SpIconBubble(icon: Icons.menu_book_outlined),
        title: Text(
          title == null || title.isEmpty ? l10n.untitledEntry : title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              body.isEmpty ? l10n.emptyJournal : body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            if (entry.authorMemberId != null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.journalWrittenBy(authorName ?? l10n.unknownMemberLabel),
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              _shortDateTime(context, entry.createdAt),
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
        trailing: IconButton(
          tooltip: duplicateTitle
              ? l10n.deleteJournalEntryFor(
                  title == null || title.isEmpty ? l10n.untitledEntry : title,
                  entry.id.substring(
                    entry.id.length > 8 ? entry.id.length - 8 : 0,
                  ),
                )
              : l10n.deleteJournalEntryForTitle(
                  title == null || title.isEmpty ? l10n.untitledEntry : title,
                ),
          onPressed: () => confirmDelete(
            context,
            title: l10n.deleteJournalEntryTitle,
            body: l10n.deleteJournalEntryBody,
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
    enableDrag: false,
    backgroundColor: Theme.of(context).colorScheme.surface,
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
  static const _systemJournalValue = '__system_journal__';
  static const _authorNotRecordedValue = '__author_not_recorded__';

  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String? _memberId;
  String? _authorMemberId;
  late DateTime _entryDateTime;
  late DateTime _initialEntryDateTime;
  bool _dateTimeEdited = false;
  bool _readOnly = false;
  bool _preview = false;
  bool _isSaving = false;

  bool get _isEditing => widget.entry != null;

  bool get _isDirty =>
      _titleController.text != (widget.entry?.title ?? '') ||
      _bodyController.text != (widget.entry?.body ?? '') ||
      _memberId != widget.entry?.memberId ||
      _authorMemberId != widget.entry?.authorMemberId ||
      _entryDateTime != _initialEntryDateTime;

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
    final entry = widget.entry;
    _readOnly = entry != null;
    _entryDateTime = (entry?.createdAt ?? DateTime.now()).toLocal();
    _initialEntryDateTime = _entryDateTime;
    if (entry == null) {
      return;
    }
    _titleController.text = entry.title ?? '';
    _bodyController.text = entry.body;
    _memberId = entry.memberId;
    _authorMemberId = entry.authorMemberId;
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
    if (_readOnly) {
      final entry = widget.entry!;
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: StreamBuilder<List<MemberSummary>>(
            stream: widget.repository.watchMembers(includeArchived: true),
            initialData: const [],
            builder: (context, snapshot) {
              final memberNames = {
                for (final member in snapshot.data ?? const <MemberSummary>[])
                  member.id: member.displayName,
              };
              final about = entry.memberId == null
                  ? l10n.systemJournalLabel
                  : memberNames[entry.memberId] ?? l10n.unknownMemberLabel;
              final author = entry.authorMemberId == null
                  ? l10n.journalAuthorNotRecorded
                  : memberNames[entry.authorMemberId] ??
                        l10n.unknownMemberLabel;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      entry.title?.trim().isNotEmpty == true
                          ? entry.title!
                          : l10n.untitledEntry,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(_shortDateTime(context, entry.createdAt)),
                  const SizedBox(height: 8),
                  Text('${l10n.journalAboutMemberFieldLabel}: $about'),
                  Text('${l10n.journalAuthorFieldLabel}: $author'),
                  const SizedBox(height: 14),
                  if (entry.body.trim().isNotEmpty)
                    _MarkdownPreview(body: entry.body)
                  else
                    Text(l10n.emptyJournal),
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const ValueKey('edit-journal-entry-button'),
                    onPressed: () => setState(() => _readOnly = false),
                    child: Text(l10n.editJournalEntryTitle),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.closeButton),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }
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
              _isEditing
                  ? l10n.editJournalEntryTitle
                  : l10n.addJournalEntryButton,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('journal-title-field'),
              controller: _titleController,
              autofocus: !_isEditing,
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
                  key: ValueKey('journal-about-${members.length}-$_memberId'),
                  child: DropdownButtonFormField<String>(
                    key: const ValueKey('journal-member-field'),
                    initialValue: _memberId ?? _systemJournalValue,
                    decoration: InputDecoration(
                      labelText: l10n.journalAboutMemberFieldLabel,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: _systemJournalValue,
                        child: Text(l10n.systemJournalLabel),
                      ),
                      if (_memberId != null && !hasSelectedMember)
                        DropdownMenuItem(
                          value: _memberId,
                          child: Text(l10n.unknownMemberLabel),
                        ),
                      for (final member in members)
                        DropdownMenuItem(
                          value: member.id,
                          child: Text(member.displayName),
                        ),
                    ],
                    onChanged: (value) => setState(() {
                      _memberId = value == _systemJournalValue ? null : value;
                    }),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<MemberSummary>>(
              stream: widget.repository.watchMembers(includeArchived: true),
              initialData: const [],
              builder: (context, snapshot) {
                final members = snapshot.data ?? const <MemberSummary>[];
                final hasAuthor = members.any(
                  (member) => member.id == _authorMemberId,
                );
                return KeyedSubtree(
                  key: ValueKey(
                    'journal-author-${members.length}-$_authorMemberId',
                  ),
                  child: DropdownButtonFormField<String>(
                    key: const ValueKey('journal-author-field'),
                    initialValue: _authorMemberId ?? _authorNotRecordedValue,
                    decoration: InputDecoration(
                      labelText: l10n.journalAuthorFieldLabel,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: _authorNotRecordedValue,
                        child: Text(l10n.journalAuthorNotRecorded),
                      ),
                      if (_authorMemberId != null && !hasAuthor)
                        DropdownMenuItem(
                          value: _authorMemberId,
                          child: Text(l10n.unknownMemberLabel),
                        ),
                      for (final member in members)
                        DropdownMenuItem(
                          value: member.id,
                          child: Text(member.displayName),
                        ),
                    ],
                    onChanged: (value) => setState(() {
                      _authorMemberId = value == _authorNotRecordedValue
                          ? null
                          : value;
                    }),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              key: const ValueKey('journal-date-field'),
              onPressed: _chooseDate,
              child: Text(
                '${l10n.journalDateFieldLabel}: '
                '${MaterialLocalizations.of(context).formatMediumDate(_entryDateTime)}',
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              key: const ValueKey('journal-time-field'),
              onPressed: _chooseTime,
              child: Text(
                '${l10n.journalTimeFieldLabel}: '
                '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(_entryDateTime))}',
              ),
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
                key: const ValueKey('journal-body-field'),
                controller: _bodyController,
                minLines: 8,
                maxLines: 12,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(labelText: l10n.entryFieldLabel),
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
              key: const ValueKey('save-journal-entry-button'),
              onPressed: _isSaving ? null : _save,
              child: Text(
                _isEditing ? l10n.saveEntryButton : l10n.createEntryButton,
              ),
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
    final now = DateTime.now().toUtc();
    final existing = widget.entry;
    setState(() => _isSaving = true);
    try {
      await widget.repository.saveJournal(
        JournalEntry(
          id: existing?.id ?? newLocalId('journal'),
          systemId: localSystemId,
          memberId: _memberId,
          authorMemberId: _authorMemberId,
          title: _nullIfBlank(_titleController.text),
          body: _bodyController.text,
          visibility: existing?.visibility ?? 'system',
          createdAt: existing == null && !_dateTimeEdited
              ? now
              : _entryDateTime.toUtc(),
          updatedAt: now,
        ),
      );
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

  Future<void> _chooseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _entryDateTime,
      firstDate: DateTime(1),
      lastDate: DateTime(9999, 12, 31),
    );
    if (date == null || !mounted) return;
    setState(() {
      _dateTimeEdited = true;
      _entryDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        _entryDateTime.hour,
        _entryDateTime.minute,
        _entryDateTime.second,
        _entryDateTime.millisecond,
        _entryDateTime.microsecond,
      );
    });
  }

  Future<void> _chooseTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_entryDateTime),
    );
    if (time == null || !mounted) return;
    setState(() {
      _dateTimeEdited = true;
      _entryDateTime = DateTime(
        _entryDateTime.year,
        _entryDateTime.month,
        _entryDateTime.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _showHistory() async {
    final entry = widget.entry;
    if (entry == null) return;
    final restored = await showContentRevisionSheet(
      context,
      repository: widget.repository,
      targetType: 'journal',
      targetId: entry.id,
    );
    if (restored && mounted) Navigator.pop(context);
  }
}

class _MarkdownPreview extends StatelessWidget {
  const _MarkdownPreview({required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: MarkdownBody(
          data: body,
          selectable: true,
          imageBuilder: (uri, title, alt) => Semantics(
            label: l10n.markdownImageBlockedLabel,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hide_image_outlined, size: 16),
                if (alt != null && alt.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Flexible(child: Text(alt)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool> showContentRevisionSheet(
  BuildContext context, {
  required HavenRepository repository,
  required String targetType,
  required String targetId,
}) async {
  return await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        builder: (context) => _ContentRevisionSheet(
          repository: repository,
          targetType: targetType,
          targetId: targetId,
        ),
      ) ??
      false;
}

class _ContentRevisionSheet extends StatelessWidget {
  const _ContentRevisionSheet({
    required this.repository,
    required this.targetType,
    required this.targetId,
  });

  final HavenRepository repository;
  final String targetType;
  final String targetId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: StreamBuilder<List<ContentRevision>>(
        stream: repository.watchRevisions(targetType, targetId),
        initialData: const [],
        builder: (context, snapshot) {
          final revisions = snapshot.data ?? const <ContentRevision>[];
          return ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            children: [
              Text(
                l10n.revisionHistoryTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              if (revisions.isEmpty)
                Text(l10n.noRevisionsYet)
              else
                for (final revision in revisions) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      revision.title?.trim().isNotEmpty == true
                          ? revision.title!
                          : l10n.untitledEntry,
                    ),
                    subtitle: Text(_shortDateTime(context, revision.createdAt)),
                    trailing: IconButton(
                      tooltip: revision.pinnedAt == null
                          ? l10n.pinRevisionTooltip
                          : l10n.unpinRevisionTooltip,
                      onPressed: () => revision.pinnedAt == null
                          ? repository.pinRevision(revision.id)
                          : repository.unpinRevision(revision.id),
                      icon: Icon(
                        revision.pinnedAt == null
                            ? Icons.push_pin_outlined
                            : Icons.push_pin,
                      ),
                    ),
                  ),
                  _MarkdownPreview(body: revision.body),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await repository.restoreRevision(
                        revision.id,
                        targetType,
                        targetId,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.revisionRestored)),
                        );
                        Navigator.pop(context, true);
                      }
                    },
                    icon: const Icon(Icons.restore_rounded),
                    label: Text(l10n.restoreRevisionButton),
                  ),
                  const Divider(height: 28),
                ],
            ],
          );
        },
      ),
    );
  }
}
