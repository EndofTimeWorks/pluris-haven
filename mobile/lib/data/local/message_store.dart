import 'package:drift/drift.dart';

import 'app_database.dart';
import 'local_id.dart';
import 'local_text_codec.dart';

class MessageSummary {
  const MessageSummary({
    required this.id,
    required this.body,
    this.memberId,
    this.boardKind = 'system',
    this.boardMemberId,
    this.parentMessageId,
    this.channelId,
    required this.createdAt,
    this.updatedAt,
    this.edited = false,
    this.archived = false,
  });

  final String id;
  final String body;
  final String? memberId;
  final String boardKind;
  final String? boardMemberId;
  final String? parentMessageId;
  final String? channelId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool edited;
  final bool archived;
}

class MessageDraft {
  const MessageDraft({
    required this.body,
    this.memberId,
    this.boardKind = 'system',
    this.boardMemberId,
    this.parentMessageId,
    this.channelId,
  });

  final String body;
  final String? memberId;
  final String boardKind;
  final String? boardMemberId;
  final String? parentMessageId;
  final String? channelId;
}

class LocalMessageStore {
  LocalMessageStore(
    this.database, {
    required this.encryptText,
    required this.decryptText,
    required this.recordRevision,
  });

  final AppDatabase database;
  final EncryptLocalText encryptText;
  final DecryptLocalText decryptText;
  final Future<void> Function({
    required String targetType,
    required String targetId,
    String? title,
    required String body,
  })
  recordRevision;

  Stream<List<MessageSummary>> watch({bool deletedOnly = false}) {
    final query = database.select(database.messages)
      ..where(
        (message) =>
            message.systemId.equals(localSystemId) &
            (deletedOnly
                ? message.archived.equals(true) & message.purgedAt.isNull()
                : message.archived.equals(false)),
      )
      ..orderBy([
        (message) => OrderingTerm(
          expression: message.createdAt,
          mode: OrderingMode.desc,
        ),
      ]);

    return query.watch().asyncMap(
      (rows) async => [
        for (final row in rows)
          MessageSummary(
            id: row.id,
            body: await decryptText(row.body, 'messages', row.id, 'body') ?? '',
            memberId: row.memberId,
            boardKind: row.boardKind,
            boardMemberId: row.boardMemberId,
            parentMessageId: row.parentMessageId,
            channelId: row.channelId,
            createdAt: row.createdAt,
            updatedAt: row.updatedAt,
            edited: await _hasRevision(row.id),
            archived: row.archived,
          ),
      ],
    );
  }

  Stream<List<MessageSummary>> watchDeleted() => watch(deletedOnly: true);

  Future<void> save(MessageDraft draft) async {
    final body = draft.body.trim();
    if (body.isEmpty) return;

    final now = DateTime.now().toUtc();
    final messageId = newLocalId('message');
    await database
        .into(database.messages)
        .insert(
          MessagesCompanion.insert(
            id: messageId,
            systemId: localSystemId,
            memberId: Value(_nullIfBlank(draft.memberId)),
            body: await encryptText(body, 'messages', messageId, 'body'),
            boardKind: Value(_boardKind(draft.boardKind)),
            boardMemberId: Value(
              draft.boardKind == 'member'
                  ? _nullIfBlank(draft.boardMemberId)
                  : null,
            ),
            parentMessageId: Value(_nullIfBlank(draft.parentMessageId)),
            channelId: Value(
              draft.boardKind == 'channel'
                  ? _nullIfBlank(draft.channelId)
                  : null,
            ),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> update(String messageId, MessageDraft draft) async {
    final body = draft.body.trim();
    if (body.isEmpty) return;

    await database.transaction(() async {
      final existing =
          await (database.select(database.messages)..where(
                (message) =>
                    message.systemId.equals(localSystemId) &
                    message.id.equals(messageId) &
                    message.purgedAt.isNull(),
              ))
              .getSingleOrNull();
      if (existing == null) return;
      final previousBody =
          await decryptText(existing.body, 'messages', messageId, 'body') ?? '';
      if (previousBody != body) {
        await recordRevision(
          targetType: 'message',
          targetId: messageId,
          body: previousBody,
        );
      }
      final now = DateTime.now().toUtc();
      final updatedAt = now.isAfter(existing.updatedAt)
          ? now
          : existing.updatedAt.add(const Duration(microseconds: 1));
      await (database.update(database.messages)..where(
            (message) =>
                message.systemId.equals(localSystemId) &
                message.id.equals(messageId) &
                message.purgedAt.isNull(),
          ))
          .write(
            MessagesCompanion(
              memberId: Value(_nullIfBlank(draft.memberId)),
              body: Value(
                await encryptText(body, 'messages', messageId, 'body'),
              ),
              boardKind: Value(_boardKind(draft.boardKind)),
              boardMemberId: Value(
                draft.boardKind == 'member'
                    ? _nullIfBlank(draft.boardMemberId)
                    : null,
              ),
              parentMessageId: Value(_nullIfBlank(draft.parentMessageId)),
              channelId: Value(
                draft.boardKind == 'channel'
                    ? _nullIfBlank(draft.channelId)
                    : null,
              ),
              archived: const Value(false),
              deletedAt: const Value(null),
              purgedAt: const Value(null),
              updatedAt: Value(updatedAt),
            ),
          );
    });
  }

  Future<void> delete(String messageId) async {
    final now = DateTime.now().toUtc();
    await (database.update(database.messages)..where(
          (message) =>
              message.systemId.equals(localSystemId) &
              message.id.equals(messageId) &
              message.purgedAt.isNull(),
        ))
        .write(
          MessagesCompanion(
            archived: const Value(true),
            deletedAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  Future<void> restore(String messageId) {
    final now = DateTime.now().toUtc();
    return (database.update(database.messages)..where(
          (message) =>
              message.systemId.equals(localSystemId) &
              message.id.equals(messageId) &
              message.archived.equals(true) &
              message.purgedAt.isNull(),
        ))
        .write(
          MessagesCompanion(
            archived: const Value(false),
            deletedAt: const Value(null),
            updatedAt: Value(now),
          ),
        );
  }

  Future<void> purge(String messageId) async {
    return database.transaction(() async {
      await (database.delete(database.contentRevisions)..where(
            (revision) =>
                revision.targetType.equals('message') &
                revision.targetId.equals(messageId),
          ))
          .go();
      // Keep an ID-only encrypted tombstone so replies do not become dangling,
      // while erasing the content payload and all content-bearing revisions.
      await (database.update(database.messages)..where(
            (message) =>
                message.systemId.equals(localSystemId) &
                message.id.equals(messageId) &
                message.archived.equals(true) &
                message.purgedAt.isNull(),
          ))
          .write(
            MessagesCompanion(
              body: Value(await encryptText('', 'messages', messageId, 'body')),
              memberId: const Value(null),
              boardMemberId: const Value(null),
              purgedAt: Value(DateTime.now().toUtc()),
              updatedAt: Value(DateTime.now().toUtc()),
            ),
          );
    });
  }

  String _boardKind(String value) {
    if (value == 'member' || value == 'channel') return value;
    return 'system';
  }

  Future<bool> _hasRevision(String messageId) async {
    final revision =
        await (database.select(database.contentRevisions)
              ..where(
                (revision) =>
                    revision.targetType.equals('message') &
                    revision.targetId.equals(messageId),
              )
              ..limit(1))
            .getSingleOrNull();
    return revision != null;
  }

  String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
