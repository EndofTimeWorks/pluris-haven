import 'package:drift/drift.dart';

import 'app_database.dart';

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

class LocalTagStore {
  LocalTagStore(
    this.database, {
    required this.encryptText,
    required this.encryptNullableText,
    required this.decryptText,
  });

  final AppDatabase database;
  final EncryptLocalText encryptText;
  final EncryptNullableLocalText encryptNullableText;
  final DecryptLocalText decryptText;

  Stream<List<Tag>> watch() {
    final query = database.select(database.tags)
      ..where((tag) => tag.systemId.equals(localSystemId))
      ..orderBy([(tag) => OrderingTerm(expression: tag.createdAt)]);
    return query.watch().asyncMap(
      (rows) async => [
        for (final row in rows)
          row.copyWith(
            name: await decryptText(row.name, 'tags', row.id, 'name') ?? '',
            colorHex: Value(
              await decryptText(row.colorHex, 'tags', row.id, 'color_hex'),
            ),
          ),
      ],
    );
  }

  Future<void> save(Tag tag) async {
    final now = DateTime.now().toUtc();
    await database
        .into(database.tags)
        .insertOnConflictUpdate(
          TagsCompanion.insert(
            id: tag.id,
            systemId: localSystemId,
            name: await encryptText(tag.name, 'tags', tag.id, 'name'),
            colorHex: Value(
              await encryptNullableText(
                tag.colorHex,
                'tags',
                tag.id,
                'color_hex',
              ),
            ),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> delete(String tagId) async {
    await (database.delete(
      database.memberTags,
    )..where((memberTag) => memberTag.tagId.equals(tagId))).go();
    await (database.delete(
      database.tags,
    )..where((tag) => tag.id.equals(tagId))).go();
  }

  Stream<List<Tag>> watchForMember(String memberId) {
    final query = database.select(database.memberTags).join([
      innerJoin(
        database.tags,
        database.memberTags.tagId.equalsExp(database.tags.id),
      ),
    ])..where(database.memberTags.memberId.equals(memberId));
    return query.watch().asyncMap((rows) async {
      final tags = <Tag>[];
      for (final row in rows) {
        final tag = row.readTable(database.tags);
        tags.add(
          tag.copyWith(
            name: await decryptText(tag.name, 'tags', tag.id, 'name') ?? '',
            colorHex: Value(
              await decryptText(tag.colorHex, 'tags', tag.id, 'color_hex'),
            ),
          ),
        );
      }
      return tags;
    });
  }

  Future<void> setForMember(String memberId, List<String> tagIds) async {
    await database.transaction(() async {
      await (database.delete(
        database.memberTags,
      )..where((memberTag) => memberTag.memberId.equals(memberId))).go();
      for (final tagId in tagIds) {
        await database
            .into(database.memberTags)
            .insert(
              MemberTagsCompanion.insert(tagId: tagId, memberId: memberId),
              mode: InsertMode.insertOrIgnore,
            );
      }
    });
  }
}
