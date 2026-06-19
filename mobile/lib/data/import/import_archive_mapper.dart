import 'dart:convert';

import 'import_file_decoder.dart';
import 'import_sources.dart';

class NormalizedImportArchive {
  const NormalizedImportArchive({
    required this.source,
    required this.fileName,
    required this.archiveJson,
    required this.counts,
    required this.warnings,
  });

  final ImportSource source;
  final String fileName;
  final String archiveJson;
  final Map<String, int> counts;
  final List<String> warnings;
}

NormalizedImportArchive normalizeImportTextToLocalArchive({
  required ImportSource source,
  required String fileName,
  required String text,
  List<ImportAvatarAsset> avatarAssets = const [],
  DateTime? importedAt,
}) {
  final decoded = jsonDecode(text);
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('Expected a JSON object at the top level.');
  }

  if (source == ImportSource.plurisHavenArchive) {
    return NormalizedImportArchive(
      source: source,
      fileName: fileName,
      archiveJson: text,
      counts: _archiveCounts(decoded),
      warnings: const [],
    );
  }

  if (source == ImportSource.prism) {
    throw const FormatException('Prism imports need decryption first.');
  }
  if (source == ImportSource.pluralKitLive) {
    throw const FormatException('PluralKit live import needs a token.');
  }

  final normalizer = _ExternalArchiveNormalizer(
    source: source,
    decoded: decoded,
    avatarAssets: avatarAssets,
    importedAt: importedAt ?? DateTime.now().toUtc(),
  )..normalize();

  final archive = normalizer.archive();
  return NormalizedImportArchive(
    source: source,
    fileName: fileName,
    archiveJson: const JsonEncoder.withIndent('  ').convert(archive),
    counts: _archiveCounts(archive),
    warnings: normalizer.warnings,
  );
}

class _ExternalArchiveNormalizer {
  _ExternalArchiveNormalizer({
    required this.source,
    required this.decoded,
    required this.avatarAssets,
    required this.importedAt,
  });

  final ImportSource source;
  final Map<String, Object?> decoded;
  final List<ImportAvatarAsset> avatarAssets;
  final DateTime importedAt;
  final warnings = <String>[];
  final _memberIdsByExternalId = <String, String>{};
  final _groupIdsByExternalId = <String, String>{};

  late final List<Map<String, Object?>> members;
  late final List<Map<String, Object?>> groups;
  late final List<Map<String, Object?>> notes;
  late final List<Map<String, Object?>> messages;
  late final List<Map<String, Object?>> fronts;
  late final List<Map<String, Object?>> frontMembers;
  late final List<Map<String, Object?>> reminders;
  late final List<Map<String, Object?>> rawPayloads;

  void normalize() {
    groups = _normalizeGroups();
    _indexGroupMembers();
    members = _normalizeMembers();
    notes = _normalizeNotes();
    messages = _normalizeMessages();
    reminders = _normalizeReminders();
    final frontData = _normalizeFronts();
    fronts = frontData.fronts;
    frontMembers = frontData.frontMembers;
    rawPayloads = _normalizeRawPayloads();
  }

  Map<String, Object?> archive() => {
    'format': 'pluris_haven.local_archive',
    'version': 1,
    'exported_at': importedAt.toIso8601String(),
    'source': source.jobSource,
    'system': {
      'id': 'local-system',
      'name': _systemName(),
      'created_at': importedAt.toIso8601String(),
      'updated_at': importedAt.toIso8601String(),
    },
    'members': members,
    'groups': groups,
    'notes': notes,
    'messages': messages,
    'reminders': reminders,
    'fronts': fronts,
    'front_members': frontMembers,
    'avatar_assets': _avatarAssetsToJson(),
    'raw_payloads': rawPayloads,
    'import_records': const [],
    'notification_events': const [],
    'preferences': const [],
  };

  List<Map<String, Object?>> _avatarAssetsToJson() => [
    for (final asset in avatarAssets)
      {
        'id': asset.id,
        'name': asset.name,
        'mime_type': asset.mimeType,
        'bytes_base64': base64Encode(asset.bytes),
      },
  ];

