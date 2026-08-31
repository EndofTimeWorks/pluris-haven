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
  final _scrollController = ScrollController();
  late Stream<List<FrontHistoryEntry>> _historyStream;
  String _filter = 'all';
  String _query = '';
  int _historyLimit = 25;
  bool _loadingOlder = false;
  bool _showCalendar = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _historyStream = widget.repository.watchRecentFrontHistory(
      limit: _historyLimit,
    );
    _scrollController.addListener(_loadOlderAtEnd);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadOlderAtEnd() {
    if (_loadingOlder || !_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter > 300) return;
    final total = widget.snapshot?.frontHistoryCount ?? 0;
    if (_historyLimit >= total) return;
    setState(() {
      _loadingOlder = true;
      _historyLimit += 50;
      _historyStream = widget.repository.watchRecentFrontHistory(
        limit: _historyLimit,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filters = <String, String>{
      'all': l10n.allFilter,
      'today': l10n.todayFilter,
      'week': l10n.weekFilter,
      'month': l10n.monthFilter,
    };
    return StreamBuilder<List<FrontHistoryEntry>>(
      stream: _historyStream,
      initialData: const [],
      builder: (context, historySnapshot) {
        final entries = historySnapshot.data ?? const <FrontHistoryEntry>[];
        final visualTheme = _visualThemeOf(context);
        final isAmpersand = visualTheme == HavenVisualTheme.ampersand;
        final filteredEntries = entries
            .where(_matchesEntry)
            .where(
              (entry) =>
                  !isAmpersand ||
                  !_showCalendar ||
                  _isOnSelectedDate(entry.startedAt),
            )
            .toList();

        final hasMore =
            (widget.snapshot?.frontHistoryCount ?? entries.length) >
            entries.length;
        if (_loadingOlder && (!hasMore || entries.length >= _historyLimit)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _loadingOlder = false);
          });
        }

        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 0),
              sliver: SliverList.list(
                children: [
                  if (!isAmpersand) ...[
                    CurrentFrontEntry(
                      snapshot: widget.snapshot,
                      repository: widget.repository,
                    ),
                    const SizedBox(height: 12),
                  ],
                  SpSearchField(
                    key: const ValueKey('front-history-search-field'),
                    hintText: l10n.searchFrontHistoryHint,
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 12),
                  if (isAmpersand) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.frontHistoryTitle,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: _showCalendar
                              ? 'Show chronological list'
                              : 'Show calendar',
                          onPressed: () =>
                              setState(() => _showCalendar = !_showCalendar),
                          icon: Icon(
                            _showCalendar
                                ? Icons.format_list_bulleted_rounded
                                : Icons.calendar_month_rounded,
                          ),
                        ),
                      ],
                    ),
                    if (_showCalendar) ...[
                      const SizedBox(height: 8),
                      CalendarDatePicker(
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(DateTime.now().year + 1),
                        onDateChanged: (date) =>
                            setState(() => _selectedDate = date),
                      ),
                    ],
                  ] else if (visualTheme == HavenVisualTheme.simplyPlural)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SegmentedButton<String>(
                        segments: [
                          for (final entry in filters.entries)
                            ButtonSegment<String>(
                              value: entry.key,
                              label: Text(entry.value),
                            ),
                        ],
                        selected: {_filter},
                        onSelectionChanged: (selection) =>
                            setState(() => _filter = selection.first),
                      ),
                    )
                  else
                    SpFilterRow(
                      filters: filters.values.toList(growable: false),
                      selected: filters[_filter]!,
                      onSelected: (label) => setState(
                        () => _filter = filters.entries
                            .firstWhere((entry) => entry.value == label)
                            .key,
                      ),
                    ),
                  if (!isAmpersand) ...[
                    const SizedBox(height: 12),
                    SpCard(
                      child: SpSectionHeader(
                        title: l10n.frontHistoryTitle,
                        trailing: StatusPill(
                          text: '${filteredEntries.length}/${entries.length}',
                        ),
                      ),
                    ),
                  ],
                  if (entries.isEmpty || filteredEntries.isEmpty)
                    SpCard(
                      child: entries.isEmpty
                          ? SpEmptyState(
                              title: l10n.noFrontHistoryYet,
                              body: l10n.frontHistoryEmptyBody,
                            )
                          : SpEmptyState(
                              title: l10n.noMatchingFronts,
                              body: l10n.noMatchingFrontsBody,
                            ),
                    ),
                ],
              ),
            ),
            if (filteredEntries.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                sliver: SliverList.builder(
                  itemCount: filteredEntries.length,
                  itemBuilder: (context, index) {
                    final tile = FrontHistoryTile(
                      entry: filteredEntries[index],
                      repository: widget.repository,
                    );
                    if (isAmpersand) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: tile,
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 1),
                      child: SpCard(child: tile),
                    );
                  },
                ),
              ),
            if (hasMore)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: _loadingOlder
                        ? const Padding(
                            padding: EdgeInsets.all(8),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : const SizedBox(height: 1),
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 24),
              sliver: SliverToBoxAdapter(
                child: SpActionRow(
                  primary: l10n.addEntryButton,
                  secondary: l10n.resetButton,
                  onPrimary: () => showFrontHistoryEditor(
                    context,
                    repository: widget.repository,
                  ),
                  onSecondary: () {
                    _searchController.clear();
                    setState(() {
                      _query = '';
                      _filter = 'all';
                    });
                  },
                ),
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
      _frontTimingLabel(entry, AppLocalizations.of(context)),
    ]);
  }

  bool _matchesFrontDateFilter(FrontHistoryEntry entry) {
    if (_filter == 'all') {
      return true;
    }

    final now = DateTime.now();
    final local = entry.startedAt.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final start = switch (_filter) {
      'today' => today,
      'week' => today.subtract(const Duration(days: 7)),
      'month' => DateTime(now.year, now.month - 1, now.day),
      _ => DateTime.fromMillisecondsSinceEpoch(0),
    };
    return !local.isBefore(start);
  }

  bool _isOnSelectedDate(DateTime value) {
    final local = value.toLocal();
    return local.year == _selectedDate.year &&
        local.month == _selectedDate.month &&
        local.day == _selectedDate.day;
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
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
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
              _frontTimingLabel(entry, l10n),
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            if ((entry.statusNote ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                entry.statusNote!.trim(),
                style: TextStyle(color: scheme.onSurface),
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
    backgroundColor: Theme.of(context).colorScheme.surface,
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
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
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
                        _frontTimingLabel(widget.entry, l10n),
                        style: TextStyle(color: scheme.onSurfaceVariant),
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
              decoration: InputDecoration(
                labelText: l10n.statusNoteFieldLabel,
                hintText: l10n.statusNoteFieldHint,
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
              label: Text(l10n.saveNoteButton),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                showFrontHistoryEditor(
                  context,
                  repository: widget.repository,
                  entry: widget.entry,
                );
              },
              icon: const Icon(Icons.edit_calendar_outlined),
              label: Text(l10n.editEntryButton),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => confirmDelete(
                context,
                title: l10n.deleteFrontEntryTitle,
                body: l10n.deleteFrontEntryBody,
                onDelete: () async {
                  await widget.repository.deleteFrontSession(widget.entry.id);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              icon: const Icon(Icons.delete_outline_rounded),
              label: Text(l10n.deleteEntryButton),
            ),
          ],
        ),
      ),
    );
  }
}

