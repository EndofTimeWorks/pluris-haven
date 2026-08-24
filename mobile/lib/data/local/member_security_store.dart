part of 'haven_repository.dart';

extension LocalHavenRepositoryMemberSecurity on LocalHavenRepository {
  String _memberAad(String memberId, String field) =>
      'members:$memberId:$field';

  Future<String?> _encryptMember(
    String memberId,
    String field,
    String? plaintext,
  ) {
    return crypto.encrypt(plaintext, aad: _memberAad(memberId, field));
  }

  Future<String?> _decryptMember(
    Member member,
    String field,
    String? ciphertext,
  ) {
    return _decryptMemberValue(member.id, field, ciphertext);
  }

  Future<String?> _decryptMemberValue(
    String memberId,
    String field,
    String? ciphertext,
  ) async {
    final key = (memberId, field);
    final cached = _memberDecryptCache[key];
    if (cached != null && cached.ciphertext == ciphertext) {
      return cached.plaintext;
    }
    final plaintext = await crypto.decrypt(
      ciphertext,
      aad: _memberAad(memberId, field),
    );
    _memberDecryptCache[key] = (ciphertext: ciphertext, plaintext: plaintext);
    return plaintext;
  }

  Future<String?> _migrateMemberField(
    Member member,
    String field,
    String? legacyCiphertext,
  ) async {
    final plaintext = member.profileEncryptionVersion == 0
        ? legacyCiphertext
        : await crypto.decrypt(legacyCiphertext);
    return _encryptMember(member.id, field, plaintext);
  }

  Future<String?> _blindIndex(String plaintext) async {
    return await crypto.blindIndex(plaintext);
  }

  Future<void> _ensureLocalSystem() async {
    final now = DateTime.now().toUtc();

    await database
        .into(database.pluralSystems)
        .insert(
          PluralSystemsCompanion.insert(
            id: localSystemId,
            name: await _encryptLocalText(
              'Local system',
              'plural_systems',
              localSystemId,
              'name',
            ),
            createdAt: now,
            updatedAt: now,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<void> _migrateMemberNamesToEncryption() async {
    if (await _preferenceEquals(
      _memberEncryptionSweepPreference,
      _memberEncryptionSweepVersion,
    )) {
      crypto.rejectLegacyCiphertext();
      return;
    }
    await database.transaction(() async {
      final members = await (database.select(
        database.members,
      )..where((member) => member.systemId.equals(localSystemId))).get();
      for (final member in members) {
        if (member.profileEncryptionVersion >= 2) {
          await _verifyEncryptedMemberProfile(member);
          continue;
        }

        final displayName = member.displayNameHash == null
            ? member.displayName
            : await crypto.decrypt(member.displayName);
        if (displayName == null) {
          throw StateError('Member name could not be migrated: ${member.id}');
        }

        final encrypted = await _encryptMember(
          member.id,
          'display_name',
          displayName,
        );
        if (encrypted == null) {
          throw StateError('Member name encryption returned no value.');
        }
        final blindIndex = await crypto.blindIndex(displayName);
        await (database.update(
          database.members,
        )..where((row) => row.id.equals(member.id))).write(
          MembersCompanion(
            displayName: Value(encrypted),
            displayNameHash: Value(blindIndex),
            profileEncryptionVersion: const Value(2),
            pronouns: Value(
              await _migrateMemberField(member, 'pronouns', member.pronouns),
            ),
            colorHex: Value(
              await _migrateMemberField(member, 'color_hex', member.colorHex),
            ),
            birthday: Value(
              await _migrateMemberField(member, 'birthday', member.birthday),
            ),
            emoji: Value(
              await _migrateMemberField(member, 'emoji', member.emoji),
            ),
            privacy: Value(
              await _migrateMemberField(member, 'privacy', member.privacy),
            ),
            description: Value(
              await _migrateMemberField(
                member,
                'description',
                member.description,
              ),
            ),
            avatarUrl: Value(
              await _migrateMemberField(member, 'avatar_url', member.avatarUrl),
            ),
            pluralKitId: Value(
              await _migrateMemberField(
                member,
                'pluralkit_id',
                member.pluralKitId,
              ),
            ),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
      }
      await _writePreference(
        _memberEncryptionSweepPreference,
        _memberEncryptionSweepVersion,
      );
      crypto.rejectLegacyCiphertext();
    });
  }

  Future<void> _verifyEncryptedMemberProfile(Member member) async {
    await _decryptMember(member, 'display_name', member.displayName);
    await _decryptMember(member, 'pronouns', member.pronouns);
    await _decryptMember(member, 'color_hex', member.colorHex);
    await _decryptMember(member, 'birthday', member.birthday);
    await _decryptMember(member, 'emoji', member.emoji);
    await _decryptMember(member, 'privacy', member.privacy);
    await _decryptMember(member, 'description', member.description);
    await _decryptMember(member, 'avatar_url', member.avatarUrl);
    await _decryptMember(member, 'pluralkit_id', member.pluralKitId);
  }
}
