import 'dart:convert';

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
      keys: const {'tuppers': 'tuppers', 'tags': 'tags'},
    ),
    ImportSource.pluralSpace => _previewLooseSource(
      source: source,
      fileName: fileName,
      decoded: decoded,
      keys: const {
        'members': 'members',
        'groups': 'groups',
        'fronts': 'fronts',
        'notes': 'notes',
      },
    ),
    ImportSource.prism => ImportPreview(
      source: source,
      fileName: fileName,
      counts: const {},
      canApply: false,
      events: const [
        ImportPreviewEvent(
          severity: ImportPreviewSeverity.warning,
          stage: 'decrypt',
          message: 'Prism preview needs encrypted file decryption first.',
        ),
      ],
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
    'fronts': _listCount(decoded['fronts']),
    'front_members': _listCount(decoded['front_members']),
    'import_records': _listCount(decoded['import_records']),
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
  final counts = <String, int>{
    'members': _countFirstList(decoded, const [
      'members',
      'membersList',
      'profiles',
    ]),
    'groups': _countFirstList(decoded, const ['groups', 'folders']),
    'front_history': _countFirstList(decoded, const [
      'frontHistory',
      'fronthistory',
      'fronts',
      'switches',
    ]),
    'custom_fronts': _countFirstList(decoded, const [
      'customFronts',
      'customfronts',
      'custom_fronts',
    ]),
    'custom_fields': _countFirstList(decoded, const [
      'customFields',
      'customfields',
      'custom_fields',
    ]),
    'notes': _countFirstList(decoded, const ['notes']),
    'messages': _countFirstList(decoded, const ['messages', 'chat']),
  };

  return ImportPreview(
    source: ImportSource.simplyPlural,
    fileName: fileName,
    counts: counts,
    canApply: true,
    events: const [
      ImportPreviewEvent(
        severity: ImportPreviewSeverity.warning,
        stage: 'preview',
        message:
            'Simply Plural parser is shape-only right now; review counts before write support is added.',
      ),
    ],
  );
}

ImportPreview _previewPluralKit(String fileName, Map<String, Object?> decoded) {
  final counts = <String, int>{
    'members': _countFirstList(decoded, const ['members']),
    'groups': _countFirstList(decoded, const ['groups']),
    'switches': _countFirstList(decoded, const ['switches']),
  };

  return ImportPreview(
    source: ImportSource.pluralKitFile,
    fileName: fileName,
    counts: counts,
    canApply: true,
    events: const [
      ImportPreviewEvent(
        severity: ImportPreviewSeverity.warning,
        stage: 'preview',
        message:
            'PluralKit parser is shape-only right now; front intervals are not written yet.',
      ),
    ],
  );
}

ImportPreview _previewLooseSource({
  required ImportSource source,
  required String fileName,
  required Map<String, Object?> decoded,
  required Map<String, String> keys,
}) {
  final counts = {
    for (final entry in keys.entries)
      entry.value: _listCount(decoded[entry.key]),
  };

  return ImportPreview(
    source: source,
    fileName: fileName,
    counts: counts,
    canApply: true,
    events: [
      ImportPreviewEvent(
        severity: ImportPreviewSeverity.warning,
        stage: 'preview',
        message:
            '${source.label} parser is shape-only right now; write support is not implemented yet.',
      ),
    ],
  );
}

int _countFirstList(Map<String, Object?> object, List<String> keys) {
  for (final key in keys) {
    final count = _listCount(object[key]);
    if (count > 0) {
      return count;
    }
  }
  return 0;
}

int _listCount(Object? value) => value is List ? value.length : 0;
