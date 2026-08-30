part of 'home_page.dart';

const _maximumPastedImportCharacters = 256 * 1024;
const _maximumClipboardArchiveBytes = 512 * 1024;

String _withoutRawImportPayloads(String archiveJson) {
  final decoded = jsonDecode(archiveJson);
  if (decoded is! Map<String, Object?>) return archiveJson;
  return jsonEncode({...decoded, 'raw_payloads': const <Object?>[]});
}

class ImportExportPage extends StatefulWidget {
  const ImportExportPage({super.key, required this.repository});

  final HavenRepository repository;

  @override
  State<ImportExportPage> createState() => _ImportExportPageState();
}

class _ImportExportPageState extends State<ImportExportPage> {
  ImportSource _source = ImportSource.simplyPlural;
  ImportConflictStrategy _strategy = ImportConflictStrategy.prompt;
  String? _fileName;
  int? _fileSize;
  String? _fileText;
  List<ImportAvatarAsset> _fileAvatarAssets = const [];
  String _importPassphrase = '';
  String _pluralKitToken = '';
  ImportFileGuess? _guess;
  ImportPreview? _preview;
  RestoreRehearsalSummary? _restoreRehearsal;
  bool _isPickingImport = false;
  bool _isApplyingImport = false;
  bool _isRehearsingRestore = false;
  bool _retainRawPayloads = false;
  String? _importStatus;
  bool _canReportImportIssue = false;
  int _previewGeneration = 0;

  ImportSourcePlan get _plan => importPlanFor(_source);

