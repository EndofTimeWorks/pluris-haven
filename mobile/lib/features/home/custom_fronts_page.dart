part of 'home_page.dart';

class CustomFrontsPage extends StatefulWidget {
  const CustomFrontsPage({super.key, required this.repository});

  final HavenRepository repository;

  @override
  State<CustomFrontsPage> createState() => _CustomFrontsPageState();
}

class _CustomFrontsPageState extends State<CustomFrontsPage> {
  final _searchController = TextEditingController();
  late final Stream<List<NamedFront>> _frontsStream;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _frontsStream = widget.repository.watchNamedFronts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<List<NamedFront>>(
      stream: _frontsStream,
      initialData: const [],
      builder: (context, snapshot) {
        final scheme = Theme.of(context).colorScheme;
        final isSimplyPlural =
            _visualThemeOf(context) == HavenVisualTheme.simplyPlural;
        final fronts = snapshot.data ?? const <NamedFront>[];
        final customFronts = fronts
            .where(_isCustomFront)
            .where(_matchesFrontQuery)
            .toList(growable: false);
        final namedCombinations = fronts
            .where((front) => !_isCustomFront(front))
            .where(_matchesFrontQuery)
            .toList(growable: false);

        if (isSimplyPlural) {
          return _buildSimplyPluralLayout(
            context,
            l10n,
            customFronts,
            namedCombinations,
          );
        }

        return SpPage(
          children: [
            SpCard(
              outlined: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SpSectionHeader(
                    title: l10n.customFrontsTitle,
                    trailing: StatusPill(text: '${customFronts.length}'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.customFrontsDescription,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    key: const ValueKey('add-custom-front-page-button'),
                    onPressed: () => _openEditor(),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l10n.addCustomFrontButton),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SpSearchField(
              hintText: l10n.searchCustomFrontsHint,
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            if (customFronts.isEmpty)
              SpEmptyState(
                title: fronts.isEmpty ? l10n.noCustomFronts : l10n.noMatches,
                body: fronts.isEmpty
                    ? l10n.customFrontsEmptyBody
                    : l10n.tryDifferentSearch,
              )
            else
              SpCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var index = 0; index < customFronts.length; index++)
                      _CustomFrontRow(
                        repository: widget.repository,
                        front: customFronts[index],
                        showDivider: index != customFronts.length - 1,
                        compactActions: false,
                        onUse: (action) =>
                            _applyFront(customFronts[index], action),
                        onEdit: () => _openEditor(customFronts[index]),
                        onDelete: () => _deleteFront(customFronts[index]),
                      ),
                  ],
                ),
              ),
            if (namedCombinations.isNotEmpty) ...[
              const SizedBox(height: 16),
              SpSettingsGroup(
                title: l10n.namedCombinationsTitle,
                rows: [
                  for (final front in namedCombinations)
                    SpSettingsRow(
                      front.name,
                      l10n.memberShortcutLabel,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _FrontActionButton(
                            repository: widget.repository,
                            actionKey: 'named-front-${front.id}',
                            onPressed: (action) => _applyFront(front, action),
                          ),
                          IconButton(
                            tooltip: l10n.deleteNamedFrontTooltip,
                            onPressed: () => _deleteFront(front),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ],
                      ),
                      onTap: null,
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

  Widget _buildSimplyPluralLayout(
    BuildContext context,
    AppLocalizations l10n,
    List<NamedFront> customFronts,
    List<NamedFront> namedCombinations,
  ) {
    final fronts = [...customFronts, ...namedCombinations];
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
          sliver: SliverList.list(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.customFrontsTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  StatusPill(text: '${customFronts.length}'),
                  const SizedBox(width: 4),
                  IconButton.filledTonal(
                    key: const ValueKey('add-custom-front-page-button'),
                    tooltip: l10n.addCustomFrontButton,
                    onPressed: () => _openEditor(),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SpSearchField(
                hintText: l10n.searchCustomFrontsHint,
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
              ),
              if (fronts.isEmpty) ...[
                const SizedBox(height: 12),
                SpEmptyState(
                  title: _query.trim().isEmpty
                      ? l10n.noCustomFronts
                      : l10n.noMatches,
                  body: _query.trim().isEmpty
                      ? l10n.customFrontsEmptyBody
                      : l10n.tryDifferentSearch,
                ),
              ],
            ],
          ),
        ),
        if (customFronts.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            sliver: SliverList.builder(
              itemCount: customFronts.length,
              itemBuilder: (context, index) {
                final front = customFronts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SpCard(
                    child: _CustomFrontRow(
                      repository: widget.repository,
                      front: front,
                      showDivider: false,
                      compactActions: true,
                      onUse: (action) => _applyFront(front, action),
                      onEdit: () => _openEditor(front),
                      onDelete: () => _deleteFront(front),
                    ),
                  ),
                );
              },
            ),
          ),
        if (namedCombinations.isNotEmpty) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
            sliver: SliverToBoxAdapter(
              child: Text(
                l10n.namedCombinationsTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            sliver: SliverList.builder(
              itemCount: namedCombinations.length,
              itemBuilder: (context, index) {
                final front = namedCombinations[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: SpCard(
                    padding: EdgeInsets.zero,
                    child: SpSettingsRow(
                      front.name,
                      l10n.memberShortcutLabel,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _FrontActionButton(
                            repository: widget.repository,
                            actionKey: 'named-front-${front.id}',
                            onPressed: (action) => _applyFront(front, action),
                          ),
                          IconButton(
                            tooltip: l10n.deleteNamedFrontTooltip,
                            onPressed: () => _deleteFront(front),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ],
                      ),
                      onTap: null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _openEditor([NamedFront? front]) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) =>
          _CustomFrontEditorSheet(repository: widget.repository, front: front),
    );
  }

  Future<void> _applyFront(NamedFront front, HavenFrontAction action) async {
    final reminders = action == HavenFrontAction.add
        ? await widget.repository.addNamedFront(front.id)
        : await widget.repository.applyNamedFront(front.id);
    if (!mounted) {
      return;
    }
    await deliverAfterFrontReminders(context, widget.repository, reminders);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).setFrontConfirmation(_frontTitle(front)),
        ),
      ),
    );
  }

  Future<void> _deleteFront(NamedFront front) async {
    await confirmDelete(
      context,
      title: _isCustomFront(front)
          ? AppLocalizations.of(context).deleteCustomFrontTitle
          : AppLocalizations.of(context).deleteNamedFrontTitle,
      body: AppLocalizations.of(context).deleteSavedFrontBody,
      onDelete: () => widget.repository.deleteNamedFront(front.id),
    );
  }
}

class _CustomFrontRow extends StatelessWidget {
  const _CustomFrontRow({
    required this.repository,
    required this.front,
    required this.showDivider,
    required this.compactActions,
    required this.onUse,
    required this.onEdit,
    required this.onDelete,
  });

  final HavenRepository repository;
  final NamedFront front;
  final bool showDivider;
  final bool compactActions;
  final Future<void> Function(HavenFrontAction action) onUse;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = _frontTitle(front);
    final description = front.description?.trim();

    return Column(
      children: [
        Semantics(
          button: true,
          label: l10n.customFrontSemanticLabel(title),
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
              subtitle: description == null || description.isEmpty
                  ? null
                  : Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
              onTap: onEdit,
              trailing: compactActions
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _FrontActionButton(
                          repository: repository,
                          actionKey: 'named-front-${front.id}',
                          onPressed: onUse,
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              onEdit();
                            } else {
                              onDelete();
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text(l10n.editCustomFrontTooltip),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(l10n.deleteCustomFrontTooltip),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _FrontActionButton(
                          repository: repository,
                          actionKey: 'named-front-${front.id}',
                          onPressed: onUse,
                        ),
                        IconButton(
                          tooltip: l10n.editCustomFrontTooltip,
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          tooltip: l10n.deleteCustomFrontTooltip,
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        if (showDivider) const Divider(height: 1, indent: 64),
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
    final l10n = AppLocalizations.of(context);
    final editing = widget.front != null;
    final scheme = Theme.of(context).colorScheme;
    final previewName = _nameController.text.trim().isEmpty
        ? l10n.customFrontLabel
        : _nameController.text.trim();
    final previewColor = _colorFromHex(
      _normalizeUiHexColor(_colorController.text),
      fallback: scheme.primary,
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
              editing ? l10n.editCustomFrontTitle : l10n.addCustomFrontButton,
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
                Expanded(
                  child: Text(
                    l10n.customFrontEditorDescription,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
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
              decoration: InputDecoration(labelText: l10n.nameFieldLabel),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('custom-front-page-color-field'),
              controller: _colorController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.colourFieldLabel,
                hintText: '#F2C75C',
                prefixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _colorController,
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
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('custom-front-page-avatar-field'),
              controller: _avatarController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.importedAvatarReferenceFieldLabel,
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
                  label: Text(l10n.chooseImageButton),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('clear-custom-front-avatar-button'),
                  onPressed: _clearAvatar,
                  icon: const Icon(Icons.close_rounded),
                  label: Text(l10n.clearButton),
                ),
              ],
            ),
            if (_avatarMessage != null) ...[
              const SizedBox(height: 6),
              Text(
                _avatarMessage!,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              ),
            ],
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('custom-front-page-description-field'),
              controller: _descriptionController,
              minLines: 2,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                labelText: l10n.descriptionFieldLabel,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              key: const ValueKey('save-custom-front-page-button'),
              onPressed: _save,
              child: Text(editing ? l10n.saveChangesButton : l10n.createButton),
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
        SnackBar(
          content: Text(AppLocalizations.of(context).invalidHexColorError),
        ),
      );
      return;
    }

    final now = DateTime.now().toUtc();
    final existing = widget.front;
    await widget.repository.saveNamedFront(
      NamedFront(
        id: existing?.id ?? newLocalId('custom-front'),
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
    final l10n = AppLocalizations.of(context);
    setState(() => _avatarMessage = l10n.openingImagePickerStatus);
    try {
      final result = await NativeFileDialog.pickFiles(
        type: NativeFileType.image,
        allowMultiple: false,
        dialogTitle: l10n.chooseCustomFrontAvatarTitle,
        maximumBytes: maximumAvatarBytes,
      );
      final files = result?.files ?? const <NativePlatformFile>[];
      final file = files.isEmpty ? null : files.first;
      if (file == null) {
        if (mounted) {
          setState(() => _avatarMessage = l10n.noImageSelectedStatus);
        }
        return;
      }
      final bytes = await _readManualAvatarFile(file);
      final ref = await _storeManualAvatar(file.name, bytes);
      if (!mounted) {
        return;
      }
      setState(() {
        _avatarController.text = ref;
        _avatarMessage = l10n.avatarSavedStatus;
      });
    } on Object catch (error) {
      if (mounted) {
        setState(
          () => _avatarMessage =
              _manualAvatarValidationMessage(l10n, error) ??
              l10n.couldNotSaveAvatar(error),
        );
      }
    }
  }

  void _clearAvatar() {
    setState(() {
      _avatarController.clear();
      _avatarMessage = AppLocalizations.of(context).avatarClearedStatus;
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
    final avatarSemanticLabel = AppLocalizations.of(
      context,
    ).memberAvatarSemanticLabel(label);
    final ref = avatarUrl?.trim();
    if (ref == null || ref.isEmpty) {
      return SpAvatar(
        size: 42,
        color: color,
        label: label,
        semanticLabel: avatarSemanticLabel,
      );
    }
    if (ref.startsWith('local-avatar:')) {
      return FutureBuilder<Uint8List?>(
        future: _localAvatarFile(ref),
        builder: (context, snapshot) {
          return SpAvatar(
            size: 42,
            color: color,
            label: label,
            image: snapshot.data == null ? null : MemoryImage(snapshot.data!),
            semanticLabel: avatarSemanticLabel,
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
        semanticLabel: avatarSemanticLabel,
      );
    }
    return SpAvatar(
      size: 42,
      color: color,
      label: label,
      semanticLabel: avatarSemanticLabel,
    );
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
