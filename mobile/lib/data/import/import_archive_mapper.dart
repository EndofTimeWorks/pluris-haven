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
  final _memberNamesByExternalId = <String, String>{};
  final _groupIdsByExternalId = <String, String>{};
  final _customFieldIdsByExternalId = <String, String>{};
  final _privacyBucketIdsByExternalId = <String, String>{};
  final _chatChannelIdsByExternalId = <String, String>{};
  final _customFieldRawTypesByExternalId = <String, Object?>{};
  final _pollOptionIdsByExternalId = <String, String>{};
  final _customFrontLabelsByExternalId = <String, String>{};
  final _frontCommentsByExternalId = <String, List<String>>{};
  final _clampReport = _ImportClampReport();

  late final List<Map<String, Object?>> members;
  late final List<Map<String, Object?>> groups;
  late final List<Map<String, Object?>> groupMembers;
  late final List<Map<String, Object?>> customFields;
  late final List<Map<String, Object?>> customFieldValues;
  late final List<Map<String, Object?>> notes;
  late final List<Map<String, Object?>> journals;
  late final List<Map<String, Object?>> messages;
  late final List<Map<String, Object?>> chatCategories;
  late final List<Map<String, Object?>> chatChannels;
  late final List<Map<String, Object?>> fronts;
  late final List<Map<String, Object?>> frontMembers;
  late final List<Map<String, Object?>> namedFronts;
  late final List<Map<String, Object?>> namedFrontMembers;
  late final List<Map<String, Object?>> reminders;
  late final List<Map<String, Object?>> polls;
  late final List<Map<String, Object?>> pollOptions;
  late final List<Map<String, Object?>> pollVotes;
  late final List<Map<String, Object?>> preferences;
  late final List<Map<String, Object?>> privacyBuckets;
  late final List<Map<String, Object?>> privacyBucketMembers;
  late final List<Map<String, Object?>> rawPayloads;

  void normalize() {
    groups = _normalizeGroups();
    _indexGroupMembers();
    _indexMemberNames();
    members = _normalizeMembers();
    final privacyData = _normalizePrivacyBuckets();
    privacyBuckets = privacyData.buckets;
    privacyBucketMembers = privacyData.members;
    groupMembers = _normalizeGroupMembers();
    customFields = _normalizeCustomFields();
    customFieldValues = _normalizeCustomFieldValues();
    notes = _normalizeNotes();
    journals = _normalizeJournals();
    final chatData = _normalizeChatStructure();
    chatCategories = chatData.categories;
    chatChannels = chatData.channels;
    messages = _normalizeMessages();
    reminders = _normalizeReminders();
    final namedFrontData = _normalizeNamedFronts();
    namedFronts = namedFrontData.namedFronts;
    namedFrontMembers = namedFrontData.namedFrontMembers;
    final pollData = _normalizePolls();
    polls = pollData.polls;
    pollOptions = pollData.pollOptions;
    pollVotes = pollData.pollVotes;
    preferences = _normalizePreferences();
    _indexFrontHistoryComments();
    final frontData = _normalizeFronts();
    fronts = frontData.fronts;
    frontMembers = frontData.frontMembers;
    rawPayloads = _normalizeRawPayloads();
    warnings.addAll(_clampReport.toWarnings());
  }

  Map<String, Object?> archive() => {
    'format': 'pluris_haven.local_archive',
    'version': 1,
    'exported_at': importedAt.toIso8601String(),
    'source': source.jobSource,
    'system': _systemRecord(),
    'members': members,
    'groups': groups,
    'group_members': groupMembers,
    'custom_fields': customFields,
    'custom_field_values': customFieldValues,
    'notes': notes,
    'chat_categories': chatCategories,
    'chat_channels': chatChannels,
    'messages': messages,
    'reminders': reminders,
    'tags': const [],
    'member_tags': const [],
    'journals': journals,
    'content_revisions': const [],
    'polls': polls,
    'poll_options': pollOptions,
    'poll_votes': pollVotes,
    'poll_vote_events': const [],
    'fronts': fronts,
    'front_members': frontMembers,
    'front_audit_events': const [],
    'named_fronts': namedFronts,
    'named_front_members': namedFrontMembers,
    'privacy_buckets': privacyBuckets,
    'privacy_bucket_members': privacyBucketMembers,
    'avatar_assets': _avatarAssetsToJson(),
    'raw_payloads': rawPayloads,
    'import_records': const [],
    'notification_events': const [],
    'preferences': preferences,
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

  Map<String, Object?> _systemRecord() {
    final system = _systemSource();
    final name =
        _firstString(system, const [
          'name',
          'systemName',
          'system_name',
          'username',
          'tag',
        ]) ??
        'Imported system';
    return {
      'id': 'local-system',
      'name': _clamp(name, _capSystemName)!,
      'color_hex': _normalizeColor(
        _firstString(system, const [
          'color',
          'colour',
          'colorHex',
          'color_hex',
        ]),
      ),
      'avatar_url': _clamp(_systemAvatarReference(system), _capAvatarUrl),
      'description': _clamp(
        _firstString(system, const ['description', 'desc', 'bio']),
        _capMemberDescription,
      ),
      'created_at': importedAt.toIso8601String(),
      'updated_at': importedAt.toIso8601String(),
    };
  }

  Map<String, Object?> _systemSource() {
    final users = _firstList(decoded, const ['users']);
    return _mapValue(decoded['system']) ??
        (users.isEmpty ? null : _mapValue(users.first)) ??
        decoded;
  }

  String? _systemAvatarReference(Map<String, Object?> system) {
    final ownerId = _firstString(system, const ['uid', '_id', 'id']);
    if (ownerId != null && avatarAssets.any((asset) => asset.id == ownerId)) {
      return 'sp-avatar:$ownerId';
    }
    return _avatarReference(system);
  }

  String? _clamp(String? value, _ImportTextCap cap) =>
      _clampReport.string(value, cap);

  List<T> _clampList<T>(List<T> items, _ImportTextCap cap) =>
      _clampReport.list(items, cap);

  List<Map<String, Object?>> _normalizeMembers() {
    final items = switch (source) {
      ImportSource.tupperbox => _firstList(decoded, const ['tuppers']),
      _ => _firstList(decoded, const ['members', 'membersList', 'profiles']),
    };

    final records = <Map<String, Object?>>[];
    for (var index = 0; index < items.length; index++) {
      final member = _mapValue(items[index]);
      if (member == null) {
        warnings.add('Skipped member #${index + 1}: expected an object.');
        continue;
      }
      if (source == ImportSource.simplyPlural &&
          _isSimplyPluralCustomFrontRecord(member)) {
        continue;
      }
      final record = _memberRecord(member, index);
      if (record != null) {
        records.add(record);
      }
    }
    return records;
  }

  _PrivacyBucketData _normalizePrivacyBuckets() {
    if (source != ImportSource.simplyPlural) {
      return const _PrivacyBucketData([], []);
    }
    final sourceBuckets = _firstList(decoded, const ['privacyBuckets']);
    final buckets = <Map<String, Object?>>[];
    for (var index = 0; index < sourceBuckets.length; index++) {
      final bucket = _mapValue(sourceBuckets[index]);
      if (bucket == null) continue;
      final externalId = _firstString(bucket, const ['_id', 'id', 'uuid']);
      final name = _firstString(bucket, const ['name'])?.trim();
      if (externalId == null || name == null || name.isEmpty) {
        warnings.add(
          'Skipped privacy bucket #${index + 1}: missing ID or name.',
        );
        continue;
      }
      final id = _stableId('privacy-bucket', externalId);
      _privacyBucketIdsByExternalId[externalId] = id;
      buckets.add({
        'id': id,
        'name': name,
        'description': _firstString(bucket, const ['desc', 'description']),
        'color_hex': _normalizeColor(
          _firstString(bucket, const ['color', 'color_hex']),
        ),
        'position': index,
        'created_at': importedAt.toIso8601String(),
        'updated_at': importedAt.toIso8601String(),
      });
    }

    final links = <Map<String, Object?>>[];
    final sourceMembers = _firstList(decoded, const ['members']);
    for (final value in sourceMembers) {
      final member = _mapValue(value);
      if (member == null) continue;
      final externalMemberId = _firstString(member, const [
        '_id',
        'id',
        'uuid',
        'memberId',
        'uid',
      ]);
      final memberId = externalMemberId == null
          ? null
          : _memberIdsByExternalId[externalMemberId];
      if (memberId == null) continue;
      for (final bucketId in _memberRefsFromValue(member['buckets'])) {
        final localBucketId = _privacyBucketIdsByExternalId[bucketId];
        if (localBucketId != null) {
          links.add({'bucket_id': localBucketId, 'member_id': memberId});
        }
      }
    }
    return _PrivacyBucketData(buckets, links);
  }

  void _indexMemberNames() {
    final items = switch (source) {
      ImportSource.tupperbox => _firstList(decoded, const ['tuppers']),
      _ => _firstList(decoded, const ['members', 'membersList', 'profiles']),
    };
    for (final item in items) {
      final member = _mapValue(item);
      if (member == null) {
        continue;
      }
      final name = _firstString(member, const [
        'display_name',
        'displayName',
        'name',
        'nick',
        'nickname',
        'tupper',
      ])?.trim();
      if (name == null || name.isEmpty) {
        continue;
      }
      final externalId =
          _firstString(member, const [
            '_id',
            'id',
            'uuid',
            'memberId',
            'uid',
          ]) ??
          _slug(name);
      _memberNamesByExternalId[externalId] = name;
    }
  }

  Map<String, Object?>? _memberRecord(
    Map<String, Object?> member,
    int index, {
    bool isCustomFront = false,
  }) {
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
    final displayName = _clamp(name, _capMemberName)!;

    final externalId =
        _firstString(member, const ['_id', 'id', 'uuid', 'memberId', 'uid']) ??
        _slug(name);
    final id = _stableId('member', externalId);
    _memberIdsByExternalId[externalId] = id;
    _memberNamesByExternalId[externalId] = displayName;

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
        : _groupIdsByExternalId[groupExternalId];
    if (groupExternalId != null && groupId == null) {
      warnings.add('Member "$name" ignored missing group "$groupExternalId".');
    }

    return {
      'id': id,
      'display_name': displayName,
      'pronouns': _clamp(
        _firstString(member, const ['pronouns', 'pronoun']),
        _capMemberPronouns,
      ),
      'color_hex': _normalizeColor(
        _firstString(member, const [
          'color',
          'colour',
          'colorHex',
          'color_hex',
        ]),
      ),
      'birthday': _clamp(
        _firstString(member, const [
          'birthday',
          'birthdate',
          'birth_date',
          'birthDay',
        ]),
        _capMemberBirthday,
      ),
      'emoji': _clamp(
        _firstString(member, const ['emoji', 'proxyTag', 'proxy_tag']),
        _capMemberEmoji,
      ),
      'privacy': _firstString(member, const [
        'privacy',
        'private',
        'privacyBucket',
        'privacy_bucket',
      ]),
      'folder_id': groupId,
      'description': _clamp(
        _replaceMemberPlaceholders(
          _firstString(member, const [
            'description',
            'desc',
            'info',
            'bio',
            'content',
          ]),
        ),
        _capMemberDescription,
      ),
      'avatar_url': _clamp(_avatarReference(member), _capAvatarUrl),
      'pluralkit_id': _firstString(member, const [
        'pluralkit_id',
        'pluralKitId',
        'pkId',
        'pk_id',
        'uuid',
      ]),
      'archived': member['archived'] == true,
      'is_custom_front': isCustomFront || member['is_custom_front'] == true,
      'created_at': _dateString(member, const ['created_at', 'createdAt']),
      'updated_at': _dateString(member, const ['updated_at', 'updatedAt']),
    };
  }

  _NamedFrontData _normalizeNamedFronts() {
    final namedFronts = <Map<String, Object?>>[];
    final namedFrontMembers = <Map<String, Object?>>[];
    if (source != ImportSource.simplyPlural) {
      return const _NamedFrontData([], []);
    }

    final items = _simplyPluralCustomFrontItems();
    final seenExternalIds = <String>{};
    for (var index = 0; index < items.length; index++) {
      final customFront = _mapValue(items[index]);
      if (customFront == null) {
        warnings.add('Skipped custom front #${index + 1}: expected an object.');
        continue;
      }
      final label = _firstString(customFront, const [
        'display_name',
        'displayName',
        'label',
        'name',
        'status',
        'customStatus',
        'custom_status',
      ])?.trim();
      if (label == null || label.isEmpty) {
        warnings.add('Skipped custom front #${index + 1}: missing label.');
        continue;
      }
      final name = _clamp(label, _capMemberName)!;

      final externalId =
          _firstString(customFront, const ['_id', 'id', 'uuid', 'uid']) ??
          _slug(label);
      if (!seenExternalIds.add(externalId)) {
        continue;
      }
      final id = _stableId('named-front', externalId);
      _customFrontLabelsByExternalId[externalId] = name;
      namedFronts.add({
        'id': id,
        'name': name,
        'custom_label': name,
        'color_hex': _normalizeColor(
          _firstString(customFront, const [
            'color',
            'colour',
            'colorHex',
            'color_hex',
          ]),
        ),
        'avatar_url': _clamp(_avatarReference(customFront), _capAvatarUrl),
        'description': _clamp(
          _replaceMemberPlaceholders(
            _firstString(customFront, const [
              'description',
              'desc',
              'message',
              'note',
            ]),
          ),
          _capMemberDescription,
        ),
        'created_at': _dateString(customFront, const [
          'created_at',
          'createdAt',
          'lastOperationTime',
        ]),
        'updated_at': _dateString(customFront, const [
          'updated_at',
          'updatedAt',
          'lastOperationTime',
        ]),
      });

      final memberRefs = _rawMemberRefs(customFront);
      for (final memberExternalId in memberRefs) {
        final memberId = _memberIdsByExternalId[memberExternalId];
        if (memberId == null) {
          continue;
        }
        namedFrontMembers.add({'named_front_id': id, 'member_id': memberId});
      }
    }

    return _NamedFrontData(namedFronts, namedFrontMembers);
  }

  List<Object?> _simplyPluralCustomFrontItems() {
    final explicit = _combinedLists(decoded, const [
      'customFronts',
      'custom_fronts',
      'frontStatuses',
      'FrontStatuses',
    ]);
    final memberLike = <Map<String, Object?>>[];
    for (final value in _firstList(decoded, const [
      'members',
      'membersList',
      'profiles',
    ])) {
      final object = _mapValue(value);
      if (object != null && _isSimplyPluralCustomFrontRecord(object)) {
        memberLike.add(object);
      }
    }
    return [...explicit, ...memberLike];
  }

  bool _isSimplyPluralCustomFrontRecord(Map<String, Object?> object) {
    return object['is_custom_front'] == true ||
        object['isCustomFront'] == true ||
        object['custom_front'] == true ||
        object['customFront'] == true ||
        object['front_status'] == true ||
        object['frontStatus'] == true ||
        object['custom'] == true;
  }

  List<Map<String, Object?>> _normalizeCustomFields() {
    final items = _firstList(decoded, const [
      'customFields',
      'custom_fields',
      'fields',
    ]);
    final records = <Map<String, Object?>>[];
    for (var index = 0; index < items.length; index++) {
      final field = _mapValue(items[index]);
      if (field == null) {
        warnings.add('Skipped custom field #${index + 1}: expected an object.');
        continue;
      }
      final name = _firstString(field, const [
        'name',
        'label',
        'title',
      ])?.trim();
      if (name == null || name.isEmpty) {
        warnings.add('Skipped custom field #${index + 1}: missing name.');
        continue;
      }
      final clampedName = _clamp(name, _capCustomFieldName)!;
      final externalId =
          _firstString(field, const ['_id', 'id', 'uuid', 'fieldId']) ??
          _slug(name);
      final id = _stableId('custom-field', externalId);
      final rawType = field['type'] ?? field['field_type'];
      _customFieldIdsByExternalId[externalId] = id;
      _customFieldRawTypesByExternalId[externalId] = rawType;
      records.add({
        'id': id,
        'name': clampedName,
        'field_type': _customFieldType(rawType),
        'privacy': _firstString(field, const ['privacy', 'private', 'bucket']),
        'position':
            _intValue(field['order']) ?? _intValue(field['position']) ?? index,
        'created_at': _dateString(field, const ['created_at', 'createdAt']),
        'updated_at': _dateString(field, const ['updated_at', 'updatedAt']),
      });
    }
    return records;
  }

  List<Map<String, Object?>> _normalizeCustomFieldValues() {
    final records = <Map<String, Object?>>[];
    for (final userValue in _firstList(decoded, const ['users'])) {
      final user = _mapValue(userValue);
      final fields = user == null ? null : _mapValue(user['fields']);
      if (fields == null || fields.isEmpty) {
        continue;
      }
      records.addAll(
        _customFieldValueRecords(
          fields,
          ownerExternalId: 'system',
          memberId: null,
          updatedAt: _dateString(user!, const ['lastOperationTime']),
        ),
      );
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
      records.addAll(
        _customFieldValueRecords(
          info,
          ownerExternalId: externalId,
          memberId: _memberIdsByExternalId[externalId],
          updatedAt: _dateString(member, const ['lastOperationTime']),
        ),
      );
    }
    return records;
  }

  List<Map<String, Object?>> _customFieldValueRecords(
    Map<String, Object?> values, {
    required String ownerExternalId,
    required String? memberId,
    required String? updatedAt,
  }) {
    final records = <Map<String, Object?>>[];
    for (final entry in values.entries) {
      final fieldId = _customFieldIdsByExternalId[entry.key];
      if (fieldId == null || entry.value == null) {
        continue;
      }
      records.add({
        'id': _stableId('custom-field-value', '$ownerExternalId-${entry.key}'),
        'field_id': fieldId,
        'member_id': memberId,
        'value': _customFieldValueForField(entry.key, entry.value),
        'created_at': updatedAt,
        'updated_at': updatedAt,
      });
    }
    return records;
  }

  String _customFieldValueForField(String fieldExternalId, Object? value) {
    final rawType = _customFieldRawTypesByExternalId[fieldExternalId];
    final textValue = _customFieldValue(value);
    final normalizedType = rawType?.toString().trim().toLowerCase();
    if (rawType == 1 || normalizedType == 'color') {
      return _normalizeColor(textValue) ?? textValue;
    }
    if (rawType == 2 ||
        rawType == 3 ||
        rawType == 4 ||
        rawType == 5 ||
        rawType == 6 ||
        rawType == 7 ||
        normalizedType == 'date' ||
        normalizedType == 'datetime' ||
        normalizedType == 'timestamp') {
      return _parseDateValue(value)?.toUtc().toIso8601String() ?? textValue;
    }
    return _clamp(
      _replaceMemberPlaceholders(textValue) ?? textValue,
      _capCustomFieldValue,
    )!;
  }

  List<Map<String, Object?>> _normalizeGroups() {
    final items = _firstList(decoded, const ['groups', 'folders']);
    for (final item in items) {
      final group = _mapValue(item);
      if (group == null) {
        continue;
      }
      final externalId =
          _firstString(group, const ['_id', 'id', 'uuid', 'folderId', 'uid']) ??
          _firstString(group, const ['name', 'displayName', 'title']);
      if (externalId != null) {
        _groupIdsByExternalId.putIfAbsent(
          externalId,
          () => _stableId('group', externalId),
        );
      }
    }

    final records = <Map<String, Object?>>[];
    for (var index = 0; index < items.length; index++) {
      final group = _mapValue(items[index]);
      if (group == null) {
        warnings.add('Skipped group #${index + 1}: expected an object.');
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

  List<Map<String, Object?>> _normalizeGroupMembers() {
    final links = <Map<String, Object?>>[];
    final seen = <String>{};

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
      final groupId = _groupIdsByExternalId[groupExternalId];
      if (groupId == null) {
        continue;
      }
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
        if (memberExternalId == null) {
          continue;
        }
        final memberId = _memberIdsByExternalId[memberExternalId];
        if (memberId == null) {
          warnings.add(
            'Group "$groupExternalId" ignored missing member "$memberExternalId".',
          );
          continue;
        }
        final key = '$groupId::$memberId';
        if (seen.add(key)) {
          links.add({'group_id': groupId, 'member_id': memberId});
        }
      }
    }

    for (final member in members) {
      final groupId = _firstString(member, const ['folder_id']);
      final memberId = _firstString(member, const ['id']);
      if (groupId == null || memberId == null) {
        continue;
      }
      final key = '$groupId::$memberId';
      if (seen.add(key)) {
        links.add({'group_id': groupId, 'member_id': memberId});
      }
    }

    return links;
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
    final clampedName = _clamp(name, _capGroupName)!;

    final externalId =
        _firstString(group, const ['_id', 'id', 'uuid', 'folderId', 'uid']) ??
        _slug(name);
    final id =
        _groupIdsByExternalId[externalId] ?? _stableId('group', externalId);
    _groupIdsByExternalId[externalId] = id;

    final parentId = _firstString(group, const [
      'parent_group_id',
      'parentGroupId',
      'parentId',
      'parent',
    ]);

    final normalizedParentId = parentId == 'root' ? null : parentId;
    final parentGroupId = normalizedParentId == null
        ? null
        : _groupIdsByExternalId[normalizedParentId];
    if (normalizedParentId != null && parentGroupId == null) {
      warnings.add(
        'Group "$name" ignored missing parent "$normalizedParentId".',
      );
    }

    return {
      'id': id,
      'parent_group_id': parentGroupId,
      'name': clampedName,
      'color_hex': _normalizeColor(
        _firstString(group, const ['color', 'colour', 'colorHex', 'color_hex']),
      ),
      'description': _clamp(
        _replaceMemberPlaceholders(
          _firstString(group, const ['description', 'desc']),
        ),
        _capLongText,
      ),
      'emoji': _clamp(
        _firstString(group, const ['emoji', 'icon']),
        _capMemberEmoji,
      ),
      'created_at': _dateString(group, const ['created_at', 'createdAt']),
      'updated_at': _dateString(group, const ['updated_at', 'updatedAt']),
    };
  }

  List<Map<String, Object?>> _normalizeNotes() {
    final items = _firstList(decoded, const ['notes']);
    final records = <Map<String, Object?>>[];
    for (var index = 0; index < items.length; index++) {
      final note = _mapValue(items[index]);
      if (note == null) {
        warnings.add('Skipped note #${index + 1}: expected an object.');
        continue;
      }
      final record = _noteRecord(note, index);
      if (record != null) {
        records.add(record);
      }
    }
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
      'title': _clamp(
        _replaceMemberPlaceholders(
          title == null || title.isEmpty ? 'Imported note' : title,
        ),
        _capContentTitle,
      ),
      'body':
          _clamp(_replaceMemberPlaceholders(body) ?? '', _capLongText) ?? '',
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

  List<Map<String, Object?>> _normalizeJournals() {
    final items = _combinedLists(decoded, const [
      'journals',
      'journalEntries',
      'journal_entries',
    ]);
    final records = <Map<String, Object?>>[];
    for (var index = 0; index < items.length; index++) {
      final journal = _mapValue(items[index]);
      if (journal == null) {
        warnings.add('Skipped journal #${index + 1}: expected an object.');
        continue;
      }
      final record = _journalRecord(journal, index);
      if (record != null) {
        records.add(record);
      }
    }
    return records;
  }

  Map<String, Object?>? _journalRecord(
    Map<String, Object?> journal,
    int index,
  ) {
    final body = _firstString(journal, const [
      'body',
      'text',
      'content',
      'note',
      'entry',
    ])?.trim();
    final title = _firstString(journal, const [
      'title',
      'name',
      'subject',
    ])?.trim();
    if ((body == null || body.isEmpty) && (title == null || title.isEmpty)) {
      warnings.add('Skipped journal #${index + 1}: missing title and body.');
      return null;
    }

    final externalId =
        _firstString(journal, const ['_id', 'id', 'uuid', 'uid']) ??
        '${title ?? 'journal'}-$index';

    return {
      'id': _stableId('journal', externalId),
      'member_id': _memberRef(journal),
      'title': _clamp(
        _replaceMemberPlaceholders(
          title == null || title.isEmpty ? 'Imported journal' : title,
        ),
        _capContentTitle,
      ),
      'body':
          _clamp(_replaceMemberPlaceholders(body) ?? '', _capJournalBody) ?? '',
      'visibility':
          _firstString(journal, const ['visibility', 'privacy']) ?? 'system',
      'created_at': _dateString(journal, const [
        'created_at',
        'createdAt',
        'date',
        'writtenAt',
      ]),
      'updated_at': _dateString(journal, const [
        'updated_at',
        'updatedAt',
        'date',
        'writtenAt',
      ]),
    };
  }

  ({List<Map<String, Object?>> categories, List<Map<String, Object?>> channels})
  _normalizeChatStructure() {
    final channelItems = _combinedLists(decoded, const [
      'channels',
      'chatChannels',
    ]);
    final channels = <Map<String, Object?>>[];
    final channelsByExternalId = <String, Map<String, Object?>>{};
    for (var index = 0; index < channelItems.length; index++) {
      final channel = _mapValue(channelItems[index]);
      if (channel == null) {
        warnings.add('Skipped chat channel #${index + 1}: expected an object.');
        continue;
      }
      final name = _firstString(channel, const ['name', 'title'])?.trim();
      if (name == null || name.isEmpty) {
        warnings.add('Skipped chat channel #${index + 1}: missing name.');
        continue;
      }
      final externalId =
          _firstString(channel, const ['_id', 'id', 'uuid', 'uid']) ??
          'chat-channel-$index';
      final id = _stableId('chat-channel', externalId);
      _chatChannelIdsByExternalId[externalId] = id;
      final record = <String, Object?>{
        'id': id,
        'category_id': null,
        'name': _clamp(name, _capContentTitle),
        'description': _clamp(
          _firstString(channel, const ['desc', 'description']),
          _capJournalBody,
        ),
        'color_hex': _firstString(channel, const ['color', 'colorHex']),
        'position': index,
        'created_at': _dateString(channel, const [
          'created_at',
          'createdAt',
          'lastOperationTime',
        ]),
        'updated_at': _dateString(channel, const [
          'updated_at',
          'updatedAt',
          'lastOperationTime',
        ]),
      };
      channels.add(record);
      channelsByExternalId[externalId] = record;
    }

    final categoryItems = _combinedLists(decoded, const [
      'channelCategories',
      'chatCategories',
    ]);
    final categories = <Map<String, Object?>>[];
    for (var index = 0; index < categoryItems.length; index++) {
      final category = _mapValue(categoryItems[index]);
      if (category == null) {
        warnings.add(
          'Skipped chat category #${index + 1}: expected an object.',
        );
        continue;
      }
      final name = _firstString(category, const ['name', 'title'])?.trim();
      if (name == null || name.isEmpty) {
        warnings.add('Skipped chat category #${index + 1}: missing name.');
        continue;
      }
      final externalId =
          _firstString(category, const ['_id', 'id', 'uuid', 'uid']) ??
          'chat-category-$index';
      final id = _stableId('chat-category', externalId);
      categories.add({
        'id': id,
        'name': _clamp(name, _capContentTitle),
        'description': _clamp(
          _firstString(category, const ['desc', 'description']),
          _capJournalBody,
        ),
        'position': index,
        'created_at': _dateString(category, const [
          'created_at',
          'createdAt',
          'lastOperationTime',
        ]),
        'updated_at': _dateString(category, const [
          'updated_at',
          'updatedAt',
          'lastOperationTime',
        ]),
      });
      final refs = _firstList(category, const ['channels', 'channelIds']);
      for (var channelIndex = 0; channelIndex < refs.length; channelIndex++) {
        final ref = refs[channelIndex]?.toString();
        final channel = ref == null ? null : channelsByExternalId[ref];
        if (channel == null) {
          if (ref != null) {
            warnings.add(
              'Ignored missing chat channel reference "$ref" in "$name".',
            );
          }
          continue;
        }
        channel['category_id'] = id;
        channel['position'] = channelIndex;
      }
    }
    return (categories: categories, channels: channels);
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
        warnings.add('Skipped message #${index + 1}: expected an object.');
        continue;
      }
      if (_isFrontHistoryComment(message)) {
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
    final channelExternalId = _firstString(message, const [
      'channel_id',
      'channelId',
      'channel',
    ]);
    final parentExternalId = _firstString(message, const [
      'parent_message_id',
      'parentMessageId',
      'replyTo',
    ]);
    return {
      'id': _stableId('message', externalId),
      'member_id': _memberRef(message),
      'body':
          _clamp(
            _replaceMemberPlaceholders(_messageBody(message, body)) ?? '',
            _capMessageBody,
          ) ??
          '',
      'archived': message['archived'] == true,
      'board_kind': channelExternalId == null ? 'system' : 'channel',
      'channel_id': channelExternalId == null
          ? null
          : _chatChannelIdsByExternalId[channelExternalId],
      'parent_message_id': parentExternalId == null
          ? null
          : _stableId('message', parentExternalId),
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
        warnings.add('Skipped reminder #${index + 1}: expected an object.');
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
      warnings.add(
        'Skipped reminder #${index + 1}: missing title or schedule.',
      );
      return null;
    }
    final structuredSchedule = _structuredReminderSchedule(reminder, schedule);

    final externalId =
        _firstString(reminder, const ['_id', 'id', 'uuid', 'uid']) ??
        'reminder-$index';
    return {
      'id': _stableId('reminder', externalId),
      'title': _clamp(title, _capReminderTitle),
      'body': _clamp(
        _replaceMemberPlaceholders(
          _firstString(reminder, const [
            'body',
            'text',
            'description',
            'message',
            'event',
          ]),
        ),
        _capReminderBody,
      ),
      'schedule_text': _clamp(schedule, _capReminderSchedule),
      'schedule_kind': structuredSchedule.kind,
      'schedule_time': structuredSchedule.time,
      'schedule_dow_mask': structuredSchedule.dowMask,
      'schedule_dom': structuredSchedule.dom,
      'enabled': reminder['enabled'] != false,
      'created_at': _dateString(reminder, const ['created_at', 'createdAt']),
      'updated_at': _dateString(reminder, const ['updated_at', 'updatedAt']),
    };
  }

  _ReminderScheduleFields _structuredReminderSchedule(
    Map<String, Object?> reminder,
    String schedule,
  ) {
    final explicitKind = _firstString(reminder, const [
      'schedule_kind',
      'scheduleKind',
      'kind',
      'frequency',
    ])?.toLowerCase();
    final scheduleLower = schedule.toLowerCase();
    final kind = switch (explicitKind) {
      'daily' => 'daily',
      'weekly' => 'weekly',
      'monthly' => 'monthly',
      'after_front' ||
      'after-front' ||
      'fronting' ||
      'member_front' => 'after_front',
      _ when scheduleLower.startsWith('daily') => 'daily',
      _ when scheduleLower.startsWith('weekly') => 'weekly',
      _ when scheduleLower.startsWith('monthly') => 'monthly',
      _ when scheduleLower.startsWith('after') => 'after_front',
      _ => null,
    };
    final time =
        _firstString(reminder, const ['schedule_time', 'scheduleTime']) ??
        _timeFromScheduleText(schedule);
    final weekday =
        _intValue(reminder['weekday']) ??
        _intValue(reminder['dayOfWeek']) ??
        _weekdayFromScheduleText(schedule);
    final dom =
        _intValue(reminder['schedule_dom']) ??
        _intValue(reminder['scheduleDom']) ??
        _intValue(reminder['dayOfMonth']) ??
        _monthDayFromScheduleText(schedule);

    return _ReminderScheduleFields(
      kind: kind,
      time: time,
      dowMask: kind == 'weekly' && weekday != null
          ? 1 << (weekday.clamp(1, 7) - 1)
          : _intValue(reminder['schedule_dow_mask']) ??
                _intValue(reminder['scheduleDowMask']),
      dom: kind == 'monthly' && dom != null ? dom.clamp(1, 31) : null,
    );
  }

  _PollData _normalizePolls() {
    final items = _firstList(decoded, const ['polls', 'pollList', 'votes']);
    final pollRecords = <Map<String, Object?>>[];
    final optionRecords = <Map<String, Object?>>[];
    final voteRecords = <Map<String, Object?>>[];
    final voteKeys = <String>{};

    for (var index = 0; index < items.length; index++) {
      final poll = _mapValue(items[index]);
      if (poll == null) {
        warnings.add('Skipped poll #${index + 1}: expected an object.');
        continue;
      }

      final question = _firstString(poll, const [
        'question',
        'prompt',
        'title',
        'name',
        'body',
      ])?.trim();
      if (question == null || question.isEmpty) {
        warnings.add('Skipped poll #${index + 1}: missing question.');
        continue;
      }

      final externalId =
          _firstString(poll, const ['_id', 'id', 'uuid', 'pollId', 'uid']) ??
          _slug(question);
      final id = _stableId('poll', externalId);
      final options = _pollOptionRecords(poll, id, externalId);
      if (options.length < 2) {
        warnings.add(
          'Skipped poll "$question": fewer than two usable options.',
        );
        continue;
      }

      pollRecords.add({
        'id': id,
        'question': _clamp(
          _replaceMemberPlaceholders(question) ?? question,
          _capPollQuestion,
        ),
        'description': _clamp(
          _replaceMemberPlaceholders(
            _firstString(poll, const [
              'description',
              'desc',
              'details',
              'note',
            ]),
          ),
          _capPollDescription,
        ),
        'kind': _pollKind(poll),
        'closed':
            _boolValue(poll['closed']) ??
            _boolValue(poll['ended']) ??
            _dateString(poll, const ['closedAt', 'endedAt']) != null,
        'created_at':
            _dateString(poll, const ['created_at', 'createdAt', 'date']) ??
            importedAt.toIso8601String(),
        'updated_at':
            _dateString(poll, const [
              'updated_at',
              'updatedAt',
              'lastOperationTime',
              'date',
            ]) ??
            importedAt.toIso8601String(),
      });
      optionRecords.addAll(options);
      voteRecords.addAll(_pollVoteRecords(poll, id, externalId, voteKeys));
    }

    return _PollData(pollRecords, optionRecords, voteRecords);
  }

  List<Map<String, Object?>> _pollOptionRecords(
    Map<String, Object?> poll,
    String pollId,
    String pollExternalId,
  ) {
    final rawOptions =
        poll['options'] ?? poll['choices'] ?? poll['answers'] ?? poll['items'];
    final values = switch (rawOptions) {
      final List list => list.cast<Object?>(),
      final Map map => map.values.toList(growable: false),
      _ => const <Object?>[],
    };
    final cappedValues = _clampList<Object?>(values, _capPollOptionList);

    final records = <Map<String, Object?>>[];
    for (var index = 0; index < cappedValues.length; index++) {
      final value = cappedValues[index];
      final body = switch (value) {
        final String text => text.trim(),
        final num number => number.toString(),
        final Map<String, Object?> option => _firstString(option, const [
          'body',
          'text',
          'label',
          'name',
          'title',
          'option',
          'value',
        ])?.trim(),
        _ => null,
      };
      if (body == null || body.isEmpty) {
        continue;
      }

      final optionExternalId = value is Map<String, Object?>
          ? _firstString(value, const ['_id', 'id', 'uuid', 'optionId'])
          : null;
      final stableExternalId = optionExternalId ?? '$pollExternalId-$index';
      final id = _stableId('poll-option', stableExternalId);
      _pollOptionIdsByExternalId[stableExternalId] = id;
      if (optionExternalId != null) {
        _pollOptionIdsByExternalId[optionExternalId] = id;
      }

      records.add({
        'id': id,
        'poll_id': pollId,
        'body': _clamp(
          _replaceMemberPlaceholders(body) ?? body,
          _capPollOption,
        ),
        'position':
            _intValue(
              value is Map<String, Object?>
                  ? value['position'] ?? value['order']
                  : null,
            ) ??
            index,
      });
    }
    return records;
  }

  List<Map<String, Object?>> _pollVoteRecords(
    Map<String, Object?> poll,
    String pollId,
    String pollExternalId,
    Set<String> voteKeys,
  ) {
    final records = <Map<String, Object?>>[];
    void addVote(String? externalOptionId, Object? createdAt) {
      if (externalOptionId == null) {
        return;
      }
      final optionId =
          _pollOptionIdsByExternalId[externalOptionId] ??
          _pollOptionIdsByExternalId['$pollExternalId-$externalOptionId'];
      if (optionId == null) {
        return;
      }
      final key = '$pollId/$optionId';
      if (!voteKeys.add(key)) {
        return;
      }
      records.add({
        'poll_id': pollId,
        'option_id': optionId,
        'created_at':
            _parseDateValue(createdAt)?.toUtc().toIso8601String() ??
            importedAt.toIso8601String(),
      });
    }

    final rawOptions =
        poll['options'] ?? poll['choices'] ?? poll['answers'] ?? poll['items'];
    final optionValues = switch (rawOptions) {
      final List list => list,
      final Map map => map.values.toList(growable: false),
      _ => const <Object?>[],
    };
    for (var index = 0; index < optionValues.length; index++) {
      final option = _mapValue(optionValues[index]);
      if (option == null) {
        continue;
      }
      final selected =
          _boolValue(option['selected']) ??
          _boolValue(option['voted']) ??
          ((_intValue(option['votes']) ?? _intValue(option['voteCount']) ?? 0) >
              0);
      if (selected) {
        addVote(
          _firstString(option, const ['_id', 'id', 'uuid', 'optionId']) ??
              '$pollExternalId-$index',
          option['votedAt'] ?? option['updatedAt'] ?? poll['updatedAt'],
        );
      }
    }

    final rawVotes = poll['votes'] ?? poll['responses'] ?? poll['results'];
    final voteValues = switch (rawVotes) {
      final List list => list,
      final Map map => map.values.toList(growable: false),
      _ => const <Object?>[],
    };
    for (final vote in voteValues) {
      if (vote is String || vote is num) {
        addVote(vote.toString(), poll['updatedAt']);
      } else if (vote is Map<String, Object?>) {
        addVote(
          _firstString(vote, const [
            'option_id',
            'optionId',
            'option',
            'choice',
            'choiceId',
            'answer',
          ]),
          vote['created_at'] ?? vote['createdAt'] ?? vote['date'],
        );
      }
    }
    return records;
  }

  String _pollKind(Map<String, Object?> poll) {
    final multi =
        _boolValue(poll['multiple']) ??
        _boolValue(poll['multiChoice']) ??
        _boolValue(poll['allowMultiple']) ??
        _boolValue(poll['multipleChoice']);
    if (multi == true) {
      return 'multiple_choice';
    }
    final raw = _firstString(poll, const ['kind', 'type', 'mode']);
    final normalized = raw?.trim().toLowerCase().replaceAll('-', '_');
    return switch (normalized) {
      'multiple' || 'multi' || 'multiple_choice' => 'multiple_choice',
      _ => 'single_choice',
    };
  }

  List<Map<String, Object?>> _normalizePreferences() {
    Map<String, Object?>? user;
    for (final value in _firstList(decoded, const ['users'])) {
      user = _mapValue(value);
      if (user != null) {
        break;
      }
    }
    final settings = _mapValue(decoded['settings']);
    final color = _normalizeColor(
      _firstString(settings ?? const {}, const [
            'color',
            'accentColor',
            'accent_color',
          ]) ??
          _firstString(user ?? const {}, const [
            'color',
            'accentColor',
            'accent_color',
          ]),
    );
    if (color == null) {
      return const [];
    }
    return [
      {
        'key': 'custom_accent_hex',
        'value': color,
        'updated_at': importedAt.toIso8601String(),
      },
    ];
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
        warnings.add('Skipped front #${index + 1}: expected an object.');
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
      final memberIds = _frontMemberIds(front);
      final label =
          _frontLabel(front) ??
          (source == ImportSource.pluralKitFile && memberIds.isEmpty
              ? 'No fronters'
              : null);
      if (memberIds.isEmpty && (label == null || label.trim().isEmpty)) {
        warnings.add(
          'Skipped front #${index + 1}: no member ids or custom label.',
        );
        continue;
      }

      final endedAt = _dateString(front, const [
        'ended_at',
        'endedAt',
        'end',
        'endTime',
      ]);
      final normalizedTimes = _normalizeFrontTimes(
        start: start,
        end: endedAt,
        index: index,
      );

      sessions.add({
        'id': id,
        'label': _clamp(label, _capMemberName),
        'status_note': _clamp(_frontStatusNote(front), _capFrontStatusNote),
        'started_at': normalizedTimes.start,
        'ended_at': normalizedTimes.end,
        'created_at':
            _dateString(front, const [
              'created_at',
              'createdAt',
              'lastOperationTime',
            ]) ??
            normalizedTimes.start,
        'updated_at':
            _dateString(front, const [
              'updated_at',
              'updatedAt',
              'lastOperationTime',
            ]) ??
            normalizedTimes.start,
      });

      for (final memberExternalId in memberIds) {
        final memberId = _memberIdsByExternalId[memberExternalId];
        if (memberId == null) {
          warnings.add(
            'Front #${index + 1} ignored missing member "$memberExternalId".',
          );
          continue;
        }
        links.add({'session_id': id, 'member_id': memberId});
      }
    }

    _fillMissingFrontEnds(sessions);
    return _FrontData(sessions, links);
  }

  List<String> _frontMemberIds(Map<String, Object?> front) {
    return [
      for (final id in _rawMemberRefs(front))
        if (!_customFrontLabelsByExternalId.containsKey(id)) id,
    ];
  }

  List<String> _rawMemberRefs(Map<String, Object?> front) {
    final value =
        front['members'] ??
        front['memberIds'] ??
        front['member_ids'] ??
        front['memberIdsList'] ??
        front['membersIds'] ??
        front['members_ids'] ??
        front['memberIDs'] ??
        front['fronters'] ??
        front['member'];
    final refs = _memberRefsFromValue(value);
    if (refs.isNotEmpty) {
      return refs;
    }

    final single = _firstString(front, const ['memberId', 'member_id']);
    return single == null ? const [] : [single];
  }

  List<String> _memberRefsFromValue(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return [value.trim()];
    }
    if (value is num) {
      return [value.toString()];
    }
    if (value is List) {
      return [for (final item in value) ..._memberRefsFromValue(item)];
    }
    final object = _mapValue(value);
    if (object == null) {
      return const [];
    }
    final id = _firstString(object, const [
      '_id',
      'id',
      'uuid',
      'memberId',
      'member_id',
      'uid',
      'pkId',
      'pk_id',
    ]);
    if (id != null) {
      return [id];
    }
    return _memberRefsFromValue(
      object['member'] ?? object['members'] ?? object['fronters'],
    );
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
    final memberId = _memberIdsByExternalId[external];
    if (memberId == null) {
      warnings.add('Ignored missing member reference "$external".');
    }
    return memberId;
  }

  String? _frontLabel(Map<String, Object?> front) {
    final explicit = _firstString(front, const [
      'label',
      'name',
      'status',
      'customStatus',
      'custom_status',
      'comment',
    ]);
    final custom = front['custom'];
    final missingLabel = _missingFrontReferenceLabel(front);
    if (custom is bool) {
      if (!custom) {
        return _customFrontLabelFromRefs(front) ?? missingLabel;
      }
      return explicit ??
          _customFrontLabelFromRefs(front) ??
          missingLabel ??
          'Custom front';
    }
    return _customFrontLabelFromRefs(front) ??
        missingLabel ??
        _firstString(front, const [
          'label',
          'custom',
          'name',
          'status',
          'customStatus',
          'custom_status',
          'comment',
        ]);
  }

  String? _missingFrontReferenceLabel(Map<String, Object?> front) {
    final refs = _rawMemberRefs(front);
    if (refs.isEmpty) {
      return null;
    }
    if (refs.any(
      (id) =>
          _memberIdsByExternalId.containsKey(id) ||
          _customFrontLabelsByExternalId.containsKey(id),
    )) {
      return null;
    }
    if (front['custom'] == true) {
      return 'Deleted custom front';
    }
    if (front['custom'] == false) {
      return 'Deleted member';
    }
    return null;
  }

  String? _frontStatusNote(Map<String, Object?> front) {
    final note = _firstString(front, const [
      'status_note',
      'statusNote',
      'frontStatus',
      'customStatus',
      'custom_status',
      'comment',
      'note',
    ])?.trim();
    String? normalizedNote;

    // In SP, `customStatus` does double duty: for custom-front rows it is the
    // displayed non-member front label; for member rows it is the per-front
    // status note. Do not duplicate custom-front labels as notes.
    final custom = front['custom'];
    if (note != null &&
        note.isNotEmpty &&
        _customFrontLabelFromRefs(front) != note &&
        !(custom == true && _frontLabel(front) == note)) {
      normalizedNote = _replaceMemberPlaceholders(note);
    }

    final externalId = _firstString(front, const ['_id', 'id', 'uuid', 'uid']);
    final comments = externalId == null
        ? const <String>[]
        : _frontCommentsByExternalId[externalId] ?? const <String>[];
    final parts = [?normalizedNote, ...comments];
    return parts.isEmpty ? null : parts.join('\n');
  }

  String? _customFrontLabelFromRefs(Map<String, Object?> front) {
    for (final id in _rawMemberRefs(front)) {
      final label = _customFrontLabelsByExternalId[id];
      if (label != null) {
        return label;
      }
    }
    return null;
  }

  ({String start, String? end}) _normalizeFrontTimes({
    required String start,
    required String? end,
    required int index,
  }) {
    if (end == null) {
      return (start: start, end: null);
    }
    final startedAt = DateTime.tryParse(start);
    final endedAt = DateTime.tryParse(end);
    if (startedAt != null && endedAt != null && endedAt.isBefore(startedAt)) {
      warnings.add(
        'Front #${index + 1} ended before it started; swapped start and end.',
      );
      return (start: endedAt.toUtc().toIso8601String(), end: start);
    }
    return (start: start, end: end);
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
    final uuid = _firstString(object, const ['avatarUuid', 'avatar_uuid']);
    if (uuid != null && avatarAssets.any((asset) => asset.id == uuid)) {
      return 'sp-avatar:$uuid';
    }

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

    if (uuid == null) {
      return null;
    }
    final owner =
        _firstString(object, const ['uid', 'owner', 'ownerId']) ??
        _simplyPluralOwnerId();
    if (owner == null) {
      return 'sp-avatar:$uuid';
    }
    return 'https://serve.apparyllis.com/avatars/$owner/$uuid';
  }

  String? _simplyPluralOwnerId() {
    final users = _firstList(decoded, const ['users']);
    final user = users.isEmpty ? null : _mapValue(users.first);
    if (user == null) {
      return null;
    }
    return _firstString(user, const ['uid', '_id', 'id']);
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

  void _indexFrontHistoryComments() {
    for (final value in _firstList(decoded, const ['comments'])) {
      final comment = _mapValue(value);
      if (comment == null || !_isFrontHistoryComment(comment)) {
        continue;
      }
      final frontExternalId = _firstString(comment, const [
        'documentId',
        'document_id',
        'frontId',
        'front_id',
        'targetId',
        'target_id',
      ]);
      final body = _firstString(comment, const [
        'body',
        'text',
        'content',
        'message',
        'comment',
        'note',
      ])?.trim();
      if (frontExternalId == null || body == null || body.isEmpty) {
        continue;
      }
      _frontCommentsByExternalId
          .putIfAbsent(frontExternalId, () => [])
          .add(_replaceMemberPlaceholders(body) ?? body);
    }
  }

  String? _replaceMemberPlaceholders(String? value) {
    if (value == null || !value.contains('<###@')) {
      return value;
    }
    return value.replaceAllMapped(RegExp(r'<###@([^#>]+)###>'), (match) {
      final externalId = match.group(1);
      if (externalId == null) {
        return match.group(0) ?? '';
      }
      final name = _memberNamesByExternalId[externalId];
      return name == null ? '@$externalId' : '@$name';
    });
  }

  bool _isFrontHistoryComment(Map<String, Object?> comment) {
    final collection = _firstString(comment, const [
      'collection',
      'target',
      'targetType',
      'target_type',
    ]);
    if (collection == null) {
      return false;
    }
    final normalized = collection.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    return normalized == 'fronthistory' || normalized == 'fronts';
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

class _NamedFrontData {
  const _NamedFrontData(this.namedFronts, this.namedFrontMembers);

  final List<Map<String, Object?>> namedFronts;
  final List<Map<String, Object?>> namedFrontMembers;
}

class _PrivacyBucketData {
  const _PrivacyBucketData(this.buckets, this.members);

  final List<Map<String, Object?>> buckets;
  final List<Map<String, Object?>> members;
}

class _ReminderScheduleFields {
  const _ReminderScheduleFields({
    required this.kind,
    required this.time,
    required this.dowMask,
    required this.dom,
  });

  final String? kind;
  final String? time;
  final int? dowMask;
  final int? dom;
}

class _PollData {
  const _PollData(this.polls, this.pollOptions, this.pollVotes);

  final List<Map<String, Object?>> polls;
  final List<Map<String, Object?>> pollOptions;
  final List<Map<String, Object?>> pollVotes;
}

class _ImportTextCap {
  const _ImportTextCap(this.label, this.limit);

  final String label;
  final int limit;
}

class _ImportClampReport {
  final _stringHits = <_ImportTextCap, int>{};
  final _listHits = <_ImportTextCap, int>{};

  String? string(String? value, _ImportTextCap cap) {
    if (value == null || value.length <= cap.limit) {
      return value;
    }
    _stringHits[cap] = (_stringHits[cap] ?? 0) + 1;
    return value.substring(0, cap.limit);
  }

  List<T> list<T>(List<T> items, _ImportTextCap cap) {
    if (items.length <= cap.limit) {
      return items;
    }
    _listHits[cap] = (_listHits[cap] ?? 0) + 1;
    return items.take(cap.limit).toList(growable: false);
  }

  List<String> toWarnings() {
    final warnings = <String>[];
    final stringEntries = _stringHits.entries.toList()
      ..sort((left, right) => left.key.label.compareTo(right.key.label));
    final listEntries = _listHits.entries.toList()
      ..sort((left, right) => left.key.label.compareTo(right.key.label));

    for (final entry in stringEntries) {
      final label = entry.value == 1 ? entry.key.label : '${entry.key.label}s';
      warnings.add(
        '${entry.value} $label will be shortened to ${entry.key.limit} characters.',
      );
    }
    for (final entry in listEntries) {
      final label = entry.value == 1 ? entry.key.label : '${entry.key.label}s';
      warnings.add(
        '${entry.value} $label will be trimmed to ${entry.key.limit} entries.',
      );
    }
    return warnings;
  }
}

const _capSystemName = _ImportTextCap('system name', 100);
const _capMemberName = _ImportTextCap('member name', 100);
const _capMemberPronouns = _ImportTextCap('member pronouns', 100);
const _capMemberBirthday = _ImportTextCap('member birthday', 10);
const _capMemberEmoji = _ImportTextCap('member emoji', 8);
const _capMemberDescription = _ImportTextCap('member description', 5000);
const _capAvatarUrl = _ImportTextCap('avatar URL', 500);
const _capGroupName = _ImportTextCap('group name', 100);
const _capCustomFieldName = _ImportTextCap('custom field name', 100);
const _capCustomFieldValue = _ImportTextCap('custom field value', 5000);
const _capContentTitle = _ImportTextCap('content title', 200);
const _capLongText = _ImportTextCap('long text field', 5000);
const _capJournalBody = _ImportTextCap('journal body', 20000);
const _capMessageBody = _ImportTextCap('message body', 5000);
const _capReminderTitle = _ImportTextCap('reminder title', 120);
const _capReminderBody = _ImportTextCap('reminder body', 2000);
const _capReminderSchedule = _ImportTextCap('reminder schedule', 500);
const _capPollQuestion = _ImportTextCap('poll question', 500);
const _capPollDescription = _ImportTextCap('poll description', 2000);
const _capPollOption = _ImportTextCap('poll option', 200);
const _capPollOptionList = _ImportTextCap('poll option list', 20);
const _capFrontStatusNote = _ImportTextCap('front status note', 2000);

Map<String, int> _archiveCounts(Map<String, Object?> archive) => {
  'members': _listCount(archive['members']),
  'groups': _listCount(archive['groups']),
  'group_members': _listCount(archive['group_members']),
  'custom_fields': _listCount(archive['custom_fields']),
  'custom_field_values': _listCount(archive['custom_field_values']),
  'notes': _listCount(archive['notes']),
  'chat_categories': _listCount(archive['chat_categories']),
  'chat_channels': _listCount(archive['chat_channels']),
  'messages': _listCount(archive['messages']),
  'reminders': _listCount(archive['reminders']),
  'tags': _listCount(archive['tags']),
  'member_tags': _listCount(archive['member_tags']),
  'journals': _listCount(archive['journals']),
  'content_revisions': _listCount(archive['content_revisions']),
  'polls': _listCount(archive['polls']),
  'poll_options': _listCount(archive['poll_options']),
  'poll_votes': _listCount(archive['poll_votes']),
  'poll_vote_events': _listCount(archive['poll_vote_events']),
  'fronts': _listCount(archive['fronts']),
  'front_members': _listCount(archive['front_members']),
  'front_audit_events': _listCount(archive['front_audit_events']),
  'named_fronts': _listCount(archive['named_fronts']),
  'named_front_members': _listCount(archive['named_front_members']),
  'privacy_buckets': _listCount(archive['privacy_buckets']),
  'privacy_bucket_members': _listCount(archive['privacy_bucket_members']),
  'avatar_refs':
      _avatarRefCount(archive['members']) +
      _avatarRefCount(archive['named_fronts']),
  'avatar_assets': _listCount(archive['avatar_assets']),
  'raw_payloads': _listCount(archive['raw_payloads']),
  'preferences': _listCount(archive['preferences']),
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
  var trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  if (trimmed.startsWith('#')) {
    trimmed = trimmed.substring(1);
  }
  if (trimmed.length == 3) {
    trimmed = trimmed.split('').map((char) => '$char$char').join();
  } else if (trimmed.length == 8) {
    trimmed = trimmed.substring(2);
  }
  if (trimmed.length != 6 || !RegExp(r'^[0-9a-fA-F]+$').hasMatch(trimmed)) {
    return null;
  }
  return '#${trimmed.toLowerCase()}';
}

int? _intValue(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim());
  }
  return null;
}

bool? _boolValue(Object? value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == 'yes' || normalized == '1') {
      return true;
    }
    if (normalized == 'false' || normalized == 'no' || normalized == '0') {
      return false;
    }
  }
  return null;
}

