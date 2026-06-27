part of 'home_page.dart';

class ImportExportPage extends StatefulWidget {
  const ImportExportPage({super.key, required this.repository});

  final HavenRepository repository;

  @override
  State<ImportExportPage> createState() => _ImportExportPageState();
}

class _ImportExportPageState extends State<ImportExportPage> {
  ImportSource _source = ImportSource.simplyPlural;
  ImportConflictStrategy _strategy = ImportConflictStrategy.skip;
  String? _fileName;
  int? _fileSize;
  String? _fileText;
  List<ImportAvatarAsset> _fileAvatarAssets = const [];
  ImportFileGuess? _guess;
  ImportPreview? _preview;
  bool _isPickingImport = false;
  bool _isApplyingImport = false;
  String? _importStatus;

  ImportSourcePlan get _plan => importPlanFor(_source);

  @override
  Widget build(BuildContext context) {
    final plan = _plan;

    return SpPage(
      children: [
        const SpCard(
          outlined: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SpSectionHeader(
                title: 'Import',
                trailing: StatusPill(text: 'preview first'),
              ),
              SizedBox(height: 8),
              Text(
                'Upload an export, check what was found, then import it into local storage.',
                style: TextStyle(color: _spMuted, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ImportSetupCard(
          source: _source,
          strategy: _strategy,
          fileName: _fileName,
          fileSize: _fileSize,
          guess: _guess,
          preview: _preview,
          plan: plan,
          onPickFile: _pickImportFile,
          onPasteJson: _pasteImportJson,
          onPreview: _refreshImportPreview,
          onSourceChanged: _selectImportSource,
          onStrategyChanged: (strategy) => setState(() => _strategy = strategy),
          canPreview: _fileText != null,
        ),
        if (_importStatus != null || _isPickingImport || _isApplyingImport) ...[
          const SizedBox(height: 12),
          ImportProgressCard(
            status: _importStatus,
            isActive: _isPickingImport || _isApplyingImport,
          ),
        ],
        const SizedBox(height: 12),
        ImportPlanCard(plan: plan),
        if (_preview != null) ...[
          const SizedBox(height: 12),
          ImportPreviewCard(
            preview: _preview!,
            onApply: _isApplyingImport ? null : _applyImportFile,
            isImporting: _isApplyingImport,
          ),
        ],
        const SizedBox(height: 12),
        ImportJobsCard(repository: widget.repository),
        const SizedBox(height: 2),
        SpSettingsGroup(
          title: 'Export',
          rows: [
            SpSettingsRow(
              'Export local archive',
              'portable JSON',
              onTap: () => showLocalArchiveSheet(context, widget.repository),
            ),
            const SpSettingsRow('Encrypted export', 'password protected'),
            const SpSettingsRow('Backup folder', 'choose later'),
          ],
        ),
      ],
    );
  }

  Future<void> _pickImportFile() async {
    setState(() {
      _isPickingImport = true;
      _importStatus = 'Waiting for file picker...';
    });
    final result = await FilePicker.pickFiles(
      dialogTitle: 'Choose import file',
      type: FileType.custom,
      allowedExtensions: ['json', 'zip', 'prism', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty || !mounted) {
      if (mounted) {
        setState(() {
          _isPickingImport = false;
          _importStatus = 'No file selected.';
        });
      }
      return;
    }

    final file = result.files.single;
    setState(() {
      _importStatus = 'Reading ${file.name}...';
    });
    final bytes = await _pickedFileBytes(file);
    final decoded = decodeImportFileBytes(fileName: file.name, bytes: bytes);
    _setImportText(
      displayName: decoded?.displayName ?? file.name,
      fileSize: file.size,
      text: decoded?.text,
      avatarAssets: decoded?.avatarAssets ?? const [],
      unreadableStatus: 'Could not read an import JSON from ${file.name}.',
    );
  }

  Future<void> _pasteImportJson() async {
    final pasted = await showPasteImportJsonSheet(context);
    if (pasted == null || !mounted) {
      return;
    }

    _setImportText(
      displayName: 'pasted-import.json',
      fileSize: utf8.encode(pasted).length,
      text: pasted,
      avatarAssets: const [],
      unreadableStatus: 'Could not read the pasted JSON.',
    );
  }

  void _setImportText({
    required String displayName,
    required int? fileSize,
    required String? text,
    required List<ImportAvatarAsset> avatarAssets,
    required String unreadableStatus,
  }) {
    final guess = guessImportSourceFromFile(
      fileName: displayName,
      textPreview: text,
    );
    final preview = text == null
        ? null
        : previewImportText(
            fileName: displayName,
            text: text,
            selectedSource: guess.source ?? _source,
            avatarAssets: avatarAssets,
          );

    setState(() {
      _fileName = displayName;
      _fileSize = fileSize;
      _fileText = text;
      _fileAvatarAssets = avatarAssets;
      _guess = guess;
      _preview = preview;
      if (guess.source != null) {
        _source = guess.source!;
      }
      _isPickingImport = false;
      _importStatus = preview == null
          ? unreadableStatus
          : 'Preview ready: ${_countSummary(preview.counts)}.';
    });
  }

  void _selectImportSource(ImportSource source) {
    final fileName = _fileName;
    final text = _fileText;

    final preview = fileName == null || text == null
        ? null
        : previewImportText(
            fileName: fileName,
            text: text,
            selectedSource: source,
            avatarAssets: _fileAvatarAssets,
          );

    setState(() {
      _source = source;
      _preview = preview;
      _importStatus = preview == null
          ? _importStatus
          : 'Preview ready: ${_countSummary(preview.counts)}.';
    });
    if (preview != null) {
      appDebugLog(
        'Import preview source=${preview.source.name} file=${preview.fileName} '
        'canApply=${preview.canApply} counts=${preview.counts} '
        'events=${preview.events.length} warnings=${preview.warningsAndErrors.length}',
      );
    }
  }

  Future<Uint8List?> _pickedFileBytes(PlatformFile file) async {
    final bytes = file.bytes;
    if (bytes != null && bytes.isNotEmpty) {
      return bytes;
    }
    final path = file.path;
    if (path == null || path.trim().isEmpty) {
      return bytes;
    }
    try {
      return await File(path).readAsBytes();
    } on Object catch (error) {
      appDebugLog('Import file read failed path=$path error=$error');
      return bytes;
    }
  }

  void _refreshImportPreview() {
    final fileName = _fileName;
    final text = _fileText;
    if (fileName == null || text == null) {
      setState(() {
        _importStatus = 'Choose or paste a file before previewing.';
      });
      return;
    }
    final preview = previewImportText(
      fileName: fileName,
      text: text,
      selectedSource: _source,
      avatarAssets: _fileAvatarAssets,
    );
    setState(() {
      _preview = preview;
      _importStatus = 'Preview ready: ${_countSummary(preview.counts)}.';
    });
    appDebugLog(
      'Import preview refreshed source=${preview.source.name} file=$fileName '
      'canApply=${preview.canApply} counts=${preview.counts} '
      'events=${preview.events.length} warnings=${preview.warningsAndErrors.length}',
    );
  }

  Future<void> _applyImportFile() async {
    final text = _fileText;
    if (text == null) {
      return;
    }

    setState(() {
      _isApplyingImport = true;
      _importStatus = 'Preparing ${_source.label} import...';
    });

    var importCompleted = false;
    try {
      final normalized = normalizeImportTextToLocalArchive(
        source: _source,
        fileName: _fileName ?? 'import.json',
        text: text,
        avatarAssets: _fileAvatarAssets,
      );
      appDebugLog(
        'Apply import source=${_source.name} file=${_fileName ?? 'import.json'} '
        'counts=${normalized.counts} warnings=${normalized.warnings.length}',
      );

      if (mounted) {
        setState(() {
          _importStatus = 'Writing ${_countSummary(normalized.counts)}...';
        });
      }

      final jobId = await widget.repository.enqueueImportArchiveJob(
        normalized.archiveJson,
        strategy: _strategy,
        fileName: _fileName,
        source: _source,
      );
      appDebugLog('Import job queued id=$jobId source=${_source.name}');

      if (mounted) {
        setState(() {
          _importStatus = 'Importing ${_countSummary(normalized.counts)}...';
        });
      }

      importCompleted = await widget.repository.runBackgroundJob(jobId);
      appDebugLog('Import job finished id=$jobId success=$importCompleted');
      if (mounted) {
        setState(() {
          _isApplyingImport = false;
          _importStatus = importCompleted
              ? 'Import complete: ${_countSummary(normalized.counts)}.'
              : 'Import failed. Check recent jobs below.';
        });
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _isApplyingImport = false;
          _importStatus = 'Import failed: $error';
        });
      }
      return;
    }

    if (mounted && importCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_source.label} import complete')),
      );
    }
  }

