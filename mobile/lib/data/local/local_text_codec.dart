typedef EncryptLocalText =
    Future<String> Function(
      String value,
      String table,
      String rowId,
      String column,
    );
typedef EncryptNullableLocalText =
    Future<String?> Function(
      String? value,
      String table,
      String rowId,
      String column,
    );
typedef DecryptLocalText =
    Future<String?> Function(
      String? stored,
      String table,
      String rowId,
      String column,
    );
