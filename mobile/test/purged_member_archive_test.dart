import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/import/import_sources.dart';
import 'package:pluris_haven/data/local/app_database.dart';
import 'package:pluris_haven/data/local/haven_repository.dart';

import 'test_repository.dart';

void main() {
  test('purge deletes only an unreferenced local avatar file', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = testRepository(database);
    await repository.ensureLocalSystem();
    await repository.saveMember(const MemberDraft(displayName: 'First'));
    final first = (await repository.watchMembers().first).single;
    final archive = jsonDecode(
      await repository.buildLocalArchiveJson(),
    ) as Map<String, dynamic>;
    ((archive['members'] as List).single
            as Map<String, dynamic>)['avatar_url'] =
        'local-avatar:avatar-1';
    (archive['avatar_assets'] as List).add({
      'id': 'avatar-1',
      'name': 'avatar-1.jpg',
      'mime_type': 'image/jpeg',
      'bytes_base64': base64Encode([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10]),
    });
    await repository.importLocalArchiveJson(
      jsonEncode(archive),
      strategy: ImportConflictStrategy.update,
    );
    final reference = (await repository.watchMembers().first).single.avatarUrl!;
    expect(await repository.readAvatar(reference), isNotNull);

    await repository.saveMember(
      MemberDraft(displayName: 'Second', avatarUrl: reference),
    );
    final second = (await repository.watchMembers().first).singleWhere(
      (member) => member.id != first.id,
    );
    await repository.deleteMember(first.id);
    await repository.purgeMember(first.id);
    expect(await repository.readAvatar(reference), isNotNull);
    await repository.deleteMember(second.id);
    await repository.purgeMember(second.id);
    expect(await repository.readAvatar(reference), isNull);
    await repository.importLocalArchiveJson(
      jsonEncode(archive),
      strategy: ImportConflictStrategy.update,
    );
    expect(await repository.readAvatar(reference), isNull);
  });

  test('purged member stays clear of older archive payloads', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = testRepository(database);
    await repository.ensureLocalSystem();
    await repository.saveMember(
      const MemberDraft(displayName: 'Private member', description: 'old bio'),
    );
    final member = (await repository.watchMembers().first).single;
    await repository.saveCustomField(
      const CustomFieldDraft(name: 'Private field', fieldType: 'text'),
    );
    final field = (await repository.watchCustomFields().first).single;
    await repository.setCustomFieldValue(
      fieldId: field.id,
      memberId: member.id,
      value: 'old private value',
    );

    final archive = jsonDecode(
      await repository.buildLocalArchiveJson(),
    ) as Map<String, dynamic>;
    (archive['content_revisions'] as List).add({
      'id': 'old-bio-revision',
      'target_type': 'member_bio',
      'target_id': member.id,
      'title': null,
      'body': 'old private bio',
      'pinned_at': null,
      'created_at': DateTime.utc(2026).toIso8601String(),
    });
    await repository.importLocalArchiveJson(
      jsonEncode(archive),
      strategy: ImportConflictStrategy.update,
    );
    expect(
      await database.select(database.contentRevisions).get(),
      hasLength(1),
    );

    await repository.deleteMember(member.id);
    await repository.purgeMember(member.id);
    expect(await database.select(database.contentRevisions).get(), isEmpty);

    await repository.importLocalArchiveJson(
      jsonEncode(archive),
      strategy: ImportConflictStrategy.update,
    );
    final tombstone = await (database.select(
      database.members,
    )..where((row) => row.id.equals(member.id))).getSingle();
    expect(tombstone.purgedAt, isNotNull);
    expect(tombstone.description, isNull);
    expect(await database.select(database.customFieldValues).get(), isEmpty);
    expect(await database.select(database.contentRevisions).get(), isEmpty);
  });
}
