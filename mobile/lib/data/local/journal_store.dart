import 'package:drift/drift.dart';

import 'app_database.dart';
import 'local_text_codec.dart';

class LocalJournalStore {
  LocalJournalStore(
    this.database, {
    required this.encryptText,
    required this.encryptNullableText,
    required this.decryptText,
  });

  final AppDatabase database;
  final EncryptLocalText encryptText;
  final EncryptNullableLocalText encryptNullableText;
  final DecryptLocalText decryptText;

  Stream<List<JournalEntry>> watch({String? memberId}) {
    final query = database.select(database.journalEntries)
      ..where((entry) => entry.systemId.equals(localSystemId));
    if (memberId != null) {
      query.where((entry) => entry.memberId.equals(memberId));
    }
    query.orderBy([
      (entry) =>
          OrderingTerm(expression: entry.createdAt, mode: OrderingMode.desc),
    ]);
    return query.watch().asyncMap(
      (rows) async => [
        for (final row in rows)
          row.copyWith(
            title: Value(
              await decryptText(row.title, 'journal_entries', row.id, 'title'),
            ),
            body:
                await decryptText(
                  row.body,
                  'journal_entries',
                  row.id,
                  'body',
                ) ??
                '',
          ),
      ],
    );
  }

  Future<void> save(JournalEntry entry) async {
    final now = DateTime.now().toUtc();
    await database
        .into(database.journalEntries)
        .insertOnConflictUpdate(
          JournalEntriesCompanion.insert(
            id: entry.id,
            systemId: localSystemId,
            memberId: Value(entry.memberId),
            title: Value(
              await encryptNullableText(
                entry.title,
                'journal_entries',
                entry.id,
                'title',
              ),
            ),
            body: await encryptText(
              entry.body,
              'journal_entries',
              entry.id,
              'body',
            ),
            createdAt: entry.createdAt,
            updatedAt: now,
          ),
        );
  }

  Future<void> delete(String entryId) {
    return (database.delete(
      database.journalEntries,
    )..where((entry) => entry.id.equals(entryId))).go();
  }
}
