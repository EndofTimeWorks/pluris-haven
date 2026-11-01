import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/import/import_sources.dart';
import 'package:pluris_haven/data/local/app_database.dart';
import 'package:pluris_haven/data/local/haven_repository.dart';

import 'test_repository.dart';

void main() {
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
