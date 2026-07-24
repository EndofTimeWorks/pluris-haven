import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/backup/encrypted_backup_snapshot.dart';

import 'test_repository.dart';

void main() {
  test('creates an opaque chunked snapshot and restores it', () async {
    final crypto = testCrypto();
    final archive = jsonEncode({
      'format': 'pluris_haven.local_archive',
      'version': 1,
      'members': List.filled(40, {'display_name': 'River'}),
    });

    final snapshot = await EncryptedBackupSnapshot.create(
      snapshotId: 'snapshot-20260724-1',
      archiveJson: archive,
      crypto: crypto,
      createdAt: DateTime.utc(2026, 7, 24),
      chunkSize: 1024,
    );
    final manifest = snapshot.toJson();
    final roundTripped = EncryptedBackupSnapshot.fromJson(manifest);

    expect(roundTripped.chunks.length, greaterThan(1));
    expect(roundTripped.toJson(), manifest);
    expect(
      roundTripped.chunks.every(
        (chunk) => chunk.ciphertext.startsWith(encryptedBackupCiphertextPrefix),
      ),
      isTrue,
    );
    expect(await roundTripped.restoreArchiveJson(crypto), archive);
    expect(
      roundTripped.chunks.any((chunk) => chunk.ciphertext.contains('River')),
      isFalse,
    );
  });

  test('rejects a tampered or incomplete chunk', () async {
    final crypto = testCrypto();
    final snapshot = await EncryptedBackupSnapshot.create(
      snapshotId: 'snapshot-test',
      archiveJson: '{"private":"value"}',
      crypto: crypto,
      chunkSize: 1024,
    );
    final json = snapshot.toJson();
    final chunks = (json['chunks'] as List).cast<Map<String, dynamic>>();
    chunks[0] = {...chunks[0], 'ciphertext': '${chunks[0]['ciphertext']}x'};
    final tampered = EncryptedBackupSnapshot.fromJson(json);

    await expectLater(
      tampered.restoreArchiveJson(crypto),
      throwsA(isA<FormatException>()),
    );
  });
}
