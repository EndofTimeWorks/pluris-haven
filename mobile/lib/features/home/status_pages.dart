part of 'home_page.dart';

class LocalPrivacyPage extends StatelessWidget {
  const LocalPrivacyPage({
    super.key,
    required this.repository,
    required this.onSelect,
  });

  final HavenRepository repository;
  final ValueChanged<SpSection> onSelect;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PrivacyBucketSummary>>(
      stream: repository.watchPrivacyBuckets(),
      initialData: const [],
      builder: (context, snapshot) {
        final buckets = snapshot.data ?? const <PrivacyBucketSummary>[];
        return SpPage(
          children: [
            SpCard(
              outlined: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SpSectionHeader(
                    title: 'Privacy buckets',
                    trailing: StatusPill(text: '${buckets.length}'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Group members by who may see them. Sharing stays off until sync is configured.',
                    style: TextStyle(color: _spMuted, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  if (buckets.isEmpty)
                    const SpEmptyState(
                      title: 'No privacy buckets',
                      body: 'Create one to prepare member visibility rules.',
                    )
                  else
                    for (final bucket in buckets) ...[
                      Material(
                        color: Colors.transparent,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: SpIconBubble(
                            icon: Icons.shield_outlined,
                            color: _colorFromHex(
                              bucket.colorHex,
                              fallback: _spGold,
                            ),
                          ),
                          title: Text(bucket.name),
                          subtitle: Text(
                            bucket.description?.trim().isNotEmpty == true
                                ? '${bucket.description} - ${bucket.memberIds.length} members'
                                : '${bucket.memberIds.length} members',
                          ),
                          trailing: IconButton(
                            tooltip: 'Delete ${bucket.name}',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => confirmDelete(
                              context,
                              title: 'Delete privacy bucket?',
                              body:
                                  'Member assignments to ${bucket.name} will be removed.',
                              onDelete: () =>
                                  repository.deletePrivacyBucket(bucket.id),
                            ),
                          ),
                          onTap: () => showPrivacyBucketEditor(
                            context,
                            repository: repository,
                            bucket: bucket,
                          ),
                        ),
                      ),
                      if (bucket != buckets.last)
                        const Divider(height: 1, color: _spLine),
                    ],
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    key: const ValueKey('add-privacy-bucket-button'),
                    onPressed: () => showPrivacyBucketEditor(
                      context,
                      repository: repository,
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add bucket'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SpSettingsGroup(
              title: 'Related visibility',
              rows: [
                SpSettingsRow(
                  'Member visibility',
                  'edit privacy on member profiles',
                  onTap: () => onSelect(SpSection.members),
                ),
                SpSettingsRow(
                  'Custom fields privacy',
                  'edit field-level labels',
                  onTap: () => onSelect(SpSection.customFields),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

void showPrivacyBucketEditor(
  BuildContext context, {
  required HavenRepository repository,
  PrivacyBucketSummary? bucket,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: _spSurface,
    builder: (context) =>
        PrivacyBucketEditorSheet(repository: repository, bucket: bucket),
  );
}

class PrivacyBucketEditorSheet extends StatefulWidget {
  const PrivacyBucketEditorSheet({
    super.key,
    required this.repository,
    this.bucket,
  });

  final HavenRepository repository;
  final PrivacyBucketSummary? bucket;

  @override
  State<PrivacyBucketEditorSheet> createState() =>
      _PrivacyBucketEditorSheetState();
}

class _PrivacyBucketEditorSheetState extends State<PrivacyBucketEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _colorController;
  late final Set<String> _memberIds;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.bucket?.name);
    _descriptionController = TextEditingController(
      text: widget.bucket?.description,
    );
    _colorController = TextEditingController(
      text: widget.bucket?.colorHex ?? '#F2C75C',
    );
    _memberIds = {...?widget.bucket?.memberIds};
  }

  @override
  void dispose() {
    _nameController.dispose();
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.bucket == null
                  ? 'Add privacy bucket'
                  : 'Edit privacy bucket',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('privacy-bucket-name-field'),
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
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
              controller: _colorController,
              decoration: const InputDecoration(
                labelText: 'Color hex',
                hintText: '#F2C75C',
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Members',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            StreamBuilder<List<MemberSummary>>(
              stream: widget.repository.watchMembers(includeArchived: true),
              initialData: const [],
              builder: (context, snapshot) => Column(
                children: [
                  for (final member in snapshot.data ?? const <MemberSummary>[])
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(member.displayName),
                      value: _memberIds.contains(member.id),
                      onChanged: (selected) => setState(() {
                        if (selected == true) {
                          _memberIds.add(member.id);
                        } else {
                          _memberIds.remove(member.id);
                        }
                      }),
                    ),
                ],
              ),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 14),
            FilledButton.icon(
              key: const ValueKey('save-privacy-bucket-button'),
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final color = _colorController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name is required.');
      return;
    }
    if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(color)) {
      setState(() => _error = 'Use a six-digit hex color such as #F2C75C.');
      return;
    }
    final draft = PrivacyBucketDraft(
      name: name,
      description: _descriptionController.text,
      colorHex: color,
      memberIds: _memberIds.toList(growable: false),
    );
    if (widget.bucket == null) {
      await widget.repository.savePrivacyBucket(draft);
    } else {
      await widget.repository.updatePrivacyBucket(widget.bucket!.id, draft);
    }
    if (mounted) Navigator.pop(context);
  }
}

class LocalTokensPage extends StatelessWidget {
  const LocalTokensPage({super.key, required this.onSelect});

  final ValueChanged<SpSection> onSelect;

  @override
  Widget build(BuildContext context) {
    return SpPage(
      children: [
        const SpCard(
          outlined: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SpSectionHeader(
                title: 'Tokens',
                trailing: StatusPill(text: 'disabled'),
              ),
              SizedBox(height: 8),
              Text(
                'There is no local API token surface yet. Imports do not need a Pluris Haven token.',
                style: TextStyle(color: _spMuted, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SpSettingsGroup(
          title: 'Token status',
          rows: [
            const SpSettingsRow(
              'Local token store',
              'empty',
              interactive: false,
            ),
            SpSettingsRow(
              'PluralKit live import',
              'paste a token during import',
              onTap: () => onSelect(SpSection.importExport),
            ),
            SpSettingsRow(
              'Sync tokens',
              'requires sync setup',
              onTap: () => onSelect(SpSection.sync),
            ),
          ],
        ),
      ],
    );
  }
}

class UserReportPage extends StatelessWidget {
  const UserReportPage({
    super.key,
    required this.snapshot,
    required this.onSelect,
  });

  final HomeSnapshot? snapshot;
  final ValueChanged<SpSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final report = _buildReport(snapshot);

    return SpPage(
      children: [
        SpCard(
          outlined: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SpSectionHeader(
                title: 'User Report',
                trailing: StatusPill(text: 'local'),
              ),
              const SizedBox(height: 8),
              const Text(
                'A small local snapshot you can copy before filing a bug. It excludes system and front names.',
                style: TextStyle(color: _spMuted, height: 1.35),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _copyReport(context, report),
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy report'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SpCard(
          child: SelectableText(
            report,
            style: const TextStyle(color: _spMuted, height: 1.35),
          ),
        ),
        const SizedBox(height: 12),
        SpSettingsGroup(
          title: 'Related',
          rows: [
            SpSettingsRow(
              'Import jobs',
              'open import details and errors',
              onTap: () => onSelect(SpSection.importExport),
            ),
            SpSettingsRow(
              'Notification history',
              'local event log',
              onTap: () => onSelect(SpSection.notificationHistory),
            ),
          ],
        ),
      ],
    );
  }

  String _buildReport(HomeSnapshot? snapshot) {
    final home = snapshot;
    return [
      'Pluris Haven local report',
      'stage: pre-alpha',
      'members: ${home?.memberCount ?? 0}',
      'groups: ${home?.groupCount ?? 0}',
      'notes: ${home?.noteCount ?? 0}',
      'front history: ${home?.frontHistoryCount ?? 0}',
      'storage: device',
      'sync: off by default',
    ].join('\n');
  }

  Future<void> _copyReport(BuildContext context, String report) async {
    await Clipboard.setData(ClipboardData(text: report));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Report copied')));
    }
  }
}

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({
    super.key,
    required this.snapshot,
    required this.repository,
    required this.serverAccount,
    required this.onSelect,
  });

  final HomeSnapshot? snapshot;
  final HavenRepository repository;
  final ServerAccountController? serverAccount;
  final ValueChanged<SpSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final home = snapshot;

    return SpPage(
      children: [
        SpCard(
          outlined: true,
          child: Row(
            children: [
              StoredAvatar(
                size: 52,
                color: _colorFromHex(
                  home?.systemColorHex,
                  fallback: Theme.of(context).colorScheme.primary,
                ),
                label: (home?.systemName ?? '').trim().isEmpty
                    ? 'PH'
                    : home!.systemName.trim().substring(0, 1),
                avatarUrl: home?.systemAvatarUrl,
                semanticLabel:
                    'System avatar for ${home?.systemName ?? 'Local system'}',
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      home?.systemName ?? 'Local system',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      home?.systemDescription?.trim().isNotEmpty == true
                          ? home!.systemDescription!.trim()
                          : 'saved on device',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _spMuted),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit system profile',
                onPressed: home == null
                    ? null
                    : () => showSystemProfileEditor(
                        context,
                        snapshot: home,
                        repository: repository,
                      ),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ServerAccountPanel(controller: serverAccount),
        const SizedBox(height: 12),
        SpSettingsGroup(
          title: 'Account',
          rows: [
            SpSettingsRow(
              'Import / Export',
              'move data in or out',
              onTap: () => onSelect(SpSection.importExport),
            ),
            SpSettingsRow(
              'App options',
              'theme, language, dashboard',
              onTap: () => onSelect(SpSection.appOptions),
            ),
            SpSettingsRow(
              'Sync',
              'off by default',
              onTap: () => onSelect(SpSection.sync),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const SpSettingsGroup(
          title: 'Security',
          rows: [
            SpSettingsRow('Storage', 'device database', interactive: false),
            SpSettingsRow(
              'Member name encryption',
              'key stored in device secure storage',
              interactive: false,
            ),
            SpSettingsRow(
              'Destructive actions',
              'confirmed with dialogs',
              interactive: false,
            ),
          ],
        ),
      ],
    );
  }
}

Future<void> showSystemProfileEditor(
  BuildContext context, {
  required HomeSnapshot snapshot,
  required HavenRepository repository,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: _spSurface,
    builder: (context) =>
        SystemProfileEditorSheet(snapshot: snapshot, repository: repository),
  );
}

class SystemProfileEditorSheet extends StatefulWidget {
  const SystemProfileEditorSheet({
    super.key,
    required this.snapshot,
    required this.repository,
  });

  final HomeSnapshot snapshot;
  final HavenRepository repository;

  @override
  State<SystemProfileEditorSheet> createState() =>
      _SystemProfileEditorSheetState();
}

class _SystemProfileEditorSheetState extends State<SystemProfileEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _colorController;
  late String? _avatarUrl;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.snapshot.systemName);
    _descriptionController = TextEditingController(
      text: widget.snapshot.systemDescription,
    );
    _colorController = TextEditingController(
      text: widget.snapshot.systemColorHex ?? '#7B61FF',
    );
    _avatarUrl = widget.snapshot.systemAvatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previewColor = _colorFromHex(
      _colorController.text,
      fallback: Theme.of(context).colorScheme.primary,
    );
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'System profile',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Center(
              child: StoredAvatar(
                size: 88,
                color: previewColor,
                label: _nameController.text.trim().isEmpty
                    ? 'PH'
                    : _nameController.text.trim().substring(0, 1),
                avatarUrl: _avatarUrl,
                semanticLabel:
                    'System avatar for ${_nameController.text.trim().isEmpty ? 'Local system' : _nameController.text.trim()}',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: _pickAvatar,
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Choose image'),
                ),
                if (_avatarUrl != null)
                  TextButton.icon(
                    onPressed: () => setState(() => _avatarUrl = null),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove'),
                  ),
              ],
            ),
            TextField(
              key: const ValueKey('system-name-field'),
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'System name'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('system-color-field'),
              controller: _colorController,
              autocorrect: false,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Color hex',
                hintText: '#7B61FF',
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: AccentSwatch(color: previewColor),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              key: const ValueKey('save-system-profile-button'),
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Saving...' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final result = await NativeFileDialog.pickFiles(
      type: NativeFileType.image,
      allowMultiple: false,
      dialogTitle: 'Choose system avatar',
    );
    final file = result?.files.firstOrNull;
    if (file == null) return;
    try {
      final bytes = await file.readBytes();
      if (bytes.isEmpty) {
        throw const FormatException('Selected image was empty.');
      }
      final ref = await _storeManualAvatar(file.name, bytes);
      if (mounted) setState(() => _avatarUrl = ref);
    } on Object catch (error) {
      if (mounted) setState(() => _error = 'Could not save image: $error');
    }
  }

  Future<void> _save() async {
    final color = _colorController.text.trim();
    if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(color)) {
      setState(() => _error = 'Use a six-digit hex color such as #7B61FF.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.updateSystemProfile(
        SystemProfileDraft(
          name: _nameController.text,
          description: _descriptionController.text,
          colorHex: color,
          avatarUrl: _avatarUrl,
        ),
      );
      if (mounted) Navigator.pop(context);
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.toString();
        });
      }
    }
  }
}
