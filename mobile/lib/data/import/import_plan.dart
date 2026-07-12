import 'import_sources.dart';

enum ImportPlanStatus {
  ready('ready'),
  next('next'),
  planned('planned');

  const ImportPlanStatus(this.label);

  final String label;
}

class ImportPlanStep {
  const ImportPlanStep(this.title, this.detail);

  final String title;
  final String detail;
}

class ImportPlanCount {
  const ImportPlanCount(this.label);

  final String label;
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
  final List<String> privacyNotes;

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
  final String reason;

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
      reason: '.prism file extension',
    );
  }

  if (_hasAny(name, ['pluris-haven', 'pluris_haven', 'plurishaven'])) {
    return const ImportFileGuess(
      source: ImportSource.plurisHavenArchive,
      confidence: 0.9,
      reason: 'filename looks like a Pluris Haven archive',
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
      reason: 'filename looks like a Simply Plural export',
    );
  }

  if (_hasAny(name, ['pluralkit', 'plural-kit', 'pk-export'])) {
    return const ImportFileGuess(
      source: ImportSource.pluralKitFile,
      confidence: 0.84,
      reason: 'filename looks like a PluralKit export',
    );
  }

  if (_hasAny(name, ['tupperbox', 'tuppers'])) {
    return const ImportFileGuess(
      source: ImportSource.tupperbox,
      confidence: 0.84,
      reason: 'filename looks like a Tupperbox export',
    );
  }

  if (_hasAny(name, ['pluralspace', 'plural-space'])) {
    return const ImportFileGuess(
      source: ImportSource.pluralSpace,
      confidence: 0.84,
      reason: 'filename looks like a PluralSpace export',
    );
  }

  if (_hasAny(name, ['openplural', 'open-plural']) ||
      name.endsWith('.openplural.zip') ||
      name.endsWith('.openplural.json')) {
    return const ImportFileGuess(
      source: ImportSource.openPlural,
      confidence: 0.9,
      reason: 'filename looks like an OpenPlural export',
    );
  }

  if (text.isEmpty) {
    return const ImportFileGuess(
      source: null,
      confidence: 0,
      reason: 'pick a service after upload',
    );
  }

  if (_hasAny(text, [
    '"format":"pluris_haven.encrypted_archive"',
    '"format": "pluris_haven.encrypted_archive"',
  ])) {
    return const ImportFileGuess(
      source: ImportSource.plurisHavenArchive,
      confidence: 0.98,
      reason: 'file is an encrypted Pluris Haven archive',
    );
  }

  if (_hasAny(text, [
    '"format":"pluris_haven.local_archive"',
    '"format": "pluris_haven.local_archive"',
  ])) {
    return const ImportFileGuess(
      source: ImportSource.plurisHavenArchive,
      confidence: 0.98,
      reason: 'file is a Pluris Haven local archive',
    );
  }

  if (_hasAny(text, ['"tuppers"', '"brackets"', '"avatar_url"'])) {
    return const ImportFileGuess(
      source: ImportSource.tupperbox,
      confidence: 0.76,
      reason: 'file contains Tupperbox-style roster fields',
    );
  }

  if (_hasAny(text, ['"switches"', '"members"', '"proxy_tags"', '"privacy"']) &&
      _hasAny(text, ['"pluralkit"', '"uuid"', '"system"'])) {
    return const ImportFileGuess(
      source: ImportSource.pluralKitFile,
      confidence: 0.78,
      reason: 'file contains PluralKit-style members and switches',
    );
  }

  if (_hasAny(text, ['"customfronts"', '"fronthistory"', '"fronters"'])) {
    return const ImportFileGuess(
      source: ImportSource.simplyPlural,
      confidence: 0.78,
      reason: 'file contains Simply Plural fronting fields',
    );
  }

  if (_hasAny(text, ['"pluralspace"', '"plural_space"'])) {
    return const ImportFileGuess(
      source: ImportSource.pluralSpace,
      confidence: 0.78,
      reason: 'file contains PluralSpace markers',
    );
  }

  if (_hasAny(text, [
    '"openplural_version"',
    '"front_periods"',
    '"front_events"',
  ])) {
    return const ImportFileGuess(
      source: ImportSource.openPlural,
      confidence: 0.9,
      reason: 'file contains OpenPlural markers',
    );
  }

  if (_hasAny(text, ['"members"', '"groups"'])) {
    return const ImportFileGuess(
      source: null,
      confidence: 0.45,
      reason: 'member/group JSON found, choose the source to confirm',
    );
  }

  return const ImportFileGuess(
    source: null,
    confidence: 0,
    reason: 'could not recognize this file yet',
  );
}