  String _systemName() {
    final users = _firstList(decoded, const ['users']);
    final system =
        _mapValue(decoded['system']) ??
        (users.isEmpty ? null : _mapValue(users.first)) ??
        decoded;
    return _firstString(system, const [
          'name',
          'systemName',
          'system_name',
          'username',
          'tag',
        ]) ??
        'Imported system';
  }

  List<Map<String, Object?>> _normalizeMembers() {
    final items = switch (source) {
      ImportSource.tupperbox => _firstList(decoded, const ['tuppers']),
      _ => _firstList(decoded, const ['members', 'membersList', 'profiles']),
    };

    final records = <Map<String, Object?>>[];
    for (var index = 0; index < items.length; index++) {
      final member = _mapValue(items[index]);
      if (member == null) {
        continue;
      }
      final record = _memberRecord(member, index);
      if (record != null) {
        records.add(record);
      }
    }
    return records;
  }

  Map<String, Object?>? _memberRecord(Map<String, Object?> member, int index) {
    final name = _firstString(member, const [
      'display_name',
      'displayName',
      'name',
      'nick',
      'nickname',
      'tupper',
    ])?.trim();
    if (name == null || name.isEmpty) {
      warnings.add('Skipped member #${index + 1}: missing name.');
      return null;
    }

    final externalId =
        _firstString(member, const ['_id', 'id', 'uuid', 'memberId', 'uid']) ??
        _slug(name);
    final id = _stableId('member', externalId);
    _memberIdsByExternalId[externalId] = id;

    final groupExternalId = _firstString(member, const [
      'folder',
      'folderId',
      'folder_id',
      'group',
      'groupId',
      'group_id',
    ]);
    final groupId = groupExternalId == null
        ? _groupIdsByExternalId['member:$externalId']
        : _groupIdsByExternalId[groupExternalId] ??
              _stableId('group', groupExternalId);

    return {
      'id': id,
      'display_name': name,
      'pronouns': _firstString(member, const ['pronouns', 'pronoun']),
      'color_hex': _normalizeColor(
        _firstString(member, const [
          'color',
          'colour',
          'colorHex',
          'color_hex',
        ]),
      ),
      'folder_id': groupId,
      'description': _firstString(member, const [
        'description',
        'desc',
        'info',
        'bio',
        'content',
      ]),
      'avatar_url': _avatarReference(member),
      'pluralkit_id': _firstString(member, const [
        'pluralkit_id',
        'pluralKitId',
        'pkId',
        'pk_id',
        'uuid',
      ]),
      'archived': member['archived'] == true,
      'created_at': _dateString(member, const ['created_at', 'createdAt']),
      'updated_at': _dateString(member, const ['updated_at', 'updatedAt']),
    };
  }

  List<Map<String, Object?>> _normalizeGroups() {
    final items = _firstList(decoded, const ['groups', 'folders']);
    final records = <Map<String, Object?>>[];
    for (var index = 0; index < items.length; index++) {
      final group = _mapValue(items[index]);
      if (group == null) {
        continue;
      }
      final record = _groupRecord(group, index);
      if (record != null) {
        records.add(record);
      }
    }
    return records;
  }

  void _indexGroupMembers() {
    for (final groupValue in _firstList(decoded, const ['groups', 'folders'])) {
      final group = _mapValue(groupValue);
      if (group == null) {
        continue;
      }
      final groupExternalId =
          _firstString(group, const ['_id', 'id', 'uuid', 'folderId', 'uid']) ??
          _firstString(group, const ['name', 'displayName', 'title']);
      if (groupExternalId == null) {
        continue;
      }
      final groupId =
          _groupIdsByExternalId[groupExternalId] ??
          _stableId('group', groupExternalId);
      final members = group['members'];
      if (members is! List) {
        continue;
      }
      for (final member in members) {
        final memberExternalId = member is String
            ? member
            : member is Map<String, Object?>
            ? _firstString(member, const [
                '_id',
                'id',
                'uuid',
                'memberId',
                'uid',
              ])
            : null;
        if (memberExternalId != null) {
          _groupIdsByExternalId['member:$memberExternalId'] = groupId;
        }
      }
    }
  }

