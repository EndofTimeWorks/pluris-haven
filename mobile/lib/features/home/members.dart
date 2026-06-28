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
          label: _initial,
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

  String get _initial {
    return _initialFor(member.displayName);
  }

  String get _subtitle {
    final pronouns = member.pronouns?.isNotEmpty == true
        ? member.pronouns!
        : 'no pronouns';
    return member.archived ? '$pronouns - archived' : pronouns;
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
                  label: _initialFor(member.displayName),
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
            SpSettingsGroup(
              title: 'Profile',
              rows: [
                SpSettingsRow(
                  'Pronouns',
                  _memberPronouns(member),
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
                  'Group',
                  member.folderId == null ? 'none' : member.folderId!,
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

String _memberPronouns(MemberSummary member) {
  final pronouns = member.pronouns?.trim();
  return pronouns == null || pronouns.isEmpty ? 'no pronouns' : pronouns;
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
  final _descriptionController = TextEditingController();
  final _avatarController = TextEditingController();
  final _pluralKitController = TextEditingController();
  final _colorController = TextEditingController(
    text: _hexFromAccent(HavenAccentColor.purple),
  );
  String? _folderId;
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
    _descriptionController.text = member.description ?? '';
    _avatarController.text = member.avatarUrl ?? '';
    _pluralKitController.text = member.pluralKitId ?? '';
    _folderId = member.folderId;
    _colorController.text =
        _normalizeUiHexColor(member.colorHex ?? '') ??
        _hexFromAccent(HavenAccentColor.purple);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pronounsController.dispose();
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
                return DropdownButtonFormField<String?>(
                  initialValue: _folderId,
                  decoration: const InputDecoration(labelText: 'Group'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('No group'),
                    ),
                    for (final group in groups)
                      DropdownMenuItem<String?>(
                        value: group.id,
                        child: Text(group.name),
                      ),
                  ],
                  onChanged: (value) => setState(() => _folderId = value),
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
      description: _descriptionController.text,
      avatarUrl: _avatarController.text,
      pluralKitId: _pluralKitController.text,
      folderId: _folderId,
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
