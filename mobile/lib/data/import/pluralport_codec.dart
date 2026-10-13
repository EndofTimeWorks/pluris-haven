import 'dart:convert';

const pluralPortDraftVersion = '0.1';
const pluralPortHavenAppId = 'pluris_haven';

Map<String, Object?> decodePluralPortEnvelope(String text) {
  final decoded = jsonDecode(text);
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('PluralPort file must be a JSON object.');
  }
  validatePluralPortEnvelope(decoded);
  return decoded;
}

void validatePluralPortEnvelope(Map<String, Object?> envelope) {
  final version = envelope['pluralport_version'];
  if (version != pluralPortDraftVersion) {
    throw FormatException(
      'Unsupported PluralPort version: ${version ?? 'missing'}.',
    );
  }

  final producer = envelope['producer'];
  if (producer is! Map<String, Object?> ||
      !_nonEmptyString(producer['app']) ||
      !_nonEmptyString(producer['app_version']) ||
      !_nonEmptyString(producer['app_id'])) {
    throw const FormatException(
      'PluralPort producer must include app, app_version, and app_id.',
    );
  }

  final capabilities = envelope['capabilities'];
  if (capabilities is! Map<String, Object?> ||
      capabilities['modules'] is! List ||
      !(capabilities['modules'] as List).every(_nonEmptyString)) {
    throw const FormatException(
      'PluralPort capabilities.modules must be an array of strings.',
    );
  }

  _parseUtcTimestamp(envelope['exported_at'], 'exported_at');

  for (final module in _pluralPortArrayModules) {
    final value = envelope[module];
    if (value != null && value is! List) {
      throw FormatException('PluralPort $module must be an array.');
    }
    if (value is List && value.any((record) => record is! Map)) {
      throw FormatException('PluralPort $module must contain JSON objects.');
    }
  }
  if (envelope['extensions'] case final extensions?) {
    if (extensions is! Map<String, Object?>) {
      throw const FormatException('PluralPort extensions must be an object.');
    }
  }

  for (final record in _maps(envelope['front_periods'])) {
    _parseUtcTimestamp(record['started_at'], 'front_periods[].started_at');
    if (record['ended_at'] != null) {
      _parseUtcTimestamp(record['ended_at'], 'front_periods[].ended_at');
    }
  }
  for (final record in _maps(envelope['front_events'])) {
    _parseUtcTimestamp(record['at'], 'front_events[].at');
  }
}

