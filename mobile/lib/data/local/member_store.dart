import 'package:drift/drift.dart';

import '../ordering/lexorank.dart';
import 'app_database.dart';
import 'local_id.dart';

typedef EncryptMemberText =
    Future<String?> Function(String memberId, String field, String? plaintext);
typedef DecryptMemberText =
    Future<String?> Function(String memberId, String field, String? ciphertext);
typedef BlindIndexText = Future<String?> Function(String plaintext);

class MemberSummary {
  const MemberSummary({
    required this.id,
    required this.displayName,
    this.pronouns,
    this.colorHex,
    this.birthday,
    this.emoji,
    this.privacy,
    this.description,
    this.avatarUrl,
    this.pluralKitId,
    this.archived = false,
    this.isCustomFront = false,
    this.frameShape = 'circle',
    this.lexoRank = '0|m',
    this.folderId,
    this.groupIds = const [],
  });

  final String id;
  final String displayName;
  final String? pronouns;
  final String? colorHex;
  final String? birthday;
  final String? emoji;
  final String? privacy;
  final String? description;
  final String? avatarUrl;
  final String? pluralKitId;
  final bool archived;
  final bool isCustomFront;
  final String frameShape;
  final String lexoRank;
  final String? folderId;
  final List<String> groupIds;
}

class MemberDraft {
  const MemberDraft({
    required this.displayName,
    this.pronouns,
    this.colorHex,
    this.birthday,
    this.emoji,
    this.privacy,
    this.description,
    this.avatarUrl,
    this.pluralKitId,
    this.folderId,
    this.groupIds,
  });

  final String displayName;
  final String? pronouns;
  final String? colorHex;
  final String? birthday;
  final String? emoji;
  final String? privacy;
  final String? description;
  final String? avatarUrl;
  final String? pluralKitId;
  final String? folderId;
  final List<String>? groupIds;
}

class LocalMemberStore {
  LocalMemberStore(
    this.database, {
    required this.encryptText,
    required this.decryptText,
    required this.blindIndex,
    required this.onDeleted,
  });

  final AppDatabase database;
  final EncryptMemberText encryptText;
  final DecryptMemberText decryptText;
  final BlindIndexText blindIndex;
  final void Function(String memberId) onDeleted;

  Stream<List<MemberSummary>> watch({
    bool includeArchived = false,
    bool includeCustomFronts = false,
    bool listOnly = false,
  }) {
    return database
        .customSelect(
          '''
SELECT
  m.id,
  m.display_name,
  m.pronouns,
  m.color_hex,
  m.birthday,
  m.emoji,
  m.privacy,
  m.description,
  m.avatar_url,
  m.plural_kit_id,
  m.archived,
  m.is_custom_front,
  m.frame_shape,
  m.lexo_rank,
  m.folder_id,
  GROUP_CONCAT(gm.group_id) AS group_ids
FROM members m
LEFT JOIN group_members gm ON gm.member_id = m.id
WHERE
  m.system_id = ?
  AND (? = 1 OR m.archived = 0)
  AND (? = 1 OR m.is_custom_front = 0)
GROUP BY
  m.id,
  m.display_name,
  m.pronouns,
  m.color_hex,
  m.birthday,
  m.emoji,
  m.privacy,
  m.description,
  m.avatar_url,
  m.plural_kit_id,
  m.archived,
  m.is_custom_front,
  m.frame_shape,
  m.lexo_rank,
  m.folder_id
ORDER BY m.lexo_rank ASC, m.created_at ASC, m.id ASC
          ''',
          variables: [
            Variable<String>(localSystemId),
            Variable<int>(includeArchived ? 1 : 0),
            Variable<int>(includeCustomFronts ? 1 : 0),
          ],
          readsFrom: {database.members, database.groupMembers},
        )
        .watch()
        .asyncMap((rows) async {
          return Future.wait(
            rows.map((row) async {
              final data = row.data;
              final memberId = data['id'] as String;
              final values = await Future.wait([
                decryptText(
                  memberId,
                  'display_name',
                  data['display_name'] as String,
                ),
                decryptText(memberId, 'pronouns', data['pronouns'] as String?),
                decryptText(
                  memberId,
                  'color_hex',
                  data['color_hex'] as String?,
                ),
                if (!listOnly)
                  decryptText(
                    memberId,
                    'birthday',
                    data['birthday'] as String?,
                  ),
                if (!listOnly)
                  decryptText(memberId, 'emoji', data['emoji'] as String?),
                decryptText(memberId, 'privacy', data['privacy'] as String?),
                if (!listOnly)
                  decryptText(
                    memberId,
                    'description',
                    data['description'] as String?,
                  ),
                decryptText(
                  memberId,
                  'avatar_url',
                  data['avatar_url'] as String?,
                ),
                if (!listOnly)
                  decryptText(
                    memberId,
                    'pluralkit_id',
                    data['plural_kit_id'] as String?,
                  ),
              ]);
              final displayName = values[0];
              if (displayName == null) {
                throw StateError('Protected member name is unexpectedly null.');
              }
              return MemberSummary(
                id: memberId,
                displayName: displayName,
                pronouns: values[1],
                colorHex: values[2],
                birthday: listOnly ? null : values[3],
                emoji: listOnly ? null : values[4],
                privacy: values[listOnly ? 3 : 5],
                description: listOnly ? null : values[6],
                avatarUrl: values[listOnly ? 4 : 7],
                pluralKitId: listOnly ? null : values[8],
                archived: _readSqlBool(data['archived']),
                isCustomFront: _readSqlBool(data['is_custom_front']),
                frameShape: data['frame_shape'] as String,
                lexoRank: data['lexo_rank'] as String,
                folderId: data['folder_id'] as String?,
                groupIds: _splitJoinedIds(data['group_ids']),
              );
            }),
          );
        });
  }