  bool get _needsImportPassphrase =>
      (_fileText != null && archiveTextLooksEncrypted(_fileText!)) ||
      _plan.requiresPassphrase;

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
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
                title: l10n.importTitle,
                trailing: StatusPill(text: l10n.previewFirstStatus),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.importDescription,
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.35),
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
          needsPassphrase: _needsImportPassphrase,
          onPickFile: _pickImportFile,
          onPickAvatars: _pickAvatarBundle,
          onPasteJson: _pasteImportJson,
          onPreview: _refreshImportPreview,
          onPassphraseChanged: (value) {
            _importPassphrase = value;
          },
          onTokenChanged: (value) => _pluralKitToken = value,
          onSourceChanged: _selectImportSource,
          onStrategyChanged: (strategy) => setState(() => _strategy = strategy),
          canPreview:
              _fileText != null ||
              (_source == ImportSource.pluralKitLive &&
                  _pluralKitToken.trim().isNotEmpty),
          avatarAssetCount: _fileAvatarAssets.length,
          retainRawPayloads: _retainRawPayloads,
          onRetainRawPayloadsChanged: (value) {
            setState(() => _retainRawPayloads = value);
          },
        ),
        if (_importStatus != null || _isPickingImport || _isApplyingImport) ...[
          const SizedBox(height: 12),
          ImportProgressCard(
            status: _importStatus,
            isActive: _isPickingImport || _isApplyingImport,
            onCopyDetails: _importStatus == null
                ? null
                : () => _copyImportDetails(_importStatus!),
            onReportIssue: _canReportImportIssue
                ? () => launchExternalUrl(context, _importIssueUri)
                : null,
          ),
        ],
        const SizedBox(height: 12),
        ImportPlanCard(plan: plan),
        if (_preview != null) ...[
          const SizedBox(height: 12),
          ImportPreviewCard(
            preview: _preview!,
            onApply: _isApplyingImport ? null : _applyImportFile,
            onRehearse: _isRehearsingRestore ? null : _runRestoreRehearsal,
            isImporting: _isApplyingImport,
            isRehearsing: _isRehearsingRestore,
            rehearsal: _restoreRehearsal,
            onCopyDetails: () => _copyPreviewDetails(_preview!),
          ),
        ],
        const SizedBox(height: 12),
        ImportJobsCard(repository: widget.repository),
        const SizedBox(height: 12),
        RetainedImportPayloadsCard(repository: widget.repository),
        const SizedBox(height: 2),
        SpSettingsGroup(
          title: l10n.exportTitle,
          rows: [
            SpSettingsRow(
              l10n.exportLocalArchiveTitle,
              l10n.portableJsonValue,
              onTap: () => showLocalArchiveSheet(context, widget.repository),
            ),
            SpSettingsRow(
              l10n.encryptedExportTitle,
              l10n.passwordProtectedFileValue,
              onTap: () =>
                  showEncryptedArchiveSheet(context, widget.repository),
            ),
            SpSettingsRow(
              l10n.backupFolderTitle,
              l10n.manualArchiveSaveValue,
              onTap: () => showLocalArchiveSheet(context, widget.repository),
            ),
          ],
        ),
      ],
    );
  }

  Future<({NativeFileResult? result, bool usedOverride})>
  _pickFilesAllowingSizeOverride({
    required String dialogTitle,
    required List<String> allowedExtensions,
  }) async {
    try {
      final result = await NativeFileDialog.pickFiles(
        dialogTitle: dialogTitle,
        type: NativeFileType.custom,
        allowedExtensions: allowedExtensions,
      );
      return (result: result, usedOverride: false);
    } on NativePickedFileTooLargeException {
      if (!mounted) rethrow;
      final proceed = await _confirmOversizedFileImport();
      if (!mounted || !proceed) rethrow;
      final result = await NativeFileDialog.pickFiles(
        dialogTitle: dialogTitle,
        type: NativeFileType.custom,
        allowedExtensions: allowedExtensions,
        maximumBytes: maximumOverriddenPickedFileBytes,
      );
      return (result: result, usedOverride: true);
    }
  }

  Future<bool> _confirmOversizedFileImport() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.oversizedImportWarningTitle),
        content: Text(l10n.oversizedImportWarningBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.oversizedImportConfirmButton),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _pickImportFile() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _isPickingImport = true;
      _importStatus = l10n.waitingForFilePicker;
      _canReportImportIssue = false;
    });
    NativeFileResult? result;
    bool usedOverride;
    try {
      final picked = await _pickFilesAllowingSizeOverride(
        dialogTitle: l10n.chooseImportFileTitle,
        allowedExtensions: ['json', 'zip', 'prism', 'txt'],
      );
      result = picked.result;
      usedOverride = picked.usedOverride;
    } on NativePickedFileTooLargeException {
      if (mounted) {
        setState(() {
          _isPickingImport = false;
          _importStatus = l10n.importFileTooLarge;
          _canReportImportIssue = true;
        });
      }
      return;
    } on Object {
      if (mounted) {
        setState(() {
          _isPickingImport = false;
          _importStatus = l10n.couldNotOpenFilePicker;
        });
      }
      return;
    }
    if (result == null || result.files.isEmpty || !mounted) {
      if (mounted) {
        setState(() {
          _isPickingImport = false;
          _importStatus = l10n.noFileSelected;
        });
      }
      return;
    }

    final file = result.files.single;
    final maximumBytes = usedOverride
        ? maximumOverriddenPickedFileBytes
        : maximumNativePickedFileBytes;
    setState(() {
      _importStatus = l10n.readingFileStatus(file.name);
    });
    DecodedImportFile decoded;
    try {
      final bytes = await _pickedFileBytes(file, maximumBytes: maximumBytes);
      if (!mounted) return;
      decoded = await decodeImportFileBytes(
        fileName: file.name,
        bytes: bytes,
        maximumBytes: maximumBytes,
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _isPickingImport = false;
        _importStatus = _importReadError(l10n, error, file.name);
        _canReportImportIssue = _isReportableImportFailure(error);
      });
      return;
    }
    await _setImportText(
      displayName: decoded.displayName,
      fileSize: file.size,
      text: decoded.text,
      avatarAssets: decoded.avatarAssets,
      unreadableStatus: l10n.couldNotReadImportFile(file.name),
    );
  }

  Future<void> _pasteImportJson() async {
    final l10n = AppLocalizations.of(context);
    final pasted = await showPasteImportJsonSheet(context);
    if (pasted == null || !mounted) {
      return;
    }

    await _setImportText(
      displayName: 'pasted-import.json',
      fileSize: utf8.encode(pasted).length,
      text: pasted,
      avatarAssets: const [],
      unreadableStatus: l10n.couldNotReadPastedJson,
    );
  }

  Future<void> _pickAvatarBundle() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _isPickingImport = true;
      _importStatus = l10n.waitingForAvatarZip;
      _canReportImportIssue = false;
    });
    NativeFileResult? result;
    bool usedOverride;
    try {
      final picked = await _pickFilesAllowingSizeOverride(
        dialogTitle: l10n.chooseAvatarZipTitle,
        allowedExtensions: ['zip'],
      );
      result = picked.result;
      usedOverride = picked.usedOverride;
    } on NativePickedFileTooLargeException {
      if (mounted) {
        setState(() {
          _isPickingImport = false;
          _importStatus = l10n.importFileTooLarge;
          _canReportImportIssue = true;
        });
      }
      return;
    } on Object {
      if (mounted) {
        setState(() {
          _isPickingImport = false;
          _importStatus = l10n.couldNotOpenFilePicker;
        });
      }
      return;
    }
    if (result == null || result.files.isEmpty || !mounted) {
      if (mounted) {
        setState(() {
          _isPickingImport = false;
          _importStatus = l10n.noAvatarFileSelected;
        });
      }
      return;
    }

    final file = result.files.single;
    final maximumBytes = usedOverride
        ? maximumOverriddenPickedFileBytes
        : maximumNativePickedFileBytes;
    setState(() {
      _importStatus = l10n.readingAvatarsStatus(file.name);
    });
    DecodedImportFile decoded;
    try {
      final bytes = await _pickedFileBytes(file, maximumBytes: maximumBytes);
      if (!mounted) return;
      decoded = await decodeImportFileBytes(
        fileName: file.name,
        bytes: bytes,
        maximumBytes: maximumBytes,
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _isPickingImport = false;
        _importStatus = _importReadError(l10n, error, file.name);
        _canReportImportIssue = _isReportableImportFailure(error);
      });
      return;
    }
    final avatars = decoded.avatarAssets;
    if (avatars.isEmpty) {
      setState(() {
        _isPickingImport = false;
        _importStatus = l10n.noAvatarsFoundStatus(file.name);
      });
      return;
    }

    final mergedAvatars = _mergeAvatarAssets(_fileAvatarAssets, avatars);
    final generation = ++_previewGeneration;
    final preview = _fileName == null || _fileText == null
        ? null
        : await previewImportTextInBackground(
            fileName: _fileName!,
            text: _fileText!,
            selectedSource: _source,
            avatarAssets: mergedAvatars,
          );

    if (!mounted || generation != _previewGeneration) return;

    setState(() {
      _fileAvatarAssets = mergedAvatars;
      _preview = preview;
      _isPickingImport = false;
      _importStatus = l10n.avatarsAttachedStatus(
        avatars.length,
        file.name,
        _fileText == null ? l10n.chooseJsonNext : l10n.refreshOrImportNext,
      );
    });
    appDebugLog(
      'Attached avatar bundle file=${file.name} added=${avatars.length} '
      'total=${mergedAvatars.length}',
    );
  }

  Future<void> _setImportText({
    required String displayName,
    required int? fileSize,
    required String? text,
    required List<ImportAvatarAsset> avatarAssets,
    required String unreadableStatus,
  }) async {
    final l10n = AppLocalizations.of(context);
    final guess = guessImportSourceFromFile(
      fileName: displayName,
      textPreview: text,
    );
    final isEncrypted = text != null && archiveTextLooksEncrypted(text);
    final generation = ++_previewGeneration;
    setState(() {
      _isPickingImport = true;
      _importStatus = l10n.preparingImportPreviewStatus;
    });
    final preview = text == null
        ? null
        : isEncrypted
        ? _encryptedArchiveLockedPreview(displayName)
        : await previewImportTextInBackground(
            fileName: displayName,
            text: text,
            selectedSource: guess.source ?? _source,
            avatarAssets: avatarAssets,
          );

    if (!mounted || generation != _previewGeneration) return;

    setState(() {
      _fileName = displayName;
      _fileSize = fileSize;
      _fileText = text;
      _fileAvatarAssets = avatarAssets;
      _importPassphrase = '';
      _guess = guess;
      _preview = preview;
      _restoreRehearsal = null;
      _canReportImportIssue = false;
      if (isEncrypted) {
        _source = ImportSource.plurisHavenArchive;
      } else if (guess.source != null) {
        _source = guess.source!;
      }
      _isPickingImport = false;
      _importStatus = isEncrypted
          ? l10n.encryptedArchiveLoaded
          : preview == null
          ? unreadableStatus
          : l10n.previewReadyStatus(_countSummary(preview.counts));
    });
  }

  String _importReadError(
    AppLocalizations l10n,
    Object error,
    String fileName,
  ) {
    if (error is! ImportFileDecodeException) {
      return l10n.couldNotReadImportFile(fileName);
    }
    return switch (error.failure) {
      ImportFileDecodeFailure.empty => l10n.importFileEmpty,
      ImportFileDecodeFailure.tooLarge => l10n.importFileTooLarge,
      ImportFileDecodeFailure.invalidUtf8 => l10n.importFileInvalidUtf8,
      ImportFileDecodeFailure.invalidZip => l10n.importFileInvalidZip,
      ImportFileDecodeFailure.tooManyZipEntries => l10n.importZipTooManyEntries,
      ImportFileDecodeFailure.zipExpansionTooLarge =>
        l10n.importZipExpansionTooLarge,
      ImportFileDecodeFailure.unsupportedZip => l10n.importZipUnsupported,
    };
  }

  bool _isReportableImportFailure(Object error) {
    if (error is! ImportFileDecodeException) return false;
    return switch (error.failure) {
      ImportFileDecodeFailure.tooLarge ||
      ImportFileDecodeFailure.tooManyZipEntries ||
      ImportFileDecodeFailure.zipExpansionTooLarge => true,
      _ => false,
    };
  }

  Future<void> _selectImportSource(ImportSource source) async {
    final l10n = AppLocalizations.of(context);
    final fileName = _fileName;
    final text = _fileText;
    final isEncrypted = text != null && archiveTextLooksEncrypted(text);

    final generation = ++_previewGeneration;
    setState(() {
      _source = source;
      _preview = null;
      _restoreRehearsal = null;
      _importStatus = l10n.preparingImportPreviewStatus;
    });
    final preview = fileName == null || text == null
        ? null
        : isEncrypted
        ? _encryptedArchiveLockedPreview(fileName)
        : await previewImportTextInBackground(
            fileName: fileName,
            text: text,
            selectedSource: source,
            avatarAssets: _fileAvatarAssets,
          );

    if (!mounted || generation != _previewGeneration) return;

    setState(() {
      _source = source;
      _preview = preview;
      _restoreRehearsal = null;
      _importStatus = preview == null
          ? _importStatus
          : l10n.previewReadyStatus(_countSummary(preview.counts));
    });
    if (preview != null) {
      appDebugLog(
        'Import preview source=${preview.source.name} file=${preview.fileName} '
        'canApply=${preview.canApply} counts=${preview.counts} '
        'events=${preview.events.length} warnings=${preview.warningsAndErrors.length}',
      );
    }
  }

  Future<Uint8List?> _pickedFileBytes(
    NativePlatformFile file, {
    int maximumBytes = maximumNativePickedFileBytes,
  }) async {
    final path = file.path;
    try {
      if (file.size > maximumBytes) {
        await file.dispose();
        throw FormatException(
          'Selected file exceeds the $maximumBytes byte limit.',
        );
      }
      return await file.readBytes();
    } on Object catch (error) {
      appDebugLog('Import file read failed path=$path error=$error');
      return null;
    }
  }

  Future<void> _refreshImportPreview() async {
    final l10n = AppLocalizations.of(context);
    if (_source == ImportSource.pluralKitLive) {
      await _fetchPluralKitPreview();
      return;
    }
    final fileName = _fileName;
    final text = _fileText;
    if (fileName == null || text == null) {
      setState(() {
        _importStatus = l10n.chooseFileBeforePreview;
      });
      return;
    }
    final generation = ++_previewGeneration;
    setState(() {
      _preview = null;
      _restoreRehearsal = null;
      _importStatus = l10n.preparingImportPreviewStatus;
    });
    try {
      final effectiveText = await _effectiveImportText(text);
      final preview = await previewImportTextInBackground(
        fileName: fileName,
        text: effectiveText,
        selectedSource: _source,
        avatarAssets: _fileAvatarAssets,
      );
      if (!mounted || generation != _previewGeneration) return;
      setState(() {
        _preview = preview;
        _restoreRehearsal = null;
        _importStatus = l10n.previewReadyStatus(_countSummary(preview.counts));
      });
      appDebugLog(
        'Import preview refreshed source=${preview.source.name} file=$fileName '
        'canApply=${preview.canApply} counts=${preview.counts} '
        'events=${preview.events.length} warnings=${preview.warningsAndErrors.length}',
      );
    } on Object catch (error) {
      if (!mounted || generation != _previewGeneration) return;
      setState(() {
        _preview = _encryptedArchiveFailedPreview(fileName, error);
        _restoreRehearsal = null;
        _importStatus = l10n.decryptArchiveFailed;
      });
    }
  }

  Future<void> _fetchPluralKitPreview() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _isPickingImport = true;
      _importStatus = l10n.fetchingPluralKitData;
    });
    try {
      final text = await PluralKitLiveClient().fetchArchiveJson(
        _pluralKitToken,
      );
      if (!mounted) return;
      final generation = ++_previewGeneration;
      final preview = await previewImportTextInBackground(
        fileName: 'pluralkit-live.json',
        text: text,
        selectedSource: ImportSource.pluralKitLive,
      );
      if (!mounted || generation != _previewGeneration) return;
      setState(() {
        _fileName = 'pluralkit-live.json';
        _fileSize = utf8.encode(text).length;
        _fileText = text;
        _fileAvatarAssets = const [];
        _guess = null;
        _preview = preview;
        _restoreRehearsal = null;
        _isPickingImport = false;
        _importStatus = l10n.previewReadyStatus(_countSummary(preview.counts));
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _isPickingImport = false;
        _preview = null;
        _importStatus = error is PluralKitResponseTooLargeException
            ? l10n.pluralKitResponseTooLarge
            : l10n.pluralKitImportFailed(error.toString());
      });
    }
  }

  Future<void> _runRestoreRehearsal() async {
    final l10n = AppLocalizations.of(context);
    final text = _fileText;
    final fileName = _fileName ?? 'import.json';
    if (text == null) {
      setState(() {
        _importStatus = l10n.chooseFileBeforeRehearsal;
      });
      return;
    }

    setState(() {
      _isRehearsingRestore = true;
      _restoreRehearsal = null;
      _importStatus = l10n.rehearsingRestoreStatus;
    });

    try {
      final effectiveText = await _effectiveImportText(text);
      final normalized = await normalizeImportTextToLocalArchiveInBackground(
        source: _source,
        fileName: fileName,
        text: effectiveText,
        avatarAssets: _fileAvatarAssets,
      );
      final archiveJson = _retainRawPayloads
          ? normalized.archiveJson
          : _withoutRawImportPayloads(normalized.archiveJson);
      final summary = await widget.repository.rehearseLocalArchiveRestore(
        archiveJson,
        strategy: _strategy,
        fileName: _fileName,
        source: _source,
      );

      if (!mounted) return;
      setState(() {
        _isRehearsingRestore = false;
        _restoreRehearsal = summary;
        _importStatus = summary.canRestore
            ? l10n.restoreRehearsalPassedStatus(_countSummary(summary.counts))
            : l10n.restoreRehearsalFailedStatus;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _isRehearsingRestore = false;
        _restoreRehearsal = RestoreRehearsalSummary(
          canRestore: false,
          fileName: _fileName,
          counts: const {},
          checkedAt: DateTime.now().toUtc(),
          elapsed: Duration.zero,
          error: error.toString(),
        );
        _importStatus = l10n.restoreRehearsalFailedStatus;
      });
    }
  }

  Future<void> _applyImportFile() async {
    final l10n = AppLocalizations.of(context);
    final text = _fileText;
    if (text == null) {
      return;
    }

    setState(() {
      _isApplyingImport = true;
      _importStatus = l10n.preparingImportStatus(
        localizeImportSource(l10n, _source),
      );
    });

    var importCompleted = false;
    try {
      final effectiveText = await _effectiveImportText(text);
      final normalized = await normalizeImportTextToLocalArchiveInBackground(
        source: _source,
        fileName: _fileName ?? 'import.json',
        text: effectiveText,
        avatarAssets: _fileAvatarAssets,
      );
      final archiveJson = _retainRawPayloads
          ? normalized.archiveJson
          : _withoutRawImportPayloads(normalized.archiveJson);
      appDebugLog(
        'Apply import source=${_source.name} file=${_fileName ?? 'import.json'} '
        'counts=${normalized.counts} warnings=${normalized.warnings.length}',
      );

      if (mounted) {
        setState(() {
          _importStatus = l10n.writingImportStatus(
            _countSummary(normalized.counts),
          );
        });
      }

      var effectiveStrategy = _strategy;
      if (effectiveStrategy == ImportConflictStrategy.prompt) {
        final conflictResult = await _promptForConflicts(archiveJson);
        if (conflictResult.cancelled) {
          if (mounted) {
            setState(() {
              _isApplyingImport = false;
              _importStatus = l10n.importCancelledStatus;
            });
          }
          return;
        }
        if (conflictResult.strategy != null) {
          effectiveStrategy = conflictResult.strategy!;
        }
      }

      final jobId = await widget.repository.enqueueImportArchiveJob(
        archiveJson,
        strategy: effectiveStrategy,
        fileName: _fileName,
        source: _source,
      );
      appDebugLog('Import job queued id=$jobId source=${_source.name}');

      if (mounted) {
        setState(() {
          _importStatus = l10n.importingStatus(
            _countSummary(normalized.counts),
          );
        });
      }

      importCompleted = await widget.repository.runBackgroundJob(jobId);
      appDebugLog('Import job finished id=$jobId success=$importCompleted');
      if (mounted) {
        setState(() {
          _isApplyingImport = false;
          _importStatus = importCompleted
              ? l10n.importCompleteStatus(_countSummary(normalized.counts))
              : l10n.importFailedJobsStatus;
        });
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _isApplyingImport = false;
          _importStatus = l10n.importFailedStatus(error.toString());
        });
      }
      return;
    }

    if (mounted && importCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.sourceImportComplete(localizeImportSource(l10n, _source)),
          ),
        ),
      );
    }
  }

  Future<String> _effectiveImportText(String text) {
    if (!archiveTextLooksEncrypted(text)) {
      return Future.value(text);
    }
    if (_importPassphrase.trim().isEmpty) {
      throw FormatException(AppLocalizations.of(context).enterExportPassphrase);
    }
    return decryptArchiveJson(
      encryptedArchiveJson: text,
      passphrase: _importPassphrase,
    );
  }

  ImportPreview _encryptedArchiveLockedPreview(String fileName) {
    return ImportPreview(
      source: ImportSource.plurisHavenArchive,
      fileName: fileName,
      counts: const {},
      canApply: false,
      events: [
        ImportPreviewEvent(
          severity: ImportPreviewSeverity.warning,
          stage: ImportPreviewStage.decrypt,
          diagnostic: const ImportDiagnostic(
            ImportDiagnosticCode.encryptedArchiveLocked,
          ),
        ),
      ],
    );
  }

  ImportPreview _encryptedArchiveFailedPreview(String fileName, Object error) {
    return ImportPreview(
      source: ImportSource.plurisHavenArchive,
      fileName: fileName,
      counts: const {},
      canApply: false,
      events: [
        ImportPreviewEvent(
          severity: ImportPreviewSeverity.error,
          stage: ImportPreviewStage.decrypt,
          diagnostic: ImportDiagnostic(
            ImportDiagnosticCode.encryptedArchiveDecryptFailed,
            {'error': error.toString()},
          ),
        ),
      ],
    );
  }

  Future<_ConflictPromptResult> _promptForConflicts(String archiveJson) async {
    final decoded = jsonDecode(archiveJson);
    if (decoded is! Map<String, Object?>) {
      return const _ConflictPromptResult.resolved(ImportConflictStrategy.skip);
    }

    final importMembers = _jsonObjectList(decoded['members']);
    final importGroups = _jsonObjectList(decoded['groups']);

    final existingMembers = await widget.repository.watchMembers().first;
    final existingGroups = await widget.repository.watchGroups().first;

    final memberConflicts = <Map<String, Object?>>[];
    final groupConflicts = <Map<String, Object?>>[];

    if (importMembers.isNotEmpty && existingMembers.isNotEmpty) {
      final dedupe = MemberDedupeIndex([
        for (final member in existingMembers)
          ExistingMemberIdentity(
            localId: member.id,
            displayName: member.displayName,
            source: _source,
            sourceMemberId: member.id,
            pluralKitId: member.pluralKitId,
            isCustomFront: member.isCustomFront,
          ),
      ]);
      for (final candidate in importMembers) {
        final resolution = dedupe.resolve(
          ImportMemberCandidate(
            source: _source,
            displayName: _stringValue(candidate['display_name']) ?? '',
            sourceMemberId:
                _stringValue(candidate['source_member_id']) ??
                (_source == ImportSource.plurisHavenArchive
                    ? _stringValue(candidate['id'])
                    : null),
            pluralKitId: _stringValue(candidate['pluralkit_id']),
            isCustomFront: candidate['is_custom_front'] == true,
          ),
          strategy: ImportConflictStrategy.prompt,
        );
        if (resolution.disposition == ImportDedupeDisposition.skipped) {
          memberConflicts.add(candidate);
        }
      }
    }

    if (importGroups.isNotEmpty && existingGroups.isNotEmpty) {
      final existingNames = existingGroups
          .map((g) => g.name.trim().toLowerCase())
          .toSet();
      for (final candidate in importGroups) {
        final name = _stringValue(candidate['name'])?.trim().toLowerCase();
        if (name != null && existingNames.contains(name)) {
          groupConflicts.add(candidate);
        }
      }
    }

    if (memberConflicts.isEmpty && groupConflicts.isEmpty) {
      return const _ConflictPromptResult.noConflicts();
    }

    if (!mounted) return const _ConflictPromptResult.cancelled();

    final l10n = AppLocalizations.of(context);
    final result = await showDialog<ImportConflictStrategy>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ConflictPromptDialog(
        memberCount: memberConflicts.length,
        groupCount: groupConflicts.length,
        sourceLabel: localizeImportSource(l10n, _source),
      ),
    );

    if (result == null) {
      // Dialog was dismissed without an explicit choice (e.g. a system back
      // gesture) - treat this as cancelling the import, never as "no
      // conflicts found", so an unresolved conflict can never be silently
      // skipped.
      return const _ConflictPromptResult.cancelled();
    }
    return _ConflictPromptResult.resolved(result);
  }

  String _countSummary(Map<String, int> counts) {
    final l10n = AppLocalizations.of(context);
    final visible = counts.entries
        .where((entry) => entry.value > 0)
        .map(
          (entry) =>
              '${entry.value} ${_importCountLabel(l10n, entry.key, entry.value)}',
        )
        .join(', ');

    return visible.isEmpty ? l10n.noRecordsFound : visible;
  }

  Future<void> _copyImportDetails(String details) async {
    await Clipboard.setData(ClipboardData(text: details));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).fullErrorCopied)),
    );
  }

  Future<void> _copyPreviewDetails(ImportPreview preview) {
    final l10n = AppLocalizations.of(context);
    return _copyImportDetails(
      [
        'source: ${localizeImportSource(l10n, preview.source)}',
        'file: ${preview.fileName}',
        'counts: ${preview.counts}',
        for (final event in preview.events)
          '${event.severity.name} ${event.stage.name}: '
              '${localizeImportDiagnostic(l10n, event.diagnostic)}',
      ].join('\n'),
    );
  }
}

