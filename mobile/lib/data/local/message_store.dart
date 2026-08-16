import 'package:drift/drift.dart';

import 'app_database.dart';
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
  });

  final AppDatabase database;
  final EncryptLocalText encryptText;
  final DecryptLocalText decryptText;

  Stream<List<MessageSummary>> watch() {
    final query = database.select(database.messages)
      ..where(
        (message) =>
            message.systemId.equals(localSystemId) &
            message.archived.equals(false),
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
            archived: row.archived,
          ),
      ],
    );
  }

  Future<void> save(MessageDraft draft) async {
    final body = draft.body.trim();
    if (body.isEmpty) return;

    final now = DateTime.now().toUtc();
    final messageId = 'message-${now.microsecondsSinceEpoch}';
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

    final now = DateTime.now().toUtc();
    await (database.update(database.messages)..where(
          (message) =>
              message.systemId.equals(localSystemId) &
              message.id.equals(messageId),
        ))
        .write(
          MessagesCompanion(
            memberId: Value(_nullIfBlank(draft.memberId)),
            body: Value(await encryptText(body, 'messages', messageId, 'body')),
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
            updatedAt: Value(now),
          ),
        );
  }

  Future<void> delete(String messageId) async {
    final now = DateTime.now().toUtc();
    await (database.update(database.messages)..where(
          (message) =>
              message.systemId.equals(localSystemId) &
              message.id.equals(messageId),
        ))
        .write(
          MessagesCompanion(
            archived: const Value(true),
            deletedAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  String _boardKind(String value) {
    if (value == 'member' || value == 'channel') return value;
    return 'system';
  }

  String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