String encodePluralPortFromLocalArchive(
  String archiveJson, {
  required String appVersion,
  DateTime? exportedAt,
}) {
  final decoded = jsonDecode(archiveJson);
  if (decoded is! Map<String, Object?> ||
      decoded['format'] != 'pluris_haven.local_archive' ||
      decoded['version'] != 1) {
    throw const FormatException(
      'Expected a Pluris Haven local archive version 1.',
    );
  }

  final warnings = <Map<String, Object?>>[];
  final system = _map(decoded['system']);
  final systemId = _string(system?['id']) ?? 'local-system';
  final members = _maps(decoded['members']);
  final fronts = _maps(decoded['fronts']);
  final frontMembers = _maps(decoded['front_members']);
  final importedSourceRefs = _importedPluralPortSourceRefs(
    decoded['raw_payloads'],
  );

  final frontAssignments = <String, List<Map<String, Object?>>>{};
  for (final link in frontMembers) {
    final frontId = _string(link['session_id'] ?? link['front_id']);
    final memberId = _string(link['member_id']);
    if (frontId != null && memberId != null) {
      frontAssignments.putIfAbsent(frontId, () => []).add({
        'member_id': memberId,
        'front_role': 'member',
      });
    }
  }

  final modules = <String>[];
  void module(String name, Object? value) {
    if (value is List && value.isNotEmpty) modules.add(name);
  }

  final exportedSystems = system == null
      ? <Map<String, Object?>>[]
      : [
          _withoutNulls({
            'id': systemId,
            'name': _string(system['name']) ?? 'Pluris Haven system',
            'description': _string(system['description']),
            'color': _string(system['color_hex']),
            'source_refs': _mergeSourceRefs([
              _sourceRef('systems', systemId),
              ...importedSourceRefs.systems,
            ]),
            'extensions': _havenRecordExtension(system, const [
              'avatar_url',
              'created_at',
              'updated_at',
            ]),
          }),
        ];
  final exportedMembers = [
    for (final member in members)
      if (_string(member['id']) case final id?)
        _withoutNulls({
          'id': id,
          'system_id': systemId,
          'name': _string(member['display_name'] ?? member['name']) ?? id,
          'display_name': _string(member['display_name']),
          'pronouns': _string(member['pronouns']),
          'description': _string(member['description']),
          'birthday': _string(member['birthday']),
          'color': _string(member['color_hex'] ?? member['color']),
          'archived': member['archived'] == true,
          'source_refs': _mergeSourceRefs([
            _sourceRef('members', id),
            if (_string(member['pluralkit_id']) case final pluralKitId?)
              {'app': 'pluralkit', 'collection': 'members', 'id': pluralKitId},
            ...?importedSourceRefs.members[id],
          ]),
          'extensions': _havenRecordExtension(member, const [
            'emoji',
            'privacy',
            'folder_id',
            'avatar_url',
            'is_custom_front',
            'deleted_at',
            'purged_at',
            'created_at',
            'updated_at',
          ]),
        }),
  ];
  final exportedFronts = [
    for (final front in fronts)
      if (_string(front['id']) case final id?)
        _withoutNulls({
          'id': id,
          'system_id': systemId,
          'started_at': _normaliseUtcTimestamp(
            front['started_at'],
            'fronts[].started_at',
          ),
          'ended_at': front['ended_at'] == null
              ? null
              : _normaliseUtcTimestamp(front['ended_at'], 'fronts[].ended_at'),
          'assignments': frontAssignments[id] ?? const [],
          'status': _string(front['status'] ?? front['status_note']),
          'source_kind': 'grouped',
          'source_refs': _mergeSourceRefs([
            _sourceRef('front_periods', id),
            ...?importedSourceRefs.frontPeriods[id],
          ]),
          'extensions': _havenRecordExtension(front, const [
            'label',
            'created_at',
            'updated_at',
          ]),
        }),
  ];

  final unsupported = <String, Object?>{};
  for (final key in _havenArchiveOnlyCollections) {
    final value = decoded[key];
    if (value is List && value.isNotEmpty) unsupported[key] = value;
  }
  if (unsupported.isNotEmpty) {
    warnings.add({
      'level': 'warning',
      'code': 'pluris_haven_archive_only_data',
      'message': 'Some Pluris Haven data is preserved only in extensions.pluris_haven.',
    });
  }

  module('systems', exportedSystems);
  module('members', exportedMembers);
  module('fronting', exportedFronts);

  final envelope = <String, Object?>{
    'pluralport_version': pluralPortDraftVersion,
    'exported_at': (exportedAt ?? DateTime.now()).toUtc().toIso8601String(),
    'producer': {
      'app': 'Pluris Haven',
      'app_version': appVersion,
      'exporter_version': pluralPortDraftVersion,
      'app_id': pluralPortHavenAppId,
    },
    'capabilities': {'modules': modules},
    'systems': exportedSystems,
    'members': exportedMembers,
    'front_periods': exportedFronts,
    'front_events': const <Object?>[],
    'extensions': {
      if (unsupported.isNotEmpty)
        pluralPortHavenAppId: {'archive_only': unsupported},
    },
    'warnings': warnings,
  };
  validatePluralPortEnvelope(envelope);
  return const JsonEncoder.withIndent('  ').convert(envelope);
}

const _pluralPortArrayModules = {
  'systems',
  'members',
  'groups',
  'group_memberships',
  'taxonomy_terms',
  'taxonomy_assignments',
  'custom_fields',
  'custom_field_values',
  'front_periods',
  'front_events',
  'front_comments',
  'notes',
  'assets',
  'conversations',
  'chat_messages',
  'attachments',
  'reactions',
  'board_posts',
};

const _havenArchiveOnlyCollections = {
  // Draft v0.1 names these record types but does not yet define their fields.
  // Preserve Haven's complete representation instead of inventing a wire shape.
  'groups',
  'group_members',
  'notes',
  'avatar_assets',
  'tags',
  'member_tags',
  'custom_fields',
  'custom_field_values',
  'chat_categories',
  'chat_channels',
  'messages',
  'reminders',
  'journals',
  'content_revisions',
  'custom_field_value_migration_provenance',
  'polls',
  'poll_options',
  'poll_votes',
  'poll_vote_events',
  'front_audit_events',
  'named_fronts',
  'named_front_members',
  'privacy_buckets',
  'privacy_bucket_members',
  'import_records',
  'raw_payloads',
  'notification_events',
  'preferences',
};

Map<String, Object?> _sourceRef(String collection, String id) => {
  'app': pluralPortHavenAppId,
  'collection': collection,
  'id': id,
};

class _ImportedSourceRefs {
  const _ImportedSourceRefs({
    required this.systems,
    required this.members,
    required this.frontPeriods,
  });

  final List<Map<String, Object?>> systems;
  final Map<String, List<Map<String, Object?>>> members;
  final Map<String, List<Map<String, Object?>>> frontPeriods;
}