ImportSourcePlan importPlanFor(ImportSource source) {
  return switch (source) {
    ImportSource.plurisHavenArchive => const ImportSourcePlan(
      source: ImportSource.plurisHavenArchive,
      status: ImportPlanStatus.ready,
      defaultConflictStrategy: ImportConflictStrategy.prompt,
      previewCounts: [
        ImportPlanCount('members'),
        ImportPlanCount('groups'),
        ImportPlanCount('notes'),
        ImportPlanCount('journals'),
        ImportPlanCount('messages'),
        ImportPlanCount('reminders'),
        ImportPlanCount('tags'),
        ImportPlanCount('custom fields'),
        ImportPlanCount('polls'),
        ImportPlanCount('front history'),
        ImportPlanCount('notifications'),
        ImportPlanCount('preferences'),
      ],
      privacyNotes: [
        'Archive import previews before writing anything.',
        'This is the backup and restore path for local data.',
      ],
      steps: [
        ImportPlanStep(
          'Read archive',
          'Accept a Pluris Haven local archive JSON export.',
        ),
        ImportPlanStep(
          'Validate format',
          'Require format pluris_haven.local_archive and a supported version.',
        ),
        ImportPlanStep(
          'Review contents',
          'Show local members, groups, journals, notes, fronts, tags, polls, and preferences before writing.',
        ),
        ImportPlanStep(
          'Restore locally',
          'Apply selected records and keep an import record for future dedupe.',
        ),
      ],
    ),
    ImportSource.simplyPlural => const ImportSourcePlan(
      source: ImportSource.simplyPlural,
      status: ImportPlanStatus.next,
      defaultConflictStrategy: ImportConflictStrategy.prompt,
      previewCounts: [
        ImportPlanCount('members'),
        ImportPlanCount('groups'),
        ImportPlanCount('front history'),
        ImportPlanCount('custom fronts'),
        ImportPlanCount('notes'),
      ],
      privacyNotes: [
        'Preview happens before records are saved.',
        'Re-imports match by Simply Plural ID, PluralKit ID, then normalized name.',
        'Avatar ZIPs stay offline. Remote avatar URLs may be fetched during import so they can be stored locally.',
      ],
      steps: [
        ImportPlanStep(
          'Read export',
          'Accept a Simply Plural JSON export or backup archive.',
        ),
        ImportPlanStep(
          'Normalize fields',
          'Map members, groups, custom fields, custom fronts, and notes into local records.',
        ),
        ImportPlanStep(
          'Prepare avatars',
          'Use attached avatar ZIP bytes first, then keep or localize remote avatar URLs during import.',
        ),
        ImportPlanStep(
          'Review matches',
          'Show creates, skips, and updates before writing.',
        ),
        ImportPlanStep(
          'Write locally',
          'Save records and keep an import record for future dedupe.',
        ),
      ],
    ),
    ImportSource.pluralKitFile => const ImportSourcePlan(
      source: ImportSource.pluralKitFile,
      status: ImportPlanStatus.next,
      defaultConflictStrategy: ImportConflictStrategy.prompt,
      previewCounts: [
        ImportPlanCount('members'),
        ImportPlanCount('groups'),
        ImportPlanCount('switches'),
        ImportPlanCount('front intervals'),
      ],
      privacyNotes: [
        'PluralKit IDs are kept as import identifiers for dedupe and optional sync.',
        'Switch logs become local front history intervals.',
      ],
      steps: [
        ImportPlanStep('Read export', 'Accept a PluralKit JSON export file.'),
        ImportPlanStep(
          'Build roster',
          'Stage members, groups, avatars, descriptions, and proxy metadata.',
        ),
        ImportPlanStep(
          'Convert switches',
          'Turn PK switches into local front history.',
        ),
        ImportPlanStep(
          'Review matches',
          'Dedupe by PK UUID, short ID, then normalized name.',
        ),
      ],
    ),
    ImportSource.pluralKitLive => const ImportSourcePlan(
      source: ImportSource.pluralKitLive,
      status: ImportPlanStatus.ready,
      defaultConflictStrategy: ImportConflictStrategy.prompt,
      previewCounts: [
        ImportPlanCount('members'),
        ImportPlanCount('groups'),
        ImportPlanCount('switches'),
      ],
      privacyNotes: [
        'The pk;token should be used for the import request only.',
        'Live import needs network access, but the preview and write still happen locally.',
      ],
      steps: [
        ImportPlanStep(
          'Validate token',
          'Call GET /systems/@me with the token as Authorization.',
        ),
        ImportPlanStep(
          'Fetch roster',
          'Read members and groups from the PluralKit API.',
        ),
        ImportPlanStep(
          'Fetch switches',
          'Page switches with a delay to avoid rate limits.',
        ),
        ImportPlanStep(
          'Review matches',
          'Dedupe by PK UUID and short ID before saving.',
        ),
      ],
    ),
    ImportSource.tupperbox => const ImportSourcePlan(
      source: ImportSource.tupperbox,
      status: ImportPlanStatus.next,
      defaultConflictStrategy: ImportConflictStrategy.prompt,
      previewCounts: [
        ImportPlanCount('tuppers'),
        ImportPlanCount('avatars'),
        ImportPlanCount('tags'),
      ],
      privacyNotes: [
        'Tupperbox IDs are retained only for dedupe and future re-imports.',
        'Proxy patterns can be imported later as optional metadata.',
      ],
      steps: [
        ImportPlanStep('Read roster', 'Accept a Tupperbox export file.'),
        ImportPlanStep(
          'Map tuppers',
          'Convert tuppers to members with names, avatars, brackets, and descriptions.',
        ),
        ImportPlanStep(
          'Review matches',
          'Dedupe by Tupperbox ID, then normalized name.',
        ),
      ],
    ),
    ImportSource.pluralSpace => const ImportSourcePlan(
      source: ImportSource.pluralSpace,
      status: ImportPlanStatus.next,
      defaultConflictStrategy: ImportConflictStrategy.prompt,
      previewCounts: [
        ImportPlanCount('members'),
        ImportPlanCount('groups'),
        ImportPlanCount('fronts'),
      ],
      privacyNotes: [
        'PluralSpace source IDs are kept as import identifiers.',
        'Unknown fields are kept in the preview until a mapper exists.',
      ],
      steps: [
        ImportPlanStep('Read export', 'Accept a PluralSpace export file.'),
        ImportPlanStep(
          'Map records',
          'Stage members, groups, notes, and fronting data when present.',
        ),
        ImportPlanStep(
          'Review matches',
          'Dedupe by source ID, then normalized name.',
        ),
      ],
    ),
    ImportSource.openPlural => const ImportSourcePlan(
      source: ImportSource.openPlural,
      status: ImportPlanStatus.next,
      defaultConflictStrategy: ImportConflictStrategy.prompt,
      previewCounts: [
        ImportPlanCount('members'),
        ImportPlanCount('groups'),
        ImportPlanCount('front periods'),
        ImportPlanCount('front events'),
        ImportPlanCount('custom fields'),
        ImportPlanCount('notes'),
      ],
      privacyNotes: [
        'Only OpenPlural v0.1 is accepted in this pre-alpha build.',
        'Unknown app extensions are preserved as raw payloads until native surfaces exist.',
      ],
      steps: [
        ImportPlanStep(
          'Read envelope',
          'Accept a bare OpenPlural JSON export or the JSON inside an OpenPlural bundle.',
        ),
        ImportPlanStep(
          'Map core records',
          'Convert systems, members, groups, custom fields, notes, and front history.',
        ),
        ImportPlanStep(
          'Convert switch events',
          'Turn OpenPlural front_events into front intervals when needed.',
        ),
        ImportPlanStep(
          'Review matches',
          'Dedupe by source IDs, PluralKit refs, then normalized names.',
        ),
      ],
    ),
    ImportSource.prism => const ImportSourcePlan(
      source: ImportSource.prism,
      status: ImportPlanStatus.planned,
      defaultConflictStrategy: ImportConflictStrategy.prompt,
      previewCounts: [
        ImportPlanCount('members'),
        ImportPlanCount('fronts'),
        ImportPlanCount('notes'),
      ],
      privacyNotes: [
        'The passphrase is only used to decrypt the import in memory.',
        'Prism source IDs are kept for re-import dedupe.',
      ],
      steps: [
        ImportPlanStep(
          'Choose .prism file',
          'Accept an encrypted Prism export.',
        ),
        ImportPlanStep(
          'Decrypt preview',
          'Use the passphrase locally and avoid storing it.',
        ),
        ImportPlanStep(
          'Review matches',
          'Dedupe by Prism ID, then normalized name.',
        ),
      ],
    ),
  };
}

bool _hasAny(String value, List<String> needles) {
  return needles.any(value.contains);
}