  String _countSummary(Map<String, int> counts) {
    final visible = counts.entries
        .where((entry) => entry.value > 0)
        .map((entry) => '${entry.value} ${entry.key}')
        .join(', ');

    return visible.isEmpty ? 'no records found' : visible;
  }
}

void showLocalArchiveSheet(BuildContext context, HavenRepository repository) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: _spSurface,
    builder: (context) => LocalArchiveSheet(repository: repository),
  );
}

class LocalArchiveSheet extends StatelessWidget {
  const LocalArchiveSheet({super.key, required this.repository});

  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<String>(
        future: repository.buildLocalArchiveJson(),
        builder: (context, snapshot) {
          final archive = snapshot.data;

          return SingleChildScrollView(
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
                  'Local archive',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'JSON export for backup or migration. It includes local members, groups, notes, fronts, and app preferences.',
                  style: TextStyle(color: _spMuted, height: 1.35),
                ),
                const SizedBox(height: 14),
                if (snapshot.connectionState != ConnectionState.done)
                  const Center(child: CircularProgressIndicator())
                else if (snapshot.hasError)
                  Text(
                    'Could not build archive: ${snapshot.error}',
                    style: const TextStyle(color: _spMuted),
                  )
                else ...[
                  FilledButton.icon(
                    key: const ValueKey('copy-local-archive-button'),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: archive!));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Archive copied')),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy JSON'),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 320),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _spSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _spLine),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        archive!,
                        style: const TextStyle(
                          color: _spMuted,
                          fontFamily: 'monospace',
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

Future<String?> showPasteImportJsonSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: _spSurface,
    builder: (context) => const PasteImportJsonSheet(),
  );
}

