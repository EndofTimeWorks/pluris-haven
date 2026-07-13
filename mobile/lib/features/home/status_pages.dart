part of 'home_page.dart';

class LocalPrivacyPage extends StatelessWidget {
  const LocalPrivacyPage({super.key, required this.onSelect});

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
                title: 'Privacy buckets',
                trailing: StatusPill(text: 'local'),
              ),
              SizedBox(height: 8),
              Text(
                'Buckets are kept as local visibility notes until friend sync is enabled.',
                style: TextStyle(color: _spMuted, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SpSettingsGroup(
          title: 'Current buckets',
          rows: [
            const SpSettingsRow(
              'Private',
              'stored on this device',
              interactive: false,
            ),
            const SpSettingsRow(
              'Trusted',
              'ready for future sharing rules',
              interactive: false,
            ),
            const SpSettingsRow(
              'Public',
              'off unless sync is configured',
              interactive: false,
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
                'A small local snapshot you can copy before filing a bug.',
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
      'system: ${home?.systemName ?? 'Local system'}',
      'members: ${home?.memberCount ?? 0}',
      'groups: ${home?.groupCount ?? 0}',
      'notes: ${home?.noteCount ?? 0}',
      'front history: ${home?.frontHistoryCount ?? 0}',
      'current front: ${home?.currentFrontLabel ?? 'none'}',
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
    required this.onSelect,
  });

  final HomeSnapshot? snapshot;
  final HavenRepository repository;
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
                label: (home?.systemName ?? 'PH').trim().substring(0, 1),
                avatarUrl: home?.systemAvatarUrl,
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
        SpSettingsGroup(
          title: 'Account',
          rows: [
            const SpSettingsRow(
              'Cloud account',
              'not required',
              interactive: false,
            ),
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
              'Field encryption',
              'local crypto enabled',
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
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
      dialogTitle: 'Choose system avatar',
    );
    final file = result?.files.firstOrNull;
    if (file == null) return;
    try {
      final bytes = file.bytes ?? await _readPickedFileBytes(file.path);
      if (bytes == null || bytes.isEmpty) {
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
