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

  Future<List<ReminderSummary>> _frontSetFrontMembers(List<String> memberIds) =>
      _frontApplyMembers(memberIds, replaceExisting: true);

  Future<List<ReminderSummary>> _frontAddFrontMembers(List<String> memberIds) =>
      _frontApplyMembers(memberIds, replaceExisting: false);

  Future<List<ReminderSummary>> _frontApplyMembers(
    List<String> memberIds, {
    required bool replaceExisting,
  }) async {
    final ids = memberIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (ids.isEmpty) {
      if (replaceExisting) await _frontClearCurrentFront();
      return const [];
    }

    final members =
        await (database.select(database.members)..where(
              (member) =>
                  member.systemId.equals(localSystemId) &
                  member.archived.equals(false) &
                  member.deletedAt.isNull() &
                  member.isCustomFront.equals(false) &
                  member.id.isIn(ids),
            ))
            .get();
    if (members.isEmpty) {
      if (replaceExisting) await _frontClearCurrentFront();
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

      final activeMemberIds = <String>{};
      for (final link in openLinks) {
        activeMemberIds.add(link.memberId);
      }
      final desiredMemberIds = members.map((member) => member.id).toSet();
      final hasCustomFront = openSessions.any(
        (session) => session.label != null,
      );
      if (replaceExisting &&
          !hasCustomFront &&
          activeMemberIds.length == desiredMemberIds.length &&
          activeMemberIds.containsAll(desiredMemberIds)) {
        return const <ReminderSummary>[];
      }
      if (replaceExisting) await _endOpenFrontSessions(now);

      var offset = 0;
      final newlyStartedMemberIds = <String>{};
      for (final member in members) {
        if (!replaceExisting && activeMemberIds.contains(member.id)) {
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
    await database.transaction(() async {
      final before = await _frontSnapshot(frontId);
      if (before == null) return;
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
      final after = await _frontSnapshot(frontId);
      if (after != null) await _frontRecordAudit(frontId, before, after);
    });
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
      final before = create ? null : await _frontSnapshot(frontId);
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
      if (before != null) {
        final after = await _frontSnapshot(frontId);
        if (after != null && after != before) {
          await _frontRecordAudit(frontId, before, after);
        }
      }
    });
  }

  Future<String?> _frontSnapshot(String frontId) async {
    final front =
        await (database.select(database.frontSessions)..where(
              (session) =>
                  session.id.equals(frontId) &
                  session.systemId.equals(localSystemId),
            ))
            .getSingleOrNull();
    if (front == null) return null;
    final links = await (database.select(
      database.frontSessionMembers,
    )..where((link) => link.sessionId.equals(frontId))).get();
    return jsonEncode({
      'label': await _decryptLocalText(
        front.label,
        'front_sessions',
        frontId,
        'label',
      ),
      'status_note': await _decryptLocalText(
        front.statusNote,
        'front_sessions',
        frontId,
        'status_note',
      ),
      'started_at': front.startedAt.toIso8601String(),
      'ended_at': front.endedAt?.toIso8601String(),
      'member_ids': [for (final link in links) link.memberId],
    });
  }

  Future<void> _frontRecordAudit(
    String frontId,
    String before,
    String after,
  ) async {
    final auditId = newLocalId('front-audit');
    await database
        .into(database.frontAuditEvents)
        .insert(
          FrontAuditEventsCompanion.insert(
            id: auditId,
            frontId: Value(frontId),
            historicalFrontId: frontId,
            beforeSnapshot: Value(
              await _encryptNullableLocalText(
                before,
                'front_audit_events',
                auditId,
                'before_snapshot',
              ),
            ),
            afterSnapshot: Value(
              await _encryptNullableLocalText(
                after,
                'front_audit_events',
                auditId,
                'after_snapshot',
              ),
            ),
            createdAt: DateTime.now().toUtc(),
          ),
        );
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

  Future<List<ReminderSummary>> _frontSetCustomFront(String label) =>
      _frontApplyCustomFront(label, replaceExisting: true);

  Future<List<ReminderSummary>> _frontAddCustomFront(String label) =>
      _frontApplyCustomFront(label, replaceExisting: false);

  Future<List<ReminderSummary>> _frontApplyCustomFront(
    String label, {
    required bool replaceExisting,
  }) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty) {
      if (replaceExisting) await _frontClearCurrentFront();
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
      if (!replaceExisting) {
        for (final front in existing) {
          if ((await _decryptLocalText(
                front.label,
                'front_sessions',
                front.id,
                'label',
              ))?.trim().toLowerCase() ==
              trimmed.toLowerCase()) {
            return const <ReminderSummary>[];
          }
        }
      } else if (existing.length == 1 &&
          (await _decryptLocalText(
                existing.single.label,
                'front_sessions',
                existing.single.id,
                'label',
              ))?.trim().toLowerCase() ==
              trimmed.toLowerCase()) {
        return const <ReminderSummary>[];
      }
      if (replaceExisting) await _endOpenFrontSessions(now);

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
