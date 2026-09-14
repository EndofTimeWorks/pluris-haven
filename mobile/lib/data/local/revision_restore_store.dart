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
    if (revision.targetType != targetType || revision.targetId != targetId) {
      throw ArgumentError(
        'Revision target does not match the requested restore target.',
      );
    }

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

    await database.transaction(() async {
      switch (revision.targetType) {
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
          final current = await (database.select(
            database.notes,
          )..where((note) => note.id.equals(targetId))).getSingleOrNull();
          if (current == null) return;
          final currentTitle =
              await _decryptLocalText(
                current.title,
                'notes',
                targetId,
                'title',
              ) ??
              '';
          final currentBody =
              await _decryptLocalText(
                current.body,
                'notes',
                targetId,
                'body',
              ) ??
              '';
          if (currentTitle != (revisionTitle ?? '') ||
              currentBody != revisionBody) {
            await _recordRevision(
              targetType: 'note',
              targetId: targetId,
              title: currentTitle,
              body: currentBody,
            );
          }
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
                await _encryptLocalText(
                  revisionBody,
                  'notes',
                  targetId,
                  'body',
                ),
              ),
              updatedAt: Value(now),
            ),
          );
        case 'journal':
          final current = await (database.select(
            database.journalEntries,
          )..where((journal) => journal.id.equals(targetId))).getSingleOrNull();
          if (current == null) return;
          final currentTitle = await _decryptLocalText(
            current.title,
            'journal_entries',
            targetId,
            'title',
          );
          final currentBody =
              await _decryptLocalText(
                current.body,
                'journal_entries',
                targetId,
                'body',
              ) ??
              '';
          if (currentTitle != revisionTitle || currentBody != revisionBody) {
            await _recordRevision(
              targetType: 'journal',
              targetId: targetId,
              title: currentTitle,
              body: currentBody,
            );
          }
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
          final current =
              await (database.select(database.messages)..where(
                    (message) =>
                        message.systemId.equals(localSystemId) &
                        message.id.equals(targetId),
                  ))
                  .getSingleOrNull();
          if (current == null) return;
          final currentBody =
              await _decryptLocalText(
                current.body,
                'messages',
                targetId,
                'body',
              ) ??
              '';
          if (currentBody != revisionBody) {
            await _recordRevision(
              targetType: 'message',
              targetId: targetId,
              body: currentBody,
            );
          }
          final now = DateTime.now().toUtc();
          final updatedAt = now.isAfter(current.updatedAt)
              ? now
              : current.updatedAt.add(const Duration(microseconds: 1));
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
              updatedAt: Value(updatedAt),
            ),
          );
      }
    });
  }
}
