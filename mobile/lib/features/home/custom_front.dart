part of 'home_page.dart';

String _activeCustomFrontName(
  FrontHistoryEntry entry,
  Iterable<FrontHistoryEntry> activeFronts,
  AppLocalizations l10n,
) {
  final name = entry.label.trim().toLowerCase();
  final duplicate =
      activeFronts
          .where((front) => front.label.trim().toLowerCase() == name)
          .length >
      1;
  return duplicate
      ? l10n.memberWithId(entry.label, _shortFrontId(entry.id))
      : entry.label;
}

class CustomFrontSheet extends StatefulWidget {
  const CustomFrontSheet({super.key, required this.repository});

  final HavenRepository repository;

  @override
  State<CustomFrontSheet> createState() => _CustomFrontSheetState();
}

class _CustomFrontSheetState extends State<CustomFrontSheet> {
  final _controller = TextEditingController();
  final _customFrontColorController = TextEditingController(text: '#F2C75C');
  final _memberSearchController = TextEditingController();
  final _savedFrontSearchController = TextEditingController();
  final _saveNameController = TextEditingController();
  final _selectedMemberIds = <String>{};
  final _activeMemberIds = <String>{};
  bool _currentFrontLoaded = false;
  bool _currentFrontLoadFailed = false;
  String _memberQuery = '';
  String _savedFrontQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentFront();
  }

  Future<void> _loadCurrentFront() async {
    try {
      final members = await widget.repository.watchCurrentFrontMembers().first;
      if (!mounted) return;
      setState(() {
        _selectedMemberIds.addAll(members.map((member) => member.id));
        _activeMemberIds.addAll(members.map((member) => member.id));
        _currentFrontLoaded = true;
      });
    } on Object {
      if (!mounted) return;
      setState(() => _currentFrontLoadFailed = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _customFrontColorController.dispose();
    _memberSearchController.dispose();
    _savedFrontSearchController.dispose();
    _saveNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: SizedBox(
        height:
            MediaQuery.sizeOf(context).height * 0.9 -
            MediaQuery.viewInsetsOf(context).bottom,
        child: Column(
          children: [
            Expanded(child: _buildScrollableContents(context, l10n)),
            _buildSelectionBar(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionBar(BuildContext context, AppLocalizations l10n) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.selectedMembersSummary('${_selectedMemberIds.length}')),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('add-selected-members-front-button'),
                    onPressed: _selectedMemberIds.isEmpty
                        ? null
                        : () => _setMemberFront(replaceExisting: false),
                    child: Text(l10n.addToFrontButton),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('set-selected-members-front-button'),
                    onPressed: _selectedMemberIds.isEmpty
                        ? null
                        : () => _setMemberFront(replaceExisting: true),
                    child: Text(l10n.replaceCurrentMembersButton),
                  ),
                ),
              ],
            ),
            TextButton(
              key: const ValueKey('save-selected-named-front-button'),
              onPressed: _selectedMemberIds.isEmpty
                  ? null
                  : _showSaveSelectedFrontSheet,
              child: Text(l10n.saveSelectedNamedFrontButton),
            ),
            TextButton(
              onPressed: _selectedMemberIds.isEmpty
                  ? null
                  : () => setState(_selectedMemberIds.clear),
              child: Text(l10n.clearSelectionButton),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollableContents(BuildContext context, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.setFrontButton,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<MemberSummary>>(
            stream: _currentFrontLoaded
                ? widget.repository.watchMembers(listOnly: true)
                : null,
            initialData: const [],
            builder: (context, snapshot) {
              if (_currentFrontLoadFailed) {
                return SpEmptyState(
                  title: l10n.dataLoadFailedTitle,
                  body: l10n.dataLoadFailedBody,
                );
              }
              if (!_currentFrontLoaded) {
                return const Center(child: CircularProgressIndicator());
              }
              final members = snapshot.data ?? const <MemberSummary>[];
              final nameCounts = <String, int>{};
              for (final member in members) {
                final name = member.displayName.trim().toLowerCase();
                nameCounts[name] = (nameCounts[name] ?? 0) + 1;
              }
              final visibleMembers =
                  [
                    for (final member in members)
                      if (_matchesQuery(_memberQuery, [
                        member.displayName,
                        member.pronouns,
                        member.description,
                        member.pluralKitId,
                      ]))
                        member,
                  ]..sort((left, right) {
                    final leftActive = _activeMemberIds.contains(left.id);
                    final rightActive = _activeMemberIds.contains(right.id);
                    if (leftActive != rightActive) return leftActive ? -1 : 1;
                    return left.displayName.toLowerCase().compareTo(
                      right.displayName.toLowerCase(),
                    );
                  });
              final selectedNames = [
                for (final member in members)
                  if (_selectedMemberIds.contains(member.id))
                    member.displayName,
              ];
              if (members.isEmpty) {
                return SpEmptyState(
                  title: l10n.noMembersYetTitle,
                  body: l10n.noMembersFrontPickerBody,
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SpSearchField(
                    key: const ValueKey('front-member-search-field'),
                    hintText: l10n.searchMembersHint,
                    controller: _memberSearchController,
                    onChanged: (value) => setState(() => _memberQuery = value),
                  ),
                  if (selectedNames.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      l10n.selectedMembersSummary(selectedNames.join(', ')),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
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
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FilterChip(
                                label: Text(
                                  (nameCounts[member.displayName
                                                  .trim()
                                                  .toLowerCase()] ??
                                              0) >
                                          1
                                      ? l10n.memberWithId(
                                          member.displayName,
                                          member.id.substring(
                                            member.id.length > 8
                                                ? member.id.length - 8
                                                : 0,
                                          ),
                                        )
                                      : member.displayName,
                                ),
                                selected: _selectedMemberIds.contains(
                                  member.id,
                                ),
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedMemberIds.add(member.id);
                                    } else {
                                      _selectedMemberIds.remove(member.id);
                                    }
                                  });
                                },
                              ),
                              if (_activeMemberIds.contains(member.id))
                                IconButton(
                                  key: ValueKey('end-front-${member.id}'),
                                  tooltip: l10n.endMemberFrontButton(
                                    member.displayName,
                                  ),
                                  onPressed: () => _endMemberFront(member),
                                  icon: const Icon(Icons.stop_circle_outlined),
                                ),
                            ],
                          ),
                      ],
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          StreamBuilder<List<FrontHistoryEntry>>(
            stream: widget.repository.watchFrontHistory(),
            builder: (context, snapshot) {
              final activeCustomFronts = [
                for (final entry
                    in snapshot.data ?? const <FrontHistoryEntry>[])
                  if (entry.isActive && entry.memberIds.isEmpty) entry,
              ];
              if (activeCustomFronts.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.activeCustomFrontsTitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final entry in activeCustomFronts)
                    ListTile(
                      key: ValueKey('active-custom-front-${entry.id}'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _activeCustomFrontName(entry, activeCustomFronts, l10n),
                      ),
                      trailing: IconButton(
                        key: ValueKey('end-custom-front-${entry.id}'),
                        tooltip: l10n.endCustomFrontButton(
                          _activeCustomFrontName(
                            entry,
                            activeCustomFronts,
                            l10n,
                          ),
                        ),
                        onPressed: () => _endCustomFront(
                          entry,
                          _activeCustomFrontName(
                            entry,
                            activeCustomFronts,
                            l10n,
                          ),
                        ),
                        icon: const Icon(Icons.stop_circle_outlined),
                      ),
                    ),
                  const Divider(),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
          StreamBuilder<List<NamedFront>>(
            stream: widget.repository.watchNamedFronts(),
            initialData: const [],
            builder: (context, snapshot) {
              final allNamedFronts = snapshot.data ?? const <NamedFront>[];
              final namedFronts = [
                for (final front in allNamedFronts)
                  if (_matchesQuery(_savedFrontQuery, [
                    front.name,
                    front.customLabel,
                    front.description,
                    front.colorHex,
                  ]))
                    front,
              ];
              if (allNamedFronts.isEmpty) {
                return const SizedBox.shrink();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.savedFrontsTitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SpSearchField(
                    key: const ValueKey('saved-front-search-field'),
                    hintText: l10n.searchSavedFrontsHint,
                    controller: _savedFrontSearchController,
                    onChanged: (value) =>
                        setState(() => _savedFrontQuery = value),
                  ),
                  const SizedBox(height: 10),
                  if (namedFronts.isEmpty)
                    SpEmptyState(
                      title: l10n.noMatchingSavedFrontsTitle,
                      body: l10n.noMatchingSavedFrontsBody,
                    ),
                  for (final front in namedFronts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          contentPadding: const EdgeInsetsDirectional.only(
                            start: 12,
                            end: 6,
                          ),
                          leading: _NamedFrontAvatar(front: front),
                          title: Text(
                            front.customLabel?.trim().isNotEmpty == true
                                ? front.customLabel!.trim()
                                : front.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                front.customLabel?.trim().isNotEmpty == true
                                    ? l10n.customFrontLabel
                                    : l10n.namedCombinationLabel,
                              ),
                              if (front.description?.trim().isNotEmpty == true)
                                Text(
                                  front.description!.trim(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                          onTap: null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _FrontActionButton(
                                actionKey: 'dashboard-named-front-${front.id}',
                                targetName: _frontTitle(front),
                                targetId: front.id,
                                showId: _hasDuplicateFrontTitle(
                                  front,
                                  namedFronts,
                                ),
                                onPressed: (action) =>
                                    _applyNamedFront(front, action),
                              ),
                              IconButton(
                                tooltip:
                                    _hasDuplicateFrontTitle(front, namedFronts)
                                    ? l10n.deleteFrontFor(
                                        _frontTitle(front),
                                        _shortFrontId(front.id),
                                      )
                                    : l10n.deleteFrontForName(
                                        _frontTitle(front),
                                      ),
                                onPressed: () => _deleteNamedFront(front),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
          Text(
            l10n.customFrontLabel,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('custom-front-label-field'),
            controller: _controller,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: l10n.labelFieldLabel),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('custom-front-color-hex-field'),
            controller: _customFrontColorController,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _setFront(_controller.text),
            decoration: InputDecoration(
              labelText: l10n.colourFieldLabel,
              hintText: '#F2C75C',
              prefixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _customFrontColorController,
                builder: (context, value, child) {
                  final color = _colorFromHex(
                    _normalizeUiHexColor(value.text),
                    fallback: Theme.of(context).colorScheme.primary,
                  );
                  return Center(
                    widthFactor: 1,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      key: const ValueKey('make-custom-front-current-button'),
                      onPressed: () => _setFront(_controller.text),
                      child: Text(l10n.setButtonLabel),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      key: const ValueKey('save-custom-front-button'),
                      onPressed: () => _saveCustomFront(_controller.text),
                      child: Text(l10n.saveButtonLabel),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _clearFront,
                child: Text(l10n.endAllCurrentFrontsButton),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _setFront(String label) async {
    if (!await _confirmReplaceCurrentFront(context) || !mounted) return;
    final reminders = await widget.repository.setCustomFront(label);
    if (mounted) {
      await deliverAfterFrontReminders(context, widget.repository, reminders);
    }
    if (mounted) {
      await _syncFrontNotification(context, widget.repository);
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _setMemberFront({required bool replaceExisting}) async {
    if (replaceExisting) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(AppLocalizations.of(context).replaceCurrentMembersButton),
          content: Text(
            AppLocalizations.of(context).replaceCurrentMembersWarning,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(AppLocalizations.of(context).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                AppLocalizations.of(context).replaceCurrentMembersButton,
              ),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    final ids = _selectedMemberIds.toList();
    final reminders = replaceExisting
        ? await widget.repository.setFrontMembers(ids)
        : await widget.repository.addFrontMembers(ids);
    if (mounted) {
      await deliverAfterFrontReminders(context, widget.repository, reminders);
    }
    if (mounted) {
      await _syncFrontNotification(context, widget.repository);
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _endMemberFront(MemberSummary member) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.endMemberFrontButton(member.displayName)),
        content: Text(l10n.endMemberFrontWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.endMemberFrontButton(member.displayName)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final active = await widget.repository.watchCurrentFrontMembers().first;
    if (!mounted) return;
    await widget.repository.setFrontMembers([
      for (final current in active)
        if (current.id != member.id) current.id,
    ]);
    if (!mounted) return;
    setState(() {
      _activeMemberIds.remove(member.id);
      _selectedMemberIds.remove(member.id);
    });
    await _syncFrontNotification(context, widget.repository);
  }

  Future<void> _endCustomFront(
    FrontHistoryEntry entry,
    String displayName,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.endCustomFrontButton(displayName)),
        content: Text(l10n.endCustomFrontWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.endCustomFrontButton(displayName)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await widget.repository.endCustomFrontSession(entry.id);
    if (mounted) await _syncFrontNotification(context, widget.repository);
  }

  Future<void> _applyNamedFront(
    NamedFront front,
    HavenFrontAction action,
  ) async {
    final reminders = action == HavenFrontAction.add
        ? await widget.repository.addNamedFront(front.id)
        : await widget.repository.applyNamedFront(front.id);
    if (mounted) {
      await deliverAfterFrontReminders(context, widget.repository, reminders);
    }
    if (mounted) {
      await _syncFrontNotification(context, widget.repository);
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _clearFront() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.endAllCurrentFrontsButton),
        content: Text(l10n.endAllCurrentFrontsWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.endAllCurrentFrontsButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await widget.repository.clearCurrentFront();
    if (mounted) {
      await _syncFrontNotification(context, widget.repository);
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _showSaveSelectedFrontSheet() async {
    final l10n = AppLocalizations.of(context);
    final name = await _askForFrontName(
      title: l10n.saveNamedFrontTitle,
      label: l10n.nameFieldLabel,
      initialValue: _selectedMemberIds.length <= 1
          ? l10n.frontingDefaultName
          : l10n.cofrontDefaultName,
    );
    if (name == null) {
      return;
    }

    await _saveNamedFront(name: name, memberIds: _selectedMemberIds.toList());
  }

  Future<void> _saveCustomFront(String label) async {
    final normalized = label.trim();
    if (normalized.isEmpty) {
      return;
    }
    final colorHex = _normalizeUiHexColor(_customFrontColorController.text);
    if (colorHex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).invalidHexColorError),
        ),
      );
      return;
    }
    await _saveNamedFront(
      name: normalized,
      customLabel: normalized,
      colorHex: colorHex,
      memberIds: const [],
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).savedNamedFront(normalized),
          ),
        ),
      );
    }
  }

  Future<void> _saveNamedFront({
    required String name,
    String? customLabel,
    String? colorHex,
    String? avatarUrl,
    String? description,
    required List<String> memberIds,
  }) async {
    final now = DateTime.now().toUtc();
    await widget.repository.saveNamedFront(
      NamedFront(
        id: newLocalId('named-front'),
        systemId: localSystemId,
        name: name,
        customLabel: customLabel,
        colorHex: colorHex,
        avatarUrl: avatarUrl,
        description: description,
        createdAt: now,
        updatedAt: now,
      ),
      memberIds,
    );
  }

  Future<void> _deleteNamedFront(NamedFront front) async {
    final l10n = AppLocalizations.of(context);
    await confirmDelete(
      context,
      title: l10n.deleteNamedFrontTitle,
      body: l10n.deleteSavedFrontBody,
      onDelete: () => widget.repository.deleteNamedFront(front.id),
    );
  }

  Future<String?> _askForFrontName({
    required String title,
    required String label,
    required String initialValue,
  }) async {
    _saveNameController.text = initialValue;
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            18,
            18,
            18 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('named-front-name-field'),
                controller: _saveNameController,
                autofocus: true,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(labelText: label),
                onSubmitted: (value) {
                  final trimmed = value.trim();
                  if (trimmed.isNotEmpty) {
                    Navigator.pop(context, trimmed);
                  }
                },
              ),
              const SizedBox(height: 14),
              FilledButton(
                key: const ValueKey('confirm-save-named-front-button'),
                onPressed: () {
                  final trimmed = _saveNameController.text.trim();
                  if (trimmed.isNotEmpty) {
                    Navigator.pop(context, trimmed);
                  }
                },
                child: Text(AppLocalizations.of(context).saveButtonLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _syncFrontNotification(
  BuildContext context,
  HavenRepository repository,
) async {
  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context);
  final frontLabel = (await repository.watchHomeSnapshot().first)
      .currentFrontLabel
      ?.trim();
  final hasFront = frontLabel != null && frontLabel.isNotEmpty;
  final notificationCopy = _notificationCopy(l10n);
  try {
    final customization = await repository.loadCustomization();
    if (customization.frontStatusNotification) {
      await NotificationService.instance.showFrontStatusNotification(
        frontLabel: hasFront ? frontLabel : null,
        copy: notificationCopy,
        showOnLockScreen: customization.frontStatusShowOnLockScreen,
        revealMemberName: customization.frontStatusRevealMemberName,
      );
    } else {
      await NotificationService.instance.cancelFrontStatusNotification();
    }
  } on Object catch (error, stackTrace) {
    appDebugLog(
      'Front status notification failed',
      error: error,
      stackTrace: stackTrace,
    );
  }

  await repository.recordNotificationEvent(
    NotificationEventDraft(
      kind: 'front',
      title: hasFront ? l10n.frontChangedTitle : l10n.frontClearedTitle,
      body: hasFront
          ? l10n.setFrontConfirmation(frontLabel)
          : l10n.noOneFrontingBody,
    ),
  );
}

class _NamedFrontAvatar extends StatelessWidget {
  const _NamedFrontAvatar({required this.front});

  final NamedFront front;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = _colorFromHex(
      front.colorHex,
      fallback: front.customLabel?.trim().isNotEmpty == true
          ? Theme.of(context).colorScheme.secondary
          : Theme.of(context).colorScheme.primary,
    );
    final label = front.customLabel?.trim().isNotEmpty == true
        ? front.customLabel!.trim()
        : front.name;
    final avatarLabel = _customFrontAvatarInitial(label);
    final avatarUrl = front.avatarUrl;

    if (avatarUrl == null || avatarUrl.trim().isEmpty) {
      return SpAvatar(
        size: 34,
        color: color,
        label: avatarLabel,
        semanticLabel: l10n.avatarForLabel(label),
      );
    }
    if (avatarUrl.startsWith('local-avatar:')) {
      return FutureBuilder<Uint8List?>(
        future: _localAvatarFile(avatarUrl),
        builder: (context, snapshot) {
          return SpAvatar(
            size: 34,
            color: color,
            label: avatarLabel,
            image: snapshot.data == null ? null : MemoryImage(snapshot.data!),
            semanticLabel: l10n.avatarForLabel(label),
          );
        },
      );
    }
    return SpAvatar(
      size: 34,
      color: color,
      label: avatarLabel,
      semanticLabel: l10n.avatarForLabel(label),
    );
  }
}

String _customFrontAvatarInitial(String label) {
  final withoutNumberPrefix = label.replaceFirst(
    RegExp(r'^\d+\s*[:.)-]?\s*'),
    '',
  );
  return _initialFor(
    withoutNumberPrefix.trim().isEmpty ? label : withoutNumberPrefix,
  );
}