String _importCountLabel(AppLocalizations l10n, String key, int count) {
  return switch (key) {
    'members' => l10n.importCountMembers,
    'groups' => l10n.importCountGroups,
    'group_members' => l10n.importCountGroupMembers,
    'custom_fields' => l10n.importCountCustomFields,
    'custom_field_values' => l10n.importCountCustomFieldValues,
    'notes' => l10n.importCountNotes,
    'chat_categories' => l10n.importCountChatCategories,
    'chat_channels' => l10n.importCountChatChannels,
    'messages' => l10n.importCountMessages,
    'reminders' => l10n.importCountReminders,
    'tags' => l10n.importCountTags,
    'member_tags' => l10n.importCountMemberTags,
    'journals' => l10n.importCountJournals,
    'content_revisions' => l10n.importCountContentRevisions,
    'polls' => l10n.importCountPolls,
    'poll_options' => l10n.importCountPollOptions,
    'poll_votes' => l10n.importCountPollVotes,
    'poll_vote_events' => l10n.importCountPollVoteEvents,
    'fronts' => l10n.importCountFronts,
    'front_members' => l10n.importCountFrontMembers,
    'front_audit_events' => l10n.importCountFrontAuditEvents,
    'named_fronts' => l10n.importCountCustomFronts,
    'named_front_members' => l10n.importCountNamedFrontMembers,
    'privacy_buckets' => l10n.importCountPrivacyBuckets,
    'privacy_bucket_members' => l10n.importCountPrivacyBucketMembers,
    'avatar_refs' => l10n.importCountAvatarReferences,
    'avatar_assets' => l10n.importCountAvatarAssets,
    'import_records' => l10n.importCountImportRecords,
    'raw_payloads' => l10n.importCountPreservedSourceCollections(count),
    'notification_events' => l10n.importCountNotificationEvents,
    'preferences' => l10n.importCountPreferences,
    _ => l10n.importCountOther(key),
  };
}

