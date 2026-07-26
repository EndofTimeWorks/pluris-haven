import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/backup/repository_backup.dart';
import 'package:pluris_haven/data/local/app_database.dart';
import 'package:pluris_haven/data/local/haven_repository.dart';
import 'package:pluris_haven/data/security/archive_encryption.dart';
import 'package:pluris_haven/data/security/haven_crypto.dart';

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

  test(
    'password archive can recover data into a repository with a new device key',
    () async {
      final sourceDatabase = AppDatabase(NativeDatabase.memory());
      final restoredDatabase = AppDatabase(NativeDatabase.memory());
      addTearDown(sourceDatabase.close);
      addTearDown(restoredDatabase.close);

      final source = LocalHavenRepository(sourceDatabase, crypto: testCrypto());
      await source.ensureLocalSystem();
      await source.saveMember(const MemberDraft(displayName: 'River'));

      final encrypted = await encryptArchiveJson(
        archiveJson: await source.buildLocalArchiveJson(),
        passphrase: 'portable-recovery-passphrase',
        iterations: 1000,
      );
      final archiveJson = await decryptArchiveJson(
        encryptedArchiveJson: encrypted,
        passphrase: 'portable-recovery-passphrase',
      );

      final restored = LocalHavenRepository(
        restoredDatabase,
        crypto: HavenCrypto(
          SecretKey(List<int>.filled(32, 0x24, growable: false)),
        ),
      );
      await restored.ensureLocalSystem();
      await restored.importLocalArchiveJson(
        archiveJson,
        fileName: 'portable-recovery.phx.json',
      );

      final members = await restored.watchMembers().first;
      expect(members.map((member) => member.displayName), contains('River'));
    },
  );
}
