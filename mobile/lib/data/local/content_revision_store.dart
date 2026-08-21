import 'package:drift/drift.dart';

import 'app_database.dart';
import 'local_text_codec.dart';

class LocalContentRevisionStore {
  LocalContentRevisionStore(this.database, {required this.decryptText});

  final AppDatabase database;
  final DecryptLocalText decryptText;

  Stream<List<ContentRevision>> watch(String targetType, String targetId) {
    final query = database.select(database.contentRevisions)
      ..where(
        (revision) =>
            revision.targetType.equals(targetType) &
            revision.targetId.equals(targetId),
      )
      ..orderBy([
        (revision) => OrderingTerm(
          expression: revision.createdAt,
          mode: OrderingMode.desc,
        ),
      ]);
    return query.watch().asyncMap(
      (rows) async => [
        for (final row in rows)
          row.copyWith(
            title: Value(
              await decryptText(
                row.title,
                'content_revisions',
                row.id,
                'title',
              ),
            ),
            body:
                (await decryptText(
                  row.body,
                  'content_revisions',
                  row.id,
                  'body',
                )) ??
                '',
          ),
      ],
    );
  }

  Future<void> pin(String revisionId) async {
    await (database.update(
      database.contentRevisions,
    )..where((revision) => revision.id.equals(revisionId))).write(
      ContentRevisionsCompanion(pinnedAt: Value(DateTime.now().toUtc())),
    );
  }

  Future<void> unpin(String revisionId) async {
    await (database.update(database.contentRevisions)
          ..where((revision) => revision.id.equals(revisionId)))
        .write(const ContentRevisionsCompanion(pinnedAt: Value(null)));
  }
}
