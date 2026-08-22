part of 'haven_repository.dart';

extension LocalHavenRepositoryEncryptionMigration on LocalHavenRepository {
  Future<void> _migrateLocalPrivateContentToEncryption() async {
    if (await _preferenceEquals(
      _localEncryptionSweepPreference,
      _localEncryptionSweepVersion,
    )) {
      return;
    }
    await database.transaction(() async {
      final notes = await database.select(database.notes).get();
      final messages = await database.select(database.messages).get();
      final fronts = await database.select(database.frontSessions).get();
      final journals = await database.select(database.journalEntries).get();
      final reminders = await database.select(database.reminders).get();
      final polls = await database.select(database.polls).get();
      final pollOptions = await database.select(database.pollOptions).get();
      final customFields = await database
          .select(database.customFieldDefinitions)
          .get();
      final customFieldValues = await database
          .select(database.customFieldValues)
          .get();
      final groups = await database.select(database.systemGroups).get();
      final tags = await database.select(database.tags).get();
      final namedFronts = await database.select(database.namedFronts).get();
      final privacyBuckets = await database
          .select(database.privacyBuckets)
          .get();
      final systems = await database.select(database.pluralSystems).get();
      final chatCategories = await database
          .select(database.chatCategories)
          .get();
      final chatChannels = await database.select(database.chatChannels).get();
      final notificationEvents = await database
          .select(database.notificationEvents)
          .get();
      final contentRevisions = await database
          .select(database.contentRevisions)
          .get();
      final frontAuditEvents = await database
          .select(database.frontAuditEvents)
          .get();
      final importRecords = await database.select(database.importRecords).get();
      final importPayloads = await database
          .select(database.importPayloads)
          .get();
      final backgroundJobs = await database
          .select(database.backgroundJobs)
          .get();
      for (final note in notes) {
        if (!_needsLocalTextMigration(note.title) &&
            !_needsLocalTextMigration(note.body)) {
          continue;
        }
        await (database.update(
          database.notes,
        )..where((row) => row.id.equals(note.id))).write(
          NotesCompanion(
            title: Value(
              await _migrateLocalText(note.title, 'notes', note.id, 'title'),
            ),
            body: Value(
              await _migrateLocalText(note.body, 'notes', note.id, 'body'),
            ),
          ),
        );
      }
      for (final message in messages) {
        if (!_needsLocalTextMigration(message.body)) continue;
        await (database.update(
          database.messages,
        )..where((row) => row.id.equals(message.id))).write(
          MessagesCompanion(
            body: Value(
              await _migrateLocalText(
                message.body,
                'messages',
                message.id,
                'body',
              ),
            ),
          ),
        );
      }
      for (final front in fronts) {
        if (!_needsLocalTextMigration(front.label) &&
            !_needsLocalTextMigration(front.statusNote)) {
          continue;
        }
        await (database.update(
          database.frontSessions,
        )..where((row) => row.id.equals(front.id))).write(
          FrontSessionsCompanion(
            label: Value(
              await _migrateNullableLocalText(
                front.label,
                'front_sessions',
                front.id,
                'label',
              ),
            ),
            statusNote: Value(
              await _migrateNullableLocalText(
                front.statusNote,
                'front_sessions',
                front.id,
                'status_note',
              ),
            ),
          ),
        );
      }
      for (final journal in journals) {
        if (!_needsLocalTextMigration(journal.title) &&
            !_needsLocalTextMigration(journal.body)) {
          continue;
        }
        await (database.update(
          database.journalEntries,
        )..where((row) => row.id.equals(journal.id))).write(
          JournalEntriesCompanion(
            title: Value(
              await _migrateNullableLocalText(
                journal.title,
                'journal_entries',
                journal.id,
                'title',
              ),
            ),
            body: Value(
              await _migrateLocalText(
                journal.body,
                'journal_entries',
                journal.id,
                'body',
              ),
            ),
          ),
        );
      }
      for (final reminder in reminders) {
        if (![
          reminder.title,
          reminder.body,
          reminder.scheduleText,
          reminder.triggerEvent,
          reminder.scheduleKind,
          reminder.scheduleTime,
        ].any(_needsLocalTextMigration)) {
          continue;
        }
        await (database.update(
          database.reminders,
        )..where((row) => row.id.equals(reminder.id))).write(
          RemindersCompanion(
            title: Value(
              await _migrateLocalText(
                reminder.title,
                'reminders',
                reminder.id,
                'title',
              ),
            ),
            body: Value(
              await _migrateNullableLocalText(
                reminder.body,
                'reminders',
                reminder.id,
                'body',
              ),
            ),
            scheduleText: Value(
              await _migrateLocalText(
                reminder.scheduleText,
                'reminders',
                reminder.id,
                'schedule_text',
              ),
            ),
            triggerEvent: Value(
              await _migrateNullableLocalText(
                reminder.triggerEvent,
                'reminders',
                reminder.id,
                'trigger_event',
              ),
            ),
            scheduleKind: Value(
              await _migrateNullableLocalText(
                reminder.scheduleKind,
                'reminders',
                reminder.id,
                'schedule_kind',
              ),
            ),
            scheduleTime: Value(
              await _migrateNullableLocalText(
                reminder.scheduleTime,
                'reminders',
                reminder.id,
                'schedule_time',
              ),
            ),
          ),
        );
      }
      for (final poll in polls) {
        if (!_needsLocalTextMigration(poll.question) &&
            !_needsLocalTextMigration(poll.description)) {
          continue;
        }
        await (database.update(
          database.polls,
        )..where((row) => row.id.equals(poll.id))).write(
          PollsCompanion(
            question: Value(
              await _migrateLocalText(
                poll.question,
                'polls',
                poll.id,
                'question',
              ),
            ),
            description: Value(
              await _migrateNullableLocalText(
                poll.description,
                'polls',
                poll.id,
                'description',
              ),
            ),
          ),
        );
      }
      for (final option in pollOptions) {
        if (!_needsLocalTextMigration(option.body)) continue;
        await (database.update(
          database.pollOptions,
        )..where((row) => row.id.equals(option.id))).write(
          PollOptionsCompanion(
            body: Value(
              await _migrateLocalText(
                option.body,
                'poll_options',
                option.id,
                'body',
              ),
            ),
          ),
        );
      }
      for (final field in customFields) {
        if (!_needsLocalTextMigration(field.name) &&
            !_needsLocalTextMigration(field.privacy)) {
          continue;
        }
        await (database.update(
          database.customFieldDefinitions,
        )..where((row) => row.id.equals(field.id))).write(
          CustomFieldDefinitionsCompanion(
            name: Value(
              await _migrateLocalText(
                field.name,
                'custom_field_definitions',
                field.id,
                'name',
              ),
            ),
            privacy: Value(
              await _migrateNullableLocalText(
                field.privacy,
                'custom_field_definitions',
                field.id,
                'privacy',
              ),
            ),
          ),
        );
      }
      for (final value in customFieldValues) {
        if (!_needsLocalTextMigration(value.value)) continue;
        await (database.update(
          database.customFieldValues,
        )..where((row) => row.id.equals(value.id))).write(
          CustomFieldValuesCompanion(
            value: Value(
              await _migrateLocalText(
                value.value,
                'custom_field_values',
                value.id,
                'value',
              ),
            ),
          ),
        );
      }
      for (final group in groups) {
        if (![
          group.name,
          group.colorHex,
          group.description,
          group.emoji,
        ].any(_needsLocalTextMigration)) {
          continue;
        }
        await (database.update(
          database.systemGroups,
        )..where((row) => row.id.equals(group.id))).write(
          SystemGroupsCompanion(
            name: Value(
              await _migrateLocalText(
                group.name,
                'system_groups',
                group.id,
                'name',
              ),
            ),
            colorHex: Value(
              await _migrateNullableLocalText(
                group.colorHex,
                'system_groups',
                group.id,
                'color_hex',
              ),
            ),
            description: Value(
              await _migrateNullableLocalText(
                group.description,
                'system_groups',
                group.id,
                'description',
              ),
            ),
            emoji: Value(
              await _migrateNullableLocalText(
                group.emoji,
                'system_groups',
                group.id,
                'emoji',
              ),
            ),
          ),
        );
      }
      for (final tag in tags) {
        if (!_needsLocalTextMigration(tag.name) &&
            !_needsLocalTextMigration(tag.colorHex)) {
          continue;
        }
        await (database.update(
          database.tags,
        )..where((row) => row.id.equals(tag.id))).write(
          TagsCompanion(
            name: Value(
              await _migrateLocalText(tag.name, 'tags', tag.id, 'name'),
            ),
            colorHex: Value(
              await _migrateNullableLocalText(
                tag.colorHex,
                'tags',
                tag.id,
                'color_hex',
              ),
            ),
          ),
        );
      }
      for (final front in namedFronts) {
        if (![
          front.name,
          front.customLabel,
          front.colorHex,
          front.avatarUrl,
          front.description,
        ].any(_needsLocalTextMigration)) {
          continue;
        }
        await (database.update(
          database.namedFronts,
        )..where((row) => row.id.equals(front.id))).write(
          NamedFrontsCompanion(
            name: Value(
              await _migrateLocalText(
                front.name,
                'named_fronts',
                front.id,
                'name',
              ),
            ),
            customLabel: Value(
              await _migrateNullableLocalText(
                front.customLabel,
                'named_fronts',
                front.id,
                'custom_label',
              ),
            ),
            colorHex: Value(
              await _migrateNullableLocalText(
                front.colorHex,
                'named_fronts',
                front.id,
                'color_hex',
              ),
            ),
            avatarUrl: Value(
              await _migrateNullableLocalText(
                front.avatarUrl,
                'named_fronts',
                front.id,
                'avatar_url',
              ),
            ),
            description: Value(
              await _migrateNullableLocalText(
                front.description,
                'named_fronts',
                front.id,
                'description',
              ),
            ),
          ),
        );
      }
      for (final bucket in privacyBuckets) {
        if (![
          bucket.name,
          bucket.description,
          bucket.colorHex,
        ].any(_needsLocalTextMigration)) {
          continue;
        }
        await (database.update(
          database.privacyBuckets,
        )..where((row) => row.id.equals(bucket.id))).write(
          PrivacyBucketsCompanion(
            name: Value(
              await _migrateLocalText(
                bucket.name,
                'privacy_buckets',
                bucket.id,
                'name',
              ),
            ),
            description: Value(
              await _migrateNullableLocalText(
                bucket.description,
                'privacy_buckets',
                bucket.id,
                'description',
              ),
            ),
            colorHex: Value(
              await _migrateNullableLocalText(
                bucket.colorHex,
                'privacy_buckets',
                bucket.id,
                'color_hex',
              ),
            ),
          ),
        );
      }
      for (final system in systems) {
        if (![
          system.name,
          system.colorHex,
          system.avatarUrl,
          system.description,
        ].any(_needsLocalTextMigration)) {
          continue;
        }
        await (database.update(
          database.pluralSystems,
        )..where((row) => row.id.equals(system.id))).write(
          PluralSystemsCompanion(
            name: Value(
              await _migrateLocalText(
                system.name,
                'plural_systems',
                system.id,
                'name',
              ),
            ),
            colorHex: Value(
              await _migrateNullableLocalText(
                system.colorHex,
                'plural_systems',
                system.id,
                'color_hex',
              ),
            ),
            avatarUrl: Value(
              await _migrateNullableLocalText(
                system.avatarUrl,
                'plural_systems',
                system.id,
                'avatar_url',
              ),
            ),
            description: Value(
              await _migrateNullableLocalText(
                system.description,
                'plural_systems',
                system.id,
                'description',
              ),
            ),
          ),
        );
      }
      for (final category in chatCategories) {
        if (!_needsLocalTextMigration(category.name) &&
            !_needsLocalTextMigration(category.description)) {
          continue;
        }
        await (database.update(
          database.chatCategories,
        )..where((row) => row.id.equals(category.id))).write(
          ChatCategoriesCompanion(
            name: Value(
              await _migrateLocalText(
                category.name,
                'chat_categories',
                category.id,
                'name',
              ),
            ),
            description: Value(
              await _migrateNullableLocalText(
                category.description,
                'chat_categories',
                category.id,
                'description',
              ),
            ),
          ),
        );
      }
      for (final channel in chatChannels) {
        if (![
          channel.name,
          channel.description,
          channel.colorHex,
        ].any(_needsLocalTextMigration)) {
          continue;
        }
        await (database.update(
          database.chatChannels,
        )..where((row) => row.id.equals(channel.id))).write(
          ChatChannelsCompanion(
            name: Value(
              await _migrateLocalText(
                channel.name,
                'chat_channels',
                channel.id,
                'name',
              ),
            ),
            description: Value(
              await _migrateNullableLocalText(
                channel.description,
                'chat_channels',
                channel.id,
                'description',
              ),
            ),
            colorHex: Value(
              await _migrateNullableLocalText(
                channel.colorHex,
                'chat_channels',
                channel.id,
                'color_hex',
              ),
            ),
          ),
        );
      }
      for (final event in notificationEvents) {
        if (!_needsLocalTextMigration(event.title) &&
            !_needsLocalTextMigration(event.body)) {
          continue;
        }
        await (database.update(
          database.notificationEvents,
        )..where((row) => row.id.equals(event.id))).write(
          NotificationEventsCompanion(
            title: Value(
              await _migrateLocalText(
                event.title,
                'notification_events',
                event.id,
                'title',
              ),
            ),
            body: Value(
              await _migrateLocalText(
                event.body,
                'notification_events',
                event.id,
                'body',
              ),
            ),
          ),
        );
      }
      for (final revision in contentRevisions) {
        if (!_needsLocalTextMigration(revision.title) &&
            !_needsLocalTextMigration(revision.body)) {
          continue;
        }
        await (database.update(
          database.contentRevisions,
        )..where((row) => row.id.equals(revision.id))).write(
          ContentRevisionsCompanion(
            title: Value(
              await _migrateNullableLocalText(
                revision.title,
                'content_revisions',
                revision.id,
                'title',
              ),
            ),
            body: Value(
              await _migrateLocalText(
                revision.body,
                'content_revisions',
                revision.id,
                'body',
              ),
            ),
          ),
        );
      }
      for (final event in frontAuditEvents) {
        if (!_needsLocalTextMigration(event.beforeSnapshot) &&
            !_needsLocalTextMigration(event.afterSnapshot)) {
          continue;
        }
        await (database.update(
          database.frontAuditEvents,
        )..where((row) => row.id.equals(event.id))).write(
          FrontAuditEventsCompanion(
            beforeSnapshot: Value(
              await _migrateNullableLocalText(
                event.beforeSnapshot,
                'front_audit_events',
                event.id,
                'before_snapshot',
              ),
            ),
            afterSnapshot: Value(
              await _migrateNullableLocalText(
                event.afterSnapshot,
                'front_audit_events',
                event.id,
                'after_snapshot',
              ),
            ),
          ),
        );
      }
      for (final record in importRecords) {
        if (!_needsLocalTextMigration(record.fileName) &&
            !_needsLocalTextMigration(record.summaryJson)) {
          continue;
        }
        await (database.update(
          database.importRecords,
        )..where((row) => row.id.equals(record.id))).write(
          ImportRecordsCompanion(
            fileName: Value(
              await _migrateNullableLocalText(
                record.fileName,
                'import_records',
                record.id,
                'file_name',
              ),
            ),
            summaryJson: Value(
              await _migrateNullableLocalText(
                record.summaryJson,
                'import_records',
                record.id,
                'summary_json',
              ),
            ),
          ),
        );
      }
      for (final payload in importPayloads) {
        if (!_needsLocalTextMigration(payload.payloadJson)) continue;
        await (database.update(
          database.importPayloads,
        )..where((row) => row.id.equals(payload.id))).write(
          ImportPayloadsCompanion(
            payloadJson: Value(
              await _migrateLocalText(
                payload.payloadJson,
                'import_payloads',
                payload.id,
                'payload_json',
              ),
            ),
          ),
        );
      }
      for (final job in backgroundJobs) {
        if (![
          job.fileName,
          job.payloadJson,
          job.error,
        ].any(_needsLocalTextMigration)) {
          continue;
        }
        await (database.update(
          database.backgroundJobs,
        )..where((row) => row.id.equals(job.id))).write(
          BackgroundJobsCompanion(
            fileName: Value(
              await _migrateNullableLocalText(
                job.fileName,
                'background_jobs',
                job.id,
                'file_name',
              ),
            ),
            payloadJson: Value(
              await _migrateLocalText(
                job.payloadJson,
                'background_jobs',
                job.id,
                'payload_json',
              ),
            ),
            error: Value(
              await _migrateNullableLocalText(
                job.error,
                'background_jobs',
                job.id,
                'error',
              ),
            ),
          ),
        );
      }
      await _writePreference(
        _localEncryptionSweepPreference,
        _localEncryptionSweepVersion,
      );
    });
  }
}
