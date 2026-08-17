import 'package:drift/drift.dart';

import 'app_database.dart';
import 'local_text_codec.dart';

class GroupSummary {
  const GroupSummary({
    required this.id,
    required this.name,
    this.parentGroupId,
    this.colorHex,
    this.description,
    this.emoji,
    this.memberCount = 0,
    this.isSubsystem = false,
  });

  final String id;
  final String name;
  final String? parentGroupId;
  final String? colorHex;
  final String? description;
  final String? emoji;
  final int memberCount;
  final bool isSubsystem;
}

class GroupDraft {
  const GroupDraft({
    required this.name,
    this.parentGroupId,
    this.colorHex,
    this.description,
    this.emoji,
    this.isSubsystem = false,
  });

  final String name;
  final String? parentGroupId;
  final String? colorHex;
  final String? description;
  final String? emoji;
  final bool isSubsystem;
}

class LocalGroupStore {
  LocalGroupStore(
    this.database, {
    required this.encryptText,
    required this.encryptNullableText,
    required this.decryptText,
  });

  final AppDatabase database;
  final EncryptLocalText encryptText;
  final EncryptNullableLocalText encryptNullableText;
  final DecryptLocalText decryptText;

  Stream<List<GroupSummary>> watch() {
    return database
        .customSelect(
          '''
SELECT
  g.id,
  g.parent_group_id,
  g.name,
  g.color_hex,
  g.description,
  g.emoji,
  g.is_subsystem,
  COUNT(gm.member_id) AS member_count
FROM system_groups g
LEFT JOIN group_members gm ON gm.group_id = g.id
WHERE g.system_id = ?
GROUP BY g.id, g.parent_group_id, g.name, g.color_hex, g.description, g.emoji, g.is_subsystem
ORDER BY LOWER(g.name) ASC
          ''',
          variables: [Variable<String>(localSystemId)],
          readsFrom: {database.systemGroups, database.groupMembers},
        )
        .watch()
        .asyncMap(
          (rows) async => [
            for (final row in rows)
              GroupSummary(
                id: row.data['id'] as String,
                name:
                    (await decryptText(
                      row.data['name'] as String,
                      'system_groups',
                      row.data['id'] as String,
                      'name',
                    )) ??
                    '',
                parentGroupId: row.data['parent_group_id'] as String?,
                colorHex: await decryptText(
                  row.data['color_hex'] as String?,
                  'system_groups',
                  row.data['id'] as String,
                  'color_hex',
                ),
                description: await decryptText(
                  row.data['description'] as String?,
                  'system_groups',
                  row.data['id'] as String,
                  'description',
                ),
                emoji: await decryptText(
                  row.data['emoji'] as String?,
                  'system_groups',
                  row.data['id'] as String,
                  'emoji',
                ),
                isSubsystem: (row.data['is_subsystem'] as int?) == 1,
                memberCount: row.data['member_count'] as int,
              ),
          ],
        );
  }

  Future<void> save(GroupDraft draft) async {
    final name = draft.name.trim();
    if (name.isEmpty) return;

    final now = DateTime.now().toUtc();
    final groupId = 'group-${now.microsecondsSinceEpoch}';
    await database
        .into(database.systemGroups)
        .insert(
          SystemGroupsCompanion.insert(
            id: groupId,
            systemId: localSystemId,
            name: await encryptText(name, 'system_groups', groupId, 'name'),
            parentGroupId: Value(_nullIfBlank(draft.parentGroupId)),
            colorHex: Value(
              await encryptNullableText(
                _nullIfBlank(draft.colorHex),
                'system_groups',
                groupId,
                'color_hex',
              ),
            ),
            description: Value(
              await encryptNullableText(
                _nullIfBlank(draft.description),
                'system_groups',
                groupId,
                'description',
              ),
            ),
            emoji: Value(
              await encryptNullableText(
                _nullIfBlank(draft.emoji),
                'system_groups',
                groupId,
                'emoji',
              ),
            ),
            isSubsystem: Value(draft.isSubsystem),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> update(String groupId, GroupDraft draft) async {
    final name = draft.name.trim();
    if (name.isEmpty) return;

    final parentId = _nullIfBlank(draft.parentGroupId);
    if (parentId == groupId || await _wouldCreateCycle(groupId, parentId)) {
      return;
    }

    await (database.update(database.systemGroups)..where(
          (group) =>
              group.id.equals(groupId) & group.systemId.equals(localSystemId),
        ))
        .write(
          SystemGroupsCompanion(
            parentGroupId: Value(parentId),
            name: Value(
              await encryptText(name, 'system_groups', groupId, 'name'),
            ),
            colorHex: Value(
              await encryptNullableText(
                _nullIfBlank(draft.colorHex),
                'system_groups',
                groupId,
                'color_hex',
              ),
            ),
            description: Value(
              await encryptNullableText(
                _nullIfBlank(draft.description),
                'system_groups',
                groupId,
                'description',
              ),
            ),
            emoji: Value(
              await encryptNullableText(
                _nullIfBlank(draft.emoji),
                'system_groups',
                groupId,
                'emoji',
              ),
            ),
            isSubsystem: Value(draft.isSubsystem),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
  }

  Future<void> delete(String groupId) async {
    await database.transaction(() async {
      await (database.update(database.systemGroups)..where(
            (group) =>
                group.parentGroupId.equals(groupId) &
                group.systemId.equals(localSystemId),
          ))
          .write(
            SystemGroupsCompanion(
              parentGroupId: const Value(null),
              updatedAt: Value(DateTime.now().toUtc()),
            ),
          );
      await (database.update(database.members)..where(
            (member) =>
                member.folderId.equals(groupId) &
                member.systemId.equals(localSystemId),
          ))
          .write(
            MembersCompanion(
              folderId: const Value(null),
              updatedAt: Value(DateTime.now().toUtc()),
            ),
          );
      await (database.delete(
        database.groupMembers,
      )..where((link) => link.groupId.equals(groupId))).go();
      await (database.delete(database.systemGroups)..where(
            (group) =>
                group.id.equals(groupId) & group.systemId.equals(localSystemId),
          ))
          .go();
    });
  }

  Future<bool> _wouldCreateCycle(String groupId, String? parentId) async {
    var cursor = parentId;
    final seen = <String>{};
    while (cursor != null && cursor.isNotEmpty) {
      if (cursor == groupId || !seen.add(cursor)) return true;
      final parent =
          await (database.select(database.systemGroups)
                ..where(
                  (group) =>
                      group.id.equals(cursor!) &
                      group.systemId.equals(localSystemId),
                )
                ..limit(1))
              .getSingleOrNull();
      cursor = parent?.parentGroupId;
    }
    return false;
  }

  String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
