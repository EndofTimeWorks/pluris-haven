part of 'haven_repository.dart';

extension LocalHavenRepositoryArchiveCodec on LocalHavenRepository {
  Future<Map<String, Object?>> _systemToJson(PluralSystem system) async => {
    'id': system.id,
    'name':
        (await _decryptLocalText(
          system.name,
          'plural_systems',
          system.id,
          'name',
        )) ??
        'Local system',
    'color_hex': await _decryptLocalText(
      system.colorHex,
      'plural_systems',
      system.id,
      'color_hex',
    ),
    'avatar_url': await _decryptLocalText(
      system.avatarUrl,
      'plural_systems',
      system.id,
      'avatar_url',
    ),
    'description': await _decryptLocalText(
      system.description,
      'plural_systems',
      system.id,
      'description',
    ),
    'created_at': system.createdAt.toIso8601String(),
    'updated_at': system.updatedAt.toIso8601String(),
  };

  Future<Map<String, Object?>> _memberToJson(Member member) async {
    final displayName = await _decryptMember(
      member,
      'display_name',
      member.displayName,
    );
    if (displayName == null) {
      throw StateError('Protected member name could not be exported.');
    }
    final pronouns = await _decryptMember(member, 'pronouns', member.pronouns);
    final colorHex = await _decryptMember(member, 'color_hex', member.colorHex);
    final birthday = await _decryptMember(member, 'birthday', member.birthday);
    final emoji = await _decryptMember(member, 'emoji', member.emoji);
    final privacy = await _decryptMember(member, 'privacy', member.privacy);
    final description = await _decryptMember(
      member,
      'description',
      member.description,
    );
    final avatarUrl = await _decryptMember(
      member,
      'avatar_url',
      member.avatarUrl,
    );
    final pluralKitId = await _decryptMember(
      member,
      'pluralkit_id',
      member.pluralKitId,
    );
    return {
      'id': member.id,
      'display_name': displayName,
      'pronouns': pronouns,
      'color_hex': colorHex,
      'birthday': birthday,
      'emoji': emoji,
      'privacy': privacy,
      'folder_id': member.folderId,
      'description': description,
      'avatar_url': avatarUrl,
      'pluralkit_id': pluralKitId,
      'is_custom_front': member.isCustomFront,
      'archived': member.archived,
      'created_at': member.createdAt.toIso8601String(),
      'updated_at': member.updatedAt.toIso8601String(),
    };
  }

  Future<Map<String, Object?>> _groupToJson(SystemGroup group) async => {
    'id': group.id,
    'parent_group_id': group.parentGroupId,
    'name':
        (await _decryptLocalText(
          group.name,
          'system_groups',
          group.id,
          'name',
        )) ??
        '',
    'color_hex': await _decryptLocalText(
      group.colorHex,
      'system_groups',
      group.id,
      'color_hex',
    ),
    'description': await _decryptLocalText(
      group.description,
      'system_groups',
      group.id,
      'description',
    ),
    'emoji': await _decryptLocalText(
      group.emoji,
      'system_groups',
      group.id,
      'emoji',
    ),
    'created_at': group.createdAt.toIso8601String(),
    'updated_at': group.updatedAt.toIso8601String(),
  };

  Map<String, Object?> _groupMemberToJson(GroupMember link) => {
    'group_id': link.groupId,
    'member_id': link.memberId,
  };

  List<Map<String, Object?>> _jsonObjectList(Object? value) {
    if (value == null) return <Map<String, Object?>>[];
    if (value is! List) {
      throw const FormatException('Expected an archive list.');
    }

    return [
      for (final item in value)
        if (item is Map<String, Object?>) item else _throwArchiveObjectError(),
    ];
  }

  Map<String, Object?> _throwArchiveObjectError() {
    throw const FormatException('Expected an archive object in list.');
  }

  String _requiredString(Map<String, Object?> object, String key) {
    final value = _stringValue(object[key]);
    if (value == null || value.trim().isEmpty) {
      throw FormatException('Missing required archive field: $key.');
    }
    return value;
  }

  String? _stringValue(Object? value) => value is String ? value : null;

  int? _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    final text = _stringValue(value);
    return text == null ? null : int.tryParse(text);
  }

  DateTime? _dateValue(Object? value) {
    final text = _stringValue(value);
    if (text == null || text.trim().isEmpty) return null;
    return DateTime.tryParse(text)?.toUtc();
  }
}

class _ImportAvatarBytes {
  const _ImportAvatarBytes({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.bytes,
  });

  final String id;
  final String name;
  final String? mimeType;
  final Uint8List bytes;
}

String _avatarExtension(String sourceName, String? mimeType) {
  final mimeExtension = switch (mimeType) {
    'image/png' => '.png',
    'image/jpeg' => '.jpg',
    'image/webp' => '.webp',
    'image/gif' => '.gif',
    'image/svg+xml' => '.svg',
    _ => null,
  };
  if (mimeExtension != null) return mimeExtension;

  final lowerName = sourceName.toLowerCase();
  if (lowerName.endsWith('.png')) return '.png';
  if (lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg')) return '.jpg';
  if (lowerName.endsWith('.webp')) return '.webp';
  if (lowerName.endsWith('.gif')) return '.gif';
  if (lowerName.endsWith('.svg')) return '.svg';
  return '.bin';
}

String _safeFilePart(String value) {
  final cleaned = value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9._-]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^[-.]+|[-.]+$'), '');
  return cleaned.isEmpty ? 'avatar' : cleaned;
}
