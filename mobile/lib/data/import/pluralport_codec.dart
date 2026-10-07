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

  final exportedAt = envelope['exported_at'];
  if (exportedAt is! String || DateTime.tryParse(exportedAt) == null) {
    throw const FormatException(
      'PluralPort exported_at must be an ISO-8601 timestamp.',
    );
  }

  for (final module in _pluralPortArrayModules) {
    final value = envelope[module];
    if (value != null && value is! List) {
      throw FormatException('PluralPort $module must be an array.');
    }
  }
  if (envelope['extensions'] case final extensions?) {
    if (extensions is! Map<String, Object?>) {
      throw const FormatException('PluralPort extensions must be an object.');
    }
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
  final groups = _maps(decoded['groups']);
  final groupMembers = _maps(decoded['group_members']);
  final fronts = _maps(decoded['fronts']);
  final frontMembers = _maps(decoded['front_members']);
  final avatarAssets = _maps(decoded['avatar_assets']);
  final assetIdByReference = <String, String>{};
  for (final asset in avatarAssets) {
    final id = _string(asset['id']);
    if (id != null) assetIdByReference['local-avatar:$id'] = id;
  }

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
            'avatar_asset_id':
                assetIdByReference[_string(system['avatar_url'])],
            'source_refs': [_sourceRef('systems', systemId)],
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
          'avatar_asset_id': assetIdByReference[_string(member['avatar_url'])],
          'archived': member['archived'] == true,
          'source_refs': [_sourceRef('members', id)],
          if (member['is_custom_front'] == true)
            'extensions': {
              pluralPortHavenAppId: {'is_custom_front': true},
            },
        }),
  ];
  final exportedGroups = [
    for (final group in groups)
      if (_string(group['id']) case final id?)
        _withoutNulls({
          'id': id,
          'system_id': systemId,
          'name': _string(group['name']) ?? id,
          'description': _string(group['description']),
          'color': _string(group['color_hex'] ?? group['color']),
          'parent_group_id': _string(group['parent_group_id']),
          'source_refs': [_sourceRef('groups', id)],
        }),
  ];
  final exportedGroupMemberships = [
    for (final link in groupMembers)
      if (_string(link['group_id']) case final groupId?)
        if (_string(link['member_id']) case final memberId?)
          {
            'id': 'group-membership-$groupId-$memberId',
            'group_id': groupId,
            'member_id': memberId,
            'source_refs': [
              _sourceRef('group_memberships', '$groupId:$memberId'),
            ],
          },
  ];
  final exportedFronts = [
    for (final front in fronts)
      if (_string(front['id']) case final id?)
        _withoutNulls({
          'id': id,
          'system_id': systemId,
          'started_at': _string(front['started_at']),
          'ended_at': _string(front['ended_at']),
          'assignments': frontAssignments[id] ?? const [],
          'status': _string(front['status'] ?? front['status_note']),
          'source_kind': 'grouped',
          'source_refs': [_sourceRef('front_periods', id)],
        }),
  ];
  final exportedNotes = [
    for (final note in _maps(decoded['notes']))
      if (_string(note['id']) case final id?)
        _withoutNulls({
          'id': id,
          'system_id': systemId,
          'member_id': _string(note['member_id']),
          'title': _string(note['title']),
          'body': _string(note['body']),
          'created_at': _string(note['created_at']),
          'updated_at': _string(note['updated_at']),
          'source_refs': [_sourceRef('notes', id)],
        }),
  ];
  final exportedAssets = [
    for (final asset in avatarAssets)
      if (_string(asset['id']) case final id?)
        _withoutNulls({
          'id': id,
          'name': _string(asset['name']),
          'mime_type': _string(asset['mime_type']),
          'source_refs': [_sourceRef('assets', id)],
          'extensions': {
            pluralPortHavenAppId: {
              if (asset['bytes_base64'] != null)
                'bytes_base64': asset['bytes_base64'],
            },
          },
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
  module('groups', exportedGroups);
  module('fronting', exportedFronts);
  module('notes', exportedNotes);
  module('assets', exportedAssets);

  final envelope = <String, Object?>{
    'pluralport_version': pluralPortDraftVersion,
    'exported_at': (exportedAt ?? DateTime.now().toUtc()).toIso8601String(),
    'producer': {
      'app': 'Pluris Haven',
      'app_version': appVersion,
      'exporter_version': pluralPortDraftVersion,
      'app_id': pluralPortHavenAppId,
    },
    'capabilities': {'modules': modules},
    'systems': exportedSystems,
    'members': exportedMembers,
    'groups': exportedGroups,
    'group_memberships': exportedGroupMemberships,
    'front_periods': exportedFronts,
    'front_events': const <Object?>[],
    'notes': exportedNotes,
    'assets': exportedAssets,
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
