part of 'haven_repository.dart';

typedef _ProtectedTextColumn = ({String table, String column});

const _protectedLocalTextColumns = <_ProtectedTextColumn>[
  (table: 'plural_systems', column: 'name'),
  (table: 'plural_systems', column: 'color_hex'),
  (table: 'plural_systems', column: 'avatar_url'),
  (table: 'plural_systems', column: 'description'),
  (table: 'system_groups', column: 'name'),
  (table: 'system_groups', column: 'color_hex'),
  (table: 'system_groups', column: 'description'),
  (table: 'system_groups', column: 'emoji'),
  (table: 'notes', column: 'title'),
  (table: 'notes', column: 'body'),
  (table: 'chat_categories', column: 'name'),
  (table: 'chat_categories', column: 'description'),
  (table: 'chat_channels', column: 'name'),
  (table: 'chat_channels', column: 'description'),
  (table: 'chat_channels', column: 'color_hex'),
  (table: 'messages', column: 'body'),
  (table: 'reminders', column: 'title'),
  (table: 'reminders', column: 'body'),
  (table: 'reminders', column: 'schedule_text'),
  (table: 'reminders', column: 'trigger_event'),
  (table: 'reminders', column: 'schedule_kind'),
  (table: 'reminders', column: 'schedule_time'),
  (table: 'custom_field_definitions', column: 'name'),
  (table: 'custom_field_definitions', column: 'privacy'),
  (table: 'custom_field_values', column: 'value'),
  (table: 'polls', column: 'question'),
  (table: 'polls', column: 'description'),
  (table: 'poll_options', column: 'body'),
  (table: 'front_sessions', column: 'label'),
  (table: 'front_sessions', column: 'status_note'),
  (table: 'import_records', column: 'file_name'),
  (table: 'import_records', column: 'summary_json'),
  (table: 'import_payloads', column: 'payload_json'),
  (table: 'background_jobs', column: 'file_name'),
  (table: 'background_jobs', column: 'payload_json'),
  (table: 'background_jobs', column: 'error'),
  (table: 'notification_events', column: 'title'),
  (table: 'notification_events', column: 'body'),
  (table: 'tags', column: 'name'),
  (table: 'tags', column: 'color_hex'),
  (table: 'journal_entries', column: 'title'),
  (table: 'journal_entries', column: 'body'),
  (table: 'content_revisions', column: 'title'),
  (table: 'content_revisions', column: 'body'),
  (table: 'front_audit_events', column: 'before_snapshot'),
  (table: 'front_audit_events', column: 'after_snapshot'),
  (table: 'named_fronts', column: 'name'),
  (table: 'named_fronts', column: 'custom_label'),
  (table: 'named_fronts', column: 'color_hex'),
  (table: 'named_fronts', column: 'avatar_url'),
  (table: 'named_fronts', column: 'description'),
  (table: 'privacy_buckets', column: 'name'),
  (table: 'privacy_buckets', column: 'description'),
  (table: 'privacy_buckets', column: 'color_hex'),
];

typedef _ProtectedMemberColumn = ({String column, String field});

const _protectedMemberColumns = <_ProtectedMemberColumn>[
  (column: 'display_name', field: 'display_name'),
  (column: 'pronouns', field: 'pronouns'),
  (column: 'color_hex', field: 'color_hex'),
  (column: 'birthday', field: 'birthday'),
  (column: 'emoji', field: 'emoji'),
  (column: 'privacy', field: 'privacy'),
  (column: 'description', field: 'description'),
  (column: 'avatar_url', field: 'avatar_url'),
  (column: 'plural_kit_id', field: 'pluralkit_id'),
];

extension LocalHavenRepositoryLocalText on LocalHavenRepository {
  String _localTextAad(String table, String rowId, String column) =>
      'pluris-haven:local-text:v2\u0000$table\u0000$rowId\u0000$column';

  Future<String> _encryptLocalText(
    String value,
    String table,
    String rowId,
    String column,
  ) async {
    final encrypted = await crypto.encrypt(
      value,
      aad: _localTextAad(table, rowId, column),
    );
    if (encrypted == null) {
      throw StateError('Local text encryption returned no value.');
    }
    return '$_localEncryptedTextPrefix$encrypted';
  }