  Map<String, Object?>? _groupRecord(Map<String, Object?> group, int index) {
    final name = _firstString(group, const [
      'name',
      'displayName',
      'title',
    ])?.trim();
    if (name == null || name.isEmpty) {
      warnings.add('Skipped group #${index + 1}: missing name.');
      return null;
    }

    final externalId =
        _firstString(group, const ['_id', 'id', 'uuid', 'folderId', 'uid']) ??
        _slug(name);
    final id = _stableId('group', externalId);
    _groupIdsByExternalId[externalId] = id;

    final parentId = _firstString(group, const [
      'parent_group_id',
      'parentGroupId',
      'parentId',
      'parent',
    ]);

    return {
      'id': id,
      'parent_group_id': parentId == null ? null : _stableId('group', parentId),
      'name': name,
      'color_hex': _normalizeColor(
        _firstString(group, const ['color', 'colour', 'colorHex', 'color_hex']),
      ),
      'description': _firstString(group, const ['description', 'desc']),
      'emoji': _firstString(group, const ['emoji', 'icon']),
      'created_at': _dateString(group, const ['created_at', 'createdAt']),
      'updated_at': _dateString(group, const ['updated_at', 'updatedAt']),
    };
  }

  List<Map<String, Object?>> _normalizeNotes() {
    final items = _firstList(decoded, const ['notes', 'journals']);
    final records = <Map<String, Object?>>[];
    for (var index = 0; index < items.length; index++) {
      final note = _mapValue(items[index]);
      if (note == null) {
        continue;
      }
      final record = _noteRecord(note, index);
      if (record != null) {
        records.add(record);
      }
    }
    records.addAll(_normalizeCustomDefinitionsAsNotes());
    return records;
  }

  Map<String, Object?>? _noteRecord(Map<String, Object?> note, int index) {
    final body = _firstString(note, const [
      'body',
      'text',
      'content',
      'note',
    ])?.trim();
    final title = _firstString(note, const [
      'title',
      'name',
      'subject',
    ])?.trim();
    if ((body == null || body.isEmpty) && (title == null || title.isEmpty)) {
      warnings.add('Skipped note #${index + 1}: missing title and body.');
      return null;
    }

    final externalId =
        _firstString(note, const ['_id', 'id', 'uuid', 'uid']) ??
        '${title ?? 'note'}-$index';
    final memberId = _memberRef(note);

    return {
      'id': _stableId('note', externalId),
      'member_id': memberId,
      'title': title == null || title.isEmpty ? 'Imported note' : title,
      'body': body ?? '',
      'created_at': _dateString(note, const [
        'created_at',
        'createdAt',
        'date',
      ]),
      'updated_at': _dateString(note, const [
        'updated_at',
        'updatedAt',
        'date',
      ]),
    };
  }

  List<Map<String, Object?>> _normalizeMessages() {
    final items = _combinedLists(decoded, const [
      'messages',
      'chat',
      'messageBoard',
      'boardMessages',
      'chatMessages',
      'comments',
    ]);
    final records = <Map<String, Object?>>[];
    for (var index = 0; index < items.length; index++) {
      final message = _mapValue(items[index]);
      if (message == null) {
        continue;
      }
      final record = _messageRecord(message, index);
      if (record != null) {
        records.add(record);
      }
    }
    return records;
  }

  Map<String, Object?>? _messageRecord(
    Map<String, Object?> message,
    int index,
  ) {
    final body = _firstString(message, const [
      'body',
      'text',
      'content',
      'message',
      'title',
    ])?.trim();
    if (body == null || body.isEmpty) {
      warnings.add('Skipped message #${index + 1}: missing body.');
      return null;
    }

    final externalId =
        _firstString(message, const ['_id', 'id', 'uuid', 'uid']) ??
        'message-$index';
    return {
      'id': _stableId('message', externalId),
      'member_id': _memberRef(message),
      'body': _messageBody(message, body),
      'archived': message['archived'] == true,
      'created_at': _dateString(message, const [
        'created_at',
        'createdAt',
        'date',
        'writtenAt',
        'updatedAt',
        'time',
      ]),
      'updated_at': _dateString(message, const [
        'updated_at',
        'updatedAt',
        'date',
        'writtenAt',
        'lastOperationTime',
        'time',
      ]),
    };
  }

