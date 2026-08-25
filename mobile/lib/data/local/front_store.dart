part of 'haven_repository.dart';

extension LocalHavenRepositoryFronts on LocalHavenRepository {
  Stream<List<FrontHistoryEntry>> _frontWatchHistory({int? limit}) {
    final query = database.select(database.frontSessions)
      ..where((session) => session.systemId.equals(localSystemId))
      ..orderBy([
        (session) => OrderingTerm(
          expression: session.startedAt,
          mode: OrderingMode.desc,
        ),
      ]);
    if (limit != null) {
      query.limit(limit);
    }

    return query.watch().asyncMap(_frontHistoryEntries);
  }

  Future<List<FrontHistoryEntry>> _frontHistoryEntries(
    List<FrontSession> rows,
  ) async {
    if (rows.isEmpty) {
      return const [];
    }

    final links =
        await (database.select(database.frontSessionMembers)..where(
              (link) => link.sessionId.isIn(rows.map((row) => row.id).toList()),
            ))
            .get();
    final linksBySession = <String, List<FrontSessionMember>>{};
    for (final link in links) {
      linksBySession.putIfAbsent(link.sessionId, () => []).add(link);
    }

    final memberIds = links.map((link) => link.memberId).toSet();
    final members = memberIds.isEmpty
        ? const <Member>[]
        : await (database.select(database.members)..where(
                (member) =>
                    member.systemId.equals(localSystemId) &
                    member.id.isIn(memberIds),
              ))
              .get();
    final namesById = <String, String>{};
    final memberNames = await Future.wait(
      members.map((member) async {
        final name = (await _decryptMember(
          member,
          'display_name',
          member.displayName,
        ))?.trim();
        return (id: member.id, name: name);
      }),
    );
    for (final member in memberNames) {
      final name = member.name;
      if (name != null && name.isNotEmpty) {
        namesById[member.id] = name;
      }
    }

    return Future.wait(
      rows.map((row) async {
        final sessionLinks = linksBySession[row.id] ?? const [];
        final values = await Future.wait([
          _decryptLocalText(row.label, 'front_sessions', row.id, 'label'),
          _decryptLocalText(
            row.statusNote,
            'front_sessions',
            row.id,
            'status_note',
          ),
        ]);
        final explicit = values[0]?.trim();
        final label = explicit != null && explicit.isNotEmpty
            ? explicit
            : sessionLinks.isEmpty
            ? 'Unknown front'
            : sessionLinks
                  .map((link) => namesById[link.memberId])
                  .whereType<String>()
                  .where((name) => name.isNotEmpty)
                  .join(', ');
        return FrontHistoryEntry(
          id: row.id,
          label: label.isEmpty ? 'Unknown front' : label,
          statusNote: values[1],
          startedAt: row.startedAt,
          endedAt: row.endedAt,
          memberIds: [for (final link in sessionLinks) link.memberId],
        );
      }),
    );
  }

  Future<List<ReminderSummary>> _frontSetFrontMembers(
    List<String> memberIds,
  ) async {
    final ids = memberIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (ids.isEmpty) {
      await _frontClearCurrentFront();
      return const [];
    }

    final members =
        await (database.select(database.members)..where(
              (member) =>
                  member.systemId.equals(localSystemId) &
                  member.archived.equals(false) &
                  member.isCustomFront.equals(false) &
                  member.id.isIn(ids),
            ))
            .get();
    if (members.isEmpty) {
      await _frontClearCurrentFront();
      return const [];
    }

    final now = DateTime.now().toUtc();

    return database.transaction(() async {
      final openSessions =
          await (database.select(database.frontSessions)..where(
                (front) =>
                    front.systemId.equals(localSystemId) &
                    front.endedAt.isNull(),
              ))
              .get();
      final openSessionIds = openSessions.map((session) => session.id).toList();
      final openLinks = openSessionIds.isEmpty
          ? const <FrontSessionMember>[]
          : await (database.select(
              database.frontSessionMembers,
            )..where((link) => link.sessionId.isIn(openSessionIds))).get();

      final sessionsByMember = <String, Set<String>>{};
      for (final link in openLinks) {
        sessionsByMember
            .putIfAbsent(link.memberId, () => <String>{})
            .add(link.sessionId);
      }
      final desiredIds = members.map((member) => member.id).toSet();
      final sessionsToClose = <String>{};
      for (final entry in sessionsByMember.entries) {
        if (!desiredIds.contains(entry.key)) {
          sessionsToClose.addAll(entry.value);
        }
      }

      for (final sessionId in sessionsToClose) {
        await _endFrontSession(sessionId, now);
      }

      final remainingActiveMemberIds = <String>{};
      for (final entry in sessionsByMember.entries) {
        if (entry.value.any(
          (sessionId) => !sessionsToClose.contains(sessionId),
        )) {
          remainingActiveMemberIds.add(entry.key);
        }
      }

      var offset = 0;
      final newlyStartedMemberIds = <String>{};
      for (final member in members) {
        if (remainingActiveMemberIds.contains(member.id)) {
          continue;
        }
        final startedAt = now.add(Duration(microseconds: offset++));
        final sessionId = newLocalId('front');
        await database
            .into(database.frontSessions)
            .insert(
              FrontSessionsCompanion.insert(
                id: sessionId,
                systemId: localSystemId,
                startedAt: startedAt,
                createdAt: startedAt,
                updatedAt: startedAt,
              ),
            );
        await database
            .into(database.frontSessionMembers)
            .insert(
              FrontSessionMembersCompanion.insert(
                sessionId: sessionId,
                memberId: member.id,
              ),
            );
        newlyStartedMemberIds.add(member.id);
      }

      return _reminders.claimAfterFront(
        newlyStartedMemberIds: newlyStartedMemberIds,
        frontStarted: newlyStartedMemberIds.isNotEmpty,
        firedAt: now,
      );
    });
  }

