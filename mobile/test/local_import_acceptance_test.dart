import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/import/import_archive_mapper.dart';
import 'package:pluris_haven/data/import/import_file_decoder.dart';
import 'package:pluris_haven/data/import/import_sources.dart';
import 'package:pluris_haven/data/local/app_database.dart';
import 'package:pluris_haven/data/security/archive_encryption.dart';

import 'test_repository.dart';

void main() {
  final exportPath = Platform.environment['PLURIS_SP_EXPORT'];
  final avatarsPath = Platform.environment['PLURIS_SP_AVATARS'];
  final localArchivePath = Platform.environment['PLURIS_HAVEN_ARCHIVE'];

  test(
    'imports and restores a local Simply Plural export without data loss',
    () async {
      final sourceText = await File(exportPath!).readAsString();
      final source = jsonDecode(sourceText) as Map<String, dynamic>;
      final avatarBundle = await decodeImportFileBytes(
        fileName: File(avatarsPath!).uri.pathSegments.last,
        bytes: Uint8List.fromList(await File(avatarsPath).readAsBytes()),
      );
      final normalized = normalizeImportTextToLocalArchive(
        source: ImportSource.simplyPlural,
        fileName: File(exportPath).uri.pathSegments.last,
        text: sourceText,
        avatarAssets: avatarBundle.avatarAssets,
        importedAt: DateTime.utc(2026, 7, 12),
      );
      final normalizedJson = _decodeArchive(normalized.archiveJson);

      expect(
        normalized.counts['members'],
        _collectionLength(source, 'members'),
      );
      expect(normalized.counts['groups'], _collectionLength(source, 'groups'));
      expect(
        normalized.counts['fronts'],
        _collectionLength(source, 'frontHistory'),
      );
      expect(
        normalized.counts['named_fronts'],
        _collectionLength(source, 'frontStatuses'),
      );
      expect(
        normalized.counts['custom_fields'],
        _collectionLength(source, 'customFields'),
      );
      expect(
        normalized.counts['privacy_buckets'],
        _collectionLength(source, 'privacyBuckets'),
      );
      expect(
        normalized.counts['avatar_assets'],
        avatarBundle.avatarAssets.length,
      );

      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = testRepository(database);
      await repository.ensureLocalSystem();

      await repository.importLocalArchiveJson(
        normalized.archiveJson,
        source: ImportSource.simplyPlural,
        fileName: normalized.fileName,
      );
      final importedArchive = _decodeArchive(
        await repository.buildLocalArchiveJson(),
      );
      final importedSystem =
          (importedArchive['system'] as Map<String, dynamic>?)!;
      expect(importedSystem['color_hex'], isNotNull);
      expect(importedSystem['avatar_url'], startsWith('local-avatar:'));
      final importedAvatar = _testAvatarFile(
        importedSystem['avatar_url'] as String,
      );
      expect(await importedAvatar.exists(), isTrue);
      await _expectFrontMemberReferencesValid(database);

      final firstExport = await repository.buildLocalArchiveJson();
      final firstCounts = _archiveCollectionCounts(_decodeArchive(firstExport));
      _expectImportedCounts(firstCounts, normalizedJson);

      await repository.importLocalArchiveJson(
        normalized.archiveJson,
        source: ImportSource.simplyPlural,
        fileName: normalized.fileName,
      );
      final secondExport = await repository.buildLocalArchiveJson();
      expect(
        (_decodeArchive(secondExport)['avatar_assets'] as List),
        isNotEmpty,
      );
      expect(
        _archiveCollectionCounts(_decodeArchive(secondExport)),
        firstCounts,
        reason: 'Re-importing the same external IDs must not duplicate data.',
      );

      final encrypted = await encryptArchiveJson(
        archiveJson: secondExport,
        passphrase: 'local-acceptance-test-passphrase',
        iterations: 1000,
      );
      final decrypted = await decryptArchiveJson(
        encryptedArchiveJson: encrypted,
        passphrase: 'local-acceptance-test-passphrase',
      );
      expect(_archiveCollectionCounts(_decodeArchive(decrypted)), firstCounts);
      await importedAvatar.delete();
      expect(await importedAvatar.exists(), isFalse);

      final rehearsal = await repository.rehearseLocalArchiveRestore(
        decrypted,
        fileName: 'acceptance-backup.json',
      );
      expect(rehearsal.canRestore, isTrue, reason: rehearsal.error);
      for (final entry in rehearsal.counts.entries) {
        if (firstCounts.containsKey(entry.key)) {
          expect(entry.value, firstCounts[entry.key], reason: entry.key);
        }
      }

      final restoredDatabase = AppDatabase(NativeDatabase.memory());
      addTearDown(restoredDatabase.close);
      final restoredRepository = testRepository(restoredDatabase);
      await restoredRepository.ensureLocalSystem();
      await restoredRepository.importLocalArchiveJson(
        decrypted,
        fileName: 'acceptance-backup.json',
      );
      final restoredArchive = _decodeArchive(
        await restoredRepository.buildLocalArchiveJson(),
      );
      final restoredSystem =
          (restoredArchive['system'] as Map<String, dynamic>?)!;
      expect(restoredSystem['avatar_url'], startsWith('local-avatar:'));
      expect(
        await _testAvatarFile(restoredSystem['avatar_url'] as String).exists(),
        isTrue,
      );
      await _expectFrontMemberReferencesValid(restoredDatabase);
      final restoredExport = await restoredRepository.buildLocalArchiveJson();
      expect(
        _archiveCollectionCounts(_decodeArchive(restoredExport)),
        firstCounts,
      );
    },
    skip: exportPath == null || avatarsPath == null
        ? 'Set PLURIS_SP_EXPORT and PLURIS_SP_AVATARS to run this local test.'
        : false,
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'restores and re-exports a user-facing Pluris Haven archive',
    () async {
      final archiveJson = await File(localArchivePath!).readAsString();
      final original = _decodeArchive(archiveJson);
      final originalCounts = _archiveCollectionCounts(original);
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = testRepository(database);
      await repository.ensureLocalSystem();

      final rehearsal = await repository.rehearseLocalArchiveRestore(
        archiveJson,
        fileName: File(localArchivePath).uri.pathSegments.last,
      );
      expect(rehearsal.canRestore, isTrue, reason: rehearsal.error);
      await repository.importLocalArchiveJson(
        archiveJson,
        fileName: File(localArchivePath).uri.pathSegments.last,
      );

      final reExportJson = await repository.buildLocalArchiveJson();
      final reExport = _decodeArchive(reExportJson);
      final reExportCounts = _archiveCollectionCounts(reExport);
      for (final entry in originalCounts.entries) {
        if (entry.key != 'import_records') {
          expect(
            reExportCounts[entry.key],
            rehearsal.counts[entry.key] ?? entry.value,
            reason:
                '${entry.key} should preserve valid rows and omit invalid '
                'foreign-key references identified during restore rehearsal',
          );
        }
      }

      final avatarAssets = (reExport['avatar_assets'] as List)
          .cast<Map<String, dynamic>>();
      final assetIds = avatarAssets.map((asset) => asset['id']).toSet();
      final avatarReferences = <Object?>[
        (reExport['system'] as Map<String, dynamic>?)?['avatar_url'],
        for (final member in (reExport['members'] as List))
          (member as Map<String, dynamic>)['avatar_url'],
        for (final front in (reExport['named_fronts'] as List))
          (front as Map<String, dynamic>)['avatar_url'],
      ].whereType<String>();
      for (final reference in avatarReferences) {
        expect(reference, startsWith('local-avatar:'));
        expect(assetIds, contains(reference.substring('local-avatar:'.length)));
      }
      expect(reExportJson, isNot(contains('content://')));
      expect(reExportJson, isNot(contains('file://')));
      expect(reExportJson, isNot(contains('/data/user/')));
    },
    skip: localArchivePath == null
        ? 'Set PLURIS_HAVEN_ARCHIVE to inspect a saved app export.'
        : false,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

Map<String, dynamic> _decodeArchive(String text) =>
    jsonDecode(text) as Map<String, dynamic>;

int _collectionLength(Map<String, dynamic> source, String key) {
  final value = source[key];
  return value is List ? value.length : 0;
}

Map<String, int> _archiveCollectionCounts(Map<String, dynamic> archive) => {
  for (final entry in archive.entries)
    if (entry.value is List && entry.key != 'import_records')
      entry.key: (entry.value as List).length,
};

void _expectImportedCounts(
  Map<String, int> imported,
  Map<String, dynamic> normalized,
) {
  for (final entry in normalized.entries) {
    final value = entry.value;
    if (value is List &&
        entry.key != 'avatar_assets' &&
        entry.key != 'import_records') {
      expect(imported[entry.key], value.length, reason: entry.key);
    }
  }
}

Future<void> _expectFrontMemberReferencesValid(AppDatabase database) async {
  final members = await database.select(database.members).get();
  final fronts = await database.select(database.frontSessions).get();
  final links = await database.select(database.frontSessionMembers).get();
  final memberIds = members.map((member) => member.id).toSet();
  final frontIds = fronts.map((front) => front.id).toSet();

  expect(links.every((link) => memberIds.contains(link.memberId)), isTrue);
  expect(links.every((link) => frontIds.contains(link.sessionId)), isTrue);
}

File _testAvatarFile(String avatarUrl) {
  final fileName = avatarUrl.substring('local-avatar:'.length);
  return File(
    '${Directory.systemTemp.path}/pluris-haven-test/avatars/$fileName',
  );
}