  Future<String?> _encryptNullableLocalText(
    String? value,
    String table,
    String rowId,
    String column,
  ) async {
    return value == null
        ? null
        : _encryptLocalText(value, table, rowId, column);
  }

  Future<String?> _decryptLocalText(
    String? stored,
    String table,
    String rowId,
    String column,
  ) async {
    if (stored == null) return null;
    if (!stored.startsWith(_localEncryptedTextPrefix)) {
      throw StateError('Protected local text is not encrypted.');
    }
    final key = (table, rowId, column);
    final cached = _localTextDecryptCache[key];
    if (cached != null && cached.ciphertext == stored) {
      return cached.plaintext;
    }
    final plaintext = await crypto.decrypt(
      stored.substring(_localEncryptedTextPrefix.length),
      aad: _localTextAad(table, rowId, column),
    );
    _localTextDecryptCache[key] = (ciphertext: stored, plaintext: plaintext);
    return plaintext;
  }

  Future<void> _migrateLegacyLocalTextToAad() async {
    if (await _preferenceEquals(
      _localTextAadMigrationPreference,
      _localTextAadMigrationVersion,
    )) {
      return;
    }
    await database.transaction(() async {
      for (final column in _protectedLocalTextColumns) {
        final rows = await database
            .customSelect(
              'SELECT id, ${column.column} AS value FROM ${column.table} '
              'WHERE ${column.column} LIKE ?',
              variables: [
                Variable.withString('$_legacyLocalEncryptedTextPrefix%'),
              ],
            )
            .get();
        for (final row in rows) {
          final id = row.read<String>('id');
          final stored = row.read<String>('value');
          final plaintext = await crypto.decrypt(
            stored.substring(_legacyLocalEncryptedTextPrefix.length),
          );
          if (plaintext == null) {
            throw StateError('Legacy local text decryption returned no value.');
          }
          final encrypted = await _encryptLocalText(
            plaintext,
            column.table,
            id,
            column.column,
          );
          await database.customUpdate(
            'UPDATE ${column.table} SET ${column.column} = ? WHERE id = ?',
            variables: [
              Variable.withString(encrypted),
              Variable.withString(id),
            ],
          );
        }
      }
      await _writePreference(
        _localTextAadMigrationPreference,
        _localTextAadMigrationVersion,
      );
    });
  }

  Future<void> _migrateUnauthenticatedEmptyCiphertexts() async {
    if (await _preferenceEquals(
      _emptyCiphertextSweepPreference,
      _emptyCiphertextSweepVersion,
    )) {
      return;
    }
    await database.transaction(() async {
      for (final column in _protectedLocalTextColumns) {
        final rows = await database
            .customSelect(
              'SELECT id FROM ${column.table} WHERE ${column.column} = ?',
              variables: [Variable.withString(_localEncryptedTextPrefix)],
            )
            .get();
        for (final row in rows) {
          final id = row.read<String>('id');
          final encrypted = await _encryptLocalText(
            '',
            column.table,
            id,
            column.column,
          );
          await database.customUpdate(
            'UPDATE ${column.table} SET ${column.column} = ? WHERE id = ?',
            variables: [
              Variable.withString(encrypted),
              Variable.withString(id),
            ],
          );
        }
      }

      for (final column in _protectedMemberColumns) {
        final rows = await database
            .customSelect(
              'SELECT id FROM members '
              'WHERE profile_encryption_version > 0 AND ${column.column} = ?',
              variables: [Variable.withString('')],
            )
            .get();
        for (final row in rows) {
          final id = row.read<String>('id');
          final encrypted = await _encryptMember(id, column.field, '');
          if (encrypted == null) {
            throw StateError('Member text encryption returned no value.');
          }
          await database.customUpdate(
            'UPDATE members SET ${column.column} = ? WHERE id = ?',
            variables: [
              Variable.withString(encrypted),
              Variable.withString(id),
            ],
          );
          if (column.column == 'display_name') {
            await database.customUpdate(
              'UPDATE members SET display_name_hash = ? WHERE id = ?',
              variables: [
                Variable.withString(await crypto.blindIndex('')),
                Variable.withString(id),
              ],
            );
          }
        }
      }
      await _writePreference(
        _emptyCiphertextSweepPreference,
        _emptyCiphertextSweepVersion,
      );
    });
  }
}
