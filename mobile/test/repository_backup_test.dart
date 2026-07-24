import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/backup/repository_backup.dart';
import 'package:pluris_haven/data/local/app_database.dart';
import 'package:pluris_haven/data/local/haven_repository.dart';

import 'test_repository.dart';

void main() {
  test(
    'builds a device-key encrypted snapshot from the live repository',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = testRepository(database);
      await repository.ensureLocalSystem();
      await repository.saveMember(const MemberDraft(displayName: 'River'));
      await repository.setCustomFront('River');

      final snapshot = await repository.buildEncryptedBackupSnapshot(
        snapshotId: 'live-repository-snapshot',
        createdAt: DateTime.utc(2026, 7, 24),
        chunkSize: 1024,
      );
      final restored =
          jsonDecode(await snapshot.restoreArchiveJson(testCrypto()))
              as Map<String, dynamic>;

      expect(restored['format'], 'pluris_haven.local_archive');
      expect((restored['members'] as List), hasLength(1));
      expect((restored['fronts'] as List), hasLength(1));
      expect(snapshot.chunks, isNotEmpty);
    },
  );
}
