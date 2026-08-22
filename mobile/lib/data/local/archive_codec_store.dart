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

  Future<Map<String, Object?>> _noteToJson(Note note) async => {
    'id': note.id,
    'member_id': note.memberId,
    'title':
        (await _decryptLocalText(note.title, 'notes', note.id, 'title')) ?? '',
    'body':
        (await _decryptLocalText(note.body, 'notes', note.id, 'body')) ?? '',
    'created_at': note.createdAt.toIso8601String(),
    'updated_at': note.updatedAt.toIso8601String(),
  };

  Future<Map<String, Object?>> _messageToJson(Message message) async => {
    'id': message.id,
    'member_id': message.memberId,
    'body':
        (await _decryptLocalText(
          message.body,
          'messages',
          message.id,
          'body',
        )) ??
        '',
    'board_kind': message.boardKind,
    'board_member_id': message.boardMemberId,
    'parent_message_id': message.parentMessageId,
    'channel_id': message.channelId,
    'deleted_at': message.deletedAt?.toIso8601String(),
    'archived': message.archived,
    'created_at': message.createdAt.toIso8601String(),
    'updated_at': message.updatedAt.toIso8601String(),
  };

  Future<Map<String, Object?>> _chatCategoryToJson(
    ChatCategory category,
  ) async => {
    'id': category.id,
    'name':
        (await _decryptLocalText(
          category.name,
          'chat_categories',
          category.id,
          'name',
        )) ??
        '',
    'description': await _decryptLocalText(
      category.description,
      'chat_categories',
      category.id,
      'description',
    ),
    'position': category.position,
    'created_at': category.createdAt.toIso8601String(),
    'updated_at': category.updatedAt.toIso8601String(),
  };

  Future<Map<String, Object?>> _chatChannelToJson(ChatChannel channel) async =>
      {
        'id': channel.id,
        'category_id': channel.categoryId,
        'name':
            (await _decryptLocalText(
              channel.name,
              'chat_channels',
              channel.id,
              'name',
            )) ??
            '',
        'description': await _decryptLocalText(
          channel.description,
          'chat_channels',
          channel.id,
          'description',
        ),
        'color_hex': await _decryptLocalText(
          channel.colorHex,
          'chat_channels',
          channel.id,
          'color_hex',
        ),
        'position': channel.position,
        'created_at': channel.createdAt.toIso8601String(),
        'updated_at': channel.updatedAt.toIso8601String(),
      };

  Future<Map<String, Object?>> _reminderToJson(Reminder reminder) async => {
    'id': reminder.id,
    'title':
        (await _decryptLocalText(
          reminder.title,
          'reminders',
          reminder.id,
          'title',
        )) ??
        '',
    'body': await _decryptLocalText(
      reminder.body,
      'reminders',
      reminder.id,
      'body',
    ),
    'schedule_text':
        (await _decryptLocalText(
          reminder.scheduleText,
          'reminders',
          reminder.id,
          'schedule_text',
        )) ??
        '',
    'trigger_type': reminder.triggerType,
    'trigger_member_id': reminder.triggerMemberId,
    'trigger_event': await _decryptLocalText(
      reminder.triggerEvent,
      'reminders',
      reminder.id,
      'trigger_event',
    ),
    'schedule_kind': await _decryptLocalText(
      reminder.scheduleKind,
      'reminders',
      reminder.id,
      'schedule_kind',
    ),
    'schedule_time': await _decryptLocalText(
      reminder.scheduleTime,
      'reminders',
      reminder.id,
      'schedule_time',
    ),
    'schedule_dow_mask': reminder.scheduleDowMask,
    'schedule_dom': reminder.scheduleDom,
    'delay_seconds': reminder.delaySeconds,
    'enabled': reminder.enabled,
    'last_fired_at': reminder.lastFiredAt?.toIso8601String(),
    'created_at': reminder.createdAt.toIso8601String(),
    'updated_at': reminder.updatedAt.toIso8601String(),
  };

  Future<Map<String, Object?>> _tagToJson(Tag tag) async => {
    'id': tag.id,
    'name': (await _decryptLocalText(tag.name, 'tags', tag.id, 'name')) ?? '',
    'color_hex': await _decryptLocalText(
      tag.colorHex,
      'tags',
      tag.id,
      'color_hex',
    ),
    'created_at': tag.createdAt.toIso8601String(),
    'updated_at': tag.updatedAt.toIso8601String(),
  };

  Map<String, Object?> _memberTagToJson(MemberTag link) => {
    'tag_id': link.tagId,
    'member_id': link.memberId,
  };

  Future<Map<String, Object?>> _journalToJson(JournalEntry journal) async => {
    'id': journal.id,
    'member_id': journal.memberId,
    'title': await _decryptLocalText(
      journal.title,
      'journal_entries',
      journal.id,
      'title',
    ),
    'body':
        (await _decryptLocalText(
          journal.body,
          'journal_entries',
          journal.id,
          'body',
        )) ??
        '',
    'visibility': journal.visibility,
    'created_at': journal.createdAt.toIso8601String(),
    'updated_at': journal.updatedAt.toIso8601String(),
  };

  Future<Map<String, Object?>> _contentRevisionToJson(
    ContentRevision revision,
  ) async => {
    'id': revision.id,
    'target_type': revision.targetType,
    'target_id': revision.targetId,
    'title': await _decryptLocalText(
      revision.title,
      'content_revisions',
      revision.id,
      'title',
    ),
    'body':
        (await _decryptLocalText(
          revision.body,
          'content_revisions',
          revision.id,
          'body',
        )) ??
        '',
    'pinned_at': revision.pinnedAt?.toIso8601String(),
    'created_at': revision.createdAt.toIso8601String(),
  };

  Future<Map<String, Object?>> _customFieldToJson(
    CustomFieldDefinition field,
  ) async => {
    'id': field.id,
    'name':
        (await _decryptLocalText(
          field.name,
          'custom_field_definitions',
          field.id,
          'name',
        )) ??
        '',
    'field_type': field.fieldType,
    'privacy': await _decryptLocalText(
      field.privacy,
      'custom_field_definitions',
      field.id,
      'privacy',
    ),
    'position': field.position,
    'created_at': field.createdAt.toIso8601String(),
    'updated_at': field.updatedAt.toIso8601String(),
  };

  Future<Map<String, Object?>> _customFieldValueToJson(
    CustomFieldValue value,
  ) async => {
    'id': value.id,
    'field_id': value.fieldId,
    'member_id': value.memberId,
    'value':
        (await _decryptLocalText(
          value.value,
          'custom_field_values',
          value.id,
          'value',
        )) ??
        '',
    'created_at': value.createdAt.toIso8601String(),
    'updated_at': value.updatedAt.toIso8601String(),
  };

  Future<Map<String, Object?>> _pollToJson(Poll poll) async => {
    'id': poll.id,
    'question':
        (await _decryptLocalText(
          poll.question,
          'polls',
          poll.id,
          'question',
        )) ??
        '',
    'description': await _decryptLocalText(
      poll.description,
      'polls',
      poll.id,
      'description',
    ),
    'kind': poll.kind,
    'closed': poll.closed,
    'created_at': poll.createdAt.toIso8601String(),
    'updated_at': poll.updatedAt.toIso8601String(),
  };

  Future<Map<String, Object?>> _pollOptionToJson(PollOption option) async => {
    'id': option.id,
    'poll_id': option.pollId,
    'body':
        (await _decryptLocalText(
          option.body,
          'poll_options',
          option.id,
          'body',
        )) ??
        '',
    'position': option.position,
  };

  Map<String, Object?> _pollVoteToJson(PollVote vote) => {
    'poll_id': vote.pollId,
    'option_id': vote.optionId,
    'created_at': vote.createdAt.toIso8601String(),
  };

  Map<String, Object?> _pollVoteEventToJson(PollVoteEvent event) => {
    'id': event.id,
    'poll_id': event.pollId,
    'option_id': event.optionId,
    'action': event.action,
    'created_at': event.createdAt.toIso8601String(),
  };

  Future<Map<String, Object?>> _frontToJson(FrontSession front) async => {
    'id': front.id,
    'label': await _decryptLocalText(
      front.label,
      'front_sessions',
      front.id,
      'label',
    ),
    'status_note': await _decryptLocalText(
      front.statusNote,
      'front_sessions',
      front.id,
      'status_note',
    ),
    'started_at': front.startedAt.toIso8601String(),
    'ended_at': front.endedAt?.toIso8601String(),
    'created_at': front.createdAt.toIso8601String(),
    'updated_at': front.updatedAt.toIso8601String(),
  };

  Map<String, Object?> _frontMemberToJson(FrontSessionMember link) => {
    'session_id': link.sessionId,
    'member_id': link.memberId,
  };

  Future<Map<String, Object?>> _frontAuditEventToJson(
    FrontAuditEvent event,
  ) async => {
    'id': event.id,
    'front_id': event.frontId,
    'before_snapshot': await _decryptLocalText(
      event.beforeSnapshot,
      'front_audit_events',
      event.id,
      'before_snapshot',
    ),
    'after_snapshot': await _decryptLocalText(
      event.afterSnapshot,
      'front_audit_events',
      event.id,
      'after_snapshot',
    ),
    'created_at': event.createdAt.toIso8601String(),
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

  String _debugErrorText(Object error, StackTrace stackTrace) {
    var text = error.toString();
    assert(() {
      final stack = stackTrace.toString().trim();
      if (stack.isNotEmpty) {
        text = '$text\n\nDebug stack:\n$stack';
      }
      return true;
    }());
    return text;
  }

  Future<Map<String, Object?>> _namedFrontToJson(NamedFront front) async => {
    'id': front.id,
    'name':
        (await _decryptLocalText(
          front.name,
          'named_fronts',
          front.id,
          'name',
        )) ??
        '',
    'custom_label': await _decryptLocalText(
      front.customLabel,
      'named_fronts',
      front.id,
      'custom_label',
    ),
    'color_hex': await _decryptLocalText(
      front.colorHex,
      'named_fronts',
      front.id,
      'color_hex',
    ),
    'avatar_url': await _decryptLocalText(
      front.avatarUrl,
      'named_fronts',
      front.id,
      'avatar_url',
    ),
    'description': await _decryptLocalText(
      front.description,
      'named_fronts',
      front.id,
      'description',
    ),
    'created_at': front.createdAt.toIso8601String(),
    'updated_at': front.updatedAt.toIso8601String(),
  };

  Map<String, Object?> _namedFrontMemberToJson(NamedFrontMember link) => {
    'named_front_id': link.namedFrontId,
    'member_id': link.memberId,
  };

  Future<Map<String, Object?>> _privacyBucketToJson(
    PrivacyBucket bucket,
  ) async => {
    'id': bucket.id,
    'name':
        (await _decryptLocalText(
          bucket.name,
          'privacy_buckets',
          bucket.id,
          'name',
        )) ??
        '',
    'description': await _decryptLocalText(
      bucket.description,
      'privacy_buckets',
      bucket.id,
      'description',
    ),
    'color_hex': await _decryptLocalText(
      bucket.colorHex,
      'privacy_buckets',
      bucket.id,
      'color_hex',
    ),
    'position': bucket.position,
    'created_at': bucket.createdAt.toIso8601String(),
    'updated_at': bucket.updatedAt.toIso8601String(),
  };

  Map<String, Object?> _privacyBucketMemberToJson(PrivacyBucketMember link) => {
    'bucket_id': link.bucketId,
    'member_id': link.memberId,
  };

  Future<Map<String, Object?>> _importRecordToJson(ImportRecord record) async =>
      {
        'id': record.id,
        'source': record.source,
        'file_name': await _decryptLocalText(
          record.fileName,
          'import_records',
          record.id,
          'file_name',
        ),
        'summary_json': await _decryptLocalText(
          record.summaryJson,
          'import_records',
          record.id,
          'summary_json',
        ),
        'imported_at': record.importedAt.toIso8601String(),
      };

  Future<Map<String, Object?>> _importPayloadToJson(
    ImportPayload payload,
  ) async => {
    'id': payload.id,
    'import_record_id': payload.importRecordId,
    'source': payload.source,
    'collection': payload.collection,
    'payload_json':
        (await _decryptLocalText(
          payload.payloadJson,
          'import_payloads',
          payload.id,
          'payload_json',
        )) ??
        '',
    'imported_at': payload.importedAt.toIso8601String(),
  };

  Future<Map<String, Object?>> _notificationEventToJson(
    NotificationEvent event,
  ) async => {
    'id': event.id,
    'kind': event.kind,
    'title':
        (await _decryptLocalText(
          event.title,
          'notification_events',
          event.id,
          'title',
        )) ??
        '',
    'body':
        (await _decryptLocalText(
          event.body,
          'notification_events',
          event.id,
          'body',
        )) ??
        '',
    'read_at': event.readAt?.toIso8601String(),
    'created_at': event.createdAt.toIso8601String(),
  };

  Map<String, Object?> _preferenceToJson(AppPreference preference) => {
    'key': preference.key,
    'value': preference.value,
    'updated_at': preference.updatedAt.toIso8601String(),
  };
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