  List<Map<String, Object?>> _normalizeReminders() {
    final items = _combinedLists(decoded, const [
      'reminders',
      'alerts',
      'repeatedReminders',
      'repeatedRemidners',
      'automatedReminders',
      'queuedEvents',
    ]);
    final records = <Map<String, Object?>>[];
    for (var index = 0; index < items.length; index++) {
      final reminder = _mapValue(items[index]);
      if (reminder == null) {
        continue;
      }
      final record = _reminderRecord(reminder, index);
      if (record != null) {
        records.add(record);
      }
    }
    return records;
  }

  Map<String, Object?>? _reminderRecord(
    Map<String, Object?> reminder,
    int index,
  ) {
    final title = _firstString(reminder, const [
      'title',
      'name',
      'label',
    ])?.trim();
    final schedule = _firstString(reminder, const [
      'schedule_text',
      'scheduleText',
      'schedule',
      'frequency',
      'time',
      'dayInterval',
      'due',
      'startTime',
    ])?.trim();
    if (title == null ||
        title.isEmpty ||
        schedule == null ||
        schedule.isEmpty) {
      return null;
    }

    final externalId =
        _firstString(reminder, const ['_id', 'id', 'uuid', 'uid']) ??
        'reminder-$index';
    return {
      'id': _stableId('reminder', externalId),
      'title': title,
      'body': _firstString(reminder, const [
        'body',
        'text',
        'description',
        'message',
        'event',
      ]),
      'schedule_text': schedule,
      'enabled': reminder['enabled'] != false,
      'created_at': _dateString(reminder, const ['created_at', 'createdAt']),
      'updated_at': _dateString(reminder, const ['updated_at', 'updatedAt']),
    };
  }

  _FrontData _normalizeFronts() {
    final items = _firstList(decoded, const [
      'frontHistory',
      'fronthistory',
      'fronts',
      'switches',
    ]);
    final sessions = <Map<String, Object?>>[];
    final links = <Map<String, Object?>>[];

    for (var index = 0; index < items.length; index++) {
      final front = _mapValue(items[index]);
      if (front == null) {
        continue;
      }

      final start = _dateString(front, const [
        'started_at',
        'startedAt',
        'start',
        'startTime',
        'timestamp',
        'time',
      ]);
      if (start == null) {
        warnings.add('Skipped front #${index + 1}: missing start time.');
        continue;
      }

      final externalId =
          _firstString(front, const ['_id', 'id', 'uuid', 'uid']) ??
          'front-$index-$start';
      final id = _stableId('front', externalId);
      sessions.add({
        'id': id,
        'label': _firstString(front, const [
          'label',
          'custom',
          'name',
          'status',
          'customStatus',
          'comment',
        ]),
        'started_at': start,
        'ended_at': _dateString(front, const [
          'ended_at',
          'endedAt',
          'end',
          'endTime',
        ]),
        'created_at':
            _dateString(front, const ['created_at', 'createdAt']) ?? start,
        'updated_at':
            _dateString(front, const ['updated_at', 'updatedAt']) ?? start,
      });

      for (final memberExternalId in _frontMemberIds(front)) {
        final memberId =
            _memberIdsByExternalId[memberExternalId] ??
            _stableId('member', memberExternalId);
        links.add({'session_id': id, 'member_id': memberId});
      }
    }

    _fillMissingFrontEnds(sessions);
    return _FrontData(sessions, links);
  }

  List<String> _frontMemberIds(Map<String, Object?> front) {
    final value =
        front['members'] ??
        front['memberIds'] ??
        front['member_ids'] ??
        front['fronters'] ??
        front['member'];
    if (value is! List) {
      final single = _firstString(front, const [
        'member',
        'memberId',
        'member_id',
      ]);
      return single == null ? const [] : [single];
    }

    final ids = <String>[];
    for (final item in value) {
      if (item is String) {
        ids.add(item);
      } else if (item is Map<String, Object?>) {
        final id = _firstString(item, const [
          '_id',
          'id',
          'uuid',
          'memberId',
          'uid',
        ]);
        if (id != null) {
          ids.add(id);
        }
      }
    }
    return ids;
  }

