import 'import_sources.dart';

enum ImportPlanStatus {
  ready('ready'),
  next('next'),
  planned('planned');

  const ImportPlanStatus(this.label);

  final String label;
}

enum ImportPlanStep {
  readPlurisArchive,
  validatePlurisArchive,
  reviewPlurisArchive,
  restorePlurisArchive,
  readSimplyPlural,
  normalizeSimplyPlural,
  prepareSimplyPluralAvatars,
  reviewSimplyPlural,
  writeSimplyPlural,
  readPluralKitFile,
  buildPluralKitRoster,
  convertPluralKitSwitches,
  reviewPluralKitFile,
  validatePluralKitToken,
  fetchPluralKitRoster,
  fetchPluralKitSwitches,
  reviewPluralKitLive,
  readTupperbox,
  mapTupperbox,
  reviewTupperbox,
  readPluralSpace,
  mapPluralSpace,
  reviewPluralSpace,
  choosePrism,
  decryptPrism,
  reviewPrism,
}

enum ImportPlanCount {
  members,
  groups,
  notes,
  journals,
  messages,
  reminders,
  tags,
  customFields,
  polls,
  frontHistory,
  notifications,
  preferences,
  customFronts,
  switches,
  frontIntervals,
  tuppers,
  avatars,
  fronts,
}

enum ImportPrivacyNote {
  previewBeforeWrite,
  localBackupRestore,
  simplyPluralDedupe,
  simplyPluralAvatars,
  pluralKitIdentifiers,
  pluralKitSwitches,
  pluralKitTokenEphemeral,
  pluralKitLiveNetwork,
  tupperboxIdentifiers,
  tupperboxProxyMetadata,
  pluralSpaceIdentifiers,
  pluralSpaceUnknownFields,
  prismPassphraseMemoryOnly,
  prismIdentifiers,
}

enum ImportDetectionReason {
  prismExtension,
  plurisFileName,
  simplyPluralFileName,
  pluralKitFileName,
  tupperboxFileName,
  pluralSpaceFileName,
  chooseAfterUpload,
  encryptedPlurisArchive,
  localPlurisArchive,
  tupperboxFields,
  pluralKitFields,
  simplyPluralFields,
  pluralSpaceMarkers,
  ambiguousMemberGroupJson,
  unrecognised,
}

class ImportSourcePlan {
  const ImportSourcePlan({
    required this.source,
    required this.status,
    required this.defaultConflictStrategy,
    required this.steps,
    required this.previewCounts,
    required this.privacyNotes,
  });

  final ImportSource source;
  final ImportPlanStatus status;
  final ImportConflictStrategy defaultConflictStrategy;
  final List<ImportPlanStep> steps;
  final List<ImportPlanCount> previewCounts;
  final List<ImportPrivacyNote> privacyNotes;

  bool get requiresFile =>
      source.inputKinds.contains(ImportInputKind.file) ||
      source.inputKinds.contains(ImportInputKind.encryptedFile);

  bool get requiresToken =>
      source.inputKinds.contains(ImportInputKind.liveToken);

  bool get requiresPassphrase =>
      source.inputKinds.contains(ImportInputKind.encryptedFile);

  bool get canPreviewOffline => !requiresToken;
}

class ImportFileGuess {
  const ImportFileGuess({
    required this.source,
    required this.confidence,
    required this.reason,
  });

  final ImportSource? source;
  final double confidence;
  final ImportDetectionReason reason;

  bool get isConfident => source != null && confidence >= 0.72;
}