String _importCountPillLabel(AppLocalizations l10n, String key, int count) {
  return l10n.importCountPill(_importCountLabel(l10n, key, count), count);
}

/// Distinguishes "no conflicts were found" (proceed with the original
/// strategy), "the user chose a strategy" (use it), and "the user cancelled"
/// (abort the import) - these must never be conflated, since a dismissed
/// dialog and an empty conflict set both previously resolved to `null`.
class _ConflictPromptResult {
  const _ConflictPromptResult.noConflicts()
    : cancelled = false,
      strategy = null;

  const _ConflictPromptResult.cancelled() : cancelled = true, strategy = null;

  const _ConflictPromptResult.resolved(ImportConflictStrategy this.strategy)
    : cancelled = false;

  final bool cancelled;
  final ImportConflictStrategy? strategy;
}

String? _stringValue(Object? value) {
  if (value is String) return value;
  if (value is num || value is bool) return value.toString();
  return null;
}

List<Map<String, Object?>> _jsonObjectList(Object? value) {
  if (value is List) {
    return [
      for (final item in value)
        if (item is Map<String, Object?>) item,
    ];
  }
  return const [];
}

class _ConflictPromptDialog extends StatelessWidget {
  const _ConflictPromptDialog({
    required this.memberCount,
    required this.groupCount,
    required this.sourceLabel,
  });

