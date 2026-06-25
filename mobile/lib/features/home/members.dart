part of 'home_page.dart';

class MembersPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return StreamBuilder<List<MemberSummary>>(
      stream: repository.watchMembers(includeArchived: true),
      initialData: const [],
      builder: (context, membersSnapshot) {
        final members = membersSnapshot.data ?? const <MemberSummary>[];

        return SpPage(
          children: [
            const SpSearchField(hintText: 'Search members'),
            const SizedBox(height: 12),
            const SpFilterRow(filters: ['All', 'Fronting', 'Archived']),
            const SizedBox(height: 12),
            SpCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SpSectionHeader(
                    title: 'Members',
                    trailing: StatusPill(text: '${snapshot?.memberCount ?? 0}'),
                  ),
                  const SizedBox(height: 12),
                  if (members.isEmpty)
                    const SpEmptyState(
                      title: 'No members saved locally',
                      body:
                          'Add members here or import a Simply Plural export.',
                    )
                  else
                    for (final member in members) ...[
                      MemberListTile(member: member, repository: repository),
                      if (member != members.last)
                        const Divider(height: 1, color: _spLine),
                    ],
                  const SizedBox(height: 14),
                  SpActionRow(
                    primary: 'Add member',
                    secondary: 'Import',
                    onPrimary: () => showAddMemberSheet(context, repository),
                    onSecondary: onImport,
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
    return ListTile(
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

class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.member,
    required this.color,
    required this.label,
  });

  final MemberSummary member;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = member.avatarUrl;
    if (avatarUrl == null || avatarUrl.trim().isEmpty) {
      return SpAvatar(size: 42, color: color, label: label);
    }
    if (avatarUrl.startsWith('local-avatar:')) {
      return FutureBuilder<File?>(
        future: _localAvatarFile(avatarUrl),
        builder: (context, snapshot) {
          final file = snapshot.data;
          return SpAvatar(
            size: 42,
            color: color,
            label: label,
            image: file == null ? null : FileImage(file),
          );
        },
      );
    }
    if (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')) {
      return SpAvatar(
        size: 42,
        color: color,
        label: label,
        image: NetworkImage(avatarUrl),
      );
    }
    return SpAvatar(size: 42, color: color, label: label);
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
  final _colorController = TextEditingController(
    text: _hexFromAccent(HavenAccentColor.purple),
  );
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
    _colorController.text =
        _normalizeUiHexColor(member.colorHex ?? '') ??
        _hexFromAccent(HavenAccentColor.purple);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pronounsController.dispose();
    _descriptionController.dispose();
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
              'Member',
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
              child: Text(_isEditing ? 'Save changes' : 'Save member'),
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
