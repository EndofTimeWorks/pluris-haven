part of 'home_page.dart';

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
  String _memberQuery = '';
  String _savedFrontQuery = '';

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
              l10n.setFrontButton,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<MemberSummary>>(
              stream: widget.repository.watchMembers(listOnly: true),
              initialData: const [],
              builder: (context, snapshot) {
                final members = snapshot.data ?? const <MemberSummary>[];
                final visibleMembers = [
                  for (final member in members)
                    if (_matchesQuery(_memberQuery, [
                      member.displayName,
                      member.pronouns,
                      member.description,
                      member.pluralKitId,
                    ]))
                      member,
                ];
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
                      onChanged: (value) =>
                          setState(() => _memberQuery = value),
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
                            FilterChip(
                              label: Text(member.displayName),
                              selected: _selectedMemberIds.contains(member.id),
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
                        ],
                      ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.clear_all_rounded),
                          label: Text(l10n.clearSelectionButton),
                          onPressed: _selectedMemberIds.isEmpty
                              ? null
                              : () => setState(_selectedMemberIds.clear),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      key: const ValueKey('set-selected-members-front-button'),
                      onPressed: _selectedMemberIds.isEmpty
                          ? null
                          : _setMemberFront,
                      child: Text(
                        _selectedMemberIds.length <= 1
                            ? l10n.setSelectedButton
                            : l10n.setCofrontButton,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      key: const ValueKey('save-selected-named-front-button'),
                      onPressed: _selectedMemberIds.isEmpty
                          ? null
                          : _showSaveSelectedFrontSheet,
                      child: Text(l10n.saveSelectedNamedFrontButton),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
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
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  front.customLabel?.trim().isNotEmpty == true
                                      ? l10n.customFrontLabel
                                      : l10n.namedCombinationLabel,
                                ),
                                if (front.description?.trim().isNotEmpty ==
                                    true)
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
                                IconButton(
                                  tooltip: l10n.setSavedFrontTooltip,
                                  onPressed: () => _applyNamedFront(front),
                                  icon: const Icon(Icons.play_arrow_rounded),
                                ),
                                IconButton(
                                  tooltip: l10n.deleteSavedFrontTooltip,
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
                      fallback: _spGold,
                    );
                    return Center(
                      widthFactor: 1,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: _spLine),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
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
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearFront,
                    child: Text(l10n.clearButton),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setFront(String label) async {
    final reminders = await widget.repository.setCustomFront(label);
    if (mounted) {
      await deliverAfterFrontReminders(context, widget.repository, reminders);
    }
    await _syncFrontNotification(label.trim());
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _setMemberFront() async {
    final label = await _selectedMemberFrontLabel();
    final reminders = await widget.repository.setFrontMembers(
      _selectedMemberIds.toList(),
    );
    if (mounted) {
      await deliverAfterFrontReminders(context, widget.repository, reminders);
    }
    await _syncFrontNotification(label);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _applyNamedFront(NamedFront front) async {
    final reminders = await widget.repository.applyNamedFront(front.id);
    if (mounted) {
      await deliverAfterFrontReminders(context, widget.repository, reminders);
    }
    await _syncFrontNotification(
      front.customLabel?.trim().isNotEmpty == true
          ? front.customLabel!.trim()
          : front.name,
    );
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _clearFront() async {
    await widget.repository.clearCurrentFront();
    await _syncFrontNotification(null);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<String> _selectedMemberFrontLabel() async {
    final ids = _selectedMemberIds.toSet();
    final members = await widget.repository.watchMembers(listOnly: true).first;
    final labels = [
      for (final member in members)
        if (ids.contains(member.id)) member.displayName,
    ];
    return labels.join(', ');
  }

  Future<void> _syncFrontNotification(String? label) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final frontLabel = label?.trim();
    final hasFront = frontLabel != null && frontLabel.isNotEmpty;
    final notificationCopy = _notificationCopy(l10n);
    try {
      final customization = await widget.repository.loadCustomization();
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

    await widget.repository.recordNotificationEvent(
      NotificationEventDraft(
        kind: 'front',
        title: hasFront ? l10n.frontChangedTitle : l10n.frontClearedTitle,
        body: hasFront
            ? l10n.memberIsFronting(frontLabel)
            : l10n.noOneFrontingBody,
      ),
    );
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
    if (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')) {
      return SpAvatar(
        size: 34,
        color: color,
        label: avatarLabel,
        image: NetworkImage(avatarUrl),
        semanticLabel: l10n.avatarForLabel(label),
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
