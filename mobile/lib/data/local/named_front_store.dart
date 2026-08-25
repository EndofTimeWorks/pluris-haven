part of 'haven_repository.dart';

extension LocalHavenRepositoryNamedFronts on LocalHavenRepository {
  Stream<List<NamedFront>> _namedFrontWatch() {
    final query = database.select(database.namedFronts)
      ..where((nf) => nf.systemId.equals(localSystemId))
      ..orderBy([(nf) => OrderingTerm(expression: nf.createdAt)]);
    return query.watch().asyncMap(
      (rows) => Future.wait(
        rows.map((row) async {
          final values = await Future.wait([
            _decryptLocalText(row.name, 'named_fronts', row.id, 'name'),
            _decryptLocalText(
              row.customLabel,
              'named_fronts',
              row.id,
              'custom_label',
            ),
            _decryptLocalText(
              row.colorHex,
              'named_fronts',
              row.id,
              'color_hex',
            ),
            _decryptLocalText(
              row.avatarUrl,
              'named_fronts',
              row.id,
              'avatar_url',
            ),
            _decryptLocalText(
              row.description,
              'named_fronts',
              row.id,
              'description',
            ),
          ]);
          return row.copyWith(
            name: values[0] ?? '',
            customLabel: Value(values[1]),
            colorHex: Value(values[2]),
            avatarUrl: Value(values[3]),
            description: Value(values[4]),
          );
        }),
      ),
    );
  }

  Future<void> _namedFrontSave(NamedFront front, List<String> memberIds) async {
    final now = DateTime.now().toUtc();
    await database.transaction(() async {
      await database
          .into(database.namedFronts)
          .insertOnConflictUpdate(
            NamedFrontsCompanion.insert(
              id: front.id,
              systemId: localSystemId,
              name: await _encryptLocalText(
                front.name,
                'named_fronts',
                front.id,
                'name',
              ),
              customLabel: Value(
                await _encryptNullableLocalText(
                  front.customLabel,
                  'named_fronts',
                  front.id,
                  'custom_label',
                ),
              ),
              colorHex: Value(
                await _encryptNullableLocalText(
                  front.colorHex,
                  'named_fronts',
                  front.id,
                  'color_hex',
                ),
              ),
              avatarUrl: Value(
                await _encryptNullableLocalText(
                  front.avatarUrl,
                  'named_fronts',
                  front.id,
                  'avatar_url',
                ),
              ),
              description: Value(
                await _encryptNullableLocalText(
                  front.description,
                  'named_fronts',
                  front.id,
                  'description',
                ),
              ),
              createdAt: front.createdAt,
              updatedAt: now,
            ),
          );
      await (database.delete(
        database.namedFrontMembers,
      )..where((nfm) => nfm.namedFrontId.equals(front.id))).go();
      for (final memberId in memberIds) {
        await database
            .into(database.namedFrontMembers)
            .insert(
              NamedFrontMembersCompanion.insert(
                namedFrontId: front.id,
                memberId: memberId,
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
    });
  }

  Future<List<ReminderSummary>> _namedFrontApply(String namedFrontId) async {
    final namedFront = await (database.select(
      database.namedFronts,
    )..where((front) => front.id.equals(namedFrontId))).getSingleOrNull();
    final members = await (database.select(
      database.namedFrontMembers,
    )..where((nfm) => nfm.namedFrontId.equals(namedFrontId))).get();
    final label = _nullIfBlank(
      await _decryptLocalText(
        namedFront?.customLabel,
        'named_fronts',
        namedFrontId,
        'custom_label',
      ),
    );
    if (members.isEmpty && label != null) return setCustomFront(label);
    return setFrontMembers(members.map((m) => m.memberId).toList());
  }

  Future<void> _namedFrontDelete(String namedFrontId) async {
    await (database.delete(
      database.namedFrontMembers,
    )..where((nfm) => nfm.namedFrontId.equals(namedFrontId))).go();
    await (database.delete(
      database.namedFronts,
    )..where((nf) => nf.id.equals(namedFrontId))).go();
  }
}
