import 'package:drift/drift.dart';

import 'app_customization.dart' show normalizeHexColor;
import 'app_database.dart';
import 'local_text_codec.dart';

class PrivacyBucketSummary {
  const PrivacyBucketSummary({
    required this.id,
    required this.name,
    this.description,
    this.colorHex,
    this.memberIds = const [],
  });

  final String id;
  final String name;
  final String? description;
  final String? colorHex;
  final List<String> memberIds;
}

class PrivacyBucketDraft {
  const PrivacyBucketDraft({
    required this.name,
    this.description,
    this.colorHex,
    this.memberIds = const [],
  });

  final String name;
  final String? description;
  final String? colorHex;
  final List<String> memberIds;
}

class LocalPrivacyBucketStore {
  LocalPrivacyBucketStore(
    this.database, {
    required this.encryptText,
    required this.encryptNullableText,
    required this.decryptText,
  });

  final AppDatabase database;
  final EncryptLocalText encryptText;
  final EncryptNullableLocalText encryptNullableText;
  final DecryptLocalText decryptText;

  Stream<List<PrivacyBucketSummary>> watch() {
    return database
        .customSelect(
          '''
SELECT
  pb.id,
  pb.name,
  pb.description,
  pb.color_hex,
  GROUP_CONCAT(pbm.member_id) AS member_ids
FROM privacy_buckets pb
LEFT JOIN privacy_bucket_members pbm ON pbm.bucket_id = pb.id
WHERE pb.system_id = ?
GROUP BY pb.id, pb.name, pb.description, pb.color_hex, pb.position
ORDER BY pb.position ASC
''',
          variables: [Variable<String>(localSystemId)],
          readsFrom: {database.privacyBuckets, database.privacyBucketMembers},
        )
        .watch()
        .asyncMap(
          (rows) async => [
            for (final row in rows)
              PrivacyBucketSummary(
                id: row.read<String>('id'),
                name:
                    (await decryptText(
                      row.read<String>('name'),
                      'privacy_buckets',
                      row.read<String>('id'),
                      'name',
                    )) ??
                    '',
                description: await decryptText(
                  row.readNullable<String>('description'),
                  'privacy_buckets',
                  row.read<String>('id'),
                  'description',
                ),
                colorHex: await decryptText(
                  row.readNullable<String>('color_hex'),
                  'privacy_buckets',
                  row.read<String>('id'),
                  'color_hex',
                ),
                memberIds: _splitJoinedIds(row.data['member_ids']),
              ),
          ],
        );
  }

  Future<void> save(PrivacyBucketDraft draft) async {
    final name = draft.name.trim();
    if (name.isEmpty) return;
    final now = DateTime.now().toUtc();
    final bucketId = 'privacy-bucket-${now.microsecondsSinceEpoch}';
    await database.transaction(() async {
      final positionExpression = database.privacyBuckets.position.max();
      final maxPosition =
          await (database.selectOnly(database.privacyBuckets)
                ..addColumns([positionExpression])
                ..where(database.privacyBuckets.systemId.equals(localSystemId)))
              .map((row) => row.read(positionExpression))
              .getSingle();
      await database
          .into(database.privacyBuckets)
          .insert(
            PrivacyBucketsCompanion.insert(
              id: bucketId,
              systemId: localSystemId,
              name: await encryptText(
                name,
                'privacy_buckets',
                bucketId,
                'name',
              ),
              description: Value(
                await encryptNullableText(
                  _nullIfBlank(draft.description),
                  'privacy_buckets',
                  bucketId,
                  'description',
                ),
              ),
              colorHex: Value(
                await encryptNullableText(
                  normalizeHexColor(draft.colorHex),
                  'privacy_buckets',
                  bucketId,
                  'color_hex',
                ),
              ),
              position: Value((maxPosition ?? -1) + 1),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await _replaceMembers(bucketId, draft.memberIds);
    });
  }

  Future<void> update(String bucketId, PrivacyBucketDraft draft) async {
    final name = draft.name.trim();
    if (name.isEmpty) return;
    await database.transaction(() async {
      await (database.update(database.privacyBuckets)..where(
            (bucket) =>
                bucket.id.equals(bucketId) &
                bucket.systemId.equals(localSystemId),
          ))
          .write(
            PrivacyBucketsCompanion(
              name: Value(
                await encryptText(name, 'privacy_buckets', bucketId, 'name'),
              ),
              description: Value(
                await encryptNullableText(
                  _nullIfBlank(draft.description),
                  'privacy_buckets',
                  bucketId,
                  'description',
                ),
              ),
              colorHex: Value(
                await encryptNullableText(
                  normalizeHexColor(draft.colorHex),
                  'privacy_buckets',
                  bucketId,
                  'color_hex',
                ),
              ),
              updatedAt: Value(DateTime.now().toUtc()),
            ),
          );
      await _replaceMembers(bucketId, draft.memberIds);
    });
  }

  Future<void> delete(String bucketId) async {
    await database.transaction(() async {
      await (database.delete(
        database.privacyBucketMembers,
      )..where((link) => link.bucketId.equals(bucketId))).go();
      await (database.delete(database.privacyBuckets)..where(
            (bucket) =>
                bucket.id.equals(bucketId) &
                bucket.systemId.equals(localSystemId),
          ))
          .go();
    });
  }

  Future<void> _replaceMembers(String bucketId, List<String> memberIds) async {
    await (database.delete(
      database.privacyBucketMembers,
    )..where((link) => link.bucketId.equals(bucketId))).go();
    for (final memberId in memberIds.toSet()) {
      await database
          .into(database.privacyBucketMembers)
          .insert(
            PrivacyBucketMembersCompanion.insert(
              bucketId: bucketId,
              memberId: memberId,
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
  }

  List<String> _splitJoinedIds(Object? value) {
    if (value is! String || value.isEmpty) return const [];
    return value.split(',').where((id) => id.isNotEmpty).toList();
  }

  String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