ImportFileGuess guessImportSourceFromFile({
  required String fileName,
  String? textPreview,
}) {
  final name = fileName.toLowerCase();
  final text = textPreview?.toLowerCase() ?? '';

  if (name.endsWith('.prism')) {
    return const ImportFileGuess(
      source: ImportSource.prism,
      confidence: 0.95,
      reason: ImportDetectionReason.prismExtension,
    );
  }

  if (_hasAny(name, ['pluris-haven', 'pluris_haven', 'plurishaven'])) {
    return const ImportFileGuess(
      source: ImportSource.plurisHavenArchive,
      confidence: 0.9,
      reason: ImportDetectionReason.plurisFileName,
    );
  }

  if (_hasAny(name, [
    'simply plural',
    'simply-plural',
    'simply_plural',
    'frontime',
  ])) {
    return const ImportFileGuess(
      source: ImportSource.simplyPlural,
      confidence: 0.82,
      reason: ImportDetectionReason.simplyPluralFileName,
    );
  }

  if (_hasAny(name, ['pluralkit', 'plural-kit', 'pk-export'])) {
    return const ImportFileGuess(
      source: ImportSource.pluralKitFile,
      confidence: 0.84,
      reason: ImportDetectionReason.pluralKitFileName,
    );
  }

  if (_hasAny(name, ['tupperbox', 'tuppers'])) {
    return const ImportFileGuess(
      source: ImportSource.tupperbox,
      confidence: 0.84,
      reason: ImportDetectionReason.tupperboxFileName,
    );
  }

  if (_hasAny(name, ['pluralspace', 'plural-space'])) {
    return const ImportFileGuess(
      source: ImportSource.pluralSpace,
      confidence: 0.84,
      reason: ImportDetectionReason.pluralSpaceFileName,
    );
  }

  if (text.isEmpty) {
    return const ImportFileGuess(
      source: null,
      confidence: 0,
      reason: ImportDetectionReason.chooseAfterUpload,
    );
  }

  if (_hasAny(text, [
    '"format":"pluris_haven.encrypted_archive"',
    '"format": "pluris_haven.encrypted_archive"',
  ])) {
    return const ImportFileGuess(
      source: ImportSource.plurisHavenArchive,
      confidence: 0.98,
      reason: ImportDetectionReason.encryptedPlurisArchive,
    );
  }

  if (_hasAny(text, [
    '"format":"pluris_haven.local_archive"',
    '"format": "pluris_haven.local_archive"',
  ])) {
    return const ImportFileGuess(
      source: ImportSource.plurisHavenArchive,
      confidence: 0.98,
      reason: ImportDetectionReason.localPlurisArchive,
    );
  }

  if (_hasAny(text, ['"tuppers"', '"brackets"', '"avatar_url"'])) {
    return const ImportFileGuess(
      source: ImportSource.tupperbox,
      confidence: 0.76,
      reason: ImportDetectionReason.tupperboxFields,
    );
  }

  if (_hasAny(text, ['"switches"', '"members"', '"proxy_tags"', '"privacy"']) &&
      _hasAny(text, ['"pluralkit"', '"uuid"', '"system"'])) {
    return const ImportFileGuess(
      source: ImportSource.pluralKitFile,
      confidence: 0.78,
      reason: ImportDetectionReason.pluralKitFields,
    );
  }

  if (_hasAny(text, ['"customfronts"', '"fronthistory"', '"fronters"'])) {
    return const ImportFileGuess(
      source: ImportSource.simplyPlural,
      confidence: 0.78,
      reason: ImportDetectionReason.simplyPluralFields,
    );
  }

  if (_hasAny(text, ['"pluralspace"', '"plural_space"'])) {
    return const ImportFileGuess(
      source: ImportSource.pluralSpace,
      confidence: 0.78,
      reason: ImportDetectionReason.pluralSpaceMarkers,
    );
  }

  if (_hasAny(text, ['"members"', '"groups"'])) {
    return const ImportFileGuess(
      source: null,
      confidence: 0.45,
      reason: ImportDetectionReason.ambiguousMemberGroupJson,
    );
  }

  return const ImportFileGuess(
    source: null,
    confidence: 0,
    reason: ImportDetectionReason.unrecognised,
  );
}