  Stream<List<MemberSummary>> watchCurrentFront() {
    final query = database.select(database.frontSessions)
      ..where(
        (front) =>
            front.systemId.equals(localSystemId) & front.endedAt.isNull(),
      )
      ..orderBy([
        (front) =>
            OrderingTerm(expression: front.startedAt, mode: OrderingMode.asc),
      ]);

    return query.watch().asyncMap((sessions) async {
      if (sessions.isEmpty) return const <MemberSummary>[];
      final sessionIds = sessions.map((session) => session.id).toList();
      final links = await (database.select(
        database.frontSessionMembers,
      )..where((link) => link.sessionId.isIn(sessionIds))).get();
      if (links.isEmpty) return const <MemberSummary>[];

      final memberIds = links.map((link) => link.memberId).toSet();
      final members =
          await (database.select(database.members)..where(
                (member) =>
                    member.systemId.equals(localSystemId) &
                    member.archived.equals(false) &
                    member.isCustomFront.equals(false) &
                    member.id.isIn(memberIds.toList()),
              ))
              .get();
      final byId = {for (final member in members) member.id: member};
      final summaries = <MemberSummary>[];
      final seen = <String>{};
      for (final link in links) {
        if (!seen.add(link.memberId)) continue;
        final row = byId[link.memberId];
        if (row == null) continue;
        final displayName = await decryptText(
          row.id,
          'display_name',
          row.displayName,
        );
        if (displayName == null) {
          throw StateError('Protected member name is unexpectedly null.');
        }
        summaries.add(
          MemberSummary(
            id: row.id,
            displayName: displayName,
            pronouns: await decryptText(row.id, 'pronouns', row.pronouns),
            colorHex: await decryptText(row.id, 'color_hex', row.colorHex),
            birthday: await decryptText(row.id, 'birthday', row.birthday),
            emoji: await decryptText(row.id, 'emoji', row.emoji),
            privacy: await decryptText(row.id, 'privacy', row.privacy),
            description: await decryptText(
              row.id,
              'description',
              row.description,
            ),
            avatarUrl: await decryptText(row.id, 'avatar_url', row.avatarUrl),
            pluralKitId: await decryptText(
              row.id,
              'pluralkit_id',
              row.pluralKitId,
            ),
            archived: row.archived,
            isCustomFront: row.isCustomFront,
            frameShape: row.frameShape,
            lexoRank: row.lexoRank,
            folderId: row.folderId,
          ),
        );
      }
      return summaries;
    });
  }

