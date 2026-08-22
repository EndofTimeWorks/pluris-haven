part of 'haven_repository.dart';

extension LocalHavenRepositoryRevisionRestore on LocalHavenRepository {
  Future<void> _restoreRevision(
    String revisionId,
    String targetType,
    String targetId,
  ) async {
    final revision = await (database.select(
      database.contentRevisions,
    )..where((r) => r.id.equals(revisionId))).getSingleOrNull();
    if (revision == null) return;

    final now = DateTime.now().toUtc();
    final revisionTitle = await _decryptLocalText(
      revision.title,
      'content_revisions',
      revision.id,
      'title',
    );
    final revisionBody = await _decryptLocalText(
      revision.body,
      'content_revisions',
      revision.id,
      'body',
    );
    if (revisionBody == null) {
      throw StateError('Protected revision body is unexpectedly null.');
    }

    switch (targetType) {
      case 'member_bio':
        await (database.update(
          database.members,
        )..where((m) => m.id.equals(targetId))).write(
          MembersCompanion(
            description: Value(
              await _encryptMember(targetId, 'description', revisionBody),
            ),
            profileEncryptionVersion: const Value(2),
            updatedAt: Value(now),
          ),
        );
      case 'note':
        await (database.update(
          database.notes,
        )..where((n) => n.id.equals(targetId))).write(
          NotesCompanion(
            title: Value(
              await _encryptLocalText(
                revisionTitle ?? '',
                'notes',
                targetId,
                'title',
              ),
            ),
            body: Value(
              await _encryptLocalText(revisionBody, 'notes', targetId, 'body'),
            ),
            updatedAt: Value(now),
          ),
        );
      case 'journal':
        await (database.update(
          database.journalEntries,
        )..where((j) => j.id.equals(targetId))).write(
          JournalEntriesCompanion(
            title: Value(
              await _encryptNullableLocalText(
                revisionTitle,
                'journal_entries',
                targetId,
                'title',
              ),
            ),
            body: Value(
              await _encryptLocalText(
                revisionBody,
                'journal_entries',
                targetId,
                'body',
              ),
            ),
            updatedAt: Value(now),
          ),
        );
      case 'message':
        await (database.update(
          database.messages,
        )..where((m) => m.id.equals(targetId))).write(
          MessagesCompanion(
            body: Value(
              await _encryptLocalText(
                revisionBody,
                'messages',
                targetId,
                'body',
              ),
            ),
            updatedAt: Value(now),
          ),
        );
    }
  }
}
