import 'dart:convert';

import 'package:cryptography/cryptography.dart';
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

    final missingChunkJson = snapshot.toJson();
    missingChunkJson['chunks'] = <Map<String, dynamic>>[];
    expect(
      () => EncryptedBackupSnapshot.fromJson(missingChunkJson),
      throwsA(isA<FormatException>()),
    );
  });

  test('authenticates manifest identity and chunk position', () async {
    final crypto = testCrypto();
    final snapshot = await EncryptedBackupSnapshot.create(
      snapshotId: 'snapshot-original',
      archiveJson: jsonEncode({'payload': List.filled(2000, 'private')}),
      crypto: crypto,
      createdAt: DateTime.utc(2026, 7, 24),
      chunkSize: 1024,
    );

    final renamedJson = snapshot.toJson()..['snapshot_id'] = 'snapshot-renamed';
    final renamed = EncryptedBackupSnapshot.fromJson(renamedJson);
    await expectLater(
      renamed.restoreArchiveJson(crypto),
      throwsA(isA<FormatException>()),
    );

    final reorderedJson = snapshot.toJson();
    final chunks = (reorderedJson['chunks'] as List)
        .cast<Map<String, dynamic>>();
    chunks[0] = {...chunks[0], 'index': 1};
    chunks[1] = {...chunks[1], 'index': 0};
    final reordered = EncryptedBackupSnapshot.fromJson(reorderedJson);
    await expectLater(
      reordered.restoreArchiveJson(crypto),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects manifests outside resource limits', () {
    final oversizedChunkSize = <String, dynamic>{
      'format': encryptedBackupFormat,
      'version': encryptedBackupVersion,
      'snapshot_id': 'snapshot-test',
      'created_at': DateTime.utc(2026, 7, 24).toIso8601String(),
      'chunk_size': maxEncryptedBackupChunkSize + 1,
      'chunk_count': 1,
      'chunks': <Map<String, dynamic>>[],
    };
    expect(
      () => EncryptedBackupSnapshot.fromJson(oversizedChunkSize),
      throwsA(isA<FormatException>()),
    );

    final oversizedChunkCount = <String, dynamic>{
      'format': encryptedBackupFormat,
      'version': encryptedBackupVersion,
      'snapshot_id': 'snapshot-test',
      'created_at': DateTime.utc(2026, 7, 24).toIso8601String(),
      'chunk_size': defaultEncryptedBackupChunkSize,
      'chunk_count': maxEncryptedBackupChunkCount + 1,
      'chunks': List<Map<String, dynamic>>.filled(
        maxEncryptedBackupChunkCount + 1,
        <String, dynamic>{},
      ),
    };
    expect(
      () => EncryptedBackupSnapshot.fromJson(oversizedChunkCount),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects malformed chunk metadata before restore', () async {
    final snapshot = await EncryptedBackupSnapshot.create(
      snapshotId: 'snapshot-test',
      archiveJson: '{"private":"value"}',
      crypto: testCrypto(),
      chunkSize: 1024,
    );
    final json = snapshot.toJson();
    final chunks = (json['chunks'] as List).cast<Map<String, dynamic>>();
    chunks[0] = {...chunks[0], 'sha256': 'not-a-sha256'};

    expect(
      () => EncryptedBackupSnapshot.fromJson(json),
      throwsA(isA<FormatException>()),
    );
  });

  test('requires explicit trusted-source recovery for legacy v1', () async {
    final crypto = testCrypto();
    const archive = '{"legacy":"private"}';
    final encrypted = await crypto.encrypt(
      base64Url.encode(utf8.encode(archive)),
    );
    final ciphertext = 'ph1:$encrypted';
    final digest = await Sha256().hash(utf8.encode(ciphertext));
    final snapshot = EncryptedBackupSnapshot(
      version: 1,
      snapshotId: 'legacy-snapshot',
      createdAt: DateTime.utc(2026, 7, 24),
      chunkSize: 1024,
      chunks: [
        EncryptedBackupChunk(
          index: 0,
          ciphertext: ciphertext,
          sha256: digest.bytes
              .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
              .join(),
        ),
      ],
    );

    await expectLater(
      snapshot.restoreArchiveJson(crypto),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('trusted-source recovery'),
        ),
      ),
    );
    expect(
      await snapshot.restoreArchiveJson(
        crypto,
        allowUnauthenticatedLegacyV1: true,
      ),
      archive,
    );
  });
}
