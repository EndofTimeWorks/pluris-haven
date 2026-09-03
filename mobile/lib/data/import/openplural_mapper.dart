part of 'import_archive_mapper.dart';

Map<String, Object?> _openPluralEnvelopeToLooseArchive(
  Map<String, Object?> envelope,
) {
  final version = envelope['openplural_version'];
  if (version != '0.1') {
    throw FormatException(
      'Unsupported OpenPlural version: ${version ?? 'missing'}.',
    );
  }

  final assets = <String, String>{};
  for (final value in _firstList(envelope, const ['assets'])) {
    final asset = _mapValue(value);
    final id = asset == null ? null : _firstString(asset, const ['id']);
    final uri = asset == null
        ? null
        : _firstString(asset, const ['uri', 'url']);
    if (id != null && uri != null) assets[id] = uri;
  }

  final systems = _firstList(envelope, const ['systems']);
  final system = systems.isEmpty ? null : _mapValue(systems.first);
  final extension = _openPluralSheafExtension(envelope);
  return {
    'system': system == null
        ? null
        : {
            'id': _firstString(system, const ['id']),
            'name': _firstString(system, const ['name']),
            'description': _firstString(system, const ['description']),
            'color': _firstString(system, const ['color']),
            'avatarUrl':
                assets[_firstString(system, const ['avatar_asset_id'])],
          },
    'members': [
      for (final value in _firstList(envelope, const ['members']))
        if (_mapValue(value) case final member?)
          _openPluralMember(member, assets),
    ],
    'groups': _openPluralGroups(envelope),
    'custom_fields': [
      for (final value in _firstList(envelope, const ['custom_fields']))
        if (_mapValue(value) case final field?)
          {
            'id': _firstString(field, const ['id']),
            'name': _firstString(field, const ['name']),
            'field_type': _firstString(field, const ['field_type']),
            'privacy': _openPluralPrivacyVisibility(field['privacy']),
            'position': _intValue(field['sort_order'] ?? field['order']),
          },
    ],
    'custom_field_values': _openPluralCustomFieldValues(envelope),
    'notes': _openPluralNotes(envelope),
    'messages': _openPluralMessages(envelope),
    'reminders': extension['reminders'] ?? const [],
    'polls': extension['polls'] ?? const [],
    'fronts': _openPluralFronts(envelope),
    'openplural_extensions': extension,
  };
}

Map<String, Object?> _openPluralMember(
  Map<String, Object?> member,
  Map<String, String> assets,
) {
  final extension = _openPluralSheafExtension(member);
  final avatarAssetId = _firstString(member, const ['avatar_asset_id']);
  final birthday = member['birthday'];
  return {
    'id': _firstString(member, const ['id']),
    'source_member_id': _openPluralSourceIdentity(member['source_refs']),
    'name':
        _firstString(member, const ['display_name']) ??
        _firstString(member, const ['name']),
    'description': _firstString(member, const ['description']),
    'pronouns': _firstString(member, const ['pronouns']),
    'color': _firstString(member, const ['color']),
    'avatarUrl': avatarAssetId == null ? null : assets[avatarAssetId],
    'pluralKitId': _openPluralSourceRef(member['source_refs'], 'pluralkit'),
    'privacy': _openPluralPrivacyVisibility(member['privacy']),
    'archived': member['archived'] == true,
    'is_custom_front': member['is_custom_front'] == true,
    'createdAt': _firstString(member, const ['created_at']),
    'info': {
      if (birthday is Map<String, Object?>)
        'birthday': _firstString(birthday, const ['value']),
      if (birthday is String) 'birthday': birthday,
      if (extension['note'] is String) 'note': extension['note'],
    },
  };
}

List<Map<String, Object?>> _openPluralGroups(Map<String, Object?> envelope) {
  final memberIdsByGroup = <String, List<String>>{};
  for (final value in _firstList(envelope, const ['group_memberships'])) {
    final row = _mapValue(value);
    final groupId = row == null ? null : _firstString(row, const ['group_id']);
    final memberId = row == null
        ? null
        : _firstString(row, const ['member_id']);
    if (groupId != null && memberId != null) {
      memberIdsByGroup.putIfAbsent(groupId, () => []).add(memberId);
    }
  }
  return [
    for (final value in _firstList(envelope, const ['groups']))
      if (_mapValue(value) case final group?)
        {
          'id': _firstString(group, const ['id']),
          'name': _firstString(group, const ['name']),
          'description': _firstString(group, const ['description']),
          'color': _firstString(group, const ['color']),
          'parent_group_id': _firstString(group, const ['parent_group_id']),
          'members':
              memberIdsByGroup[_firstString(group, const ['id'])] ??
              const <String>[],
        },
  ];
}