  Future<void> save(MemberDraft draft) async {
    final displayName = draft.displayName.trim();
    if (displayName.isEmpty) return;

    final now = DateTime.now().toUtc();
    final memberId = newLocalId('member');
    final groupIds = _normalizedGroupIds(draft);
    final folderId = _nullIfBlank(draft.folderId) ?? _firstOrNull(groupIds);
    final lexoRank = await _nextRank();
    final companion = MembersCompanion.insert(
      id: memberId,
      systemId: localSystemId,
      displayName: (await encryptText(memberId, 'display_name', displayName))!,
      displayNameHash: Value(await blindIndex(displayName)),
      profileEncryptionVersion: const Value(2),
      pronouns: Value(
        await encryptText(memberId, 'pronouns', _nullIfBlank(draft.pronouns)),
      ),
      colorHex: Value(
        await encryptText(memberId, 'color_hex', _nullIfBlank(draft.colorHex)),
      ),
      birthday: Value(
        await encryptText(memberId, 'birthday', _nullIfBlank(draft.birthday)),
      ),
      emoji: Value(
        await encryptText(memberId, 'emoji', _nullIfBlank(draft.emoji)),
      ),
      privacy: Value(
        await encryptText(memberId, 'privacy', _nullIfBlank(draft.privacy)),
      ),
      description: Value(
        await encryptText(
          memberId,
          'description',
          _nullIfBlank(draft.description),
        ),
      ),
      avatarUrl: Value(
        await encryptText(
          memberId,
          'avatar_url',
          _nullIfBlank(draft.avatarUrl),
        ),
      ),
      pluralKitId: Value(
        await encryptText(
          memberId,
          'pluralkit_id',
          _nullIfBlank(draft.pluralKitId),
        ),
      ),
      folderId: Value(folderId),
      lexoRank: lexoRank,
      createdAt: now,
      updatedAt: now,
    );

    await database.transaction(() async {
      await database.into(database.members).insert(companion);
      await _replaceGroupMemberships(memberId, groupIds);
    });
  }

  Future<void> update(String memberId, MemberDraft draft) async {
    final displayName = draft.displayName.trim();
    if (displayName.isEmpty) return;

    final existing =
        await (database.select(database.members)..where(
              (member) =>
                  member.systemId.equals(localSystemId) &
                  member.id.equals(memberId),
            ))
            .getSingleOrNull();
    final requestedFolderId = _nullIfBlank(draft.folderId);
    final preserveGroups = draft.groupIds == null && requestedFolderId == null;
    final groupIds = preserveGroups
        ? await _memberGroupIds(memberId)
        : _normalizedGroupIds(draft);
    final folderId = preserveGroups
        ? existing?.folderId
        : requestedFolderId ?? _firstOrNull(groupIds);
    final now = DateTime.now().toUtc();

    await database.transaction(() async {
      await (database.update(database.members)..where(
            (member) =>
                member.systemId.equals(localSystemId) &
                member.id.equals(memberId),
          ))
          .write(
            MembersCompanion(
              displayName: Value(
                (await encryptText(memberId, 'display_name', displayName))!,
              ),
              displayNameHash: Value(await blindIndex(displayName)),
              profileEncryptionVersion: const Value(2),
              pronouns: Value(
                await encryptText(
                  memberId,
                  'pronouns',
                  _nullIfBlank(draft.pronouns),
                ),
              ),
              colorHex: Value(
                await encryptText(
                  memberId,
                  'color_hex',
                  _nullIfBlank(draft.colorHex),
                ),
              ),
              birthday: Value(
                await encryptText(
                  memberId,
                  'birthday',
                  _nullIfBlank(draft.birthday),
                ),
              ),
              emoji: Value(
                await encryptText(memberId, 'emoji', _nullIfBlank(draft.emoji)),
              ),
              privacy: Value(
                await encryptText(
                  memberId,
                  'privacy',
                  _nullIfBlank(draft.privacy),
                ),
              ),
              description: Value(
                await encryptText(
                  memberId,
                  'description',
                  _nullIfBlank(draft.description),
                ),
              ),
              avatarUrl: Value(
                await encryptText(
                  memberId,
                  'avatar_url',
                  _nullIfBlank(draft.avatarUrl),
                ),
              ),
              pluralKitId: Value(
                await encryptText(
                  memberId,
                  'pluralkit_id',
                  _nullIfBlank(draft.pluralKitId),
                ),
              ),
              folderId: Value(folderId),
              updatedAt: Value(now),
            ),
          );
      await _replaceGroupMemberships(memberId, groupIds);
    });
  }