class PasteImportJsonSheet extends StatefulWidget {
  const PasteImportJsonSheet({super.key});

  @override
  State<PasteImportJsonSheet> createState() => _PasteImportJsonSheetState();
}

class _PasteImportJsonSheetState extends State<PasteImportJsonSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
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
              'Paste JSON',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('paste-import-json-field'),
              controller: _controller,
              autofocus: true,
              minLines: 8,
              maxLines: 14,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: const InputDecoration(
                hintText: '{"members": [...]}',
                labelText: 'Export JSON',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                final text = _controller.text.trim();
                Navigator.pop(context, text.isEmpty ? null : text);
              },
              icon: const Icon(Icons.fact_check_rounded),
              label: const Text('Preview pasted JSON'),
            ),
          ],
        ),
      ),
    );
  }
}

class ImportSetupCard extends StatelessWidget {
  const ImportSetupCard({
    super.key,
    required this.source,
    required this.strategy,
    required this.fileName,
    required this.fileSize,
    required this.guess,
    required this.preview,
    required this.plan,
    required this.onPickFile,
    required this.onPasteJson,
    required this.onPreview,
    required this.onSourceChanged,
    required this.onStrategyChanged,
    required this.canPreview,
  });

  final ImportSource source;
  final ImportConflictStrategy strategy;
  final String? fileName;
  final int? fileSize;
  final ImportFileGuess? guess;
  final ImportPreview? preview;
  final ImportSourcePlan plan;
  final bool canPreview;
  final VoidCallback onPickFile;
  final VoidCallback onPasteJson;
  final VoidCallback onPreview;
  final ValueChanged<ImportSource> onSourceChanged;
  final ValueChanged<ImportConflictStrategy> onStrategyChanged;

  @override
  Widget build(BuildContext context) {
    return SpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SpSectionHeader(
            title: 'Import setup',
            trailing: StatusPill(text: plan.status.label),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey('choose-import-file-button'),
                  onPressed: onPickFile,
                  icon: const Icon(Icons.upload_file_rounded),
                  label: Text(
                    fileName == null ? 'Upload file' : 'Choose another file',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                key: const ValueKey('paste-import-json-button'),
                tooltip: 'Paste JSON',
                onPressed: onPasteJson,
                icon: const Icon(Icons.content_paste_rounded),
              ),
            ],
          ),
          if (fileName != null) ...[
            const SizedBox(height: 10),
            ImportFileSummary(
              fileName: fileName!,
              fileSize: fileSize,
              guess: guess,
            ),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<ImportSource>(
            key: const ValueKey('import-source-dropdown'),
            initialValue: source,
            decoration: const InputDecoration(labelText: 'Service'),
            items: [
              for (final source in ImportSource.values)
                DropdownMenuItem(value: source, child: Text(source.label)),
            ],
            onChanged: (source) {
              if (source != null) {
                onSourceChanged(source);
              }
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<ImportConflictStrategy>(
            initialValue: strategy,
            decoration: const InputDecoration(labelText: 'When a match exists'),
            items: [
              for (final strategy in ImportConflictStrategy.values)
                DropdownMenuItem(value: strategy, child: Text(strategy.label)),
            ],
            onChanged: (strategy) {
              if (strategy != null) {
                onStrategyChanged(strategy);
              }
            },
          ),
          if (plan.requiresToken) ...[
            const SizedBox(height: 10),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'pk;token',
                helperText: 'Used for live import; not exported.',
              ),
            ),
          ],
          if (plan.requiresPassphrase) ...[
            const SizedBox(height: 10),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Passphrase',
                helperText: 'Used locally to decrypt the preview.',
              ),
            ),
          ],
          const SizedBox(height: 12),
          ImportMetaRow(label: 'Input', value: source.inputLabel),
          const SizedBox(height: 8),
          ImportMetaRow(label: 'Job', value: source.jobSource),
          const SizedBox(height: 8),
          ImportMetaRow(label: 'Dedupe', value: source.dedupeLabel),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: canPreview ? onPreview : null,
            icon: const Icon(Icons.fact_check_rounded),
            label: Text(preview == null ? 'Preview import' : 'Refresh preview'),
          ),
        ],
      ),
    );
  }
}