  String? _memberRef(Map<String, Object?> object) {
    final external = _firstString(object, const [
      'member_id',
      'memberId',
      'member',
      'writtenBy',
      'writtenFor',
      'writer',
      'author',
      'authorId',
    ]);
    if (external == null) {
      return null;
    }
    return _memberIdsByExternalId[external] ?? _stableId('member', external);
  }

  void _fillMissingFrontEnds(List<Map<String, Object?>> sessions) {
    sessions.sort((a, b) {
      final left = DateTime.tryParse(a['started_at'] as String);
      final right = DateTime.tryParse(b['started_at'] as String);
      return (left ?? importedAt).compareTo(right ?? importedAt);
    });

    for (var index = 0; index < sessions.length - 1; index++) {
      if (sessions[index]['ended_at'] == null) {
        sessions[index]['ended_at'] = sessions[index + 1]['started_at'];
      }
    }
  }

  String _stableId(String kind, String externalId) =>
      '${source.jobSource}-$kind-${_slug(externalId)}';

  String? _avatarReference(Map<String, Object?> object) {
    final url = _firstString(object, const [
      'avatar_url',
      'avatarUrl',
      'avatar',
      'image',
      'imageUrl',
    ]);
    if (url != null) {
      return url;
    }

    final uuid = _firstString(object, const ['avatarUuid', 'avatar_uuid']);
    return uuid == null ? null : 'sp-avatar:$uuid';
  }

  String _messageBody(Map<String, Object?> message, String body) {
    final title = _firstString(message, const ['title']);
    final channel = _firstString(message, const ['channel', 'collection']);
    final parts = [
      if (title != null && title != body) title,
      body,
      if (channel != null) 'Source: $channel',
    ];
    return parts.join('\n');
  }

  List<Map<String, Object?>> _normalizeCustomDefinitionsAsNotes() {
    final records = <Map<String, Object?>>[];
    final fields = _firstList(decoded, const [
      'customFields',
      'custom_fields',
      'fields',
    ]);
    if (fields.isNotEmpty) {
      records.add({
        'id': _stableId('note', 'custom-fields-index'),
        'member_id': null,
        'title': 'Imported custom fields',
        'body': const JsonEncoder.withIndent('  ').convert(fields),
        'created_at': importedAt.toIso8601String(),
        'updated_at': importedAt.toIso8601String(),
      });
    }

    final customFronts = _firstList(decoded, const [
      'customFronts',
      'custom_fronts',
      'frontStatuses',
      'FrontStatuses',
    ]);
    if (customFronts.isNotEmpty) {
      records.add({
        'id': _stableId('note', 'custom-fronts-index'),
        'member_id': null,
        'title': 'Imported custom fronts',
        'body': const JsonEncoder.withIndent('  ').convert(customFronts),
        'created_at': importedAt.toIso8601String(),
        'updated_at': importedAt.toIso8601String(),
      });
    }

    for (final userValue in _firstList(decoded, const ['users'])) {
      final user = _mapValue(userValue);
      final userFields = user == null ? null : _mapValue(user['fields']);
      if (userFields == null || userFields.isEmpty) {
        continue;
      }
      final updatedAt =
          _dateString(user!, const ['lastOperationTime']) ??
          importedAt.toIso8601String();
      records.add({
        'id': _stableId('note', 'system-custom-field-values'),
        'member_id': null,
        'title': 'Imported system custom field values',
        'body': const JsonEncoder.withIndent('  ').convert(userFields),
        'created_at': updatedAt,
        'updated_at': updatedAt,
      });
    }

    for (final memberValue in _firstList(decoded, const ['members'])) {
      final member = _mapValue(memberValue);
      final info = member == null ? null : _mapValue(member['info']);
      if (member == null || info == null || info.isEmpty) {
        continue;
      }
      final externalId = _firstString(member, const [
        '_id',
        'id',
        'uuid',
        'memberId',
        'uid',
      ]);
      if (externalId == null) {
        continue;
      }
      final updatedAt =
          _dateString(member, const ['lastOperationTime']) ??
          importedAt.toIso8601String();
      records.add({
        'id': _stableId('note', 'member-custom-field-values-$externalId'),
        'member_id':
            _memberIdsByExternalId[externalId] ??
            _stableId('member', externalId),
        'title': 'Imported custom field values',
        'body': const JsonEncoder.withIndent('  ').convert(info),
        'created_at': updatedAt,
        'updated_at': updatedAt,
      });
    }

    return records;
  }