  final int memberCount;
  final int groupCount;
  final String sourceLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final parts = <String>[];
    if (memberCount > 0) {
      parts.add(l10n.memberConflictCount(memberCount));
    }
    if (groupCount > 0) {
      parts.add(l10n.groupConflictCount(groupCount));
    }

    return AlertDialog(
      title: Text(l10n.conflictsFoundTitle),
      content: Text(
        l10n.importConflictsBody(parts.join(l10n.listAnd), sourceLabel),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, ImportConflictStrategy.skip),
          child: Text(l10n.skipMatchesButton),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(context, ImportConflictStrategy.create),
          child: Text(l10n.createDuplicatesButton),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, ImportConflictStrategy.update),
          child: Text(l10n.updateExistingButton),
        ),
      ],
    );
  }
}

List<ImportAvatarAsset> _mergeAvatarAssets(
  List<ImportAvatarAsset> existing,
  List<ImportAvatarAsset> incoming,
) {
  final byId = <String, ImportAvatarAsset>{
    for (final asset in existing) asset.id: asset,
  };
  for (final asset in incoming) {
    byId[asset.id] = asset;
  }
  return byId.values.toList(growable: false);
}

void showLocalArchiveSheet(BuildContext context, HavenRepository repository) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (context) => LocalArchiveSheet(repository: repository),
  );
}

void showEncryptedArchiveSheet(
  BuildContext context,
  HavenRepository repository,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (context) => EncryptedArchiveSheet(repository: repository),
  );
}

class EncryptedArchiveSheet extends StatefulWidget {
  const EncryptedArchiveSheet({super.key, required this.repository});

  final HavenRepository repository;

  @override
  State<EncryptedArchiveSheet> createState() => _EncryptedArchiveSheetState();
}

class _EncryptedArchiveSheetState extends State<EncryptedArchiveSheet> {
  final _passphraseController = TextEditingController();
  final _confirmController = TextEditingController();
  ArchiveRecoveryCode? _recoveryCode;
  bool _isSaving = false;
  bool _obscurePassphrases = true;
  String? _status;