void showFrontHistoryEditor(
  BuildContext context, {
  required HavenRepository repository,
  FrontHistoryEntry? entry,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (context) =>
        FrontHistoryEditorSheet(repository: repository, entry: entry),
  );
}

class FrontHistoryEditorSheet extends StatefulWidget {
  const FrontHistoryEditorSheet({
    super.key,
    required this.repository,
    this.entry,
  });

  final HavenRepository repository;
  final FrontHistoryEntry? entry;

  @override
  State<FrontHistoryEditorSheet> createState() =>
      _FrontHistoryEditorSheetState();
}

class _FrontHistoryEditorSheetState extends State<FrontHistoryEditorSheet> {
  late final TextEditingController _labelController;
  late final TextEditingController _noteController;
  late final TextEditingController _memberSearchController;
  late DateTime _startedAt;
  late DateTime _endedAt;
  late final Set<String> _memberIds;
  String _memberQuery = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final entry = widget.entry;
    _startedAt =
        entry?.startedAt.toLocal() ?? now.subtract(const Duration(hours: 1));
    _endedAt = entry?.endedAt?.toLocal() ?? now;
    _memberIds = {...?entry?.memberIds};
    _labelController = TextEditingController(
      text: entry?.memberIds.isEmpty == true ? entry?.label : null,
    );
    _noteController = TextEditingController(text: entry?.statusNote);
    _memberSearchController = TextEditingController();
  }

  @override
  void dispose() {
    _labelController.dispose();
    _noteController.dispose();
    _memberSearchController.dispose();
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.entry == null
                  ? l10n.addFrontHistoryTitle
                  : l10n.editFrontHistoryTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.startedFieldLabel),
              subtitle: Text(_shortDateTime(_startedAt)),
              trailing: const Icon(Icons.event_outlined),
              onTap: () => _pickDateTime(start: true),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.endedFieldLabel),
              subtitle: Text(_shortDateTime(_endedAt)),
              trailing: const Icon(Icons.event_available_outlined),
              onTap: () => _pickDateTime(start: false),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.navigationMembers,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            StreamBuilder<List<MemberSummary>>(
              stream: widget.repository.watchMembers(
                includeArchived: true,
                listOnly: true,
              ),
              initialData: const [],
              builder: (context, snapshot) {
                final members = snapshot.data ?? const <MemberSummary>[];
                final visibleMembers = [
                  for (final member in members)
                    if (_matchesMemberQuery(member, _memberQuery)) member,
                ];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SpSearchField(
                      key: const ValueKey('front-history-member-search-field'),
                      hintText: l10n.searchMembersHint,
                      controller: _memberSearchController,
                      onChanged: (value) =>
                          setState(() => _memberQuery = value),
                    ),
                    const SizedBox(height: 10),
                    if (visibleMembers.isEmpty)
                      SpEmptyState(
                        title: l10n.noMatchingMembersTitle,
                        body: l10n.noMatchingMembersBody,
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final member in visibleMembers)
                            FilterChip(
                              label: Text(member.displayName),
                              selected: _memberIds.contains(member.id),
                              onSelected: (selected) => setState(() {
                                if (selected) {
                                  _memberIds.add(member.id);
                                } else {
                                  _memberIds.remove(member.id);
                                }
                              }),
                            ),
                        ],
                      ),
                  ],
                );
              },
            ),
            TextField(
              key: const ValueKey('front-history-label-field'),
              controller: _labelController,
              decoration: InputDecoration(
                labelText: l10n.customLabelFieldLabel,
                helperText: l10n.customLabelFieldHelp,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('front-history-note-field'),
              controller: _noteController,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(labelText: l10n.statusNoteFieldLabel),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton.icon(
              key: const ValueKey('save-front-history-button'),
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(l10n.saveEntryButton),
            ),
          ],
        ),
      ),
    );
  }

  bool _matchesMemberQuery(MemberSummary member, String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return [
      member.displayName,
      member.pronouns,
      member.description,
      member.pluralKitId,
    ].any((value) => (value ?? '').toLowerCase().contains(normalized));
  }

  Future<void> _pickDateTime({required bool start}) async {
    final initial = start ? _startedAt : _endedAt;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    final value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (start) {
        _startedAt = value;
      } else {
        _endedAt = value;
      }
    });
  }

  Future<void> _save() async {
    if (_endedAt.isBefore(_startedAt)) {
      setState(() => _error = AppLocalizations.of(context).endBeforeStartError);
      return;
    }
    if (_memberIds.isEmpty && _labelController.text.trim().isEmpty) {
      setState(
        () => _error = AppLocalizations.of(context).chooseMembersOrLabelError,
      );
      return;
    }
    final draft = FrontHistoryDraft(
      startedAt: _startedAt,
      endedAt: _endedAt,
      memberIds: _memberIds.toList(growable: false),
      label: _labelController.text,
      statusNote: _noteController.text,
    );
    if (widget.entry == null) {
      await widget.repository.saveFrontHistoryEntry(draft);
    } else {
      await widget.repository.updateFrontHistoryEntry(widget.entry!.id, draft);
    }
    if (mounted) Navigator.pop(context);
  }
}

String _frontTimingLabel(FrontHistoryEntry entry, AppLocalizations l10n) {
  final started = _shortDateTime(entry.startedAt);
  if (entry.endedAt == null) {
    return l10n.activeFrontTiming(started);
  }

  return l10n.endedFrontTiming(started, _shortDateTime(entry.endedAt!));
}

String _shortDateTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.month}/${local.day} $hour:$minute';
}