  List<Map<String, Object?>> _normalizeRawPayloads() {
    return [
      for (final entry in decoded.entries)
        if (entry.value is! List || (entry.value as List).isNotEmpty)
          {
            'id': _stableId('raw', entry.key),
            'source': source.jobSource,
            'collection': entry.key,
            'payload_json': const JsonEncoder.withIndent(
              '  ',
            ).convert(entry.value),
            'imported_at': importedAt.toIso8601String(),
          },
    ];
  }
}

class _FrontData {
  const _FrontData(this.fronts, this.frontMembers);

  final List<Map<String, Object?>> fronts;
  final List<Map<String, Object?>> frontMembers;
}

Map<String, int> _archiveCounts(Map<String, Object?> archive) => {
  'members': _listCount(archive['members']),
  'groups': _listCount(archive['groups']),
  'notes': _listCount(archive['notes']),
  'messages': _listCount(archive['messages']),
  'reminders': _listCount(archive['reminders']),
  'fronts': _listCount(archive['fronts']),
  'front_members': _listCount(archive['front_members']),
  'avatar_assets': _listCount(archive['avatar_assets']),
  'raw_payloads': _listCount(archive['raw_payloads']),
};

List<Object?> _firstList(Map<String, Object?> object, List<String> keys) {
  for (final key in keys) {
    final value = object[key];
    if (value is List) {
      return value;
    }
    if (value is Map) {
      return value.values.toList(growable: false);
    }
  }
  return const [];
}

List<Object?> _combinedLists(Map<String, Object?> object, List<String> keys) {
  return [
    for (final key in keys)
      ...switch (object[key]) {
        final List value => value,
        final Map value => value.values,
        _ => const <Object?>[],
      },
  ];
}

Map<String, Object?>? _mapValue(Object? value) =>
    value is Map<String, Object?> ? value : null;

String? _firstString(Map<String, Object?> object, List<String> keys) {
  for (final key in keys) {
    final value = object[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    if (value is num) {
      return value.toString();
    }
  }
  return null;
}

String? _dateString(Map<String, Object?> object, List<String> keys) {
  for (final key in keys) {
    final parsed = _parseDateValue(object[key]);
    if (parsed != null) {
      return parsed.toUtc().toIso8601String();
    }
  }
  return null;
}

DateTime? _parseDateValue(Object? value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (RegExp(r'^\d+$').hasMatch(trimmed)) {
      return _parseEpochNumber(num.parse(trimmed));
    }
    final parsedText = DateTime.tryParse(trimmed);
    if (parsedText != null) {
      return parsedText;
    }
    final parsedNumber = num.tryParse(trimmed);
    return parsedNumber == null ? null : _parseEpochNumber(parsedNumber);
  }
  if (value is num) {
    return _parseEpochNumber(value);
  }
  if (value is Map<String, Object?>) {
    final seconds = value['_seconds'] ?? value['seconds'] ?? value['sec'];
    if (seconds is num) {
      final nanos =
          value['_nanoseconds'] ?? value['nanoseconds'] ?? value['nanos'];
      final millis =
          seconds.toInt() * Duration.millisecondsPerSecond +
          (nanos is num ? nanos ~/ Duration.microsecondsPerSecond : 0);
      return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    }
  }
  return null;
}

DateTime? _parseEpochNumber(num value) {
  final integer = value.toInt();
  if (integer <= 0) {
    return null;
  }
  final milliseconds = integer < 100000000000 ? integer * 1000 : integer;
  return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
}

String? _normalizeColor(String? value) {
  if (value == null) {
    return null;
  }
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return trimmed.startsWith('#') ? trimmed : '#$trimmed';
}

String _slug(String value) {
  final normalized = value.trim().toLowerCase().replaceAll(
    RegExp(r'[^a-z0-9]+'),
    '-',
  );
  final trimmed = normalized.replaceAll(RegExp(r'^-+|-+$'), '');
  return trimmed.isEmpty ? 'unknown' : trimmed;
}

int _listCount(Object? value) => value is List ? value.length : 0;
