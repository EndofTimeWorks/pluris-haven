part of 'home_page.dart';

class CustomFrontSheet extends StatefulWidget {
  const CustomFrontSheet({super.key, required this.repository});

  final HavenRepository repository;

  @override
  State<CustomFrontSheet> createState() => _CustomFrontSheetState();
}

class _CustomFrontSheetState extends State<CustomFrontSheet> {
  final _controller = TextEditingController();
  final _saveNameController = TextEditingController();
  final _selectedMemberIds = <String>{};

  @override
  void dispose() {
    _controller.dispose();
    _saveNameController.dispose();
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Set front',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<MemberSummary>>(
              stream: widget.repository.watchMembers(),
              initialData: const [],
              builder: (context, snapshot) {
                final members = snapshot.data ?? const <MemberSummary>[];
                if (members.isEmpty) {
                  return const SpEmptyState(
                    title: 'No members yet',
                    body: 'Add members first, or set a custom front below.',
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final member in members)
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
                    FilledButton(
                      key: const ValueKey('set-selected-members-front-button'),
                      onPressed: _selectedMemberIds.isEmpty
                          ? null
                          : _setMemberFront,
                      child: Text(
                        _selectedMemberIds.length <= 1
                            ? 'Set selected'
                            : 'Set co-front',
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      key: const ValueKey('save-selected-named-front-button'),
                      onPressed: _selectedMemberIds.isEmpty
                          ? null
                          : _showSaveSelectedFrontSheet,
                      child: const Text('Save selected as named front'),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            const Divider(color: _spLine),
            const SizedBox(height: 12),
            StreamBuilder<List<NamedFront>>(
              stream: widget.repository.watchNamedFronts(),
              initialData: const [],
              builder: (context, snapshot) {
                final namedFronts = snapshot.data ?? const <NamedFront>[];
                if (namedFronts.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Saved fronts',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final front in namedFronts)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: _spCard,
                          borderRadius: BorderRadius.circular(14),
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            contentPadding: const EdgeInsetsDirectional.only(
                              start: 12,
                              end: 6,
                            ),
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor:
                                  front.customLabel?.trim().isNotEmpty == true
                                  ? _spGold.withValues(alpha: 0.22)
                                  : _spPurple.withValues(alpha: 0.22),
                              child: Icon(
                                front.customLabel?.trim().isNotEmpty == true
                                    ? Icons.label_outline
                                    : Icons.group_outlined,
                                size: 18,
                                color:
                                    front.customLabel?.trim().isNotEmpty == true
                                    ? _spGold
                                    : _spPurple,
                              ),
                            ),
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
                            subtitle: Text(
                              front.customLabel?.trim().isNotEmpty == true
                                  ? 'custom front'
                                  : 'named combination',
                            ),
                            onTap: () => _applyNamedFront(front.id),
                            trailing: IconButton(
                              tooltip: 'Delete saved front',
                              onPressed: () => _deleteNamedFront(front),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    const Divider(color: _spLine),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
            const Text(
              'Custom front',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.done,
              onSubmitted: _setFront,
              decoration: const InputDecoration(labelText: 'Label'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => _setFront(_controller.text),
                    child: const Text('Set'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('save-custom-front-button'),
                    onPressed: () => _saveCustomFront(_controller.text),
                    child: const Text('Save'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await widget.repository.clearCurrentFront();
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Clear'),
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
    await widget.repository.setCustomFront(label);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _setMemberFront() async {
    await widget.repository.setFrontMembers(_selectedMemberIds.toList());
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _applyNamedFront(String namedFrontId) async {
    await widget.repository.applyNamedFront(namedFrontId);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _showSaveSelectedFrontSheet() async {
    final name = await _askForFrontName(
      title: 'Save named front',
      label: 'Name',
      initialValue: _selectedMemberIds.length <= 1 ? 'Fronting' : 'Co-front',
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
    await _saveNamedFront(
      name: normalized,
      customLabel: normalized,
      memberIds: const [],
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved "$normalized"')));
    }
  }

  Future<void> _saveNamedFront({
    required String name,
    String? customLabel,
    required List<String> memberIds,
  }) async {
    final now = DateTime.now().toUtc();
    await widget.repository.saveNamedFront(
      NamedFront(
        id: 'named-front-${now.microsecondsSinceEpoch}',
        systemId: localSystemId,
        name: name,
        customLabel: customLabel,
        createdAt: now,
        updatedAt: now,
      ),
      memberIds,
    );
  }

  Future<void> _deleteNamedFront(NamedFront front) async {
    await confirmDelete(
      context,
      title: 'Delete saved front?',
      body: 'This only removes the shortcut. Front history stays untouched.',
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
      backgroundColor: _spCard,
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
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
