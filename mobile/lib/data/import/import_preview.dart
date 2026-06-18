import 'dart:convert';

import 'import_archive_mapper.dart';
import 'import_plan.dart';
import 'import_sources.dart';

enum ImportPreviewSeverity { info, warning, error }

class ImportPreviewEvent {
  const ImportPreviewEvent({
    required this.severity,
    required this.stage,
    required this.message,
    this.recordRef,
  });

  final ImportPreviewSeverity severity;
  final String stage;
  final String message;
  final String? recordRef;
}

class ImportPreview {
  const ImportPreview({
    required this.source,
    required this.fileName,
    required this.counts,
    required this.events,
    required this.canApply,
  });

  final ImportSource source;
  final String fileName;
  final Map<String, int> counts;
  final List<ImportPreviewEvent> events;
  final bool canApply;

  List<ImportPreviewEvent> get warningsAndErrors => [
    for (final event in events)
      if (event.severity != ImportPreviewSeverity.info) event,
  ];
}

ImportPreview previewImportText({
  required String fileName,
  required String text,
  ImportSource? selectedSource,
}) {
  final guess = guessImportSourceFromFile(
    fileName: fileName,
    textPreview: text,
  );
  final source = selectedSource ?? guess.source ?? ImportSource.simplyPlural;

  Object? decoded;
  try {
    decoded = jsonDecode(text);
  } on FormatException catch (error) {
    return ImportPreview(
      source: source,
      fileName: fileName,
      counts: const {},
      canApply: false,
      events: [
        ImportPreviewEvent(
          severity: ImportPreviewSeverity.error,
          stage: 'parse',
          message: 'Could not parse JSON: ${error.message}',
        ),
      ],
    );
  }

  if (decoded is! Map<String, Object?>) {
    return ImportPreview(
      source: source,
      fileName: fileName,
      counts: const {},
      canApply: false,
      events: const [
        ImportPreviewEvent(
          severity: ImportPreviewSeverity.error,
          stage: 'parse',
          message: 'Expected a JSON object at the top level.',
        ),
      ],
    );
  }

  return switch (source) {
    ImportSource.plurisHavenArchive => _previewPlurisArchive(fileName, decoded),
    ImportSource.simplyPlural => _previewSimplyPlural(fileName, decoded),
    ImportSource.pluralKitFile => _previewPluralKit(fileName, decoded),
    ImportSource.pluralKitLive => ImportPreview(
      source: source,
      fileName: fileName,
      counts: const {},
      canApply: false,
      events: const [
        ImportPreviewEvent(
          severity: ImportPreviewSeverity.warning,
          stage: 'input',
          message: 'PluralKit live import uses a token, not a file.',
        ),
      ],
    ),
    ImportSource.tupperbox => _previewLooseSource(
      source: source,
      fileName: fileName,
      decoded: decoded,
    ),
    ImportSource.pluralSpace => _previewLooseSource(
      source: source,
      fileName: fileName,
      decoded: decoded,
    ),
    ImportSource.prism => _previewNormalizedSource(
      source: source,
      fileName: fileName,
      decoded: decoded,
    ),
  };
}

ImportPreview _previewPlurisArchive(
  String fileName,
  Map<String, Object?> decoded,
) {
  final events = <ImportPreviewEvent>[];
  final format = decoded['format'];
  final version = decoded['version'];

  if (format != 'pluris_haven.local_archive') {
    events.add(
      const ImportPreviewEvent(
        severity: ImportPreviewSeverity.error,
        stage: 'validate',
        message: 'This is not a Pluris Haven local archive.',
      ),
    );
  }

  if (version != 1) {
    events.add(
      ImportPreviewEvent(
        severity: ImportPreviewSeverity.error,
        stage: 'validate',
        message: 'Unsupported archive version: ${version ?? 'missing'}.',
      ),
    );
  }

  final counts = {
    'members': _listCount(decoded['members']),
    'groups': _listCount(decoded['groups']),
    'notes': _listCount(decoded['notes']),
    'messages': _listCount(decoded['messages']),
    'reminders': _listCount(decoded['reminders']),
    'fronts': _listCount(decoded['fronts']),
    'front_members': _listCount(decoded['front_members']),
    'import_records': _listCount(decoded['import_records']),
    'notification_events': _listCount(decoded['notification_events']),
    'preferences': _listCount(decoded['preferences']),
  };

  events.add(
    ImportPreviewEvent(
      severity: ImportPreviewSeverity.info,
      stage: 'preview',
      message:
          'Found ${counts['members']} members and ${counts['fronts']} fronts.',
    ),
  );

  return ImportPreview(
    source: ImportSource.plurisHavenArchive,
    fileName: fileName,
    counts: counts,
    events: events,
    canApply: events.every(
      (event) => event.severity != ImportPreviewSeverity.error,
    ),
  );
}

ImportPreview _previewSimplyPlural(
  String fileName,
  Map<String, Object?> decoded,
) {
  return _previewNormalizedSource(
    source: ImportSource.simplyPlural,
    fileName: fileName,
    decoded: decoded,
  );
}

ImportPreview _previewPluralKit(String fileName, Map<String, Object?> decoded) {
  return _previewNormalizedSource(
    source: ImportSource.pluralKitFile,
    fileName: fileName,
    decoded: decoded,
  );
}

ImportPreview _previewLooseSource({
  required ImportSource source,
  required String fileName,
  required Map<String, Object?> decoded,
}) {
  return _previewNormalizedSource(
    source: source,
    fileName: fileName,
    decoded: decoded,
  );
}

ImportPreview _previewNormalizedSource({
  required ImportSource source,
  required String fileName,
  required Map<String, Object?> decoded,
}) {
  NormalizedImportArchive normalized;
  try {
    normalized = normalizeImportTextToLocalArchive(
      source: source,
      fileName: fileName,
      text: jsonEncode(decoded),
    );
  } on FormatException catch (error) {
    return ImportPreview(
      source: source,
      fileName: fileName,
      counts: const {},
      canApply: false,
      events: [
        ImportPreviewEvent(
          severity: ImportPreviewSeverity.error,
          stage: 'normalize',
          message: error.message,
        ),
      ],
    );
  }

  final foundRecords = normalized.counts.entries.any(
    (entry) => entry.key != 'front_members' && entry.value > 0,
  );

  return ImportPreview(
    source: source,
    fileName: fileName,
    counts: normalized.counts,
    canApply: foundRecords,
    events: [
      const ImportPreviewEvent(
        severity: ImportPreviewSeverity.info,
        stage: 'normalize',
        message: 'Recognized records can be imported into the local archive.',
      ),
      if (!foundRecords)
        const ImportPreviewEvent(
          severity: ImportPreviewSeverity.warning,
          stage: 'normalize',
          message: 'No importable records were recognized.',
        ),
      for (final warning in normalized.warnings)
        ImportPreviewEvent(
          severity: ImportPreviewSeverity.warning,
          stage: 'normalize',
          message: warning,
        ),
      ImportPreviewEvent(
        severity: ImportPreviewSeverity.warning,
        stage: 'preview',
        message: '${source.label} import is best-effort. Review after import.',
      ),
    ],
  );
}

int _listCount(Object? value) => value is List ? value.length : 0;