class ImportFileSummary extends StatelessWidget {
  const ImportFileSummary({
    super.key,
    required this.fileName,
    required this.fileSize,
    required this.guess,
  });

  final String fileName;
  final int? fileSize;
  final ImportFileGuess? guess;

  @override
  Widget build(BuildContext context) {
    final detected = guess?.source;
    final label = detected == null
        ? 'Choose service'
        : '${detected.label} detected';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _spSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _spLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(fileName, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            [
              if (fileSize != null) _formatBytes(fileSize!),
              guess?.reason ?? 'waiting for detection',
            ].join(' - '),
            style: const TextStyle(color: _spMuted, fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 8),
          StatusPill(text: label),
        ],
      ),
    );
  }
}

class ImportPreviewCard extends StatelessWidget {
  const ImportPreviewCard({
    super.key,
    required this.preview,
    this.onApply,
    this.isImporting = false,
  });

  final ImportPreview preview;
  final Future<void> Function()? onApply;
  final bool isImporting;

  @override
  Widget build(BuildContext context) {
    final notableEvents = preview.warningsAndErrors;

    return SpCard(
      outlined: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SpSectionHeader(
            title: 'Preview',
            trailing: StatusPill(
              text: preview.canApply ? 'valid shape' : 'needs attention',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${preview.source.label} - ${preview.fileName}',
            style: const TextStyle(color: _spMuted, height: 1.35),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in preview.counts.entries)
                if (entry.value > 0)
                  StatusPill(text: '${entry.key}: ${entry.value}'),
              if (!preview.counts.values.any((count) => count > 0))
                const StatusPill(text: 'no records found'),
            ],
          ),
          if (notableEvents.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (final event in notableEvents) ...[
              Text(
                '${event.stage}: ${event.message}',
                style: TextStyle(
                  color: event.severity == ImportPreviewSeverity.error
                      ? Theme.of(context).colorScheme.error
                      : _spMuted,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 6),
            ],
          ],
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: preview.canApply && onApply != null
                ? () async => onApply!()
                : null,
            icon: isImporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.restore_rounded),
            label: Text(isImporting ? 'Importing...' : 'Import archive'),
          ),
        ],
      ),
    );
  }
}

class ImportProgressCard extends StatelessWidget {
  const ImportProgressCard({
    super.key,
    required this.status,
    required this.isActive,
  });

  final String? status;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = status?.toLowerCase() ?? '';
    final isQueued = normalizedStatus.contains('queued');

    return SpCard(
      outlined: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isActive)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  isQueued
                      ? Icons.schedule_rounded
                      : Icons.check_circle_rounded,
                  size: 18,
                  color: _spGold,
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  status ?? 'Import ready.',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (isActive) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }
}

class ImportJobsCard extends StatelessWidget {
  const ImportJobsCard({super.key, required this.repository});

  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BackgroundJobSummary>>(
      stream: repository.watchBackgroundJobs(),
      initialData: const [],
      builder: (context, snapshot) {
        final jobs = snapshot.data ?? const <BackgroundJobSummary>[];
        return SpCard(
          outlined: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SpSectionHeader(
                title: 'Recent jobs',
                trailing: StatusPill(
                  text: jobs.isEmpty ? 'none' : '${jobs.length}',
                ),
              ),
              const SizedBox(height: 8),
              if (jobs.isEmpty)
                const Text(
                  'No imports queued yet.',
                  style: TextStyle(color: _spMuted),
                )
              else
                for (final job in jobs) ...[
                  ImportJobRow(job: job),
                  if (job != jobs.last)
                    const Divider(height: 1, color: _spLine),
                ],
            ],
          ),
        );
      },
    );
  }
}

