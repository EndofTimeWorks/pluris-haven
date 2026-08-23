part of 'home_page.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({
    super.key,
    required this.snapshot,
    required this.repository,
    required this.onImport,
  });

  final HomeSnapshot? snapshot;
  final HavenRepository repository;
  final VoidCallback onImport;

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<List<GroupSummary>>(
      stream: widget.repository.watchGroups(),
      initialData: const [],
      builder: (context, groupSnapshot) {
        final groups = (groupSnapshot.data ?? const <GroupSummary>[])
            .where(
              (group) => _matchesQuery(_query, [
                group.name,
                group.description,
                group.emoji,
              ]),
            )
            .toList(growable: false);
        final displayGroups = _orderedGroupsForDisplay(groups);

        return SpPage(
          children: [
            SpSearchField(
              hintText: l10n.searchGroupsHint,
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            SpCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SpSectionHeader(
                    title: l10n.groupsTitle,
                    trailing: StatusPill(
                      text: '${widget.snapshot?.groupCount ?? 0}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (groups.isEmpty)
                    SpEmptyState(
                      title: _query.trim().isEmpty
                          ? l10n.noGroupsYet
                          : l10n.noMatchingGroups,
                      body: _query.trim().isEmpty
                          ? l10n.groupsEmptyBody
                          : l10n.tryAnotherSearch,
                    )
                  else
                    for (
                      var index = 0;
                      index < displayGroups.length;
                      index++
                    ) ...[
                      GroupListTile(
                        group: displayGroups[index].group,
                        depth: displayGroups[index].depth,
                        allGroups: groups,
                        repository: widget.repository,
                      ),
                      if (index != displayGroups.length - 1)
                        const Divider(height: 1, color: _spLine),
                    ],
                  const SizedBox(height: 14),
                  SpActionRow(
                    primary: l10n.addGroupButton,
                    secondary: l10n.importTitle,
                    onPrimary: () =>
                        showAddGroupSheet(context, widget.repository),
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
}

class _DisplayGroup {
  const _DisplayGroup({required this.group, required this.depth});

  final GroupSummary group;
  final int depth;
}

List<_DisplayGroup> _orderedGroupsForDisplay(List<GroupSummary> groups) {
  final byParent = <String?, List<GroupSummary>>{};
  final groupIds = groups.map((group) => group.id).toSet();
  for (final group in groups) {
    final parentId = groupIds.contains(group.parentGroupId)
        ? group.parentGroupId
        : null;
    byParent.putIfAbsent(parentId, () => <GroupSummary>[]).add(group);
  }
  for (final siblings in byParent.values) {
    siblings.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
  }

  final ordered = <_DisplayGroup>[];
  final visited = <String>{};
  void visit(String? parentId, int depth) {
    for (final group in byParent[parentId] ?? const <GroupSummary>[]) {
      if (!visited.add(group.id)) {
        continue;
      }
      ordered.add(_DisplayGroup(group: group, depth: depth));
      visit(group.id, depth + 1);
    }
  }

  visit(null, 0);
  for (final group in groups) {
    if (visited.add(group.id)) {
      ordered.add(_DisplayGroup(group: group, depth: 0));
    }
  }
  return ordered;
}

class GroupListTile extends StatelessWidget {
  const GroupListTile({
    super.key,
    required this.group,
    required this.allGroups,
    required this.repository,
    this.depth = 0,
  });

  final GroupSummary group;
  final List<GroupSummary> allGroups;
  final HavenRepository repository;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final hasDescription = group.description?.trim().isNotEmpty == true;
    final countLabel = l10n.groupMemberCount(group.memberCount);
    final subtitle = hasDescription
        ? '${group.description!.trim()} - $countLabel'
        : countLabel;
    return Semantics(
      label: depth == 0
          ? l10n.groupSemanticLabel(group.name, countLabel)
          : l10n.nestedGroupSemanticLabel(group.name, depth, countLabel),
      child: Padding(
        padding: EdgeInsetsDirectional.only(start: depth * 18.0),
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (depth > 0) ...[
                  Icon(
                    Icons.subdirectory_arrow_right_rounded,
                    color: scheme.onSurfaceVariant,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                ],
                SpAvatar(
                  size: 42,
                  color: _colorFromHex(group.colorHex, fallback: _spGold),
                  label: group.emoji?.trim().isNotEmpty == true
                      ? group.emoji!.trim()
                      : _initialFor(group.name),
                  semanticLabel: l10n.groupAvatarSemanticLabel(group.name),
                ),
              ],
            ),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    group.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (group.isSubsystem) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.layers_outlined,
                    size: 16,
                    color: scheme.primary.withValues(alpha: 0.7),
                  ),
                ],
              ],
            ),
            subtitle: Text(
              subtitle,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            onTap: () =>
                showEditGroupSheet(context, repository, group, allGroups),
            trailing: PopupMenuButton<String>(
              tooltip: l10n.groupActionsTooltip,
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    showEditGroupSheet(context, repository, group, allGroups);
                  case 'delete':
                    confirmDelete(
                      context,
                      title: l10n.deleteGroupTitle,
                      body: l10n.deleteGroupBody,
                      onDelete: () => repository.deleteGroup(group.id),
                    );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'edit', child: Text(l10n.editButton)),
                PopupMenuItem(value: 'delete', child: Text(l10n.deleteButton)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void showAddGroupSheet(BuildContext context, HavenRepository repository) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (context) => AddGroupSheet(repository: repository),
  );
}

void showEditGroupSheet(
  BuildContext context,
  HavenRepository repository,
  GroupSummary group,
  List<GroupSummary> allGroups,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (context) => AddGroupSheet(
      repository: repository,
      group: group,
      initialGroups: allGroups,
    ),
  );
}

class AddGroupSheet extends StatefulWidget {
  const AddGroupSheet({
    super.key,
    required this.repository,
    this.group,
    this.initialGroups = const [],
  });

  final HavenRepository repository;
  final GroupSummary? group;
  final List<GroupSummary> initialGroups;

  @override
  State<AddGroupSheet> createState() => _AddGroupSheetState();
}

class _AddGroupSheetState extends State<AddGroupSheet> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _emojiController = TextEditingController();
  final _colorController = TextEditingController(
    text: _hexFromAccent(HavenAccentColor.gold),
  );
  String? _colorError;
  String? _parentGroupId;
  bool _isSubsystem = false;

  bool get _isEditing => widget.group != null;

  @override
  void initState() {
    super.initState();
    final group = widget.group;
    if (group != null) {
      _nameController.text = group.name;
      _descriptionController.text = group.description ?? '';
      _emojiController.text = group.emoji ?? '';
      final groupColor = group.colorHex == null
          ? null
          : _normalizeUiHexColor(group.colorHex!);
      _colorController.text =
          groupColor ?? _hexFromAccent(HavenAccentColor.gold);
      _parentGroupId = group.parentGroupId;
      _isSubsystem = group.isSubsystem;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _emojiController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<GroupSummary>>(
      stream: widget.repository.watchGroups(),
      initialData: widget.initialGroups,
      builder: (context, snapshot) {
        final l10n = AppLocalizations.of(context);
        final allGroups = snapshot.data ?? widget.initialGroups;
        final parentOptions = _parentOptionsFor(allGroups, widget.group?.id);
        if (_parentGroupId != null &&
            !parentOptions.any((group) => group.id == _parentGroupId)) {
          _parentGroupId = null;
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
                  _isEditing ? l10n.editGroupTitle : l10n.addGroupButton,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  key: const ValueKey('group-name-field'),
                  controller: _nameController,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: l10n.nameFieldLabel),
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const ValueKey('group-emoji-field'),
                  controller: _emojiController,
                  maxLength: 4,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: l10n.emojiFieldLabel),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String?>(
                  key: const ValueKey('group-parent-field'),
                  initialValue: _parentGroupId,
                  decoration: InputDecoration(
                    labelText: l10n.parentGroupFieldLabel,
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(l10n.noParentOption),
                    ),
                    for (final option in parentOptions)
                      DropdownMenuItem<String?>(
                        value: option.id,
                        child: Text(option.name),
                      ),
                  ],
                  onChanged: (value) => setState(() => _parentGroupId = value),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _descriptionController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: l10n.descriptionFieldLabel,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final color in HavenAccentColor.values)
                      ChoiceChip(
                        label: Text(_localizedAccentLabel(color, l10n)),
                        selected:
                            _normalizeUiHexColor(_colorController.text) ==
                            _hexFromAccent(color),
                        onSelected: (_) => setState(() {
                          _colorController.text = _hexFromAccent(color);
                          _colorError = null;
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const ValueKey('group-color-hex-field'),
                  controller: _colorController,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: l10n.colorHexFieldLabel,
                    hintText: '#F2C75C',
                    errorText: _colorError,
                  ),
                  onChanged: (_) {
                    if (_colorError != null) {
                      setState(() => _colorError = null);
                    }
                  },
                ),
                SwitchListTile(
                  key: const ValueKey('group-subsystem-toggle'),
                  title: Text(l10n.subsystemToggleTitle),
                  subtitle: Text(l10n.subsystemToggleBody),
                  value: _isSubsystem,
                  onChanged: (value) => setState(() => _isSubsystem = value),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  key: const ValueKey('save-group-button'),
                  onPressed: _save,
                  child: Text(
                    _isEditing ? l10n.saveChangesButton : l10n.saveGroupButton,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    final colorHex = _normalizeUiHexColor(_colorController.text);
    if (colorHex == null) {
      setState(
        () => _colorError = AppLocalizations.of(context).invalidHexColorError,
      );
      return;
    }

    final draft = GroupDraft(
      name: _nameController.text,
      parentGroupId: _parentGroupId,
      emoji: _emojiController.text,
      colorHex: colorHex,
      description: _descriptionController.text,
      isSubsystem: _isSubsystem,
    );
    final group = widget.group;
    if (group == null) {
      await widget.repository.saveGroup(draft);
    } else {
      await widget.repository.updateGroup(group.id, draft);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }
}

String _localizedAccentLabel(HavenAccentColor color, AppLocalizations l10n) =>
    switch (color) {
      HavenAccentColor.purple => l10n.purpleColorLabel,
      HavenAccentColor.gold => l10n.goldColorLabel,
      HavenAccentColor.teal => l10n.tealColorLabel,
      HavenAccentColor.rose => l10n.roseColorLabel,
    };

List<GroupSummary> _parentOptionsFor(
  List<GroupSummary> groups,
  String? currentGroupId,
) {
  if (currentGroupId == null) {
    return [...groups]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  final childrenByParent = <String, List<GroupSummary>>{};
  for (final group in groups) {
    final parentId = group.parentGroupId;
    if (parentId != null) {
      childrenByParent.putIfAbsent(parentId, () => <GroupSummary>[]).add(group);
    }
  }
  final blocked = <String>{currentGroupId};
  void collectChildren(String groupId) {
    for (final child in childrenByParent[groupId] ?? const <GroupSummary>[]) {
      if (blocked.add(child.id)) {
        collectChildren(child.id);
      }
    }
  }

  collectChildren(currentGroupId);
  return [
    for (final group in groups)
      if (!blocked.contains(group.id)) group,
  ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
}