String? _timeFromScheduleText(String text) {
  final match = RegExp(r'\bat\s+(\d{1,2}:\d{2})\b').firstMatch(text);
  return match?.group(1);
}

int? _weekdayFromScheduleText(String text) {
  final lower = text.toLowerCase();
  final weekdays = <String, int>{
    'monday': DateTime.monday,
    'tuesday': DateTime.tuesday,
    'wednesday': DateTime.wednesday,
    'thursday': DateTime.thursday,
    'friday': DateTime.friday,
    'saturday': DateTime.saturday,
    'sunday': DateTime.sunday,
  };
  for (final entry in weekdays.entries) {
    if (lower.contains(entry.key)) return entry.value;
  }
  return null;
}

int? _monthDayFromScheduleText(String text) {
  final match = RegExp(r'\bday\s+(\d{1,2})\b').firstMatch(text);
  final value = int.tryParse(match?.group(1) ?? '');
  if (value == null || value < 1 || value > 31) return null;
  return value;
}

String _customFieldType(Object? value) {
  if (value is int) {
    return switch (value) {
      2 || 6 => 'date',
      _ => 'text',
    };
  }
  final text = value?.toString().trim().toLowerCase();
  return switch (text) {
    'number' || 'numeric' || 'integer' => 'number',
    'date' || 'datetime' || 'timestamp' => 'date',
    'bool' || 'boolean' => 'boolean',
    'select' || 'choice' || 'dropdown' => 'select',
    _ => 'text',
  };
}

String _customFieldValue(Object? value) {
  if (value is String) {
    return value;
  }
  return const JsonEncoder.withIndent('  ').convert(value);
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

int _avatarRefCount(Object? value) {
  if (value is! List) {
    return 0;
  }
  var count = 0;
  for (final item in value) {
    if (item is Map<String, Object?> &&
        _firstString(item, const ['avatar_url']) != null) {
      count++;
    }
  }
  return count;
}
