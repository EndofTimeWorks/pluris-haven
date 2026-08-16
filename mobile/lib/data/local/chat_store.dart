import 'package:drift/drift.dart';

import 'app_customization.dart' show normalizeHexColor;
import 'app_database.dart';
import 'local_text_codec.dart';

class ChatCategorySummary {
  const ChatCategorySummary({
    required this.id,
    required this.name,
    this.description,
    required this.position,
  });

  final String id;
  final String name;
  final String? description;
  final int position;
}

class ChatCategoryDraft {
  const ChatCategoryDraft({required this.name, this.description});

  final String name;
  final String? description;
}

class ChatChannelSummary {
  const ChatChannelSummary({
    required this.id,
    required this.name,
    this.categoryId,
    this.description,
    this.colorHex,
    required this.position,
  });

  final String id;
  final String name;
  final String? categoryId;
  final String? description;
  final String? colorHex;
  final int position;
}

class ChatChannelDraft {
  const ChatChannelDraft({
    required this.name,
    this.categoryId,
    this.description,
    this.colorHex,
  });

  final String name;
  final String? categoryId;
  final String? description;
  final String? colorHex;
}

class LocalChatStore {
  LocalChatStore(
    this.database, {
    required this.encryptText,
    required this.encryptNullableText,
    required this.decryptText,
  });

  final AppDatabase database;
  final EncryptLocalText encryptText;
  final EncryptNullableLocalText encryptNullableText;
  final DecryptLocalText decryptText;

  Stream<List<ChatCategorySummary>> watchCategories() {
    final query = database.select(database.chatCategories)
      ..where((category) => category.systemId.equals(localSystemId))
      ..orderBy([(category) => OrderingTerm(expression: category.position)]);
    return query.watch().asyncMap(
      (rows) async => [
        for (final row in rows)
          ChatCategorySummary(
            id: row.id,
            name:
                await decryptText(
                  row.name,
                  'chat_categories',
                  row.id,
                  'name',
                ) ??
                '',
            description: await decryptText(
              row.description,
              'chat_categories',
              row.id,
              'description',
            ),
            position: row.position,
          ),
      ],
    );
  }

  Stream<List<ChatChannelSummary>> watchChannels() {
    final query = database.select(database.chatChannels)
      ..where((channel) => channel.systemId.equals(localSystemId))
      ..orderBy([(channel) => OrderingTerm(expression: channel.position)]);
    return query.watch().asyncMap(
      (rows) async => [
        for (final row in rows)
          ChatChannelSummary(
            id: row.id,
            name:
                await decryptText(row.name, 'chat_channels', row.id, 'name') ??
                '',
            categoryId: row.categoryId,
            description: await decryptText(
              row.description,
              'chat_channels',
              row.id,
              'description',
            ),
            colorHex: await decryptText(
              row.colorHex,
              'chat_channels',
              row.id,
              'color_hex',
            ),
            position: row.position,
          ),
      ],
    );
  }

  Future<void> saveCategory(ChatCategoryDraft draft) async {
    final name = draft.name.trim();
    if (name.isEmpty) return;
    final now = DateTime.now().toUtc();
    final categoryId = 'chat-category-${now.microsecondsSinceEpoch}';
    final maxPosition = database.chatCategories.position.max();
    final position =
        await (database.selectOnly(database.chatCategories)
              ..addColumns([maxPosition])
              ..where(database.chatCategories.systemId.equals(localSystemId)))
            .map((row) => row.read(maxPosition) ?? -1)
            .getSingle();
    await database
        .into(database.chatCategories)
        .insert(
          ChatCategoriesCompanion.insert(
            id: categoryId,
            systemId: localSystemId,
            name: await encryptText(
              name,
              'chat_categories',
              categoryId,
              'name',
            ),
            description: Value(
              await encryptNullableText(
                _nullIfBlank(draft.description),
                'chat_categories',
                categoryId,
                'description',
              ),
            ),
            position: Value(position + 1),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> updateCategory(
    String categoryId,
    ChatCategoryDraft draft,
  ) async {
    final name = draft.name.trim();
    if (name.isEmpty) return;
    await (database.update(database.chatCategories)..where(
          (category) =>
              category.systemId.equals(localSystemId) &
              category.id.equals(categoryId),
        ))
        .write(
          ChatCategoriesCompanion(
            name: Value(
              await encryptText(name, 'chat_categories', categoryId, 'name'),
            ),
            description: Value(
              await encryptNullableText(
                _nullIfBlank(draft.description),
                'chat_categories',
                categoryId,
                'description',
              ),
            ),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
  }

  Future<void> deleteCategory(String categoryId) async {
    await database.transaction(() async {
      await (database.update(database.chatChannels)
            ..where((channel) => channel.categoryId.equals(categoryId)))
          .write(const ChatChannelsCompanion(categoryId: Value(null)));
      await (database.delete(database.chatCategories)..where(
            (category) =>
                category.systemId.equals(localSystemId) &
                category.id.equals(categoryId),
          ))
          .go();
    });
  }

  Future<void> saveChannel(ChatChannelDraft draft) async {
    final name = draft.name.trim();
    if (name.isEmpty) return;
    final now = DateTime.now().toUtc();
    final channelId = 'chat-channel-${now.microsecondsSinceEpoch}';
    final maxPosition = database.chatChannels.position.max();
    final position =
        await (database.selectOnly(database.chatChannels)
              ..addColumns([maxPosition])
              ..where(database.chatChannels.systemId.equals(localSystemId)))
            .map((row) => row.read(maxPosition) ?? -1)
            .getSingle();
    await database
        .into(database.chatChannels)
        .insert(
          ChatChannelsCompanion.insert(
            id: channelId,
            systemId: localSystemId,
            categoryId: Value(_nullIfBlank(draft.categoryId)),
            name: await encryptText(name, 'chat_channels', channelId, 'name'),
            description: Value(
              await encryptNullableText(
                _nullIfBlank(draft.description),
                'chat_channels',
                channelId,
                'description',
              ),
            ),
            colorHex: Value(
              await encryptNullableText(
                normalizeHexColor(draft.colorHex),
                'chat_channels',
                channelId,
                'color_hex',
              ),
            ),
            position: Value(position + 1),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> updateChannel(String channelId, ChatChannelDraft draft) async {
    final name = draft.name.trim();
    if (name.isEmpty) return;
    await (database.update(database.chatChannels)..where(
          (channel) =>
              channel.systemId.equals(localSystemId) &
              channel.id.equals(channelId),
        ))
        .write(
          ChatChannelsCompanion(
            categoryId: Value(_nullIfBlank(draft.categoryId)),
            name: Value(
              await encryptText(name, 'chat_channels', channelId, 'name'),
            ),
            description: Value(
              await encryptNullableText(
                _nullIfBlank(draft.description),
                'chat_channels',
                channelId,
                'description',
              ),
            ),
            colorHex: Value(
              await encryptNullableText(
                normalizeHexColor(draft.colorHex),
                'chat_channels',
                channelId,
                'color_hex',
              ),
            ),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
  }

  Future<void> deleteChannel(String channelId) async {
    await database.transaction(() async {
      await (database.update(database.messages)
            ..where((message) => message.channelId.equals(channelId)))
          .write(const MessagesCompanion(channelId: Value(null)));
      await (database.delete(database.chatChannels)..where(
            (channel) =>
                channel.systemId.equals(localSystemId) &
                channel.id.equals(channelId),
          ))
          .go();
    });
  }

  String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