_ImportedSourceRefs _importedPluralPortSourceRefs(Object? rawPayloads) {
  final systems = <Map<String, Object?>>[];
  final members = <String, List<Map<String, Object?>>>{};
  final frontPeriods = <String, List<Map<String, Object?>>>{};
  for (final payload in _maps(rawPayloads)) {
    if (_string(payload['source']) != 'pluralport_file' ||
        _string(payload['collection']) != 'pluralport_extensions') {
      continue;
    }
    final payloadJson = _string(payload['payload_json']);
    if (payloadJson == null) continue;
    Object? decoded;
    try {
      decoded = jsonDecode(payloadJson);
    } on FormatException {
      continue;
    }
    final preserved = _map(decoded);
    if (preserved == null) continue;
    for (final wrapper in _maps(preserved['records'])) {
      final collection = _string(wrapper['collection']);
      final record = _map(wrapper['record']);
      if (collection == null || record == null) continue;
      final refs = _validSourceRefs(record['source_refs']);
      if (refs.isEmpty) continue;
      switch (collection) {
        case 'systems':
          systems.addAll(refs);
          break;
        case 'members':
          final externalId =
              _sourceIdentity(record['source_refs']) ?? _string(record['id']);
          if (externalId != null) {
            final localId = _pluralPortStableId('member', externalId);
            members.putIfAbsent(localId, () => []).addAll(refs);
          }
          break;
        case 'front_periods':
          final externalId = _string(record['id']);
          if (externalId != null) {
            final localId = _pluralPortStableId('front', externalId);
            frontPeriods.putIfAbsent(localId, () => []).addAll(refs);
          }
          break;
        case 'front_events':
          final externalId = _string(record['id']);
          if (externalId != null) {
            final localId = _pluralPortStableId('front', 'event-$externalId');
            frontPeriods.putIfAbsent(localId, () => []).addAll(refs);
          }
          break;
      }
    }
  }
  return _ImportedSourceRefs(
    systems: _mergeSourceRefs(systems),
    members: {
      for (final entry in members.entries)
        entry.key: _mergeSourceRefs(entry.value),
    },
    frontPeriods: {
      for (final entry in frontPeriods.entries)
        entry.key: _mergeSourceRefs(entry.value),
    },
  );
}

List<Map<String, Object?>> _validSourceRefs(Object? value) => [
  for (final ref in _maps(value))
    if (_string(ref['app']) case final app?)
      if (_string(ref['collection']) case final collection?)
        if (_string(ref['id']) case final id?)
          {'app': app, 'collection': collection, 'id': id},
];

List<Map<String, Object?>> _mergeSourceRefs(
  Iterable<Map<String, Object?>> refs,
) {
  final seen = <String>{};
  return [
    for (final ref in refs)
      if (seen.add('${ref['app']}\u0000${ref['collection']}\u0000${ref['id']}'))
        ref,
  ];
}

String? _sourceIdentity(Object? value) {
  for (final ref in _validSourceRefs(value)) {
    return '${ref['app']}:${ref['collection']}:${ref['id']}';
  }
  return null;
}

String _pluralPortStableId(String kind, String externalId) {
  final normalized = externalId.trim().toLowerCase().replaceAll(
    RegExp(r'[^a-z0-9]+'),
    '-',
  );
  final trimmed = normalized.replaceAll(RegExp(r'^-+|-+$'), '');
  return 'pluralport_file-$kind-${trimmed.isEmpty ? 'unknown' : trimmed}';
}

Map<String, Object?>? _havenRecordExtension(
  Map<String, Object?> record,
  List<String> fields,
) {
  final preserved = <String, Object?>{
    for (final field in fields)
      if (record[field] != null) field: record[field],
  };
  return preserved.isEmpty ? null : {pluralPortHavenAppId: preserved};
}

DateTime _parseUtcTimestamp(Object? value, String field) {
  if (value is! String ||
      !RegExp(r'(?:Z|\+00:00)$', caseSensitive: false).hasMatch(value)) {
    throw FormatException(
      'PluralPort $field must be an ISO-8601 UTC timestamp.',
    );
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw FormatException(
      'PluralPort $field must be an ISO-8601 UTC timestamp.',
    );
  }
  return parsed.toUtc();
}

String _normaliseUtcTimestamp(Object? value, String field) =>
    _parseUtcTimestamp(value, field).toIso8601String();

Map<String, Object?> _withoutNulls(Map<String, Object?> value) => {
  for (final entry in value.entries)
    if (entry.value != null) entry.key: entry.value,
};

Map<String, Object?>? _map(Object? value) =>
    value is Map<String, Object?> ? value : null;

List<Map<String, Object?>> _maps(Object? value) =>
    value is List ? [for (final item in value) ?_map(item)] : const [];

String? _string(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;

bool _nonEmptyString(Object? value) => _string(value) != null;