class ImportJobRow extends StatelessWidget {
  const ImportJobRow({super.key, required this.job});

  final BackgroundJobSummary job;

  @override
  Widget build(BuildContext context) {
    final title = job.fileName ?? job.type;
    final subtitle = job.error == null
        ? '${job.status} - ${_shortDateTime(job.updatedAt)}'
        : '${_oneLineJobError(job.error!)} - tap for details';

    return Semantics(
      button: true,
      label: 'Import job $title, ${job.status}. Double tap for details.',
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          onTap: () => _showJobDetails(context),
          leading: Icon(_icon, color: _color, size: 20),
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _spMuted),
          ),
          trailing: StatusPill(text: job.status),
        ),
      ),
    );
  }

  void _showJobDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: _spCard,
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            bottom: 18 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(_icon, color: _color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        job.fileName ?? job.type,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    StatusPill(text: job.status),
                  ],
                ),
                const SizedBox(height: 16),
                _JobDetailLine(label: 'Type', value: job.type),
                if (job.source != null)
                  _JobDetailLine(label: 'Source', value: job.source!),
                _JobDetailLine(
                  label: 'Created',
                  value: _shortDateTime(job.createdAt),
                ),
                _JobDetailLine(
                  label: 'Updated',
                  value: _shortDateTime(job.updatedAt),
                ),
                if (job.error != null && job.error!.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _JobErrorPreview(error: job.error!),
                ] else ...[
                  const SizedBox(height: 16),
                  const Text(
                    'No error recorded for this job.',
                    style: TextStyle(color: _spMuted),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData get _icon {
    return switch (job.status) {
      'done' => Icons.check_circle_rounded,
      'failed' => Icons.error_rounded,
      'running' => Icons.sync_rounded,
      _ => Icons.schedule_rounded,
    };
  }

  Color get _color {
    return switch (job.status) {
      'done' => _spGold,
      'failed' => const Color(0xFFFFB4AB),
      'running' => _spPurple,
      _ => _spMuted,
    };
  }
}

class _JobErrorPreview extends StatelessWidget {
  const _JobErrorPreview({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    final preview = _boundedJobError(error);
    final isTruncated = preview.length < error.trim().length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Error',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: error.trim()));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Full error copied')),
                );
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy full'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (isTruncated) ...[
          const Text(
            'Showing a safe preview. The full error is too large to render here.',
            style: TextStyle(color: _spMuted),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _spSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _spLine),
          ),
          child: SelectableText(
            preview,
            style: const TextStyle(color: _spMuted, height: 1.35),
          ),
        ),
      ],
    );
  }
}

String _boundedJobError(String error) {
  final trimmed = error.trim();
  const maxLength = 4000;
  if (trimmed.length <= maxLength) {
    return trimmed;
  }
  return '${trimmed.substring(0, maxLength)}\n\n'
      '...truncated ${trimmed.length - maxLength} chars';
}

String _oneLineJobError(String error) {
  final oneLine = error.trim().replaceAll(RegExp(r'\s+'), ' ');
  const maxLength = 96;
  if (oneLine.length <= maxLength) {
    return oneLine;
  }
  return '${oneLine.substring(0, maxLength)}...';
}

class _JobDetailLine extends StatelessWidget {
  const _JobDetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: const TextStyle(
                color: _spMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class ImportPlanCard extends StatelessWidget {
  const ImportPlanCard({super.key, required this.plan});

  final ImportSourcePlan plan;

  @override
  Widget build(BuildContext context) {
    return SpCard(
      outlined: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SpSectionHeader(
            title: '${plan.source.label} plan',
            trailing: StatusPill(
              text: plan.canPreviewOffline
                  ? 'offline preview'
                  : 'needs network',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final count in plan.previewCounts)
                StatusPill(text: count.label),
            ],
          ),
          const SizedBox(height: 14),
          for (final step in plan.steps) ...[
            Text(
              step.title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 3),
            Text(
              step.detail,
              style: const TextStyle(
                color: _spMuted,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
          ],
          const Divider(height: 18),
          for (final note in plan.privacyNotes) ...[
            Text(
              note,
              style: const TextStyle(
                color: _spMuted,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class ImportMetaRow extends StatelessWidget {
  const ImportMetaRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: const TextStyle(
              color: _spMuted,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