ImportSourcePlan importPlanFor(ImportSource source) {
  return switch (source) {
    ImportSource.plurisHavenArchive => const ImportSourcePlan(
      source: ImportSource.plurisHavenArchive,
      status: ImportPlanStatus.ready,
      defaultConflictStrategy: ImportConflictStrategy.prompt,
      previewCounts: [
        ImportPlanCount.members,
        ImportPlanCount.groups,
        ImportPlanCount.notes,
        ImportPlanCount.journals,
        ImportPlanCount.messages,
        ImportPlanCount.reminders,
        ImportPlanCount.tags,
        ImportPlanCount.customFields,
        ImportPlanCount.polls,
        ImportPlanCount.frontHistory,
        ImportPlanCount.notifications,
        ImportPlanCount.preferences,
      ],
      privacyNotes: [
        ImportPrivacyNote.previewBeforeWrite,
        ImportPrivacyNote.localBackupRestore,
      ],
      steps: [
        ImportPlanStep.readPlurisArchive,
        ImportPlanStep.validatePlurisArchive,
        ImportPlanStep.reviewPlurisArchive,
        ImportPlanStep.restorePlurisArchive,
      ],
    ),
    ImportSource.simplyPlural => const ImportSourcePlan(
      source: ImportSource.simplyPlural,
      status: ImportPlanStatus.next,
      defaultConflictStrategy: ImportConflictStrategy.prompt,
      previewCounts: [
        ImportPlanCount.members,
        ImportPlanCount.groups,
        ImportPlanCount.frontHistory,
        ImportPlanCount.customFronts,
        ImportPlanCount.notes,
      ],
      privacyNotes: [
        ImportPrivacyNote.previewBeforeWrite,
        ImportPrivacyNote.simplyPluralDedupe,
        ImportPrivacyNote.simplyPluralAvatars,
      ],
      steps: [
        ImportPlanStep.readSimplyPlural,
        ImportPlanStep.normalizeSimplyPlural,
        ImportPlanStep.prepareSimplyPluralAvatars,
        ImportPlanStep.reviewSimplyPlural,
        ImportPlanStep.writeSimplyPlural,
      ],
    ),
    ImportSource.pluralKitFile => const ImportSourcePlan(
      source: ImportSource.pluralKitFile,
      status: ImportPlanStatus.next,
      defaultConflictStrategy: ImportConflictStrategy.prompt,
      previewCounts: [
        ImportPlanCount.members,
        ImportPlanCount.groups,
        ImportPlanCount.switches,
        ImportPlanCount.frontIntervals,
      ],
      privacyNotes: [
        ImportPrivacyNote.pluralKitIdentifiers,
        ImportPrivacyNote.pluralKitSwitches,
      ],
      steps: [
        ImportPlanStep.readPluralKitFile,
        ImportPlanStep.buildPluralKitRoster,
        ImportPlanStep.convertPluralKitSwitches,
        ImportPlanStep.reviewPluralKitFile,
      ],
    ),
    ImportSource.pluralKitLive => const ImportSourcePlan(
      source: ImportSource.pluralKitLive,
      status: ImportPlanStatus.next,
      defaultConflictStrategy: ImportConflictStrategy.prompt,
      previewCounts: [
        ImportPlanCount.members,
        ImportPlanCount.groups,
        ImportPlanCount.switches,
      ],
      privacyNotes: [
        ImportPrivacyNote.pluralKitTokenEphemeral,
        ImportPrivacyNote.pluralKitLiveNetwork,
      ],
      steps: [
        ImportPlanStep.validatePluralKitToken,
        ImportPlanStep.fetchPluralKitRoster,
        ImportPlanStep.fetchPluralKitSwitches,
        ImportPlanStep.reviewPluralKitLive,
      ],
    ),
    ImportSource.tupperbox => const ImportSourcePlan(
      source: ImportSource.tupperbox,
      status: ImportPlanStatus.next,
      defaultConflictStrategy: ImportConflictStrategy.prompt,
      previewCounts: [
        ImportPlanCount.tuppers,
        ImportPlanCount.avatars,
        ImportPlanCount.tags,
      ],
      privacyNotes: [
        ImportPrivacyNote.tupperboxIdentifiers,
        ImportPrivacyNote.tupperboxProxyMetadata,
      ],
      steps: [
        ImportPlanStep.readTupperbox,
        ImportPlanStep.mapTupperbox,
        ImportPlanStep.reviewTupperbox,
      ],
    ),
    ImportSource.pluralSpace => const ImportSourcePlan(
      source: ImportSource.pluralSpace,
      status: ImportPlanStatus.next,
      defaultConflictStrategy: ImportConflictStrategy.prompt,
      previewCounts: [
        ImportPlanCount.members,
        ImportPlanCount.groups,
        ImportPlanCount.fronts,
      ],
      privacyNotes: [
        ImportPrivacyNote.pluralSpaceIdentifiers,
        ImportPrivacyNote.pluralSpaceUnknownFields,
      ],
      steps: [
        ImportPlanStep.readPluralSpace,
        ImportPlanStep.mapPluralSpace,
        ImportPlanStep.reviewPluralSpace,
      ],
    ),
    ImportSource.prism => const ImportSourcePlan(
      source: ImportSource.prism,
      status: ImportPlanStatus.planned,
      defaultConflictStrategy: ImportConflictStrategy.prompt,
      previewCounts: [
        ImportPlanCount.members,
        ImportPlanCount.fronts,
        ImportPlanCount.notes,
      ],
      privacyNotes: [
        ImportPrivacyNote.prismPassphraseMemoryOnly,
        ImportPrivacyNote.prismIdentifiers,
      ],
      steps: [
        ImportPlanStep.choosePrism,
        ImportPlanStep.decryptPrism,
        ImportPlanStep.reviewPrism,
      ],
    ),
  };
}

bool _hasAny(String value, List<String> needles) {
  return needles.any(value.contains);
}