  Future<void> _frontUpdateFrontStatusNote(
    String frontId,
    String? statusNote,
  ) async {
    await (database.update(database.frontSessions)..where(
          (front) =>
              front.systemId.equals(localSystemId) & front.id.equals(frontId),
        ))
        .write(
          FrontSessionsCompanion(
            statusNote: Value(
              await _encryptNullableLocalText(
                _nullIfBlank(statusNote),
                'front_sessions',
                frontId,
                'status_note',
              ),
            ),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
  }

  Future<void> _frontSaveFrontHistoryEntry(FrontHistoryDraft draft) async {
    final now = DateTime.now().toUtc();
    final id = newLocalId('front');
    await _writeFrontHistoryEntry(id, draft, now, create: true);
  }

  Future<void> _frontUpdateFrontHistoryEntry(
    String frontId,
    FrontHistoryDraft draft,
  ) {
    return _writeFrontHistoryEntry(
      frontId,
      draft,
      DateTime.now().toUtc(),
      create: false,
    );
  }

  Future<void> _writeFrontHistoryEntry(
    String frontId,
    FrontHistoryDraft draft,
    DateTime now, {
    required bool create,
  }) async {
    final startedAt = draft.startedAt.toUtc();
    final endedAt = draft.endedAt.toUtc();
    if (endedAt.isBefore(startedAt)) {
      throw const FormatException('Front end cannot be before its start.');
    }
    final memberIds = draft.memberIds.toSet().toList(growable: false);
    final label = _nullIfBlank(draft.label);
    if (memberIds.isEmpty && label == null) {
      throw const FormatException('Choose members or enter a front label.');
    }
    await database.transaction(() async {
      if (create) {
        await database
            .into(database.frontSessions)
            .insert(
              FrontSessionsCompanion.insert(
                id: frontId,
                systemId: localSystemId,
                label: Value(
                  await _encryptNullableLocalText(
                    memberIds.isEmpty ? label : null,
                    'front_sessions',
                    frontId,
                    'label',
                  ),
                ),
                statusNote: Value(
                  await _encryptNullableLocalText(
                    _nullIfBlank(draft.statusNote),
                    'front_sessions',
                    frontId,
                    'status_note',
                  ),
                ),
                startedAt: startedAt,
                endedAt: Value(endedAt),
                createdAt: now,
                updatedAt: now,
              ),
            );
      } else {
        await (database.update(database.frontSessions)..where(
              (front) =>
                  front.id.equals(frontId) &
                  front.systemId.equals(localSystemId),
            ))
            .write(
              FrontSessionsCompanion(
                label: Value(
                  await _encryptNullableLocalText(
                    memberIds.isEmpty ? label : null,
                    'front_sessions',
                    frontId,
                    'label',
                  ),
                ),
                statusNote: Value(
                  await _encryptNullableLocalText(
                    _nullIfBlank(draft.statusNote),
                    'front_sessions',
                    frontId,
                    'status_note',
                  ),
                ),
                startedAt: Value(startedAt),
                endedAt: Value(endedAt),
                updatedAt: Value(now),
              ),
            );
        await (database.delete(
          database.frontSessionMembers,
        )..where((link) => link.sessionId.equals(frontId))).go();
      }
      for (final memberId in memberIds) {
        await database
            .into(database.frontSessionMembers)
            .insert(
              FrontSessionMembersCompanion.insert(
                sessionId: frontId,
                memberId: memberId,
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
    });
  }

  Future<void> _frontDeleteFrontSession(String frontId) async {
    await database.transaction(() async {
      await (database.delete(
        database.frontSessionMembers,
      )..where((link) => link.sessionId.equals(frontId))).go();
      await (database.delete(database.frontSessions)..where(
            (front) =>
                front.systemId.equals(localSystemId) & front.id.equals(frontId),
          ))
          .go();
    });
  }

  Future<List<ReminderSummary>> _frontSetCustomFront(String label) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty) {
      await _frontClearCurrentFront();
      return const [];
    }

    final now = DateTime.now().toUtc();

    return database.transaction(() async {
      final existing =
          await (database.select(database.frontSessions)..where(
                (front) =>
                    front.systemId.equals(localSystemId) &
                    front.endedAt.isNull(),
              ))
              .get();
      for (final front in existing) {
        if ((await _decryptLocalText(
              front.label,
              'front_sessions',
              front.id,
              'label',
            ))?.trim() ==
            trimmed) {
          return const <ReminderSummary>[];
        }
      }

      final frontId = newLocalId('front');
      await database
          .into(database.frontSessions)
          .insert(
            FrontSessionsCompanion.insert(
              id: frontId,
              systemId: localSystemId,
              label: Value(
                await _encryptLocalText(
                  trimmed,
                  'front_sessions',
                  frontId,
                  'label',
                ),
              ),
              startedAt: now,
              createdAt: now,
              updatedAt: now,
            ),
          );
      return _reminders.claimAfterFront(
        newlyStartedMemberIds: const {},
        frontStarted: true,
        firedAt: now,
      );
    });
  }

  Future<void> _frontClearCurrentFront() async {
    final now = DateTime.now().toUtc();
    await _endOpenFrontSessions(now);
  }
}