  @override
  void dispose() {
    _passphraseController.clear();
    _confirmController.clear();
    _passphraseController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
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
              l10n.encryptedExportTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.encryptedExportDescription,
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.35),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('encrypted-export-passphrase-field'),
              controller: _passphraseController,
              readOnly: true,
              obscureText: _obscurePassphrases,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: TextInputType.visiblePassword,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: l10n.generatedRecoveryCodeFieldLabel,
                suffixIcon: IconButton(
                  onPressed: _togglePassphraseVisibility,
                  tooltip: _obscurePassphrases
                      ? l10n.showRecoveryCodeTooltip
                      : l10n.hideRecoveryCodeTooltip,
                  icon: Icon(
                    _obscurePassphrases
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('encrypted-export-confirm-field'),
              controller: _confirmController,
              obscureText: _obscurePassphrases,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: TextInputType.visiblePassword,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: l10n.confirmRecoveryCodeFieldLabel,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const ValueKey('generate-archive-passphrase-button'),
              onPressed: _isSaving ? null : _generatePassphrase,
              icon: const Icon(Icons.password_rounded),
              label: Text(l10n.generateRecoveryCodeButton),
            ),
            if (_status != null) ...[
              const SizedBox(height: 10),
              Semantics(
                container: true,
                liveRegion: true,
                label: l10n.encryptedExportStatusSemanticLabel(_status!),
                child: ExcludeSemantics(
                  child: Text(
                    _status!,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton.icon(
              key: const ValueKey('save-encrypted-archive-button'),
              onPressed: _isSaving ? null : _saveEncryptedArchive,
              icon: _isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.lock_rounded),
              label: Text(
                _isSaving
                    ? l10n.encryptingArchiveButton
                    : l10n.saveEncryptedFileButton,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _togglePassphraseVisibility() {
    setState(() {
      _obscurePassphrases = !_obscurePassphrases;
    });
  }

  Future<void> _generatePassphrase() async {
    final generated = await generateArchiveRecoveryCode();
    if (!mounted) return;
    setState(() {
      _recoveryCode = generated;
      _passphraseController.text = generated.value;
      _confirmController.clear();
      _obscurePassphrases = false;
      _status = AppLocalizations.of(context).generatedRecoveryCodeStatus;
    });
  }

  Future<void> _saveEncryptedArchive() async {
    final l10n = AppLocalizations.of(context);
    final recoveryCode = _recoveryCode;
    if (recoveryCode == null) {
      setState(() {
        _status = l10n.generateRecoveryCodeFirst;
      });
      return;
    }
    final confirm = _confirmController.text;
    if (recoveryCode.value != confirm) {
      setState(() {
        _status = l10n.recoveryCodesDoNotMatch;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _status = l10n.buildingArchiveStatus;
    });

    final messenger = ScaffoldMessenger.of(context);
    try {
      final archiveJson = await widget.repository.buildLocalArchiveJson();
      if (!mounted) return;
      setState(() {
        _status = l10n.encryptingArchiveStatus;
      });
      final encrypted = await encryptArchiveJson(
        archiveJson: archiveJson,
        recoveryCode: recoveryCode,
      );
      final saved = await NativeFileDialog.saveBytes(
        dialogTitle: l10n.saveEncryptedArchiveDialogTitle,
        fileName: _encryptedArchiveFileName(),
        bytes: Uint8List.fromList(utf8.encode(encrypted)),
        mimeType: 'application/json',
      );
      if (!mounted) return;
      final message = saved ? l10n.encryptedArchiveSaved : l10n.saveCancelled;
      setState(() {
        _isSaving = false;
        _status = message;
      });
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _status = l10n.couldNotSaveEncryptedArchive(error.toString());
      });
    }
  }

  String _encryptedArchiveFileName() {
    final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(
      RegExp(r'[^0-9A-Za-z]'),
      '-',
    );
    return 'pluris-haven-encrypted-archive-$stamp.phx.json';
  }
}

class LocalArchiveSheet extends StatelessWidget {
  const LocalArchiveSheet({super.key, required this.repository});

  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: FutureBuilder<String>(
        future: repository.buildLocalArchiveJson(),
        builder: (context, snapshot) {
          final archive = snapshot.data;
          final scheme = Theme.of(context).colorScheme;
          final canCopyArchive =
              archive != null &&
              utf8.encode(archive).length <= _maximumClipboardArchiveBytes;

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
                Text(
                  l10n.localArchiveTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.localArchiveDescription,
                  style: const TextStyle(color: _spMuted, height: 1.35),
                ),
                const SizedBox(height: 14),
                if (snapshot.connectionState != ConnectionState.done)
                  Semantics(
                    container: true,
                    liveRegion: true,
                    label: l10n.buildingLocalArchiveSemanticLabel,
                    child: ExcludeSemantics(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 10),
                          Text(l10n.buildingLocalArchiveStatus),
                        ],
                      ),
                    ),
                  )
                else if (snapshot.hasError)
                  Semantics(
                    container: true,
                    liveRegion: true,
                    label: l10n.archiveErrorSemanticLabel(
                      snapshot.error.toString(),
                    ),
                    child: ExcludeSemantics(
                      child: Text(
                        l10n.couldNotBuildArchive(snapshot.error.toString()),
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  )
                else ...[
                  FilledButton.icon(
                    key: const ValueKey('save-local-archive-button'),
                    onPressed: () => _saveArchiveJson(context, archive!),
                    icon: const Icon(Icons.save_rounded),
                    label: Text(l10n.saveJsonFileButton),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    key: const ValueKey('copy-local-archive-button'),
                    onPressed: canCopyArchive
                        ? () => _copyArchiveJson(context, archive)
                        : null,
                    icon: const Icon(Icons.copy_rounded),
                    label: Text(l10n.copyJsonButton),
                  ),
                  if (!canCopyArchive) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.archiveTooLargeToCopy,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Semantics(
                    container: true,
                    label: l10n.localArchiveContentsHidden,
                    child: ExcludeSemantics(
                      child: Text(
                        l10n.localArchiveContentsHidden,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
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

  Future<void> _copyArchiveJson(BuildContext context, String archive) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.copyPlainArchiveWarningTitle),
        content: Text(l10n.copyPlainArchiveWarningBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.copyPlainArchiveConfirmButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      await SensitiveClipboard.copy(archive);
      if (!messenger.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.archiveCopied)));
    } on Object catch (error) {
      if (!messenger.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.couldNotCopyArchive(error.toString()))),
      );
    }
  }

  Future<void> _saveArchiveJson(BuildContext context, String archive) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.savePlainArchiveWarningTitle),
        content: Text(l10n.savePlainArchiveWarningBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.savePlainArchiveConfirmButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      final saved = await NativeFileDialog.saveBytes(
        dialogTitle: l10n.saveArchiveDialogTitle,
        fileName: _archiveFileName(),
        bytes: Uint8List.fromList(utf8.encode(archive)),
        mimeType: 'application/json',
      );
      if (!messenger.mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(saved ? l10n.archiveSaved : l10n.saveCancelled)),
      );
    } on Object catch (error) {
      if (!messenger.mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.couldNotSaveArchive(error.toString()))),
      );
    }
  }

  String _archiveFileName() {
    final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(
      RegExp(r'[^0-9A-Za-z]'),
      '-',
    );
    return 'pluris-haven-local-archive-$stamp.json';
  }
}

