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
        final l10n = AppLocalizations.of(context);
        final scheme = Theme.of(context).colorScheme;
        final buckets = snapshot.data ?? const <PrivacyBucketSummary>[];
        return SpPage(
          children: [
            SpCard(
              outlined: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SpSectionHeader(
                    title: l10n.navigationPrivacyBuckets,
                    trailing: StatusPill(text: '${buckets.length}'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.privacyBucketsDescription,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (buckets.isEmpty)
                    SpEmptyState(
                      title: l10n.noPrivacyBucketsTitle,
                      body: l10n.noPrivacyBucketsBody,
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
                              fallback: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          title: Text(bucket.name),
                          subtitle: Text(
                            bucket.description?.trim().isNotEmpty == true
                                ? l10n.bucketDescriptionMembers(
                                    bucket.description!,
                                    bucket.memberIds.length,
                                  )
                                : l10n.memberCount(bucket.memberIds.length),
                          ),
                          trailing: IconButton(
                            tooltip: l10n.deleteNamedItem(bucket.name),
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => confirmDelete(
                              context,
                              title: l10n.deletePrivacyBucketTitle,
                              body: l10n.deletePrivacyBucketBody(bucket.name),
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
                        Divider(height: 1, color: scheme.outlineVariant),
                    ],
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    key: const ValueKey('add-privacy-bucket-button'),
                    onPressed: () => showPrivacyBucketEditor(
                      context,
                      repository: repository,
                    ),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addBucketButton),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SpSettingsGroup(
              title: l10n.relatedVisibilityTitle,
              rows: [
                SpSettingsRow(
                  l10n.memberVisibilityTitle,
                  l10n.memberVisibilitySubtitle,
                  onTap: () => onSelect(SpSection.members),
                ),
                SpSettingsRow(
                  l10n.customFieldsPrivacyTitle,
                  l10n.customFieldsPrivacySubtitle,
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
    backgroundColor: Theme.of(context).colorScheme.surface,
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
              widget.bucket == null
                  ? l10n.addPrivacyBucketTitle
                  : l10n.editPrivacyBucketTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('privacy-bucket-name-field'),
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.nameFieldLabel),
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
            const SizedBox(height: 10),
            TextField(
              controller: _colorController,
              decoration: InputDecoration(
                labelText: l10n.colorHexFieldLabel,
                hintText: '#F2C75C',
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.membersTitle,
              style: const TextStyle(fontWeight: FontWeight.w800),
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
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 14),
            FilledButton.icon(
              key: const ValueKey('save-privacy-bucket-button'),
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(l10n.saveButtonLabel),
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
      setState(() => _error = AppLocalizations.of(context).nameRequiredError);
      return;
    }
    if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(color)) {
      setState(
        () => _error = AppLocalizations.of(context).invalidHexColorError,
      );
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
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return SpPage(
      children: [
        SpCard(
          outlined: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SpSectionHeader(
                title: l10n.navigationTokens,
                trailing: StatusPill(text: l10n.disabledStatusLabel),
              ),
              SizedBox(height: 8),
              Text(
                l10n.tokensDescription,
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SpSettingsGroup(
          title: l10n.tokenStatusTitle,
          rows: [
            SpSettingsRow(
              l10n.localTokenStoreTitle,
              l10n.emptyStatusLabel,
              interactive: false,
            ),
            SpSettingsRow(
              l10n.pluralKitLiveImportTitle,
              l10n.pasteTokenDuringImportSubtitle,
              onTap: () => onSelect(SpSection.importExport),
            ),
            SpSettingsRow(
              l10n.syncTokensTitle,
              l10n.requiresSyncSetupSubtitle,
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
    final l10n = AppLocalizations.of(context);
    final report = _buildReport(snapshot, l10n);
    final scheme = Theme.of(context).colorScheme;

    return SpPage(
      children: [
        SpCard(
          outlined: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SpSectionHeader(
                title: l10n.navigationUserReport,
                trailing: StatusPill(text: l10n.localStatusLabel),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.userReportDescription,
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.35),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => _copyReport(context, report),
                    icon: const Icon(Icons.copy_rounded),
                    label: Text(l10n.copyReportButton),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        launchExternalUrl(context, _bugReportUri(report)),
                    icon: const Icon(Icons.bug_report_outlined),
                    label: Text(l10n.reportBugButton),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SpCard(
          child: SelectableText(
            report,
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.35),
          ),
        ),
        const SizedBox(height: 12),
        SpSettingsGroup(
          title: l10n.relatedTitle,
          rows: [
            SpSettingsRow(
              l10n.importJobsTitle,
              l10n.importJobsSubtitle,
              onTap: () => onSelect(SpSection.importExport),
            ),
            SpSettingsRow(
              l10n.notificationHistoryTitle,
              l10n.localEventLogSubtitle,
              onTap: () => onSelect(SpSection.notificationHistory),
            ),
          ],
        ),
      ],
    );
  }

  String _buildReport(HomeSnapshot? snapshot, AppLocalizations l10n) {
    final home = snapshot;
    return [
      l10n.localReportHeading,
      l10n.localReportStage,
      l10n.localReportMembers(home?.memberCount ?? 0),
      l10n.localReportGroups(home?.groupCount ?? 0),
      l10n.localReportNotes(home?.noteCount ?? 0),
      l10n.localReportFrontHistory(home?.frontHistoryCount ?? 0),
      l10n.localReportStorage,
      l10n.localReportSync,
    ].join('\n');
  }

  Uri _bugReportUri(String report) {
    return Uri.https('github.com', '/EndofTimeWorks/pluris-haven/issues/new', {
      'template': 'bug_report.yml',
      'labels': 'bug',
      'logs': report,
    });
  }

  Future<void> _copyReport(BuildContext context, String report) async {
    await Clipboard.setData(ClipboardData(text: report));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).reportCopiedMessage),
        ),
      );
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
    final l10n = AppLocalizations.of(context);
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
                semanticLabel: l10n.systemAvatarFor(
                  home?.systemName ?? l10n.localSystemFallback,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      home?.systemName ?? l10n.localSystemFallback,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      home?.systemDescription?.trim().isNotEmpty == true
                          ? home!.systemDescription!.trim()
                          : l10n.savedOnDeviceSubtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.editSystemProfileTooltip,
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
          title: l10n.accountFallback,
          rows: [
            SpSettingsRow(
              l10n.navigationImportExport,
              l10n.moveDataSubtitle,
              onTap: () => onSelect(SpSection.importExport),
            ),
            SpSettingsRow(
              l10n.navigationAppOptions,
              l10n.appOptionsSubtitle,
              onTap: () => onSelect(SpSection.appOptions),
            ),
            SpSettingsRow(
              l10n.navigationSync,
              l10n.offByDefaultSubtitle,
              onTap: () => onSelect(SpSection.sync),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SpSettingsGroup(
          title: l10n.securityRowTitle,
          rows: [
            SpSettingsRow(
              l10n.storageLabel,
              l10n.deviceDatabaseSubtitle,
              interactive: false,
            ),
            SpSettingsRow(
              l10n.memberNameEncryptionTitle,
              l10n.secureStorageKeySubtitle,
              interactive: false,
            ),
            SpSettingsRow(
              l10n.destructiveActionsTitle,
              l10n.confirmedWithDialogsSubtitle,
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
    backgroundColor: Theme.of(context).colorScheme.surface,
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
    final l10n = AppLocalizations.of(context);
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
            Text(
              l10n.systemProfileTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
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
                semanticLabel: l10n.systemAvatarFor(
                  _nameController.text.trim().isEmpty
                      ? l10n.localSystemFallback
                      : _nameController.text.trim(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: _pickAvatar,
                  icon: const Icon(Icons.image_outlined),
                  label: Text(l10n.chooseImageButton),
                ),
                if (_avatarUrl != null)
                  TextButton.icon(
                    onPressed: () => setState(() => _avatarUrl = null),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(l10n.removeButton),
                  ),
              ],
            ),
            TextField(
              key: const ValueKey('system-name-field'),
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.systemNameFieldLabel),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: l10n.descriptionFieldLabel,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('system-color-field'),
              controller: _colorController,
              autocorrect: false,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: l10n.colorHexFieldLabel,
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
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              key: const ValueKey('save-system-profile-button'),
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(_saving ? l10n.savingStatus : l10n.saveButtonLabel),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final l10n = AppLocalizations.of(context);
    try {
      final result = await NativeFileDialog.pickFiles(
        type: NativeFileType.image,
        allowMultiple: false,
        dialogTitle: l10n.chooseSystemAvatarTitle,
        maximumBytes: maximumAvatarBytes,
      );
      final file = result?.files.firstOrNull;
      if (file == null) return;
      final bytes = await _readManualAvatarFile(file);
      final ref = await _storeManualAvatar(file.name, bytes);
      if (mounted) setState(() => _avatarUrl = ref);
    } on Object catch (error) {
      if (mounted) {
        setState(
          () => _error =
              _manualAvatarValidationMessage(l10n, error) ??
              l10n.couldNotSaveImage(error.toString()),
        );
      }
    }
  }

  Future<void> _save() async {
    final color = _colorController.text.trim();
    if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(color)) {
      setState(() => _error = AppLocalizations.of(context).hexDigitsErrorText);
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
