import 'package:drift/drift.dart';

import 'app_database.dart';
import 'local_text_codec.dart';

class NoteSummary {
  const NoteSummary({
    required this.id,
    required this.title,
    required this.body,
    this.memberId,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String body;
  final String? memberId;
  final DateTime updatedAt;
}

class NoteDraft {
  const NoteDraft({required this.title, required this.body, this.memberId});

  final String title;
  final String body;
  final String? memberId;
}

class LocalNoteStore {
  LocalNoteStore(
    this.database, {
    required this.encryptText,
    required this.decryptText,
  });

  final AppDatabase database;
  final EncryptLocalText encryptText;
  final DecryptLocalText decryptText;

  Stream<List<NoteSummary>> watch() {
    final query = database.select(database.notes)
      ..where((note) => note.systemId.equals(localSystemId))
      ..orderBy([
        (note) =>
            OrderingTerm(expression: note.updatedAt, mode: OrderingMode.desc),
      ]);

    return query.watch().asyncMap(
      (rows) async => [
        for (final row in rows)
          NoteSummary(
            id: row.id,
            title: await decryptText(row.title, 'notes', row.id, 'title') ?? '',
            body: await decryptText(row.body, 'notes', row.id, 'body') ?? '',
            memberId: row.memberId,
            updatedAt: row.updatedAt,
          ),
      ],
    );
  }

  Future<void> save(NoteDraft draft) async {
    final title = draft.title.trim();
    final body = draft.body.trim();
    if (title.isEmpty && body.isEmpty) return;

    final now = DateTime.now().toUtc();
    final noteId = 'note-${now.microsecondsSinceEpoch}';
    await database
        .into(database.notes)
        .insert(
          NotesCompanion.insert(
            id: noteId,
            systemId: localSystemId,
            memberId: Value(_nullIfBlank(draft.memberId)),
            title: await encryptText(
              title.isEmpty ? 'Untitled note' : title,
              'notes',
              noteId,
              'title',
            ),
            body: await encryptText(body, 'notes', noteId, 'body'),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> update(String noteId, NoteDraft draft) async {
    final title = draft.title.trim();
    final body = draft.body.trim();
    if (title.isEmpty && body.isEmpty) return;

    final now = DateTime.now().toUtc();
    await (database.update(database.notes)..where(
          (note) =>
              note.systemId.equals(localSystemId) & note.id.equals(noteId),
        ))
        .write(
          NotesCompanion(
            memberId: Value(_nullIfBlank(draft.memberId)),
            title: Value(
              await encryptText(
                title.isEmpty ? 'Untitled note' : title,
                'notes',
                noteId,
                'title',
              ),
            ),
            body: Value(await encryptText(body, 'notes', noteId, 'body')),
            updatedAt: Value(now),
          ),
        );
  }

  Future<void> delete(String noteId) {
    return (database.delete(database.notes)..where(
          (note) =>
              note.systemId.equals(localSystemId) & note.id.equals(noteId),
        ))
        .go();
  }

  String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