List<Map<String, Object?>> _openPluralCustomFieldValues(
  Map<String, Object?> envelope,
) => [
  for (final value in _firstList(envelope, const ['custom_field_values']))
    if (_mapValue(value) case final row?)
      {
        'field_id': _firstString(row, const ['field_id']),
        'member_id': _firstString(row, const ['subject_id']),
        'value': row['value'],
        'created_at': _firstString(row, const ['created_at']),
        'updated_at': _firstString(row, const ['updated_at']),
      },
];

List<Map<String, Object?>> _openPluralNotes(Map<String, Object?> envelope) => [
  for (final value in _firstList(envelope, const ['notes']))
    if (_mapValue(value) case final note?)
      {
        'id': _firstString(note, const ['id']),
        'title': _firstString(note, const ['title']),
        'body': _firstString(note, const ['body']),
        'member_id':
            _firstString(note, const ['member_id']) ??
            _firstString(_openPluralSheafExtension(note), const ['member_id']),
        'created_at': _firstString(note, const ['created_at']),
        'updated_at': _firstString(note, const ['updated_at']),
      },
];

List<Map<String, Object?>> _openPluralMessages(Map<String, Object?> envelope) {
  final boards = _mapValue(envelope['boards']);
  if (boards == null) return const [];
  return [
    for (final value in _firstList(boards, const ['posts']))
      if (_mapValue(value) case final post?)
        {
          'id': _firstString(post, const ['id']),
          'body': _firstString(post, const ['body']),
          'writer': _firstString(post, const ['author_member_id']),
          'created_at': _firstString(post, const ['created_at']),
          'updated_at': _firstString(post, const ['updated_at']),
        },
  ];
}

List<Map<String, Object?>> _openPluralFronts(Map<String, Object?> envelope) {
  final periods = [
    for (final value in _firstList(envelope, const ['front_periods']))
      if (_mapValue(value) case final front?)
        {
          'id': _firstString(front, const ['id']),
          'started_at': _firstString(front, const ['started_at']),
          'ended_at': _firstString(front, const ['ended_at']),
          'member_ids': _openPluralAssignmentMemberIds(front['assignments']),
          'custom_status': _firstString(front, const ['status']),
        },
  ];
  final seen = <String>{};
  return [
    for (final front in [
      ...periods,
      ..._openPluralFrontsFromEvents(
        _firstList(envelope, const ['front_events']),
      ),
    ])
      if (seen.add(_openPluralFrontKey(front))) front,
  ];
}

List<Map<String, Object?>> _openPluralFrontsFromEvents(List<Object?> events) {
  final timed = <({String id, String at, List<String> members})>[];
  for (var index = 0; index < events.length; index++) {
    final event = _mapValue(events[index]);
    final at = event == null ? null : _firstString(event, const ['at']);
    if (event == null || at == null) continue;
    timed.add((
      id: _firstString(event, const ['id']) ?? 'event-$index',
      at: at,
      members: _openPluralAssignmentMemberIds(event['assignments']),
    ));
  }
  timed.sort((a, b) => a.at.compareTo(b.at));
  return [
    for (var index = 0; index < timed.length; index++)
      if (timed[index].members.isNotEmpty)
        {
          'id': 'event-${timed[index].id}',
          'started_at': timed[index].at,
          'ended_at': index + 1 < timed.length ? timed[index + 1].at : null,
          'member_ids': timed[index].members,
        },
  ];
}

List<String> _openPluralAssignmentMemberIds(Object? assignments) => [
  for (final assignment
      in assignments is List ? assignments : const <Object?>[])
    if (_mapValue(assignment) case final row?)
      ?_firstString(row, const ['member_id']),
];

String _openPluralFrontKey(Map<String, Object?> front) {
  final members = switch (front['member_ids']) {
    final List list => [...list.map((value) => value.toString())]..sort(),
    _ => const <String>[],
  };
  return [front['started_at'], front['ended_at'], members.join(',')].join('|');
}

Map<String, Object?> _openPluralSheafExtension(Map<String, Object?> object) {
  final extensions = _mapValue(object['extensions']);
  return extensions == null
      ? const {}
      : _mapValue(extensions['sheaf']) ?? const {};
}

String? _openPluralSourceRef(Object? refs, String app) {
  if (refs is! List) return null;
  for (final value in refs) {
    final ref = _mapValue(value);
    if (ref != null &&
        _firstString(ref, const ['app']) == app &&
        _firstString(ref, const ['id']) != null) {
      return _firstString(ref, const ['id']);
    }
  }
  return null;
}

String? _openPluralSourceIdentity(Object? refs) {
  if (refs is! List) return null;
  for (final value in refs) {
    final ref = _mapValue(value);
    if (ref == null) continue;
    final app = _firstString(ref, const ['app']);
    final collection = _firstString(ref, const ['collection']);
    final id =
        _firstString(ref, const ['uuid']) ?? _firstString(ref, const ['id']);
    if (app != null && collection != null && id != null) {
      return '$app:$collection:$id';
    }
  }
  return null;
}

String? _openPluralPrivacyVisibility(Object? privacy) {
  final value = _mapValue(privacy);
  return value == null ? null : _firstString(value, const ['visibility']);
}
