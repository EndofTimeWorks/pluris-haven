part of 'haven_repository.dart';

extension LocalHavenRepositoryArchive on LocalHavenRepository {
  Future<String> _archiveBuildLocalArchiveJson() async {
    final systems = await (database.select(
      database.pluralSystems,
    )..where((system) => system.id.equals(localSystemId))).get();
    final members = await (database.select(
      database.members,
    )..where((member) => member.systemId.equals(localSystemId))).get();
    final memberIds = members.map((member) => member.id).toSet();
    final groups = await (database.select(
      database.systemGroups,
    )..where((group) => group.systemId.equals(localSystemId))).get();
    final groupIds = groups.map((group) => group.id).toSet();
    final groupMembers = await database.select(database.groupMembers).get();
    final notes = await (database.select(
      database.notes,
    )..where((note) => note.systemId.equals(localSystemId))).get();
    final noteIds = notes.map((note) => note.id).toSet();
    final chatCategories = await (database.select(
      database.chatCategories,
    )..where((category) => category.systemId.equals(localSystemId))).get();
    final chatCategoryIds = chatCategories
        .map((category) => category.id)
        .toSet();
    final chatChannels = await (database.select(
      database.chatChannels,
    )..where((channel) => channel.systemId.equals(localSystemId))).get();
    final messages = await (database.select(
      database.messages,
    )..where((message) => message.systemId.equals(localSystemId))).get();
    final messageIds = messages.map((message) => message.id).toSet();
    final reminders = await (database.select(
      database.reminders,
    )..where((reminder) => reminder.systemId.equals(localSystemId))).get();
    final tags = await (database.select(
      database.tags,
    )..where((tag) => tag.systemId.equals(localSystemId))).get();
    final tagIds = tags.map((tag) => tag.id).toSet();
    final memberTags = await database.select(database.memberTags).get();
    final journals = await (database.select(
      database.journalEntries,
    )..where((journal) => journal.systemId.equals(localSystemId))).get();
    final journalIds = journals.map((journal) => journal.id).toSet();
    final contentRevisions = await database
        .select(database.contentRevisions)
        .get();
    final customFields = await (database.select(
      database.customFieldDefinitions,
    )..where((field) => field.systemId.equals(localSystemId))).get();
    final customFieldIds = customFields.map((field) => field.id).toSet();
    final customFieldValues = await database
        .select(database.customFieldValues)
        .get();
    final polls = await (database.select(
      database.polls,
    )..where((poll) => poll.systemId.equals(localSystemId))).get();
    final pollIds = polls.map((poll) => poll.id).toSet();
    final pollOptions = await database.select(database.pollOptions).get();
    final pollOptionIds = pollOptions.map((option) => option.id).toSet();
    final pollVotes = await database.select(database.pollVotes).get();
    final pollVoteEvents = await database.select(database.pollVoteEvents).get();
    final fronts = await (database.select(
      database.frontSessions,
    )..where((front) => front.systemId.equals(localSystemId))).get();
    final frontIds = fronts.map((front) => front.id).toSet();
    final frontMembers = await database
        .select(database.frontSessionMembers)
        .get();
    final frontAuditEvents = await database
        .select(database.frontAuditEvents)
        .get();
    final namedFronts = await (database.select(
      database.namedFronts,
    )..where((front) => front.systemId.equals(localSystemId))).get();
    final namedFrontIds = namedFronts.map((front) => front.id).toSet();
    final namedFrontMembers = await database
        .select(database.namedFrontMembers)
        .get();
    final privacyBuckets = await (database.select(
      database.privacyBuckets,
    )..where((bucket) => bucket.systemId.equals(localSystemId))).get();
    final privacyBucketIds = privacyBuckets.map((bucket) => bucket.id).toSet();
    final privacyBucketMembers = await database
        .select(database.privacyBucketMembers)
        .get();
    final importRecords = await (database.select(
      database.importRecords,
    )..where((record) => record.systemId.equals(localSystemId))).get();
    final importPayloads = await (database.select(
      database.importPayloads,
    )..where((payload) => payload.systemId.equals(localSystemId))).get();
    final notificationEvents = await (database.select(
      database.notificationEvents,
    )..where((event) => event.systemId.equals(localSystemId))).get();
    final preferences = await database.select(database.appPreferences).get();
    final avatarAssets = await _exportLocalAvatarAssets([
      if (systems.isNotEmpty)
        await _decryptLocalText(
          systems.single.avatarUrl,
          'plural_systems',
          systems.single.id,
          'avatar_url',
        ),
      for (final member in members)
        await _decryptMember(member, 'avatar_url', member.avatarUrl),
      for (final front in namedFronts)
        await _decryptLocalText(
          front.avatarUrl,
          'named_fronts',
          front.id,
          'avatar_url',
        ),
    ]);

    final archive = {
      'format': 'pluris_haven.local_archive',
      'version': 1,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'system': systems.isEmpty ? null : await _systemToJson(systems.single),
      'members': [for (final member in members) await _memberToJson(member)],
      'groups': [for (final group in groups) await _groupToJson(group)],
      'group_members': [
        for (final link in groupMembers)
          if (groupIds.contains(link.groupId)) _groupMemberToJson(link),
      ],
      'notes': [for (final note in notes) await _noteToJson(note)],
      'chat_categories': [
        for (final category in chatCategories)
          await _chatCategoryToJson(category),
      ],
      'chat_channels': [
        for (final channel in chatChannels)
          if (channel.categoryId == null ||
              chatCategoryIds.contains(channel.categoryId))
            await _chatChannelToJson(channel),
      ],
      'messages': [
        for (final message in messages) await _messageToJson(message),
      ],
      'reminders': [
        for (final reminder in reminders) await _reminderToJson(reminder),
      ],
      'tags': [for (final tag in tags) await _tagToJson(tag)],
      'member_tags': [
        for (final link in memberTags)
          if (tagIds.contains(link.tagId) && memberIds.contains(link.memberId))
            _memberTagToJson(link),
      ],
      'journals': [
        for (final journal in journals) await _journalToJson(journal),
      ],
      'content_revisions': [
        for (final revision in contentRevisions)
          if (_revisionBelongsToArchive(
            revision,
            memberIds: memberIds,
            noteIds: noteIds,
            journalIds: journalIds,
            messageIds: messageIds,
          ))
            await _contentRevisionToJson(revision),
      ],
      'custom_fields': [
        for (final field in customFields) await _customFieldToJson(field),
      ],
      'custom_field_values': [
        for (final value in customFieldValues)
          if (customFieldIds.contains(value.fieldId))
            await _customFieldValueToJson(value),
      ],
      'polls': [for (final poll in polls) await _pollToJson(poll)],
      'poll_options': [
        for (final option in pollOptions)
          if (pollIds.contains(option.pollId)) await _pollOptionToJson(option),
      ],
      'poll_votes': [
        for (final vote in pollVotes)
          if (pollIds.contains(vote.pollId)) _pollVoteToJson(vote),
      ],
      'poll_vote_events': [
        for (final event in pollVoteEvents)
          if (pollIds.contains(event.pollId) &&
              pollOptionIds.contains(event.optionId))
            _pollVoteEventToJson(event),
      ],
      'fronts': [for (final front in fronts) await _frontToJson(front)],
      'front_members': [
        for (final link in frontMembers)
          if (frontIds.contains(link.sessionId)) _frontMemberToJson(link),
      ],
      'front_audit_events': [
        for (final event in frontAuditEvents)
          if (frontIds.contains(event.frontId))
            await _frontAuditEventToJson(event),
      ],
      'named_fronts': [
        for (final front in namedFronts) await _namedFrontToJson(front),
      ],
      'named_front_members': [
        for (final link in namedFrontMembers)
          if (namedFrontIds.contains(link.namedFrontId))
            _namedFrontMemberToJson(link),
      ],
      'privacy_buckets': [
        for (final bucket in privacyBuckets) await _privacyBucketToJson(bucket),
      ],
      'privacy_bucket_members': [
        for (final link in privacyBucketMembers)
          if (privacyBucketIds.contains(link.bucketId) &&
              memberIds.contains(link.memberId))
            _privacyBucketMemberToJson(link),
      ],
      'avatar_assets': avatarAssets,
      'import_records': [
        for (final record in importRecords) await _importRecordToJson(record),
      ],
      'raw_payloads': [
        for (final payload in importPayloads)
          await _importPayloadToJson(payload),
      ],
      'notification_events': [
        for (final event in notificationEvents)
          await _notificationEventToJson(event),
      ],
      'preferences': [
        for (final preference in preferences) _preferenceToJson(preference),
      ],
    };

    _sanitizeExportedAvatarReferences(
      archive,
      embeddedAssetIds: {
        for (final asset in avatarAssets) ?_stringValue(asset['id']),
      },
    );

    return const JsonEncoder.withIndent('  ').convert(archive);
  }

