part of 'home_page.dart';

class CustomFrontsPage extends StatefulWidget {
  const CustomFrontsPage({super.key, required this.repository});

  final HavenRepository repository;

  @override
  State<CustomFrontsPage> createState() => _CustomFrontsPageState();
}

class _CustomFrontsPageState extends State<CustomFrontsPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NamedFront>>(
      stream: widget.repository.watchNamedFronts(),
      initialData: const [],
      builder: (context, snapshot) {
        final fronts = snapshot.data ?? const <NamedFront>[];
        final customFronts = fronts
            .where(_isCustomFront)
            .where(_matchesFrontQuery)
            .toList(growable: false);
        final namedCombinations = fronts
            .where((front) => !_isCustomFront(front))
            .where(_matchesFrontQuery)
            .toList(growable: false);

        return SpPage(
          children: [
            SpSearchField(
              hintText: 'Search custom fronts',
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 10),
            SpCard(
              outlined: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SpSectionHeader(
                    title: 'Custom fronts',
                    trailing: StatusPill(text: '${customFronts.length}'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Statuses like Asleep, Away, or Lost time live here. They can front without becoming members.',
                    style: TextStyle(color: _spMuted, height: 1.35),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    key: const ValueKey('add-custom-front-page-button'),
                    onPressed: () => _openEditor(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add custom front'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (customFronts.isEmpty)
              SpEmptyState(
                title: fronts.isEmpty ? 'No custom fronts' : 'No matches',
                body: fronts.isEmpty
                    ? 'Add one here, or import them from SimplyPlural.'
                    : 'Try a different search.',
              )
            else
              SpCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var index = 0; index < customFronts.length; index++)
                      _CustomFrontRow(
                        front: customFronts[index],
                        showDivider: index != customFronts.length - 1,
                        onSet: () => _applyFront(customFronts[index]),
                        onEdit: () => _openEditor(customFronts[index]),
                        onDelete: () => _deleteFront(customFronts[index]),
                      ),
                  ],
                ),
              ),
            if (namedCombinations.isNotEmpty) ...[
              const SizedBox(height: 16),
              SpSettingsGroup(
                title: 'Named combinations',
                rows: [
                  for (final front in namedCombinations)
                    SpSettingsRow(
                      front.name,
                      'member shortcut',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Set named front',
                            onPressed: () => _applyFront(front),
                            icon: const Icon(Icons.play_arrow_rounded),
                          ),
                          IconButton(
                            tooltip: 'Delete named front',
                            onPressed: () => _deleteFront(front),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ],
                      ),
                      onTap: () => _applyFront(front),
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  bool _matchesFrontQuery(NamedFront front) {
    return _matchesQuery(_query, [
      front.name,
      front.customLabel,
      front.description,
      front.colorHex,
      front.avatarUrl,
    ]);
  }

  Future<void> _openEditor([NamedFront? front]) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _spCard,
      builder: (context) =>
          _CustomFrontEditorSheet(repository: widget.repository, front: front),
    );
  }

  Future<void> _applyFront(NamedFront front) async {
    await widget.repository.applyNamedFront(front.id);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Set ${_frontTitle(front)} as front')),
    );
  }

  Future<void> _deleteFront(NamedFront front) async {
    await confirmDelete(
      context,
      title: _isCustomFront(front)
          ? 'Delete custom front?'
          : 'Delete named front?',
      body: 'This only removes the saved shortcut. Front history stays.',
      onDelete: () => widget.repository.deleteNamedFront(front.id),
    );
  }
}

class _CustomFrontRow extends StatelessWidget {
  const _CustomFrontRow({
    required this.front,
    required this.showDivider,
    required this.onSet,
    required this.onEdit,
    required this.onDelete,
  });

  final NamedFront front;
  final bool showDivider;
  final VoidCallback onSet;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final title = _frontTitle(front);
    final description = front.description?.trim();
    final colorHex = front.colorHex?.trim();

    return Column(
      children: [
        Semantics(
          button: true,
          label: 'Custom front $title',
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding: const EdgeInsetsDirectional.only(
                start: 14,
                end: 6,
              ),
              leading: _NamedFrontAvatar(front: front),
              title: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    colorHex == null || colorHex.isEmpty
                        ? 'custom front'
                        : colorHex,
                  ),
                  if (description != null && description.isNotEmpty)
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
              onTap: onSet,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Set custom front',
                    onPressed: onSet,
                    icon: const Icon(Icons.play_arrow_rounded),
                  ),
                  IconButton(
                    tooltip: 'Edit custom front',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Delete custom front',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider) const Divider(height: 1, color: _spLine, indent: 64),
      ],
    );
  }
}

class _CustomFrontEditorSheet extends StatefulWidget {
  const _CustomFrontEditorSheet({required this.repository, this.front});

  final HavenRepository repository;
  final NamedFront? front;

  @override
  State<_CustomFrontEditorSheet> createState() =>
      _CustomFrontEditorSheetState();
}

class _CustomFrontEditorSheetState extends State<_CustomFrontEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _colorController;
  late final TextEditingController _avatarController;
  late final TextEditingController _descriptionController;
  String? _avatarMessage;

  @override
  void initState() {
    super.initState();
    final front = widget.front;
    _nameController = TextEditingController(
      text: front == null ? '' : _frontTitle(front),
    );
    _colorController = TextEditingController(
      text: front?.colorHex ?? '#F2C75C',
    );
    _avatarController = TextEditingController(text: front?.avatarUrl ?? '');
    _descriptionController = TextEditingController(
      text: front?.description ?? '',
    );
    _attachPreviewListeners();
  }

  @override
  void dispose() {
    for (final controller in [
      _nameController,
      _colorController,
      _avatarController,
    ]) {
      controller.removeListener(_refreshPreview);
    }
    _nameController.dispose();
    _colorController.dispose();
    _avatarController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.front != null;
    final previewName = _nameController.text.trim().isEmpty
        ? 'Custom front'
        : _nameController.text.trim();
    final previewColor = _colorFromHex(
      _normalizeUiHexColor(_colorController.text),
      fallback: _spGold,
    );

    return SafeArea(
      child: SingleChildScrollView(
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
              editing ? 'Edit custom front' : 'Add custom front',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _CustomFrontAvatarPreview(
                  avatarUrl: _nullIfBlank(_avatarController.text),
                  color: previewColor,
                  label: _initialFor(previewName),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Custom fronts can be used from the front picker without changing member counts.',
                    style: TextStyle(color: _spMuted, height: 1.35),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('custom-front-page-name-field'),
              controller: _nameController,
              autofocus: !editing,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('custom-front-page-color-field'),
              controller: _colorController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Color',
                hintText: '#F2C75C',
                prefixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _colorController,
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
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('custom-front-page-avatar-field'),
              controller: _avatarController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Avatar URL or imported local reference',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const ValueKey('pick-custom-front-avatar-button'),
                  onPressed: _chooseAvatar,
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Choose image'),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('clear-custom-front-avatar-button'),
                  onPressed: _clearAvatar,
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Clear'),
                ),
              ],
            ),
            if (_avatarMessage != null) ...[
              const SizedBox(height: 6),
              Text(
                _avatarMessage!,
                style: const TextStyle(color: _spMuted, fontSize: 12),
              ),
            ],
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('custom-front-page-description-field'),
              controller: _descriptionController,
              minLines: 2,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 14),
            FilledButton(
              key: const ValueKey('save-custom-front-page-button'),
              onPressed: _save,
              child: Text(editing ? 'Save changes' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }
    final colorHex = _normalizeUiHexColor(_colorController.text);
    if (colorHex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Use 6 hex digits, like #F2C75C.')),
      );
      return;
    }

    final now = DateTime.now().toUtc();
    final existing = widget.front;
    await widget.repository.saveNamedFront(
      NamedFront(
        id: existing?.id ?? 'custom-front-${now.microsecondsSinceEpoch}',
        systemId: localSystemId,
        name: name,
        customLabel: name,
        colorHex: colorHex,
        avatarUrl: _nullIfBlank(_avatarController.text),
        description: _nullIfBlank(_descriptionController.text),
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      ),
      const [],
    );
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _chooseAvatar() async {
    setState(() => _avatarMessage = 'Opening image picker...');
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
      dialogTitle: 'Choose custom front avatar',
    );
    final files = result?.files ?? const <PlatformFile>[];
    final file = files.isEmpty ? null : files.first;
    if (file == null) {
      if (mounted) {
        setState(() => _avatarMessage = 'No image selected.');
      }
      return;
    }

    try {
      final bytes = file.bytes ?? await _readPickedFileBytes(file.path);
      if (bytes == null || bytes.isEmpty) {
        throw const FormatException('Selected image was empty.');
      }
      final ref = await _storeManualAvatar(file.name, bytes);
      if (!mounted) {
        return;
      }
      setState(() {
        _avatarController.text = ref;
        _avatarMessage = 'Avatar saved on device.';
      });
    } on Object catch (error) {
      if (mounted) {
        setState(() => _avatarMessage = 'Could not save avatar: $error');
      }
    }
  }

  void _clearAvatar() {
    setState(() {
      _avatarController.clear();
      _avatarMessage = 'Avatar cleared.';
    });
  }

  void _refreshPreview() {
    if (mounted) {
      setState(() {});
    }
  }

  void _attachPreviewListeners() {
    for (final controller in [
      _nameController,
      _colorController,
      _avatarController,
    ]) {
      controller.addListener(_refreshPreview);
    }
  }
}