  Future<void> archive(String memberId, {required bool archived}) {
    return (database.update(database.members)..where(
          (member) =>
              member.systemId.equals(localSystemId) &
              member.id.equals(memberId),
        ))
        .write(
          MembersCompanion(
            archived: Value(archived),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
  }

  Future<void> delete(String memberId) async {
    await database.transaction(() async {
      await (database.delete(
        database.frontSessionMembers,
      )..where((frontMember) => frontMember.memberId.equals(memberId))).go();
      await (database.delete(
        database.groupMembers,
      )..where((groupMember) => groupMember.memberId.equals(memberId))).go();
      await (database.delete(database.members)..where(
            (member) =>
                member.systemId.equals(localSystemId) &
                member.id.equals(memberId),
          ))
          .go();
    });
    onDeleted(memberId);
  }

  Future<void> reorder(String memberId, String? prevRank, String? nextRank) {
    final newRank = Lexorank.between(prevRank, nextRank);
    return (database.update(
      database.members,
    )..where((member) => member.id.equals(memberId))).write(
      MembersCompanion(
        lexoRank: Value(newRank),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<String> rankForImport(String memberId, String? incomingRank) async {
    if (incomingRank != null && incomingRank.trim().isNotEmpty) {
      return incomingRank;
    }
    final existing = await (database.select(
      database.members,
    )..where((member) => member.id.equals(memberId))).getSingleOrNull();
    return existing?.lexoRank ?? _nextRank();
  }

  Future<String> _nextRank() async {
    var rows = await _orderedMembers();
    if (rows.isEmpty) return Lexorank.between(null, null);
    try {
      return Lexorank.between(rows.last.lexoRank, null);
    } on ArgumentError {
      await _rebalance(rows);
      rows = await _orderedMembers();
      return Lexorank.between(rows.last.lexoRank, null);
    } on StateError {
      await _rebalance(rows);
      rows = await _orderedMembers();
      return Lexorank.between(rows.last.lexoRank, null);
    }
  }

  Future<List<Member>> _orderedMembers() {
    return (database.select(database.members)
          ..where((member) => member.systemId.equals(localSystemId))
          ..orderBy([
            (member) => OrderingTerm(expression: member.lexoRank),
            (member) => OrderingTerm(expression: member.createdAt),
            (member) => OrderingTerm(expression: member.id),
          ]))
        .get();
  }

  Future<void> _rebalance(List<Member> members) async {
    final ranks = Lexorank.rebalanceRanks(members.length);
    for (var index = 0; index < members.length; index++) {
      await (database.update(database.members)
            ..where((member) => member.id.equals(members[index].id)))
          .write(MembersCompanion(lexoRank: Value(ranks[index])));
    }
  }

  Set<String> _normalizedGroupIds(MemberDraft draft) {
    final ids = <String>{};
    for (final groupId in draft.groupIds ?? const <String>[]) {
      final normalized = _nullIfBlank(groupId);
      if (normalized != null) ids.add(normalized);
    }
    final primaryGroupId = _nullIfBlank(draft.folderId);
    if (primaryGroupId != null) ids.add(primaryGroupId);
    return ids;
  }

  Future<Set<String>> _memberGroupIds(String memberId) async {
    final links = await (database.select(
      database.groupMembers,
    )..where((link) => link.memberId.equals(memberId))).get();
    return {for (final link in links) link.groupId};
  }

  Future<void> _replaceGroupMemberships(
    String memberId,
    Set<String> groupIds,
  ) async {
    await (database.delete(
      database.groupMembers,
    )..where((link) => link.memberId.equals(memberId))).go();
    for (final groupId in groupIds) {
      await database
          .into(database.groupMembers)
          .insert(
            GroupMembersCompanion.insert(groupId: groupId, memberId: memberId),
            mode: InsertMode.insertOrIgnore,
          );
    }
  }

  bool _readSqlBool(Object? value) => value == true || value == 1;

  List<String> _splitJoinedIds(Object? value) {
    if (value is! String || value.trim().isEmpty) return const [];
    return value
        .split(',')
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
  }

  String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  String? _firstOrNull(Set<String> values) =>
      values.isEmpty ? null : values.first;
}