  void _sanitizeExportedAvatarReferences(
    Map<String, Object?> archive, {
    required Set<String> embeddedAssetIds,
  }) {
    void sanitizeRecord(Object? value) {
      if (value is! Map<String, Object?>) {
        return;
      }
      value['avatar_url'] = _portableExportAvatarReference(
        _stringValue(value['avatar_url']),
        embeddedAssetIds: embeddedAssetIds,
      );
    }

    sanitizeRecord(archive['system']);
    for (final collectionName in const ['members', 'named_fronts']) {
      final records = archive[collectionName];
      if (records is List<Object?>) {
        for (final record in records) {
          sanitizeRecord(record);
        }
      }
    }
  }

  String? _portableExportAvatarReference(
    String? value, {
    required Set<String> embeddedAssetIds,
  }) {
    final reference = value?.trim();
    if (reference == null || reference.isEmpty) {
      return null;
    }

    const localPrefix = 'local-avatar:';
    if (reference.startsWith(localPrefix)) {
      final assetId = reference.substring(localPrefix.length).trim();
      return embeddedAssetIds.contains(assetId) ? '$localPrefix$assetId' : null;
    }

    final uri = Uri.tryParse(reference);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return reference;
    }

    // Native document URIs and filesystem paths only work on the source
    // device. Exported avatar bytes must be referenced through avatar_assets.
    return null;
  }

  Future<RestoreRehearsalSummary> _archiveRehearseLocalArchiveRestore(
    String archiveJson, {
    ImportConflictStrategy strategy = ImportConflictStrategy.prompt,
    String? fileName,
    ImportSource source = ImportSource.plurisHavenArchive,
  }) async {
    final startedAt = DateTime.now().toUtc();
    final previousMultipleDatabaseWarning =
        driftRuntimeOptions.dontWarnAboutMultipleDatabases;
    late final AppDatabase rehearsalDatabase;
    try {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      rehearsalDatabase = AppDatabase(await openRehearsalDatabaseConnection());
    } finally {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases =
          previousMultipleDatabaseWarning;
    }
    try {
      final rehearsalRepository = LocalHavenRepository(
        rehearsalDatabase,
        crypto: crypto,
      );
      await rehearsalRepository.ensureLocalSystem();
      await rehearsalRepository._archiveImportLocalArchiveJson(
        archiveJson,
        strategy: strategy,
        fileName: fileName,
        source: source,
        localizeAvatars: false,
      );
      final counts = await _rehearsalCounts(rehearsalDatabase);
      final checkedAt = DateTime.now().toUtc();
      appDebugLog(
        'Restore rehearsal passed source=${source.name} '
        'file=${fileName ?? '(none)'} counts=$counts',
      );
      return RestoreRehearsalSummary(
        canRestore: true,
        fileName: fileName,
        counts: counts,
        checkedAt: checkedAt,
        elapsed: checkedAt.difference(startedAt),
      );
    } on Object catch (error, stackTrace) {
      final checkedAt = DateTime.now().toUtc();
      appDebugLog(
        'Restore rehearsal failed source=${source.name} '
        'file=${fileName ?? '(none)'}',
        error: error,
        stackTrace: stackTrace,
      );
      return RestoreRehearsalSummary(
        canRestore: false,
        fileName: fileName,
        counts: const {},
        checkedAt: checkedAt,
        elapsed: checkedAt.difference(startedAt),
        error: error.toString(),
      );
    } finally {
      await rehearsalDatabase.close();
    }
  }

  Future<Map<String, int>> _rehearsalCounts(AppDatabase database) async {
    final members = await database.select(database.members).get();
    final groups = await database.select(database.systemGroups).get();
    final groupMembers = await database.select(database.groupMembers).get();
    final notes = await database.select(database.notes).get();
    final chatCategories = await database.select(database.chatCategories).get();
    final chatChannels = await database.select(database.chatChannels).get();
    final messages = await database.select(database.messages).get();
    final reminders = await database.select(database.reminders).get();
    final tags = await database.select(database.tags).get();
    final memberTags = await database.select(database.memberTags).get();
    final journals = await database.select(database.journalEntries).get();
    final contentRevisions = await database
        .select(database.contentRevisions)
        .get();
    final customFields = await database
        .select(database.customFieldDefinitions)
        .get();
    final customFieldValues = await database
        .select(database.customFieldValues)
        .get();
    final polls = await database.select(database.polls).get();
    final pollOptions = await database.select(database.pollOptions).get();
    final pollVotes = await database.select(database.pollVotes).get();
    final pollVoteEvents = await database.select(database.pollVoteEvents).get();
    final fronts = await database.select(database.frontSessions).get();
    final frontMembers = await database
        .select(database.frontSessionMembers)
        .get();
    final frontAuditEvents = await database
        .select(database.frontAuditEvents)
        .get();
    final namedFronts = await database.select(database.namedFronts).get();
    final namedFrontMembers = await database
        .select(database.namedFrontMembers)
        .get();
    final privacyBuckets = await database.select(database.privacyBuckets).get();
    final privacyBucketMembers = await database
        .select(database.privacyBucketMembers)
        .get();
    final importRecords = await database.select(database.importRecords).get();
    final rawPayloads = await database.select(database.importPayloads).get();
    final notificationEvents = await database
        .select(database.notificationEvents)
        .get();
    final preferences = await database.select(database.appPreferences).get();

    final customFrontCount = members
        .where((member) => member.isCustomFront)
        .length;

    return {
      'members': members.length - customFrontCount,
      'custom_fronts': customFrontCount,
      'groups': groups.length,
      'group_members': groupMembers.length,
      'notes': notes.length,
      'chat_categories': chatCategories.length,
      'chat_channels': chatChannels.length,
      'messages': messages.length,
      'reminders': reminders.length,
      'tags': tags.length,
      'member_tags': memberTags.length,
      'journals': journals.length,
      'content_revisions': contentRevisions.length,
      'custom_fields': customFields.length,
      'custom_field_values': customFieldValues.length,
      'polls': polls.length,
      'poll_options': pollOptions.length,
      'poll_votes': pollVotes.length,
      'poll_vote_events': pollVoteEvents.length,
      'fronts': fronts.length,
      'front_members': frontMembers.length,
      'front_audit_events': frontAuditEvents.length,
      'named_fronts': namedFronts.length,
      'named_front_members': namedFrontMembers.length,
      'privacy_buckets': privacyBuckets.length,
      'privacy_bucket_members': privacyBucketMembers.length,
      'import_records': importRecords.length,
      'raw_payloads': rawPayloads.length,
      'notification_events': notificationEvents.length,
      'preferences': preferences.length,
    };
  }

  Future<String> _archiveEnqueueImportArchiveJob(
    String archiveJson, {
    required ImportConflictStrategy strategy,
    String? fileName,
    required ImportSource source,
  }) async {
    final now = DateTime.now().toUtc();
    final jobId = 'job-${now.microsecondsSinceEpoch}';
    appDebugLog(
      'Queue import job id=$jobId source=${source.name} file=${fileName ?? '(none)'} strategy=${strategy.name}',
    );
    await database
        .into(database.backgroundJobs)
        .insert(
          BackgroundJobsCompanion.insert(
            id: jobId,
            systemId: localSystemId,
            type: 'import_archive',
            status: 'queued',
            source: Value(source.name),
            fileName: Value(
              await _encryptNullableLocalText(
                _nullIfBlank(fileName),
                'background_jobs',
                jobId,
                'file_name',
              ),
            ),
            payloadJson: await _encryptLocalText(
              jsonEncode({
                'archive_json': archiveJson,
                'strategy': strategy.name,
              }),
              'background_jobs',
              jobId,
              'payload_json',
            ),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return jobId;
  }

  Future<bool> _archiveRunBackgroundJob(String jobId) async {
    final job = await (database.select(
      database.backgroundJobs,
    )..where((job) => job.id.equals(jobId))).getSingleOrNull();
    if (job == null || job.status == 'done') {
      appDebugLog(
        'Skip background job id=$jobId status=${job?.status ?? 'missing'}',
      );
      return true;
    }

    final now = DateTime.now().toUtc();
    appDebugLog(
      'Run background job id=$jobId type=${job.type} source=${job.source}',
    );
    await (database.update(
      database.backgroundJobs,
    )..where((job) => job.id.equals(jobId))).write(
      BackgroundJobsCompanion(
        status: const Value('running'),
        error: const Value(null),
        startedAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    try {
      if (job.type == 'import_archive') {
        final payload = jsonDecode(
          (await _decryptLocalText(
                job.payloadJson,
                'background_jobs',
                job.id,
                'payload_json',
              )) ??
              '',
        );
        if (payload is! Map<String, Object?>) {
          throw const FormatException('Import job payload is invalid.');
        }
        final source = ImportSource.values.firstWhere(
          (source) => source.name == job.source,
          orElse: () => ImportSource.plurisHavenArchive,
        );
        final strategyName = _stringValue(payload['strategy']);
        final strategy = ImportConflictStrategy.values.firstWhere(
          (strategy) => strategy.name == strategyName,
          orElse: () => ImportConflictStrategy.skip,
        );
        await _archiveImportLocalArchiveJson(
          _requiredString(payload, 'archive_json'),
          strategy: strategy,
          fileName: await _decryptLocalText(
            job.fileName,
            'background_jobs',
            job.id,
            'file_name',
          ),
          source: source,
        );
      } else {
        throw FormatException('Unsupported background job type: ${job.type}.');
      }

      final finished = DateTime.now().toUtc();
      appDebugLog('Background job complete id=$jobId');
      await (database.update(
        database.backgroundJobs,
      )..where((job) => job.id.equals(jobId))).write(
        BackgroundJobsCompanion(
          status: const Value('done'),
          updatedAt: Value(finished),
          finishedAt: Value(finished),
        ),
      );
      return true;
    } on Object catch (error, stackTrace) {
      appDebugLog(
        'Background job failed id=$jobId',
        error: error,
        stackTrace: stackTrace,
      );
      final failed = DateTime.now().toUtc();
      final errorText = _debugErrorText(error, stackTrace);
      await (database.update(
        database.backgroundJobs,
      )..where((job) => job.id.equals(jobId))).write(
        BackgroundJobsCompanion(
          status: const Value('failed'),
          error: Value(
            await _encryptLocalText(
              errorText,
              'background_jobs',
              job.id,
              'error',
            ),
          ),
          updatedAt: Value(failed),
          finishedAt: Value(failed),
        ),
      );
      return false;
    }
  }

  Future<bool> runQueuedImportJobs() async {
    final jobs =
        await (database.select(database.backgroundJobs)
              ..where(
                (job) =>
                    job.systemId.equals(localSystemId) &
                    job.type.equals('import_archive') &
                    job.status.isIn(const ['queued', 'running']),
              )
              ..orderBy([
                (job) => OrderingTerm(
                  expression: job.createdAt,
                  mode: OrderingMode.asc,
                ),
              ]))
            .get();
    if (jobs.isEmpty) {
      appDebugLog('No queued import jobs to run');
      return true;
    }

    var allSucceeded = true;
    for (final job in jobs) {
      allSucceeded = await _archiveRunBackgroundJob(job.id) && allSucceeded;
    }
    return allSucceeded;
  }

  Future<void> _archiveImportLocalArchiveJson(
    String archiveJson, {
    ImportConflictStrategy strategy = ImportConflictStrategy.prompt,
    String? fileName,
    ImportSource source = ImportSource.plurisHavenArchive,
    bool localizeAvatars = true,
  }) async {
    final decoded = jsonDecode(archiveJson);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Expected a JSON object archive.');
    }
    if (decoded['format'] != 'pluris_haven.local_archive') {
      throw const FormatException('Unsupported archive format.');
    }
    if (decoded['version'] != 1) {
      throw FormatException(
        'Unsupported archive version: ${decoded['version']}.',
      );
    }

    final now = DateTime.now().toUtc();
    final members = _jsonObjectList(decoded['members']);
    final groups = _jsonObjectList(decoded['groups']);
    final groupMembers = _jsonObjectList(decoded['group_members']);
    final notes = _jsonObjectList(decoded['notes']);
    final chatCategories = _jsonObjectList(decoded['chat_categories']);
    final chatChannels = _jsonObjectList(decoded['chat_channels']);
    final messages = _jsonObjectList(decoded['messages']);
    final reminders = _jsonObjectList(decoded['reminders']);
    final tags = _jsonObjectList(decoded['tags']);
    final memberTags = _jsonObjectList(decoded['member_tags']);
    final journals = _jsonObjectList(decoded['journals']);
    final contentRevisions = _jsonObjectList(decoded['content_revisions']);
    final customFields = _jsonObjectList(decoded['custom_fields']);
    final customFieldValues = _jsonObjectList(decoded['custom_field_values']);
    final polls = _jsonObjectList(decoded['polls']);
    final pollOptions = _jsonObjectList(decoded['poll_options']);
    final pollVotes = _jsonObjectList(decoded['poll_votes']);
    final pollVoteEvents = _jsonObjectList(decoded['poll_vote_events']);
    final fronts = _jsonObjectList(decoded['fronts']);
    final frontMembers = _jsonObjectList(decoded['front_members']);
    final frontAuditEvents = _jsonObjectList(decoded['front_audit_events']);
    final namedFronts = _jsonObjectList(decoded['named_fronts']);
    final namedFrontMembers = _jsonObjectList(decoded['named_front_members']);
    final privacyBuckets = _jsonObjectList(decoded['privacy_buckets']);
    final privacyBucketMembers = _jsonObjectList(
      decoded['privacy_bucket_members'],
    );
    final avatarAssets = _jsonObjectList(decoded['avatar_assets']);
    final rawPayloads = _jsonObjectList(decoded['raw_payloads']);
    final notificationEvents = _jsonObjectList(decoded['notification_events']);
    final preferences = _jsonObjectList(decoded['preferences']);
    final cleanupCount = _sanitizeArchiveReferences(
      groups: groups,
      groupMembers: groupMembers,
      members: members,
      notes: notes,
      chatCategories: chatCategories,
      chatChannels: chatChannels,
      messages: messages,
      tags: tags,
      memberTags: memberTags,
      journals: journals,
      contentRevisions: contentRevisions,
      customFields: customFields,
      customFieldValues: customFieldValues,
      polls: polls,
      pollOptions: pollOptions,
      pollVotes: pollVotes,
      pollVoteEvents: pollVoteEvents,
      fronts: fronts,
      frontMembers: frontMembers,
      frontAuditEvents: frontAuditEvents,
      namedFronts: namedFronts,
      namedFrontMembers: namedFrontMembers,
    );
    appDebugLog(
      'Import archive source=${source.name} file=${fileName ?? '(none)'} '
      'members=${members.length} groups=${groups.length} notes=${notes.length} '
      'messages=${messages.length} reminders=${reminders.length} fronts=${fronts.length} '
      'namedFronts=${namedFronts.length} '
      'tags=${tags.length} memberTags=${memberTags.length} journals=${journals.length} '
      'contentRevisions=${contentRevisions.length} frontAuditEvents=${frontAuditEvents.length} '
      'pollVoteEvents=${pollVoteEvents.length} '
      'customFields=${customFields.length} customFieldValues=${customFieldValues.length} '
      'polls=${polls.length} pollOptions=${pollOptions.length} pollVotes=${pollVotes.length} '
      'frontMembers=${frontMembers.length} groupMembers=${groupMembers.length} '
      'cleanup=$cleanupCount',
    );
    final system = decoded['system'];
    final systemRecord = system is Map<String, Object?> ? system : null;
    final localAvatarRefs = localizeAvatars
        ? await _localizeImportAvatars(
            members: [?systemRecord, ...members, ...namedFronts],
            avatarAssets: avatarAssets,
          )
        : const <String, String>{};
    if (localizeAvatars) {
      for (final record in [?systemRecord, ...members, ...namedFronts]) {
        record['avatar_url'] = localAvatarRefs[_requiredString(record, 'id')];
      }
    }

    await database.transaction(() async {
      if (systemRecord != null) {
        final name = _stringValue(systemRecord['name'])?.trim();
        if (name != null && name.isNotEmpty) {
          await database
              .into(database.pluralSystems)
              .insertOnConflictUpdate(
                PluralSystemsCompanion.insert(
                  id: localSystemId,
                  name: await _encryptLocalText(
                    name,
                    'plural_systems',
                    localSystemId,
                    'name',
                  ),
                  colorHex: Value(
                    await _encryptNullableLocalText(
                      _stringValue(systemRecord['color_hex']),
                      'plural_systems',
                      localSystemId,
                      'color_hex',
                    ),
                  ),
                  avatarUrl: Value(
                    await _encryptNullableLocalText(
                      localAvatarRefs[localSystemId] ??
                          _stringValue(systemRecord['avatar_url']),
                      'plural_systems',
                      localSystemId,
                      'avatar_url',
                    ),
                  ),
                  description: Value(
                    await _encryptNullableLocalText(
                      _stringValue(systemRecord['description']),
                      'plural_systems',
                      localSystemId,
                      'description',
                    ),
                  ),
                  createdAt: _dateValue(systemRecord['created_at']) ?? now,
                  updatedAt: now,
                ),
              );
        }
      }

      for (final group in groups) {
        await _importGroup(group, strategy, now);
      }
      for (final member in members) {
        final memberId = _requiredString(member, 'id');
        await _importMember(member, strategy, now, localAvatarRefs[memberId]);
        final folderId = _stringValue(member['folder_id']);
        if (folderId != null) {
          await _importGroupMember({
            'group_id': folderId,
            'member_id': memberId,
          });
        }
      }
      for (final link in groupMembers) {
        await _importGroupMember(link);
      }
      for (final note in notes) {
        await _importNote(note, strategy, now);
      }
      for (final category in chatCategories) {
        await _importChatCategory(category, strategy, now);
      }
      for (final channel in chatChannels) {
        await _importChatChannel(channel, strategy, now);
      }
      for (final message in messages) {
        await _importMessage(message, strategy, now);
      }
      for (final reminder in reminders) {
        await _importReminder(reminder, strategy, now);
      }
      for (final tag in tags) {
        await _importTag(tag, strategy, now);
      }
      for (final link in memberTags) {
        await _importMemberTag(link);
      }
      for (final journal in journals) {
        await _importJournal(journal, strategy, now);
      }
      for (final field in customFields) {
        await _importCustomField(field, strategy, now);
      }
      for (final value in customFieldValues) {
        await _importCustomFieldValue(value, strategy, now);
      }
      for (final poll in polls) {
        await _importPoll(poll, strategy, now);
      }
      for (final option in pollOptions) {
        await _importPollOption(option, strategy);
      }
      for (final vote in pollVotes) {
        await _importPollVote(vote);
      }
      for (final event in pollVoteEvents) {
        await _importPollVoteEvent(event, strategy, now);
      }
      for (final front in fronts) {
        await _importFront(front, strategy, now);
      }
      for (final link in frontMembers) {
        await _importFrontMember(link);
      }
      for (final event in frontAuditEvents) {
        await _importFrontAuditEvent(event, strategy, now);
      }
      for (final namedFront in namedFronts) {
        await _importNamedFront(
          namedFront,
          strategy,
          now,
          localAvatarRefs[_requiredString(namedFront, 'id')],
        );
      }
      for (final link in namedFrontMembers) {
        await _importNamedFrontMember(link);
      }
      for (final bucket in privacyBuckets) {
        await _importPrivacyBucket(bucket, strategy, now);
      }
      for (final link in privacyBucketMembers) {
        await _importPrivacyBucketMember(link);
      }
      for (final event in notificationEvents) {
        await _importNotificationEvent(event, strategy, now);
      }
      for (final preference in preferences) {
        await _importPreference(preference, strategy, now);
      }
      for (final revision in contentRevisions) {
        await _importContentRevision(revision, strategy, now);
      }

      final importRecordId = 'import-${now.microsecondsSinceEpoch}';
      await database
          .into(database.importRecords)
          .insert(
            ImportRecordsCompanion.insert(
              id: importRecordId,
              systemId: localSystemId,
              source: source.jobSource,
              fileName: Value(
                await _encryptNullableLocalText(
                  _nullIfBlank(fileName),
                  'import_records',
                  importRecordId,
                  'file_name',
                ),
              ),
              summaryJson: Value(
                await _encryptLocalText(
                  jsonEncode({
                    'members': members.length,
                    'groups': groups.length,
                    'group_members': groupMembers.length,
                    'notes': notes.length,
                    'chat_categories': chatCategories.length,
                    'chat_channels': chatChannels.length,
                    'messages': messages.length,
                    'reminders': reminders.length,
                    'tags': tags.length,
                    'member_tags': memberTags.length,
                    'journals': journals.length,
                    'content_revisions': contentRevisions.length,
                    'custom_fields': customFields.length,
                    'custom_field_values': customFieldValues.length,
                    'polls': polls.length,
                    'poll_options': pollOptions.length,
                    'poll_votes': pollVotes.length,
                    'poll_vote_events': pollVoteEvents.length,
                    'fronts': fronts.length,
                    'front_members': frontMembers.length,
                    'front_audit_events': frontAuditEvents.length,
                    'named_fronts': namedFronts.length,
                    'named_front_members': namedFrontMembers.length,
                    'privacy_buckets': privacyBuckets.length,
                    'privacy_bucket_members': privacyBucketMembers.length,
                    'avatar_assets': avatarAssets.length,
                    'raw_payloads': rawPayloads.length,
                    'notification_events': notificationEvents.length,
                    'preferences': preferences.length,
                  }),
                  'import_records',
                  importRecordId,
                  'summary_json',
                ),
              ),
              importedAt: now,
            ),
          );

      for (final payload in rawPayloads) {
        await _importPayload(payload, importRecordId, source, strategy, now);
      }
    });
  }

  int _sanitizeArchiveReferences({
    required List<Map<String, Object?>> groups,
    required List<Map<String, Object?>> groupMembers,
    required List<Map<String, Object?>> members,
    required List<Map<String, Object?>> notes,
    required List<Map<String, Object?>> chatCategories,
    required List<Map<String, Object?>> chatChannels,
    required List<Map<String, Object?>> messages,
    required List<Map<String, Object?>> tags,
    required List<Map<String, Object?>> memberTags,
    required List<Map<String, Object?>> journals,
    required List<Map<String, Object?>> contentRevisions,
    required List<Map<String, Object?>> customFields,
    required List<Map<String, Object?>> customFieldValues,
    required List<Map<String, Object?>> polls,
    required List<Map<String, Object?>> pollOptions,
    required List<Map<String, Object?>> pollVotes,
    required List<Map<String, Object?>> pollVoteEvents,
    required List<Map<String, Object?>> fronts,
    required List<Map<String, Object?>> frontMembers,
    required List<Map<String, Object?>> frontAuditEvents,
    required List<Map<String, Object?>> namedFronts,
    required List<Map<String, Object?>> namedFrontMembers,
  }) {
    final groupIds = {
      for (final group in groups) _stringValue(group['id']),
    }.whereType<String>().toSet();
    final memberIds = {
      for (final member in members) _stringValue(member['id']),
    }.whereType<String>().toSet();
    final noteIds = {
      for (final note in notes) _stringValue(note['id']),
    }.whereType<String>().toSet();
    final chatCategoryIds = {
      for (final category in chatCategories) _stringValue(category['id']),
    }.whereType<String>().toSet();
    final chatChannelIds = {
      for (final channel in chatChannels) _stringValue(channel['id']),
    }.whereType<String>().toSet();
    final messageIds = {
      for (final message in messages) _stringValue(message['id']),
    }.whereType<String>().toSet();
    final tagIds = {
      for (final tag in tags) _stringValue(tag['id']),
    }.whereType<String>().toSet();
    final journalIds = {
      for (final journal in journals) _stringValue(journal['id']),
    }.whereType<String>().toSet();
    final customFieldIds = {
      for (final field in customFields) _stringValue(field['id']),
    }.whereType<String>().toSet();
    final pollIds = {
      for (final poll in polls) _stringValue(poll['id']),
    }.whereType<String>().toSet();
    final pollOptionIds = {
      for (final option in pollOptions) _stringValue(option['id']),
    }.whereType<String>().toSet();
    final frontIds = {
      for (final front in fronts) _stringValue(front['id']),
    }.whereType<String>().toSet();
    final namedFrontIds = {
      for (final front in namedFronts) _stringValue(front['id']),
    }.whereType<String>().toSet();
    var cleanupCount = 0;

    for (final group in groups) {
      final groupId = _stringValue(group['id']);
      final parentId = _stringValue(group['parent_group_id']);
      if (parentId != null &&
          (parentId == groupId ||
              !groupIds.contains(parentId) ||
              _groupParentChainHasCycle(groupId, parentId, groups))) {
        group['parent_group_id'] = null;
        cleanupCount++;
      }
    }

    for (final member in members) {
      final groupId = _stringValue(member['folder_id']);
      if (groupId != null && !groupIds.contains(groupId)) {
        member['folder_id'] = null;
        cleanupCount++;
      }
    }

    groupMembers.removeWhere((link) {
      final groupId = _stringValue(link['group_id']);
      final memberId = _stringValue(link['member_id']);
      final keep =
          groupId != null &&
          memberId != null &&
          groupIds.contains(groupId) &&
          memberIds.contains(memberId);
      if (!keep) {
        cleanupCount++;
      }
      return !keep;
    });

    for (final note in notes) {
      final memberId = _stringValue(note['member_id']);
      if (memberId != null && !memberIds.contains(memberId)) {
        note['member_id'] = null;
        cleanupCount++;
      }
    }

    for (final message in messages) {
      final memberId = _stringValue(message['member_id']);
      if (memberId != null && !memberIds.contains(memberId)) {
        message['member_id'] = null;
        cleanupCount++;
      }
      final boardMemberId = _stringValue(message['board_member_id']);
      if (boardMemberId != null && !memberIds.contains(boardMemberId)) {
        message['board_member_id'] = null;
        cleanupCount++;
      }
      final channelId = _stringValue(message['channel_id']);
      if (channelId != null && !chatChannelIds.contains(channelId)) {
        message['channel_id'] = null;
        cleanupCount++;
      }
      final parentMessageId = _stringValue(message['parent_message_id']);
      if (parentMessageId != null && !messageIds.contains(parentMessageId)) {
        message['parent_message_id'] = null;
        cleanupCount++;
      }
    }

    for (final channel in chatChannels) {
      final categoryId = _stringValue(channel['category_id']);
      if (categoryId != null && !chatCategoryIds.contains(categoryId)) {
        channel['category_id'] = null;
        cleanupCount++;
      }
    }

    memberTags.removeWhere((link) {
      final tagId = _stringValue(link['tag_id']);
      final memberId = _stringValue(link['member_id']);
      final keep =
          tagId != null &&
          memberId != null &&
          tagIds.contains(tagId) &&
          memberIds.contains(memberId);
      if (!keep) {
        cleanupCount++;
      }
      return !keep;
    });

    for (final journal in journals) {
      final memberId = _stringValue(journal['member_id']);
      if (memberId != null && !memberIds.contains(memberId)) {
        journal['member_id'] = null;
        cleanupCount++;
      }
    }

    contentRevisions.removeWhere((revision) {
      final targetType = _stringValue(revision['target_type']);
      final targetId = _stringValue(revision['target_id']);
      final keep =
          targetType != null &&
          targetId != null &&
          _revisionTargetBelongsToArchive(
            targetType: targetType,
            targetId: targetId,
            memberIds: memberIds,
            noteIds: noteIds,
            journalIds: journalIds,
            messageIds: messageIds,
          );
      if (!keep) {
        cleanupCount++;
      }
      return !keep;
    });

    customFieldValues.removeWhere((value) {
      final fieldId = _stringValue(value['field_id']);
      final memberId = _stringValue(value['member_id']);
      final keep =
          fieldId != null &&
          customFieldIds.contains(fieldId) &&
          (memberId == null || memberIds.contains(memberId));
      if (!keep) {
        cleanupCount++;
      }
      return !keep;
    });

    pollOptions.removeWhere((option) {
      final pollId = _stringValue(option['poll_id']);
      final keep = pollId != null && pollIds.contains(pollId);
      if (!keep) {
        cleanupCount++;
      }
      return !keep;
    });

    pollVotes.removeWhere((vote) {
      final pollId = _stringValue(vote['poll_id']);
      final optionId = _stringValue(vote['option_id']);
      final keep =
          pollId != null &&
          optionId != null &&
          pollIds.contains(pollId) &&
          pollOptionIds.contains(optionId);
      if (!keep) {
        cleanupCount++;
      }
      return !keep;
    });

    pollVoteEvents.removeWhere((event) {
      final pollId = _stringValue(event['poll_id']);
      final optionId = _stringValue(event['option_id']);
      final keep =
          pollId != null &&
          optionId != null &&
          pollIds.contains(pollId) &&
          pollOptionIds.contains(optionId);
      if (!keep) {
        cleanupCount++;
      }
      return !keep;
    });

    frontMembers.removeWhere((link) {
      final sessionId = _stringValue(link['session_id']);
      final memberId = _stringValue(link['member_id']);
      final keep =
          sessionId != null &&
          memberId != null &&
          frontIds.contains(sessionId) &&
          memberIds.contains(memberId);
      if (!keep) {
        cleanupCount++;
      }
      return !keep;
    });

    frontAuditEvents.removeWhere((event) {
      final frontId = _stringValue(event['front_id']);
      final keep = frontId != null && frontIds.contains(frontId);
      if (!keep) {
        cleanupCount++;
      }
      return !keep;
    });

    namedFrontMembers.removeWhere((link) {
      final namedFrontId = _stringValue(link['named_front_id']);
      final memberId = _stringValue(link['member_id']);
      final keep =
          namedFrontId != null &&
          memberId != null &&
          namedFrontIds.contains(namedFrontId) &&
          memberIds.contains(memberId);
      if (!keep) {
        cleanupCount++;
      }
      return !keep;
    });

    return cleanupCount;
  }

  bool _revisionBelongsToArchive(
    ContentRevision revision, {
    required Set<String> memberIds,
    required Set<String> noteIds,
    required Set<String> journalIds,
    required Set<String> messageIds,
  }) {
    return _revisionTargetBelongsToArchive(
      targetType: revision.targetType,
      targetId: revision.targetId,
      memberIds: memberIds,
      noteIds: noteIds,
      journalIds: journalIds,
      messageIds: messageIds,
    );
  }

  bool _revisionTargetBelongsToArchive({
    required String targetType,
    required String targetId,
    required Set<String> memberIds,
    required Set<String> noteIds,
    required Set<String> journalIds,
    required Set<String> messageIds,
  }) {
    return switch (targetType) {
      'member_bio' => memberIds.contains(targetId),
      'note' => noteIds.contains(targetId),
      'journal' => journalIds.contains(targetId),
      'message' => messageIds.contains(targetId),
      _ => false,
    };
  }

  Future<Map<String, String?>> _localizeImportAvatars({
    required List<Map<String, Object?>> members,
    required List<Map<String, Object?>> avatarAssets,
  }) async {
    final assetsById = <String, _ImportAvatarBytes>{};
    for (final asset in avatarAssets) {
      final id = _stringValue(asset['id']);
      final encodedBytes = _stringValue(asset['bytes_base64']);
      if (id == null || encodedBytes == null) {
        continue;
      }
      try {
        assetsById[id] = _ImportAvatarBytes(
          id: id,
          name: _stringValue(asset['name']) ?? id,
          mimeType: _stringValue(asset['mime_type']),
          bytes: base64Decode(encodedBytes),
        );
      } on FormatException {
        continue;
      }
    }

    final refs = <String, String?>{};
    for (final member in members) {
      final memberId = _requiredString(member, 'id');
      final avatarUrl = _stringValue(member['avatar_url']);
      if (avatarUrl == null) {
        refs[memberId] = avatarUrl;
        continue;
      }

      if (avatarUrl.startsWith('local-avatar:')) {
        final assetId = avatarUrl.substring('local-avatar:'.length).trim();
        final asset = assetsById[assetId];
        refs[memberId] = asset == null
            ? avatarUrl
            : await _storeAvatarBytes(
                id: asset.id,
                sourceName: asset.name,
                mimeType: asset.mimeType,
                bytes: asset.bytes,
              );
        continue;
      }

      if (avatarUrl.startsWith('import-asset:') ||
          avatarUrl.startsWith('sp-avatar:')) {
        final assetId = avatarUrl.split(':').last;
        final asset = assetsById[assetId];
        refs[memberId] = asset == null
            ? avatarUrl
            : await _storeAvatarBytes(
                id: asset.id,
                sourceName: asset.name,
                mimeType: asset.mimeType,
                bytes: asset.bytes,
              );
        continue;
      }

      if (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')) {
        refs[memberId] = await _downloadAndStoreAvatar(avatarUrl);
        continue;
      }

      refs[memberId] = avatarUrl;
    }
    return refs;
  }

  Future<List<Map<String, Object?>>> _exportLocalAvatarAssets(
    Iterable<String?> avatarUrls,
  ) async {
    final fileNames =
        <String>{
          for (final avatarUrl in avatarUrls)
            if (avatarUrl != null && avatarUrl.startsWith('local-avatar:'))
              avatarUrl.substring('local-avatar:'.length).trim(),
        }..removeWhere(
          (name) => name.isEmpty || name.contains('/') || name.contains('\\'),
        );
    if (fileNames.isEmpty) {
      return const [];
    }

    final root = await _avatarRootDirectory();
    final assets = <Map<String, Object?>>[];
    for (final fileName in fileNames) {
      final file = File('${root.path}/$fileName');
      if (!await file.exists()) {
        continue;
      }
      final length = await file.length();
      if (length <= 0 || length > 10 * 1024 * 1024) {
        continue;
      }
      final bytes = await file.readAsBytes();
      assets.add({
        'id': fileName,
        'name': fileName,
        'mime_type': _avatarMimeType(fileName, bytes),
        'bytes_base64': base64Encode(bytes),
      });
    }
    return assets;
  }

  String? _avatarMimeType(String fileName, Uint8List bytes) {
    final detected = sniffAvatarMimeType(bytes);
    if (detected != null) return detected;
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.svg')) return 'image/svg+xml';
    return null;
  }

  Future<String?> _downloadAndStoreAvatar(String url) async {
    final uri = Uri.tryParse(url);
    final allowedAddresses = uri == null
        ? null
        : await allowedRemoteAvatarAddresses(uri);
    if (uri == null || allowedAddresses == null) {
      appDebugLog('Avatar download skipped unsafe URL');
      return null;
    }

    final pinnedAddress = allowedAddresses.first;
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 8);
    client.findProxy = (_) => 'DIRECT';
    client.connectionFactory = (requestUri, proxyHost, proxyPort) async {
      if (proxyHost != null ||
          requestUri.host.toLowerCase() != uri.host.toLowerCase() ||
          requestUri.port != uri.port) {
        throw const SocketException('Avatar connection target changed.');
      }
      final task = await Socket.startConnect(pinnedAddress, requestUri.port);
      final secureSocket = task.socket.then(
        (socket) => SecureSocket.secure(socket, host: requestUri.host),
      );
      return ConnectionTask.fromSocket(secureSocket, task.cancel);
    };
    try {
      final request = await client.getUrl(uri);
      request.followRedirects = false;
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        appDebugLog(
          'Avatar download skipped host=${uri.host} status=${response.statusCode}',
        );
        return null;
      }

      final bytes = await _readAvatarResponseBytes(response);
      if (bytes == null || bytes.isEmpty) {
        appDebugLog('Avatar download skipped host=${uri.host} invalid bytes');
        return null;
      }

      return _storeAvatarBytes(
        id: uri.pathSegments.isEmpty ? 'remote-avatar' : uri.pathSegments.last,
        sourceName: uri.pathSegments.isEmpty
            ? 'remote-avatar'
            : uri.pathSegments.last,
        mimeType: response.headers.contentType?.mimeType,
        bytes: bytes,
      );
    } on Object catch (error, stackTrace) {
      appDebugLog(
        'Avatar download failed host=${uri.host}',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    } finally {
      client.close(force: true);
    }
  }

  Future<Uint8List?> _readAvatarResponseBytes(
    HttpClientResponse response,
  ) async {
    final declaredLength = response.contentLength;
    if (declaredLength > maximumAvatarBytes) return null;
    final bytes = BytesBuilder(copy: false);
    await response
        .forEach((chunk) {
          if (bytes.length > maximumAvatarBytes - chunk.length) {
            throw const FormatException('Avatar response exceeds size limit.');
          }
          bytes.add(chunk);
        })
        .timeout(const Duration(seconds: 10));
    return bytes.takeBytes();
  }

  Future<String> _storeAvatarBytes({
    required String id,
    required String sourceName,
    required String? mimeType,
    required Uint8List bytes,
  }) async {
    final root = await _avatarRootDirectory();
    final detectedMimeType = sniffAvatarMimeType(bytes) ?? mimeType;
    final extension = _avatarExtension(sourceName, detectedMimeType);
    final safeId = _safeFilePart(id);
    final digest = base64Url
        .encode(bytes.take(18).toList())
        .replaceAll('=', '');
    final fileName = '$safeId-$digest$extension';
    final file = File('${root.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return 'local-avatar:$fileName';
  }

  Future<Directory> _avatarRootDirectory() async {
    Directory base;
    try {
      base = await getApplicationDocumentsDirectory();
    } on Object {
      base = Directory('${Directory.systemTemp.path}/pluris-haven-test');
    }

    final avatars = Directory('${base.path}/avatars');
    if (!await avatars.exists()) {
      await avatars.create(recursive: true);
    }
    return avatars;
  }

  Future<void> _importGroup(
    Map<String, Object?> group,
    ImportConflictStrategy strategy,
    DateTime now,
  ) async {
    final id = _requiredString(group, 'id');
    final name = _requiredString(group, 'name');
    final companion = SystemGroupsCompanion.insert(
      id: id,
      systemId: localSystemId,
      parentGroupId: Value(_stringValue(group['parent_group_id'])),
      name: await _encryptLocalText(name, 'system_groups', id, 'name'),
      colorHex: Value(
        await _encryptNullableLocalText(
          _stringValue(group['color_hex']),
          'system_groups',
          id,
          'color_hex',
        ),
      ),
      description: Value(
        await _encryptNullableLocalText(
          _stringValue(group['description']),
          'system_groups',
          id,
          'description',
        ),
      ),
      emoji: Value(
        await _encryptNullableLocalText(
          _stringValue(group['emoji']),
          'system_groups',
          id,
          'emoji',
        ),
      ),
      createdAt: _dateValue(group['created_at']) ?? now,
      updatedAt: strategy == ImportConflictStrategy.update
          ? now
          : (_dateValue(group['updated_at']) ?? now),
    );
    return _insertArchiveRow(database.systemGroups, companion, strategy);
  }

  Future<void> _importMember(
    Map<String, Object?> member,
    ImportConflictStrategy strategy,
    DateTime now,
    String? localAvatarUrl,
  ) async {
    final id = _requiredString(member, 'id');
    final displayName = _requiredString(member, 'display_name');
    final encryptedName = await _encryptMember(id, 'display_name', displayName);
    if (encryptedName == null) {
      throw StateError('Member name encryption returned no value.');
    }
    final companion = MembersCompanion.insert(
      id: id,
      systemId: localSystemId,
      displayName: encryptedName,
      displayNameHash: Value(await _blindIndex(displayName)),
      profileEncryptionVersion: const Value(2),
      pronouns: Value(
        await _encryptMember(id, 'pronouns', _stringValue(member['pronouns'])),
      ),
      colorHex: Value(
        await _encryptMember(
          id,
          'color_hex',
          _stringValue(member['color_hex']),
        ),
      ),
      birthday: Value(
        await _encryptMember(id, 'birthday', _stringValue(member['birthday'])),
      ),
      emoji: Value(
        await _encryptMember(id, 'emoji', _stringValue(member['emoji'])),
      ),
      privacy: Value(
        await _encryptMember(id, 'privacy', _stringValue(member['privacy'])),
      ),
      folderId: Value(_stringValue(member['folder_id'])),
      description: Value(
        await _encryptMember(
          id,
          'description',
          _stringValue(member['description']),
        ),
      ),
      avatarUrl: Value(
        await _encryptMember(
          id,
          'avatar_url',
          localAvatarUrl ?? _stringValue(member['avatar_url']),
        ),
      ),
      pluralKitId: Value(
        await _encryptMember(
          id,
          'pluralkit_id',
          _stringValue(member['pluralkit_id']),
        ),
      ),
      isCustomFront: Value(member['is_custom_front'] == true),
      archived: Value(member['archived'] == true),
      lexoRank: await _members.rankForImport(
        id,
        _stringValue(member['lexo_rank']),
      ),
      createdAt: _dateValue(member['created_at']) ?? now,
      updatedAt: strategy == ImportConflictStrategy.update
          ? now
          : (_dateValue(member['updated_at']) ?? now),
    );
    await _insertArchiveRow(database.members, companion, strategy);
  }

  Future<void> _importGroupMember(Map<String, Object?> link) {
    return database
        .into(database.groupMembers)
        .insert(
          GroupMembersCompanion.insert(
            groupId: _requiredString(link, 'group_id'),
            memberId: _requiredString(link, 'member_id'),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<void> _importNote(
    Map<String, Object?> note,
    ImportConflictStrategy strategy,
    DateTime now,
  ) async {
    final id = _requiredString(note, 'id');
    final title = _requiredString(note, 'title');
    final companion = NotesCompanion.insert(
      id: id,
      systemId: localSystemId,
      memberId: Value(_stringValue(note['member_id'])),
      title: await _encryptLocalText(title, 'notes', id, 'title'),
      body: await _encryptLocalText(
        _stringValue(note['body']) ?? '',
        'notes',
        id,
        'body',
      ),
      createdAt: _dateValue(note['created_at']) ?? now,
      updatedAt: strategy == ImportConflictStrategy.update
          ? now
          : (_dateValue(note['updated_at']) ?? now),
    );
    await _insertArchiveRow(database.notes, companion, strategy);
  }

  Future<void> _importMessage(
    Map<String, Object?> message,
    ImportConflictStrategy strategy,
    DateTime now,
  ) async {
    final id = _requiredString(message, 'id');
    final body = _requiredString(message, 'body');
    final companion = MessagesCompanion.insert(
      id: id,
      systemId: localSystemId,
      memberId: Value(_stringValue(message['member_id'])),
      body: await _encryptLocalText(body, 'messages', id, 'body'),
      boardKind: Value(_stringValue(message['board_kind']) ?? 'system'),
      boardMemberId: Value(_stringValue(message['board_member_id'])),
      parentMessageId: Value(_stringValue(message['parent_message_id'])),
      channelId: Value(_stringValue(message['channel_id'])),
      deletedAt: Value(_dateValue(message['deleted_at'])),
      archived: Value(message['archived'] == true),
      createdAt: _dateValue(message['created_at']) ?? now,
      updatedAt: strategy == ImportConflictStrategy.update
          ? now
          : (_dateValue(message['updated_at']) ?? now),
    );
    await _insertArchiveRow(database.messages, companion, strategy);
  }

  Future<void> _importChatCategory(
    Map<String, Object?> category,
    ImportConflictStrategy strategy,
    DateTime now,
  ) async {
    final id = _requiredString(category, 'id');
    final companion = ChatCategoriesCompanion.insert(
      id: id,
      systemId: localSystemId,
      name: await _encryptLocalText(
        _requiredString(category, 'name'),
        'chat_categories',
        id,
        'name',
      ),
      description: Value(
        await _encryptNullableLocalText(
          _stringValue(category['description']),
          'chat_categories',
          id,
          'description',
        ),
      ),
      position: Value(_intValue(category['position']) ?? 0),
      createdAt: _dateValue(category['created_at']) ?? now,
      updatedAt: strategy == ImportConflictStrategy.update
          ? now
          : (_dateValue(category['updated_at']) ?? now),
    );
    await _insertArchiveRow(database.chatCategories, companion, strategy);
  }

  Future<void> _importChatChannel(
    Map<String, Object?> channel,
    ImportConflictStrategy strategy,
    DateTime now,
  ) async {
    final id = _requiredString(channel, 'id');
    final companion = ChatChannelsCompanion.insert(
      id: id,
      systemId: localSystemId,
      categoryId: Value(_stringValue(channel['category_id'])),
      name: await _encryptLocalText(
        _requiredString(channel, 'name'),
        'chat_channels',
        id,
        'name',
      ),
      description: Value(
        await _encryptNullableLocalText(
          _stringValue(channel['description']),
          'chat_channels',
          id,
          'description',
        ),
      ),
      colorHex: Value(
        await _encryptNullableLocalText(
          normalizeHexColor(_stringValue(channel['color_hex'])),
          'chat_channels',
          id,
          'color_hex',
        ),
      ),
      position: Value(_intValue(channel['position']) ?? 0),
      createdAt: _dateValue(channel['created_at']) ?? now,
      updatedAt: strategy == ImportConflictStrategy.update
          ? now
          : (_dateValue(channel['updated_at']) ?? now),
    );
    await _insertArchiveRow(database.chatChannels, companion, strategy);
  }

  Future<void> _importReminder(
    Map<String, Object?> reminder,
    ImportConflictStrategy strategy,
    DateTime now,
  ) async {
    final id = _requiredString(reminder, 'id');
    final title = _requiredString(reminder, 'title');
    final scheduleText = _requiredString(reminder, 'schedule_text');
    final companion = RemindersCompanion.insert(
      id: id,
      systemId: localSystemId,
      title: await _encryptLocalText(title, 'reminders', id, 'title'),
      body: Value(
        await _encryptNullableLocalText(
          _stringValue(reminder['body']),
          'reminders',
          id,
          'body',
        ),
      ),
      scheduleText: await _encryptLocalText(
        scheduleText,
        'reminders',
        id,
        'schedule_text',
      ),
      triggerType: Value(_stringValue(reminder['trigger_type']) ?? 'repeated'),
      triggerMemberId: Value(_stringValue(reminder['trigger_member_id'])),
      triggerEvent: Value(
        await _encryptNullableLocalText(
          _stringValue(reminder['trigger_event']),
          'reminders',
          id,
          'trigger_event',
        ),
      ),
      scheduleKind: Value(
        await _encryptNullableLocalText(
          _stringValue(reminder['schedule_kind']),
          'reminders',
          id,
          'schedule_kind',
        ),
      ),
      scheduleTime: Value(
        await _encryptNullableLocalText(
          _stringValue(reminder['schedule_time']),
          'reminders',
          id,
          'schedule_time',
        ),
      ),
      scheduleDowMask: Value(_intValue(reminder['schedule_dow_mask'])),
      scheduleDom: Value(_intValue(reminder['schedule_dom'])),
      delaySeconds: Value(_intValue(reminder['delay_seconds'])),
      enabled: Value(reminder['enabled'] != false),
      lastFiredAt: Value(_dateValue(reminder['last_fired_at'])),
      createdAt: _dateValue(reminder['created_at']) ?? now,
      updatedAt: strategy == ImportConflictStrategy.update
          ? now
          : (_dateValue(reminder['updated_at']) ?? now),
    );
    await _insertArchiveRow(database.reminders, companion, strategy);
  }

  Future<void> _importTag(
    Map<String, Object?> tag,
    ImportConflictStrategy strategy,
    DateTime now,
  ) async {
    final id = _requiredString(tag, 'id');
    final companion = TagsCompanion.insert(
      id: id,
      systemId: localSystemId,
      name: await _encryptLocalText(
        _requiredString(tag, 'name'),
        'tags',
        id,
        'name',
      ),
      colorHex: Value(
        await _encryptNullableLocalText(
          _stringValue(tag['color_hex']),
          'tags',
          id,
          'color_hex',
        ),
      ),
      createdAt: _dateValue(tag['created_at']) ?? now,
      updatedAt: strategy == ImportConflictStrategy.update
          ? now
          : (_dateValue(tag['updated_at']) ?? now),
    );
    await _insertArchiveRow(database.tags, companion, strategy);
  }

  Future<void> _importMemberTag(Map<String, Object?> link) {
    return database
        .into(database.memberTags)
        .insert(
          MemberTagsCompanion.insert(
            tagId: _requiredString(link, 'tag_id'),
            memberId: _requiredString(link, 'member_id'),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<void> _importJournal(
    Map<String, Object?> journal,
    ImportConflictStrategy strategy,
    DateTime now,
  ) async {
    final id = _requiredString(journal, 'id');
    final companion = JournalEntriesCompanion.insert(
      id: id,
      systemId: localSystemId,
      memberId: Value(_stringValue(journal['member_id'])),
      title: Value(
        await _encryptNullableLocalText(
          _stringValue(journal['title']),
          'journal_entries',
          id,
          'title',
        ),
      ),
      body: await _encryptLocalText(
        _stringValue(journal['body']) ?? '',
        'journal_entries',
        id,
        'body',
      ),
      visibility: Value(_stringValue(journal['visibility']) ?? 'system'),
      createdAt: _dateValue(journal['created_at']) ?? now,
      updatedAt: strategy == ImportConflictStrategy.update
          ? now
          : (_dateValue(journal['updated_at']) ?? now),
    );
    await _insertArchiveRow(database.journalEntries, companion, strategy);
  }

  Future<void> _importContentRevision(
    Map<String, Object?> revision,
    ImportConflictStrategy strategy,
    DateTime now,
  ) async {
    final id = _requiredString(revision, 'id');
    final companion = ContentRevisionsCompanion.insert(
      id: id,
      targetType: _requiredString(revision, 'target_type'),
      targetId: _requiredString(revision, 'target_id'),
      title: Value(
        await _encryptNullableLocalText(
          _stringValue(revision['title']),
          'content_revisions',
          id,
          'title',
        ),
      ),
      body: await _encryptLocalText(
        _stringValue(revision['body']) ?? '',
        'content_revisions',
        id,
        'body',
      ),
      pinnedAt: Value(_dateValue(revision['pinned_at'])),
      createdAt: _dateValue(revision['created_at']) ?? now,
    );
    await _insertArchiveRow(database.contentRevisions, companion, strategy);
  }

  Future<void> _importCustomField(
    Map<String, Object?> field,
    ImportConflictStrategy strategy,
    DateTime now,
  ) async {
    final id = _requiredString(field, 'id');
    final name = _requiredString(field, 'name');
    final companion = CustomFieldDefinitionsCompanion.insert(
      id: id,
      systemId: localSystemId,
      name: await _encryptLocalText(
        name,
        'custom_field_definitions',
        id,
        'name',
      ),
      fieldType: Value(_stringValue(field['field_type']) ?? 'text'),
      privacy: Value(
        await _encryptNullableLocalText(
          _stringValue(field['privacy']),
          'custom_field_definitions',
          id,
          'privacy',
        ),
      ),
      position: Value(_intValue(field['position']) ?? 0),
      createdAt: _dateValue(field['created_at']) ?? now,
      updatedAt: strategy == ImportConflictStrategy.update
          ? now
          : (_dateValue(field['updated_at']) ?? now),
    );
    return _insertArchiveRow(
      database.customFieldDefinitions,
      companion,
      strategy,
    );
  }

  Future<void> _importCustomFieldValue(
    Map<String, Object?> value,
    ImportConflictStrategy strategy,
    DateTime now,
  ) async {
    final id = _requiredString(value, 'id');
    final fieldId = _requiredString(value, 'field_id');
    final companion = CustomFieldValuesCompanion.insert(
      id: id,
      fieldId: fieldId,
      memberId: Value(_stringValue(value['member_id'])),
      value: await _encryptLocalText(
        _stringValue(value['value']) ?? '',
        'custom_field_values',
        id,
        'value',
      ),
      createdAt: _dateValue(value['created_at']) ?? now,
      updatedAt: strategy == ImportConflictStrategy.update
          ? now
          : (_dateValue(value['updated_at']) ?? now),
    );
    return _insertArchiveRow(database.customFieldValues, companion, strategy);
  }

  Future<void> _importPoll(
    Map<String, Object?> poll,
    ImportConflictStrategy strategy,
    DateTime now,
  ) async {
    final id = _requiredString(poll, 'id');
    final question = _requiredString(poll, 'question');
    final companion = PollsCompanion.insert(
      id: id,
      systemId: localSystemId,
      question: await _encryptLocalText(question, 'polls', id, 'question'),
      description: Value(
        await _encryptNullableLocalText(
          _stringValue(poll['description']),
          'polls',
          id,
          'description',
        ),
      ),
      kind: Value(
        PollKind.fromStorage(_stringValue(poll['kind'])).storageValue,
      ),
      closed: Value(poll['closed'] == true),
      createdAt: _dateValue(poll['created_at']) ?? now,
      updatedAt: strategy == ImportConflictStrategy.update
          ? now
          : (_dateValue(poll['updated_at']) ?? now),
    );
    await _insertArchiveRow(database.polls, companion, strategy);
  }

  Future<void> _importPollOption(
    Map<String, Object?> option,
    ImportConflictStrategy strategy,
  ) async {
    final id = _requiredString(option, 'id');
    final companion = PollOptionsCompanion.insert(
      id: id,
      pollId: _requiredString(option, 'poll_id'),
      body: await _encryptLocalText(
        _requiredString(option, 'body'),
        'poll_options',
        id,
        'body',
      ),
      position: _intValue(option['position']) ?? 0,
    );
    await _insertArchiveRow(database.pollOptions, companion, strategy);
  }

  Future<void> _importPollVote(Map<String, Object?> vote) {
    return database
        .into(database.pollVotes)
        .insert(
          PollVotesCompanion.insert(
            pollId: _requiredString(vote, 'poll_id'),
            optionId: _requiredString(vote, 'option_id'),
            createdAt: _dateValue(vote['created_at']) ?? DateTime.now().toUtc(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<void> _importPollVoteEvent(
    Map<String, Object?> event,
    ImportConflictStrategy strategy,
    DateTime now,
  ) {
    final id = _requiredString(event, 'id');
    final companion = PollVoteEventsCompanion.insert(
      id: id,
      pollId: _requiredString(event, 'poll_id'),
      optionId: _requiredString(event, 'option_id'),
      action: _requiredString(event, 'action'),
      createdAt: _dateValue(event['created_at']) ?? now,
    );
    return _insertArchiveRow(database.pollVoteEvents, companion, strategy);
  }

  Future<void> _importFront(
    Map<String, Object?> front,
    ImportConflictStrategy strategy,
    DateTime now,
  ) async {
    final id = _requiredString(front, 'id');
    final companion = FrontSessionsCompanion.insert(
      id: id,
      systemId: localSystemId,
      label: Value(
        await _encryptNullableLocalText(
          _stringValue(front['label']),
          'front_sessions',
          id,
          'label',
        ),
      ),
      statusNote: Value(
        await _encryptNullableLocalText(
          _stringValue(front['status_note']),
          'front_sessions',
          id,
          'status_note',
        ),
      ),
      startedAt: _dateValue(front['started_at']) ?? now,
      endedAt: Value(_dateValue(front['ended_at'])),
      createdAt: _dateValue(front['created_at']) ?? now,
      updatedAt: strategy == ImportConflictStrategy.update
          ? now
          : (_dateValue(front['updated_at']) ?? now),
    );
    await _insertArchiveRow(database.frontSessions, companion, strategy);
  }

  Future<void> _importFrontMember(Map<String, Object?> link) {
    return database
        .into(database.frontSessionMembers)
        .insert(
          FrontSessionMembersCompanion.insert(
            sessionId: _requiredString(link, 'session_id'),
            memberId: _requiredString(link, 'member_id'),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<void> _importFrontAuditEvent(
    Map<String, Object?> event,
    ImportConflictStrategy strategy,
    DateTime now,
  ) async {
    final id = _requiredString(event, 'id');
    final companion = FrontAuditEventsCompanion.insert(
      id: id,
      frontId: _requiredString(event, 'front_id'),
      beforeSnapshot: Value(
        await _encryptNullableLocalText(
          _stringValue(event['before_snapshot']),
          'front_audit_events',
          id,
          'before_snapshot',
        ),
      ),
      afterSnapshot: Value(
        await _encryptNullableLocalText(
          _stringValue(event['after_snapshot']),
          'front_audit_events',
          id,
          'after_snapshot',
        ),
      ),
      createdAt: _dateValue(event['created_at']) ?? now,
    );
    await _insertArchiveRow(database.frontAuditEvents, companion, strategy);
  }

  Future<void> _importNamedFront(
    Map<String, Object?> front,
    ImportConflictStrategy strategy,
    DateTime now,
    String? localAvatarUrl,
  ) async {
    final frontId = _requiredString(front, 'id');
    final companion = NamedFrontsCompanion.insert(
      id: frontId,
      systemId: localSystemId,
      name: await _encryptLocalText(
        _requiredString(front, 'name'),
        'named_fronts',
        frontId,
        'name',
      ),
      customLabel: Value(
        await _encryptNullableLocalText(
          _stringValue(front['custom_label']),
          'named_fronts',
          frontId,
          'custom_label',
        ),
      ),
      colorHex: Value(
        await _encryptNullableLocalText(
          _stringValue(front['color_hex']),
          'named_fronts',
          frontId,
          'color_hex',
        ),
      ),
      avatarUrl: Value(
        await _encryptNullableLocalText(
          localAvatarUrl ?? _stringValue(front['avatar_url']),
          'named_fronts',
          frontId,
          'avatar_url',
        ),
      ),
      description: Value(
        await _encryptNullableLocalText(
          _stringValue(front['description']),
          'named_fronts',
          frontId,
          'description',
        ),
      ),
      createdAt: _dateValue(front['created_at']) ?? now,
      updatedAt: strategy == ImportConflictStrategy.update
          ? now
          : (_dateValue(front['updated_at']) ?? now),
    );
    return _insertArchiveRow(database.namedFronts, companion, strategy);
  }

  Future<void> _importNamedFrontMember(Map<String, Object?> link) {
    return database
        .into(database.namedFrontMembers)
        .insert(
          NamedFrontMembersCompanion.insert(
            namedFrontId: _requiredString(link, 'named_front_id'),
            memberId: _requiredString(link, 'member_id'),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<void> _importPrivacyBucket(
    Map<String, Object?> bucket,
    ImportConflictStrategy strategy,
    DateTime now,
  ) async {
    final id = _requiredString(bucket, 'id');
    final companion = PrivacyBucketsCompanion.insert(
      id: id,
      systemId: localSystemId,
      name: await _encryptLocalText(
        _requiredString(bucket, 'name'),
        'privacy_buckets',
        id,
        'name',
      ),
      description: Value(
        await _encryptNullableLocalText(
          _stringValue(bucket['description']),
          'privacy_buckets',
          id,
          'description',
        ),
      ),
      colorHex: Value(
        await _encryptNullableLocalText(
          normalizeHexColor(_stringValue(bucket['color_hex'])),
          'privacy_buckets',
          id,
          'color_hex',
        ),
      ),
      position: Value(_intValue(bucket['position']) ?? 0),
      createdAt: _dateValue(bucket['created_at']) ?? now,
      updatedAt: strategy == ImportConflictStrategy.update
          ? now
          : (_dateValue(bucket['updated_at']) ?? now),
    );
    return _insertArchiveRow(database.privacyBuckets, companion, strategy);
  }

  Future<void> _importPrivacyBucketMember(Map<String, Object?> link) {
    return database
        .into(database.privacyBucketMembers)
        .insert(
          PrivacyBucketMembersCompanion.insert(
            bucketId: _requiredString(link, 'bucket_id'),
            memberId: _requiredString(link, 'member_id'),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<void> _importNotificationEvent(
    Map<String, Object?> event,
    ImportConflictStrategy strategy,
    DateTime now,
  ) async {
    final id = _requiredString(event, 'id');
    final companion = NotificationEventsCompanion.insert(
      id: id,
      systemId: localSystemId,
      kind: _requiredString(event, 'kind'),
      title: await _encryptLocalText(
        _requiredString(event, 'title'),
        'notification_events',
        id,
        'title',
      ),
      body: await _encryptLocalText(
        _requiredString(event, 'body'),
        'notification_events',
        id,
        'body',
      ),
      readAt: Value(_dateValue(event['read_at'])),
      createdAt: _dateValue(event['created_at']) ?? now,
    );
    await _insertArchiveRow(database.notificationEvents, companion, strategy);
  }

  Future<void> _importPreference(
    Map<String, Object?> preference,
    ImportConflictStrategy strategy,
    DateTime now,
  ) {
    final companion = AppPreferencesCompanion.insert(
      key: _requiredString(preference, 'key'),
      value: _requiredString(preference, 'value'),
      updatedAt: strategy == ImportConflictStrategy.update
          ? now
          : (_dateValue(preference['updated_at']) ?? now),
    );
    return _insertArchiveRow(database.appPreferences, companion, strategy);
  }

  Future<void> _importPayload(
    Map<String, Object?> payload,
    String importRecordId,
    ImportSource source,
    ImportConflictStrategy strategy,
    DateTime now,
  ) async {
    final id = _requiredString(payload, 'id');
    final companion = ImportPayloadsCompanion.insert(
      id: id,
      importRecordId: importRecordId,
      systemId: localSystemId,
      source: _stringValue(payload['source']) ?? source.jobSource,
      collection: _requiredString(payload, 'collection'),
      payloadJson: await _encryptLocalText(
        _requiredString(payload, 'payload_json'),
        'import_payloads',
        id,
        'payload_json',
      ),
      importedAt: _dateValue(payload['imported_at']) ?? now,
    );
    await _insertArchiveRow(database.importPayloads, companion, strategy);
  }

  Future<void> _insertArchiveRow<TableDsl extends Table, D>(
    TableInfo<TableDsl, D> table,
    Insertable<D> companion,
    ImportConflictStrategy strategy,
  ) {
    if (strategy == ImportConflictStrategy.update) {
      return database.into(table).insertOnConflictUpdate(companion);
    }

    return database
        .into(table)
        .insert(companion, mode: InsertMode.insertOrIgnore);
  }
}