class _CustomFrontAvatarPreview extends StatelessWidget {
  const _CustomFrontAvatarPreview({
    required this.avatarUrl,
    required this.color,
    required this.label,
  });

  final String? avatarUrl;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ref = avatarUrl?.trim();
    if (ref == null || ref.isEmpty) {
      return SpAvatar(size: 42, color: color, label: label);
    }
    if (ref.startsWith('local-avatar:')) {
      return FutureBuilder<File?>(
        future: _localAvatarFile(ref),
        builder: (context, snapshot) {
          return SpAvatar(
            size: 42,
            color: color,
            label: label,
            image: snapshot.data == null ? null : FileImage(snapshot.data!),
          );
        },
      );
    }
    if (ref.startsWith('http://') || ref.startsWith('https://')) {
      return SpAvatar(
        size: 42,
        color: color,
        label: label,
        image: NetworkImage(ref),
      );
    }
    return SpAvatar(size: 42, color: color, label: label);
  }
}

bool _isCustomFront(NamedFront front) {
  final label = front.customLabel?.trim();
  return label != null && label.isNotEmpty;
}

String _frontTitle(NamedFront front) {
  final label = front.customLabel?.trim();
  if (label != null && label.isNotEmpty) {
    return label;
  }
  return front.name;
}

String? _nullIfBlank(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