Future<String?> showPasteImportJsonSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
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
    final l10n = AppLocalizations.of(context);
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
            Text(
              l10n.pasteJsonTooltip,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('paste-import-json-field'),
              controller: _controller,
              autofocus: true,
              minLines: 8,
              maxLines: 14,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              maxLength: _maximumPastedImportCharacters,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              inputFormatters: [
                LengthLimitingTextInputFormatter(
                  _maximumPastedImportCharacters,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                ),
              ],
              decoration: InputDecoration(
                hintText: '{"members": [...]}',
                labelText: l10n.exportJsonLabel,
                helperText: l10n.pasteJsonSizeHelp,
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
              label: Text(l10n.previewPastedJson),
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
    required this.needsPassphrase,
    required this.onPickFile,
    required this.onPickAvatars,
    required this.onPasteJson,
    required this.onPreview,
    required this.onPassphraseChanged,
    required this.onTokenChanged,
    required this.onSourceChanged,
    required this.onStrategyChanged,
    required this.canPreview,
    required this.avatarAssetCount,
    required this.retainRawPayloads,
    required this.onRetainRawPayloadsChanged,
  });

  final ImportSource source;
  final ImportConflictStrategy strategy;
  final String? fileName;
  final int? fileSize;
  final ImportFileGuess? guess;
  final ImportPreview? preview;
  final ImportSourcePlan plan;
  final bool needsPassphrase;
  final bool canPreview;
  final int avatarAssetCount;
  final bool retainRawPayloads;
  final VoidCallback onPickFile;
  final VoidCallback onPickAvatars;
  final VoidCallback onPasteJson;
  final VoidCallback onPreview;
  final ValueChanged<String> onPassphraseChanged;
  final ValueChanged<String> onTokenChanged;
  final ValueChanged<ImportSource> onSourceChanged;
  final ValueChanged<ImportConflictStrategy> onStrategyChanged;
  final ValueChanged<bool> onRetainRawPayloadsChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SpSectionHeader(
            title: l10n.importSetupTitle,
            trailing: StatusPill(
              text: localizeImportPlanStatus(l10n, plan.status),
            ),
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
                    fileName == null
                        ? l10n.uploadFileButton
                        : l10n.chooseAnotherFileButton,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                key: const ValueKey('paste-import-json-button'),
                tooltip: l10n.pasteJsonTooltip,
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
          const SizedBox(height: 10),
          OutlinedButton.icon(
            key: const ValueKey('attach-avatar-zip-button'),
            onPressed: onPickAvatars,
            icon: const Icon(Icons.image_rounded),
            label: Text(
              avatarAssetCount == 0
                  ? l10n.attachAvatarsButton
                  : l10n.avatarsAttachedButton(avatarAssetCount),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ImportSource>(
            key: const ValueKey('import-source-dropdown'),
            initialValue: source,
            decoration: InputDecoration(labelText: l10n.serviceFieldLabel),
            items: [
              for (final source in ImportSource.values)
                DropdownMenuItem(
                  value: source,
                  child: Text(localizeImportSource(l10n, source)),
                ),
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
            decoration: InputDecoration(
              labelText: l10n.matchStrategyFieldLabel,
            ),
            items: [
              for (final strategy in ImportConflictStrategy.values)
                DropdownMenuItem(
                  value: strategy,
                  child: Text(localizeImportConflictStrategy(l10n, strategy)),
                ),
            ],
            onChanged: (strategy) {
              if (strategy != null) {
                onStrategyChanged(strategy);
              }
            },
          ),
          if (plan.requiresToken) ...[
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('pluralkit-token-field'),
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: onTokenChanged,
              decoration: InputDecoration(
                labelText: 'pk;token',
                helperText: l10n.pluralKitTokenHelper,
              ),
            ),
          ],
          if (needsPassphrase) ...[
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('import-passphrase-field'),
              obscureText: true,
              onChanged: onPassphraseChanged,
              decoration: InputDecoration(
                labelText: l10n.passphraseFieldLabel,
                helperText: l10n.importPassphraseHelper,
              ),
            ),
          ],
          if ((preview?.counts['raw_payloads'] ?? 0) > 0) ...[
            const SizedBox(height: 10),
            Material(
              color: Colors.transparent,
              child: SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: retainRawPayloads,
                onChanged: onRetainRawPayloadsChanged,
                title: Text(l10n.retainRawImportPayloadsTitle),
                subtitle: Text(l10n.retainRawImportPayloadsDescription),
              ),
            ),
          ],
          const SizedBox(height: 12),
          ImportMetaRow(
            label: l10n.inputLabel,
            value: localizeImportInput(l10n, source),
          ),
          const SizedBox(height: 8),
          ImportMetaRow(label: l10n.jobLabel, value: source.jobSource),
          const SizedBox(height: 8),
          ImportMetaRow(
            label: l10n.dedupeLabel,
            value: localizeImportDedupe(l10n, source),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: canPreview ? onPreview : null,
            icon: const Icon(Icons.fact_check_rounded),
            label: Text(
              preview == null
                  ? l10n.previewImportButton
                  : l10n.refreshPreviewButton,
            ),
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
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final detected = guess?.source;
    final label = detected == null
        ? l10n.chooseServiceStatus
        : l10n.serviceDetectedStatus(localizeImportSource(l10n, detected));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(fileName, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            [
              if (fileSize != null) _formatBytes(fileSize!),
              guess == null
                  ? l10n.waitingForDetection
                  : localizeImportDetectionReason(l10n, guess!.reason),
            ].join(' - '),
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 12,
              height: 1.35,
            ),
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
    this.onRehearse,
    this.isImporting = false,
    this.isRehearsing = false,
    this.rehearsal,
    this.onCopyDetails,
  });

  final ImportPreview preview;
  final Future<void> Function()? onApply;
  final Future<void> Function()? onRehearse;
  final bool isImporting;
  final bool isRehearsing;
  final RestoreRehearsalSummary? rehearsal;
  final Future<void> Function()? onCopyDetails;

  @override
  Widget build(BuildContext context) {
    final notableEvents = preview.warningsAndErrors;
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return SpCard(
      outlined: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SpSectionHeader(
            title: l10n.previewTitle,
            trailing: StatusPill(
              text: preview.canApply
                  ? l10n.validShapeStatus
                  : l10n.needsAttentionStatus,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${localizeImportSource(l10n, preview.source)} - ${preview.fileName}',
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.35),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in preview.counts.entries)
                if (entry.value > 0)
                  StatusPill(
                    text: _importCountPillLabel(l10n, entry.key, entry.value),
                  ),
              if (!preview.counts.values.any((count) => count > 0))
                StatusPill(text: l10n.noRecordsFound),
            ],
          ),
          if (notableEvents.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.errorTitle,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                if (onCopyDetails != null)
                  TextButton.icon(
                    onPressed: onCopyDetails,
                    icon: const Icon(Icons.copy_rounded),
                    label: Text(l10n.copyFullButton),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final event in notableEvents) ...[
                      Text(
                        '${localizeImportPreviewStage(l10n, event.stage)}: '
                        '${localizeImportDiagnostic(l10n, event.diagnostic)}',
                        style: TextStyle(
                          color: event.severity == ImportPreviewSeverity.error
                              ? scheme.error
                              : scheme.onSurfaceVariant,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (rehearsal != null) ...[
            RestoreRehearsalResult(summary: rehearsal!),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                key: const ValueKey('restore-rehearsal-button'),
                onPressed: preview.canApply && onRehearse != null
                    ? () async => onRehearse!()
                    : null,
                icon: isRehearsing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.fact_check_rounded),
                label: Text(
                  isRehearsing
                      ? l10n.rehearsingButton
                      : l10n.runRestoreRehearsalButton,
                ),
              ),
              FilledButton.icon(
                key: const ValueKey('import-archive-button'),
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
                label: Text(
                  isImporting ? l10n.importingButton : l10n.importArchiveButton,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RestoreRehearsalResult extends StatelessWidget {
  const RestoreRehearsalResult({super.key, required this.summary});

  final RestoreRehearsalSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final visibleCounts = summary.visibleCounts.toList(growable: false);
    final title = summary.canRestore
        ? l10n.restoreRehearsalPassed
        : l10n.restoreRehearsalFailed;
    final body = summary.canRestore
        ? l10n.restoreRehearsalPassedBody
        : summary.error ?? l10n.restoreRehearsalFailedBody;
    final counts = visibleCounts
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(', ');

    return Semantics(
      container: true,
      liveRegion: true,
      label: l10n.restoreStatusSemanticLabel(
        title,
        body,
        counts.isEmpty ? '' : '. $counts',
      ),
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: summary.canRestore
                  ? scheme.primary.withValues(alpha: 0.65)
                  : scheme.error,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    summary.canRestore
                        ? Icons.verified_rounded
                        : Icons.error_outline_rounded,
                    color: summary.canRestore ? scheme.primary : scheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  StatusPill(text: '${summary.elapsed.inMilliseconds}ms'),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                body,
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.35),
              ),
              if (visibleCounts.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in visibleCounts)
                      StatusPill(text: '${entry.key}: ${entry.value}'),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ImportProgressCard extends StatelessWidget {
  const ImportProgressCard({
    super.key,
    required this.status,
    required this.isActive,
    this.onCopyDetails,
    this.onReportIssue,
  });

  final String? status;
  final bool isActive;
  final Future<void> Function()? onCopyDetails;
  final VoidCallback? onReportIssue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final normalizedStatus = status?.toLowerCase() ?? '';
    final isQueued = normalizedStatus.contains('queued');
    final announcement = status ?? l10n.importReadyStatus;

    return Semantics(
      container: true,
      liveRegion: true,
      label: l10n.importStatusSemanticLabel(announcement),
      child: ExcludeSemantics(
        child: SpCard(
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
                      color: scheme.primary,
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      announcement,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              if (isActive) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
              ],
              if (!isActive && onCopyDetails != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: onCopyDetails,
                  icon: const Icon(Icons.copy_rounded),
                  label: Text(l10n.copyFullButton),
                ),
              ],
              if (onReportIssue != null) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: onReportIssue,
                  icon: const Icon(Icons.bug_report_outlined),
                  label: Text(l10n.reportImportIssueButton),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

final _importIssueUri = Uri.parse(
  'https://github.com/EndofTimeWorks/pluris-haven/issues/new',
);

class RetainedImportPayloadsCard extends StatelessWidget {
  const RetainedImportPayloadsCard({super.key, required this.repository});

  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return StreamBuilder<List<RetainedImportPayloadSummary>>(
      stream: repository.watchRetainedImportPayloads(),
      builder: (context, snapshot) {
        final retained = snapshot.data ?? const [];
        if (retained.isEmpty) return const SizedBox.shrink();
        return SpCard(
          outlined: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SpSectionHeader(title: l10n.retainedImportPayloadsTitle),
              const SizedBox(height: 6),
              Text(
                l10n.retainedImportPayloadsDescription,
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.35),
              ),
              const SizedBox(height: 10),
              for (final item in retained)
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      l10n.retainedImportPayloadSummary(
                        item.source,
                        item.payloadCount,
                      ),
                    ),
                    subtitle: Text(item.collections.join(', ')),
                    trailing: IconButton(
                      tooltip: l10n.deleteRetainedImportPayloadsTooltip,
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () => _confirmDelete(context, item),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    RetainedImportPayloadSummary item,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteRetainedImportPayloadsTitle),
        content: Text(
          l10n.deleteRetainedImportPayloadsDescription(item.payloadCount),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await repository.deleteRetainedImportPayloads(item.importRecordId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.retainedImportPayloadsDeleted)));
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
        final l10n = AppLocalizations.of(context);
        final scheme = Theme.of(context).colorScheme;
        return SpCard(
          outlined: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SpSectionHeader(
                title: l10n.recentJobsTitle,
                trailing: StatusPill(
                  text: jobs.isEmpty ? l10n.noneStatus : '${jobs.length}',
                ),
              ),
              const SizedBox(height: 8),
              if (jobs.isEmpty)
                Text(
                  l10n.noImportsQueued,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                )
              else
                for (final job in jobs) ...[
                  ImportJobRow(job: job),
                  if (job != jobs.last) const Divider(height: 1),
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
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final title = job.fileName ?? job.type;
    final subtitle = job.error == null
        ? '${job.status} - ${_shortDateTime(job.updatedAt)}'
        : '${_oneLineJobError(job.error!)} - ${l10n.tapForDetails}';

    return Semantics(
      button: true,
      label: l10n.importJobSemanticLabel(title, job.status),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          onTap: () => _showJobDetails(context),
          leading: Icon(_icon, color: _color(context), size: 20),
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
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          trailing: StatusPill(text: job.status),
        ),
      ),
    );
  }

  void _showJobDetails(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                    Icon(_icon, color: _color(context)),
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
                _JobDetailLine(label: l10n.typeFieldLabel, value: job.type),
                if (job.source != null)
                  _JobDetailLine(
                    label: l10n.sourceFieldLabel,
                    value: job.source!,
                  ),
                _JobDetailLine(
                  label: l10n.createdFieldLabel,
                  value: _shortDateTime(job.createdAt),
                ),
                _JobDetailLine(
                  label: l10n.updatedFieldLabel,
                  value: _shortDateTime(job.updatedAt),
                ),
                if (job.error != null && job.error!.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _JobErrorPreview(error: job.error!),
                ] else ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.noJobErrorRecorded,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
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

  Color _color(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (job.status) {
      'done' => scheme.primary,
      'failed' => scheme.error,
      'running' => scheme.secondary,
      _ => scheme.onSurfaceVariant,
    };
  }
}

class _JobErrorPreview extends StatelessWidget {
  const _JobErrorPreview({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final preview = _boundedJobError(error, l10n);
    final isTruncated = preview.length < error.trim().length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.errorTitle,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: error.trim()));
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.fullErrorCopied)));
              },
              icon: const Icon(Icons.copy_rounded),
              label: Text(l10n.copyFullButton),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (isTruncated) ...[
          Text(
            l10n.jobErrorPreviewTruncated,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: SelectableText(
            preview,
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.35),
          ),
        ),
      ],
    );
  }
}

String _boundedJobError(String error, AppLocalizations l10n) {
  final trimmed = error.trim();
  const maxLength = 4000;
  if (trimmed.length <= maxLength) {
    return trimmed;
  }
  return '${trimmed.substring(0, maxLength)}\n\n'
      '${l10n.truncatedCharacters(trimmed.length - maxLength)}';
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
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
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
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return SpCard(
      outlined: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SpSectionHeader(
            title: l10n.importPlanTitle(
              localizeImportSource(l10n, plan.source),
            ),
            trailing: StatusPill(
              text: plan.canPreviewOffline
                  ? l10n.importPlanOfflinePreview
                  : l10n.importPlanNeedsNetwork,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final count in plan.previewCounts)
                StatusPill(text: localizeImportPlanCount(l10n, count)),
            ],
          ),
          const SizedBox(height: 14),
          for (final step in plan.steps) ...[
            Text(
              localizeImportPlanStep(l10n, step).title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 3),
            Text(
              localizeImportPlanStep(l10n, step).detail,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
          ],
          const Divider(height: 18),
          for (final note in plan.privacyNotes) ...[
            Text(
              localizeImportPrivacyNote(l10n, note),
              style: TextStyle(
                color: scheme.onSurfaceVariant,
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
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
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
