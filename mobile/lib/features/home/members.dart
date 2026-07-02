part of 'home_page.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({
    super.key,
    required this.snapshot,
    required this.repository,
    required this.onImport,
  });

  final HomeSnapshot? snapshot;
  final HavenRepository repository;
  final VoidCallback onImport;

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
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
    return StreamBuilder<List<MemberSummary>>(
      stream: widget.repository.watchMembers(includeArchived: true),
      initialData: const [],
      builder: (context, membersSnapshot) {
        final members = _filteredMembers(
          membersSnapshot.data ?? const <MemberSummary>[],
        );

        return SpPage(
          children: [
            SpSearchField(
              hintText: 'Search members',
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            SpFilterRow(
              filters: const ['All', 'Fronting', 'Archived'],
              selected: _filter,
              onSelected: (filter) => setState(() => _filter = filter),
            ),
            const SizedBox(height: 12),
            SpCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SpSectionHeader(
                    title: 'Members',
                    trailing: StatusPill(
                      text: '${widget.snapshot?.memberCount ?? 0}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (members.isEmpty)
                    SpEmptyState(
                      title: _query.trim().isEmpty && _filter == 'All'
                          ? 'No members saved locally'
                          : 'No matching members',
                      body: _query.trim().isEmpty && _filter == 'All'
                          ? 'Add members here or import a Simply Plural export.'
                          : 'Try another search or filter.',
                    )
                  else
                    for (final member in members) ...[
                      MemberListTile(
                        member: member,
                        repository: widget.repository,
                      ),
                      if (member != members.last)
                        const Divider(height: 1, color: _spLine),
                    ],
                  const SizedBox(height: 14),
                  SpActionRow(
                    primary: 'Add member',
                    secondary: 'Import',
                    onPrimary: () =>
                        showAddMemberSheet(context, widget.repository),
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

  List<MemberSummary> _filteredMembers(List<MemberSummary> members) {
    final frontNames = (widget.snapshot?.currentFrontLabel ?? '')
        .split(',')
        .map((name) => name.trim().toLowerCase())
        .where((name) => name.isNotEmpty)
        .toSet();

    return [
      for (final member in members)
        if (_matchesQuery(_query, [
              member.displayName,
              member.pronouns,
              member.description,
            ]) &&
            switch (_filter) {
              'Archived' => member.archived,
              'Fronting' => frontNames.contains(
                member.displayName.toLowerCase(),
              ),
              _ => true,
            })
          member,
    ];
  }
}

class MemberListTile extends StatelessWidget {
  const MemberListTile({
    super.key,
    required this.member,
    required this.repository,
  });

  final MemberSummary member;
  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: MemberAvatar(
          member: member,
          color: _memberColor(member),
          label: _memberAvatarLabel(member),
        ),
        title: Text(
          member.displayName,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(_subtitle, style: const TextStyle(color: _spMuted)),
        onTap: () => showMemberProfileSheet(context, repository, member),
        trailing: PopupMenuButton<String>(
          tooltip: 'Member actions',
          onSelected: (value) {
            if (value == 'front') {
              repository.setFrontMembers([member.id]);
            } else if (value == 'edit') {
              showMemberSheet(context, repository, member: member);
            } else if (value == 'archive') {
              repository.archiveMember(member.id);
            } else if (value == 'restore') {
              repository.restoreMember(member.id);
            } else if (value == 'delete') {
              confirmDelete(
                context,
                title: 'Delete member?',
                body:
                    '${member.displayName} will be permanently removed from this local system.',
                onDelete: () => repository.deleteMember(member.id),
              );
            }
          },
          itemBuilder: (context) => [
            if (!member.archived)
              const PopupMenuItem(value: 'front', child: Text('Set front')),
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            if (member.archived)
              const PopupMenuItem(value: 'restore', child: Text('Restore'))
            else
              const PopupMenuItem(value: 'archive', child: Text('Archive')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  String get _subtitle {
    final pronouns = member.pronouns?.isNotEmpty == true
        ? member.pronouns!
        : 'no pronouns';
    final privacy = member.privacy?.trim();
    final parts = [
      pronouns,
      if (privacy != null && privacy.isNotEmpty) privacy,
      if (member.archived) 'archived',
    ];
    return parts.join(' - ');
  }

  Color _memberColor(MemberSummary member) {
    return _colorFromHex(member.colorHex);
  }
}

void showMemberProfileSheet(
  BuildContext context,
  HavenRepository repository,
  MemberSummary member,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: _spSurface,
    builder: (context) =>
        MemberProfileSheet(repository: repository, member: member),
  );
}

class MemberProfileSheet extends StatelessWidget {
  const MemberProfileSheet({
    super.key,
    required this.repository,
    required this.member,
  });

  final HavenRepository repository;
  final MemberSummary member;

  @override
  Widget build(BuildContext context) {
    final color = _colorFromHex(member.colorHex);
    final description = member.description?.trim();
    final pluralKitId = member.pluralKitId?.trim();

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MemberAvatar(
                  member: member,
                  color: color,
                  label: _memberAvatarLabel(member),
                  size: 72,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.displayName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _memberPronouns(member),
                        style: const TextStyle(color: _spMuted, fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          StatusPill(
                            text: member.archived ? 'archived' : 'active',
                          ),
                          if (member.colorHex?.trim().isNotEmpty == true)
                            StatusPill(text: member.colorHex!.toUpperCase()),
                          if (member.emoji?.trim().isNotEmpty == true)
                            StatusPill(text: member.emoji!.trim()),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (description != null && description.isNotEmpty)
              SpCard(
                child: Text(description, style: const TextStyle(height: 1.4)),
              )
            else
              const SpCard(
                child: Text(
                  'No description yet.',
                  style: TextStyle(color: _spMuted),
                ),
              ),
            const SizedBox(height: 12),
            StreamBuilder<List<GroupSummary>>(
              stream: repository.watchGroups(),
              initialData: const [],
              builder: (context, groupsSnapshot) {
                return SpSettingsGroup(
                  title: 'Profile',
                  rows: [
                    SpSettingsRow(
                      'Pronouns',
                      _memberPronouns(member),
                      interactive: false,
                    ),
                    SpSettingsRow(
                      'Birthday',
                      _emptyLabel(member.birthday),
                      interactive: false,
                    ),
                    SpSettingsRow(
                      'Emoji',
                      _emptyLabel(member.emoji),
                      interactive: false,
                    ),
                    SpSettingsRow(
                      'Privacy',
                      _emptyLabel(member.privacy),
                      interactive: false,
                    ),
                    SpSettingsRow(
                      'PluralKit ID',
                      pluralKitId == null || pluralKitId.isEmpty
                          ? 'not linked'
                          : pluralKitId,
                      interactive: false,
                    ),
                    SpSettingsRow(
                      'Groups',
                      _memberGroupLabel(
                        member,
                        groupsSnapshot.data ?? const <GroupSummary>[],
                      ),
                      interactive: false,
                    ),
                    SpSettingsRow(
                      'Avatar',
                      member.avatarUrl?.trim().isNotEmpty == true
                          ? member.avatarUrl!
                          : 'default',
                      interactive: false,
                    ),
                  ],
                );
              },
            ),
            MemberCustomFieldsSection(
              repository: repository,
              memberId: member.id,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!member.archived)
                  FilledButton.icon(
                    onPressed: () async {
                      await repository.setFrontMembers([member.id]);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.radio_button_checked_rounded),
                    label: const Text('Set front'),
                  ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    showMemberSheet(context, repository, member: member);
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    if (member.archived) {
                      await repository.restoreMember(member.id);
                    } else {
                      await repository.archiveMember(member.id);
                    }
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  icon: Icon(
                    member.archived
                        ? Icons.unarchive_outlined
                        : Icons.archive_outlined,
                  ),
                  label: Text(member.archived ? 'Restore' : 'Archive'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MemberCustomFieldsSection extends StatelessWidget {
  const MemberCustomFieldsSection({
    super.key,
    required this.repository,
    required this.memberId,
  });

  final HavenRepository repository;
  final String memberId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CustomFieldSummary>>(
      stream: repository.watchCustomFields(),
      initialData: const [],
      builder: (context, fieldsSnapshot) {
        final fields = fieldsSnapshot.data ?? const <CustomFieldSummary>[];
        return StreamBuilder<List<CustomFieldValueSummary>>(
          stream: repository.watchCustomFieldValues(),
          initialData: const [],
          builder: (context, valuesSnapshot) {
            final values =
                (valuesSnapshot.data ?? const <CustomFieldValueSummary>[])
                    .where((value) => value.memberId == memberId)
                    .toList(growable: false);
            final valuesByField = {
              for (final value in values) value.fieldId: value,
            };

            if (fields.isEmpty) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SpSettingsGroup(
                title: 'Data',
                rows: [
                  for (final field in fields)
                    Builder(
                      builder: (context) {
                        final value = valuesByField[field.id];
                        return SpSettingsRow(
                          field.name,
                          value == null || value.value.trim().isEmpty
                              ? 'not set'
                              : value.value,
                          trailing: _customFieldPrivacyPill(field),
                          onTap: () => showCustomFieldValueSheet(
                            context,
                            repository: repository,
                            field: field,
                            value: value,
                            memberId: memberId,
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _customFieldPrivacyPill(CustomFieldSummary? field) {
    final privacy = field?.privacy?.trim();
    if (privacy == null || privacy.isEmpty) {
      return const SizedBox.shrink();
    }
    return StatusPill(text: privacy);
  }
}

void showCustomFieldValueSheet(
  BuildContext context, {
  required HavenRepository repository,
  required CustomFieldSummary field,
  required CustomFieldValueSummary? value,
  required String? memberId,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: _spSurface,
    builder: (context) => CustomFieldValueSheet(
      repository: repository,
      field: field,
      value: value,
      memberId: memberId,
    ),
  );
}

class CustomFieldValueSheet extends StatefulWidget {
  const CustomFieldValueSheet({
    super.key,
    required this.repository,
    required this.field,
    required this.value,
    required this.memberId,
  });

  final HavenRepository repository;
  final CustomFieldSummary field;
  final CustomFieldValueSummary? value;
  final String? memberId;

  @override
  State<CustomFieldValueSheet> createState() => _CustomFieldValueSheetState();
}

class _CustomFieldValueSheetState extends State<CustomFieldValueSheet> {
  late final TextEditingController _valueController;

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController(text: widget.value?.value ?? '');
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final privacy = widget.field.privacy?.trim();
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
              widget.field.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              [
                widget.field.fieldType,
                if (privacy != null && privacy.isNotEmpty) privacy,
              ].join(' - '),
              style: const TextStyle(color: _spMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('custom-field-value-field'),
              controller: _valueController,
              autofocus: true,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: 'Value',
                hintText: 'Leave blank to clear',
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  key: const ValueKey('save-custom-field-value-button'),
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save value'),
                ),
                OutlinedButton.icon(
                  onPressed: _clear,
                  icon: const Icon(Icons.backspace_outlined),
                  label: const Text('Clear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    await widget.repository.setCustomFieldValue(
      fieldId: widget.field.id,
      memberId: widget.memberId,
      value: _valueController.text,
    );
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _clear() async {
    await widget.repository.setCustomFieldValue(
      fieldId: widget.field.id,
      memberId: widget.memberId,
      value: '',
    );
    if (mounted) {
      Navigator.pop(context);
    }
  }
}

String _memberPronouns(MemberSummary member) {
  final pronouns = member.pronouns?.trim();
  return pronouns == null || pronouns.isEmpty ? 'no pronouns' : pronouns;
}

String _emptyLabel(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? 'not set' : trimmed;
}

String _memberGroupLabel(MemberSummary member, List<GroupSummary> groups) {
  final namesById = {for (final group in groups) group.id: group.name};
  final ids = <String>{
    ...member.groupIds,
    if (member.groupIds.isEmpty && member.folderId != null) member.folderId!,
  };
  if (ids.isEmpty) {
    return 'none';
  }

  return [for (final id in ids) namesById[id] ?? id].join(', ');
}

String _memberAvatarLabel(MemberSummary member) {
  final emoji = member.emoji?.trim();
  return emoji == null || emoji.isEmpty
      ? _initialFor(member.displayName)
      : emoji;
}

class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.member,
    required this.color,
    required this.label,
    this.size = 42,
  });

  final MemberSummary member;
  final Color color;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = member.avatarUrl;
    if (avatarUrl == null || avatarUrl.trim().isEmpty) {
      return SpAvatar(size: size, color: color, label: label);
    }
    if (avatarUrl.startsWith('local-avatar:')) {
      return FutureBuilder<File?>(
        future: _localAvatarFile(avatarUrl),
        builder: (context, snapshot) {
          final file = snapshot.data;
          return SpAvatar(
            size: size,
            color: color,
            label: label,
            image: file == null ? null : FileImage(file),
          );
        },
      );
    }
    if (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')) {
      return SpAvatar(
        size: size,
        color: color,
        label: label,
        image: NetworkImage(avatarUrl),
      );
    }
    return SpAvatar(size: size, color: color, label: label);
  }
}

Future<File?> _localAvatarFile(String avatarUrl) async {
  final fileName = avatarUrl.replaceFirst('local-avatar:', '').trim();
  if (fileName.isEmpty || fileName.contains('/') || fileName.contains('\\')) {
    return null;
  }
  try {
    final base = await getApplicationDocumentsDirectory();
    final file = File('${base.path}/avatars/$fileName');
    return file.existsSync() ? file : null;
  } on Object {
    final file = File(
      '${Directory.systemTemp.path}/pluris-haven-test/avatars/$fileName',
    );
    return file.existsSync() ? file : null;
  }
}

String _initialFor(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();
}

Color _colorFromHex(String? colorHex, {Color fallback = _spPurple}) {
  final value = colorHex?.replaceFirst('#', '');
  if (value == null || value.length != 6) {
    return fallback;
  }

  final parsed = int.tryParse('FF$value', radix: 16);
  return parsed == null ? fallback : Color(parsed);
}

void showAddMemberSheet(BuildContext context, HavenRepository repository) {
  showMemberSheet(context, repository);
}

void showMemberSheet(
  BuildContext context,
  HavenRepository repository, {
  MemberSummary? member,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: _spSurface,
    builder: (context) =>
        AddMemberSheet(repository: repository, member: member),
  );
}

class AddMemberSheet extends StatefulWidget {
  const AddMemberSheet({super.key, required this.repository, this.member});

  final HavenRepository repository;
  final MemberSummary? member;

  @override
  State<AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<AddMemberSheet> {
  final _nameController = TextEditingController();
  final _pronounsController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _emojiController = TextEditingController();
  final _privacyController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _avatarController = TextEditingController();
  final _pluralKitController = TextEditingController();
  final _colorController = TextEditingController(
    text: _hexFromAccent(HavenAccentColor.purple),
  );
  String? _folderId;
  final Set<String> _groupIds = {};
  String? _colorError;

  bool get _isEditing => widget.member != null;

  @override
  void initState() {
    super.initState();
    final member = widget.member;
    if (member == null) {
      return;
    }

    _nameController.text = member.displayName;
    _pronounsController.text = member.pronouns ?? '';
    _birthdayController.text = member.birthday ?? '';
    _emojiController.text = member.emoji ?? '';
    _privacyController.text = member.privacy ?? '';
    _descriptionController.text = member.description ?? '';
    _avatarController.text = member.avatarUrl ?? '';
    _pluralKitController.text = member.pluralKitId ?? '';
    _folderId = member.folderId;
    _groupIds
      ..clear()
      ..addAll(member.groupIds);
    if (_folderId != null) {
      _groupIds.add(_folderId!);
    }
    _colorController.text =
        _normalizeUiHexColor(member.colorHex ?? '') ??
        _hexFromAccent(HavenAccentColor.purple);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pronounsController.dispose();
    _birthdayController.dispose();
    _emojiController.dispose();
    _privacyController.dispose();
    _descriptionController.dispose();
    _avatarController.dispose();
    _pluralKitController.dispose();
    _colorController.dispose();
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
              'Alter profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('member-name-field'),
              controller: _nameController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('member-pronouns-field'),
              controller: _pronounsController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Pronouns'),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('member-birthday-field'),
              controller: _birthdayController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Birthday',
                hintText: 'YYYY-MM-DD, MM-DD, or free text',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('member-emoji-field'),
              controller: _emojiController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Emoji'),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('member-privacy-field'),
              controller: _privacyController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Privacy',
                hintText: 'private, friends, public, or bucket name',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('member-avatar-field'),
              controller: _avatarController,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Avatar URL or local ref',
                hintText: 'https://... or local-avatar:...',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('member-pluralkit-field'),
              controller: _pluralKitController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'PluralKit ID'),
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<GroupSummary>>(
              stream: widget.repository.watchGroups(),
              initialData: const [],
              builder: (context, snapshot) {
                final groups = snapshot.data ?? const <GroupSummary>[];
                final groupIds = groups.map((group) => group.id).toSet();
                if (groups.isNotEmpty &&
                    _folderId != null &&
                    !groupIds.contains(_folderId)) {
                  _folderId = null;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String?>(
                      initialValue: _folderId,
                      decoration: const InputDecoration(
                        labelText: 'Primary group',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('No primary group'),
                        ),
                        for (final group in groups)
                          DropdownMenuItem<String?>(
                            value: group.id,
                            child: Text(group.name),
                          ),
                      ],
                      onChanged: (value) => setState(() {
                        _folderId = value;
                        if (value != null) {
                          _groupIds.add(value);
                        }
                      }),
                    ),
                    if (groups.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Member groups',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final group in groups)
                            FilterChip(
                              label: Text(group.name),
                              selected: _groupIds.contains(group.id),
                              onSelected: (selected) => setState(() {
                                if (selected) {
                                  _groupIds.add(group.id);
                                  _folderId ??= group.id;
                                } else {
                                  _groupIds.remove(group.id);
                                  if (_folderId == group.id) {
                                    _folderId = _groupIds.isEmpty
                                        ? null
                                        : _groupIds.first;
                                  }
                                }
                              }),
                            ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final color in HavenAccentColor.values)
                  ChoiceChip(
                    label: Text(color.label),
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
              key: const ValueKey('member-color-hex-field'),
              controller: _colorController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Color hex',
                hintText: '#7B61FF',
                errorText: _colorError,
              ),
              onChanged: (_) {
                if (_colorError != null) {
                  setState(() => _colorError = null);
                }
              },
            ),
            const SizedBox(height: 14),
            FilledButton(
              key: const ValueKey('save-member-button'),
              onPressed: _save,
              child: Text(_isEditing ? 'Save alter' : 'Create alter'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final colorHex = _normalizeUiHexColor(_colorController.text);
    if (colorHex == null) {
      setState(() => _colorError = 'Use 6 hex digits, like #7B61FF.');
      return;
    }

    final draft = MemberDraft(
      displayName: _nameController.text,
      pronouns: _pronounsController.text,
      colorHex: colorHex,
      birthday: _birthdayController.text,
      emoji: _emojiController.text,
      privacy: _privacyController.text,
      description: _descriptionController.text,
      avatarUrl: _avatarController.text,
      pluralKitId: _pluralKitController.text,
      folderId: _folderId,
      groupIds: _groupIds.toList(growable: false),
    );
    final member = widget.member;
    if (member == null) {
      await widget.repository.saveMember(draft);
    } else {
      await widget.repository.updateMember(member.id, draft);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }
}

String _hexFromAccent(HavenAccentColor color) =>
    '#${color.argb.toRadixString(16).substring(2).toUpperCase()}';
