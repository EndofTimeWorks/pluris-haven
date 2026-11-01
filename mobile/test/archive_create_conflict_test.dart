import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/import/import_sources.dart';
import 'package:pluris_haven/data/local/app_database.dart';
import 'package:pluris_haven/data/local/haven_repository.dart';

import 'test_repository.dart';

void main() {
  test('Repeated note IDs are rejected for every import choice', () async {
    final sourceDatabase = AppDatabase(NativeDatabase.memory());
    addTearDown(sourceDatabase.close);
    final source = testRepository(sourceDatabase);
    await source.ensureLocalSystem();
    await source.saveNote(const NoteDraft(title: 'First', body: 'One'));
    final archive = jsonDecode(
      await source.buildLocalArchiveJson(),
    ) as Map<String, dynamic>;
    final notes = archive['notes'] as List;
    notes.add(Map<String, dynamic>.from(notes.single as Map));

    for (final strategy in ImportConflictStrategy.values) {
      final targetDatabase = AppDatabase(NativeDatabase.memory());
      addTearDown(targetDatabase.close);
      final target = testRepository(targetDatabase);
      await target.ensureLocalSystem();
      await expectLater(
        target.importLocalArchiveJson(jsonEncode(archive), strategy: strategy),
        throwsFormatException,
      );
      expect(await target.watchNotes().first, isEmpty);
    }
  });

  test('Create rejects a reused note ID before adding other records', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = testRepository(database);
    await repository.ensureLocalSystem();
    await repository.saveNote(const NoteDraft(title: 'Local', body: 'Keep me'));
    final archive = jsonDecode(
      await repository.buildLocalArchiveJson(),
    ) as Map<String, dynamic>;
    ((archive['notes'] as List).single as Map<String, dynamic>)['body'] =
        'Imported replacement';
    (archive['groups'] as List).add({'id': 'new-group', 'name': 'New group'});

    await expectLater(
      repository.importLocalArchiveJson(
        jsonEncode(archive),
        strategy: ImportConflictStrategy.create,
      ),
      throwsFormatException,
    );
    expect((await repository.watchNotes().first).single.body, 'Keep me');
    expect(await repository.watchGroups().first, isEmpty);
  });

  test(
    'Create rejects a reused front ID without ending the active front',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = testRepository(database);
      await repository.ensureLocalSystem();
      await repository.saveMember(const MemberDraft(displayName: 'River'));
      final member = (await repository.watchMembers().first).single;
      await repository.setFrontMembers([member.id]);
      final active = (await repository.watchFrontHistory().first).single;
      final archive = jsonDecode(
        await repository.buildLocalArchiveJson(),
      ) as Map<String, dynamic>;
      archive['members'] = [];
      archive['front_members'] = [];

      await expectLater(
        repository.importLocalArchiveJson(
          jsonEncode(archive),
          strategy: ImportConflictStrategy.create,
        ),
        throwsFormatException,
      );
      final after = (await repository.watchFrontHistory().first).single;
      expect(after.id, active.id);
      expect(after.endedAt, isNull);
    },
  );

  test(
    'Create does not silently skip a reused member ID or add linked records',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = testRepository(database);
      await repository.ensureLocalSystem();
      await repository.saveMember(const MemberDraft(displayName: 'River'));
      final archive = jsonDecode(
        await repository.buildLocalArchiveJson(),
      ) as Map<String, dynamic>;
      ((archive['members'] as List).single
              as Map<String, dynamic>)['display_name'] =
          'Changed River';
      (archive['groups'] as List).add({'id': 'new-group', 'name': 'New group'});

      await expectLater(
        repository.importLocalArchiveJson(
          jsonEncode(archive),
          strategy: ImportConflictStrategy.create,
        ),
        throwsFormatException,
      );
      expect(
        (await repository.watchMembers().first).single.displayName,
        'River',
      );
      expect(await repository.watchGroups().first, isEmpty);
    },
  );
}
