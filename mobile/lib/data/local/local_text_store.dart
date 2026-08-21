part of 'haven_repository.dart';

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
    if (stored.startsWith(_legacyLocalEncryptedTextPrefix)) {
      return crypto.decrypt(
        stored.substring(_legacyLocalEncryptedTextPrefix.length),
      );
    }
    if (!stored.startsWith(_localEncryptedTextPrefix)) {
      throw StateError('Protected local text is not encrypted.');
    }
    return crypto.decrypt(
      stored.substring(_localEncryptedTextPrefix.length),
      aad: _localTextAad(table, rowId, column),
    );
  }

  Future<String> _migrateLocalText(
    String stored,
    String table,
    String rowId,
    String column,
  ) async {
    if (stored.startsWith(_localEncryptedTextPrefix)) return stored;
    final plaintext = stored.startsWith(_legacyLocalEncryptedTextPrefix)
        ? await crypto.decrypt(
            stored.substring(_legacyLocalEncryptedTextPrefix.length),
          )
        : stored;
    if (plaintext == null) {
      throw StateError('Legacy local text decryption returned no value.');
    }
    return _encryptLocalText(plaintext, table, rowId, column);
  }

  bool _needsLocalTextMigration(String? stored) =>
      stored != null && !stored.startsWith(_localEncryptedTextPrefix);
}
