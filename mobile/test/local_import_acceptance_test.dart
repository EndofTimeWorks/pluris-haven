import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/import/import_archive_mapper.dart';
import 'package:pluris_haven/data/import/import_file_decoder.dart';
import 'package:pluris_haven/data/import/import_sources.dart';
import 'package:pluris_haven/data/local/app_database.dart';
import 'package:pluris_haven/data/local/haven_repository.dart';
import 'package:pluris_haven/data/security/archive_encryption.dart';

void main() {
  final exportPath = Platform.environment['PLURIS_SP_EXPORT'];
  final avatarsPath = Platform.environment['PLURIS_SP_AVATARS'];

  test(
    'imports and restores a local Simply Plural export without data loss',
    () async {
      final sourceText = await File(exportPath!).readAsString();
      final source = jsonDecode(sourceText) as Map<String, dynamic>;
      final avatarBundle = decodeImportFileBytes(
        fileName: File(avatarsPath!).uri.pathSegments.last,
        bytes: Uint8List.fromList(await File(avatarsPath).readAsBytes()),
      );
      expect(avatarBundle, isNotNull);

      final normalized = normalizeImportTextToLocalArchive(
        source: ImportSource.simplyPlural,
        fileName: File(exportPath).uri.pathSegments.last,
        text: sourceText,
        avatarAssets: avatarBundle!.avatarAssets,
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
      final repository = LocalHavenRepository(database);
      await repository.ensureLocalSystem();

      await repository.importLocalArchiveJson(
        normalized.archiveJson,
        source: ImportSource.simplyPlural,
        fileName: normalized.fileName,
      );
      final importedSystem = await (database.select(
        database.pluralSystems,
      )..where((system) => system.id.equals(localSystemId))).getSingle();
      expect(importedSystem.colorHex, isNotNull);
      expect(importedSystem.avatarUrl, startsWith('local-avatar:'));
      final importedAvatar = _testAvatarFile(importedSystem.avatarUrl!);
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
      final restoredRepository = LocalHavenRepository(restoredDatabase);
      await restoredRepository.ensureLocalSystem();
      await restoredRepository.importLocalArchiveJson(
        decrypted,
        fileName: 'acceptance-backup.json',
      );
      final restoredSystem = await (restoredDatabase.select(
        restoredDatabase.pluralSystems,
      )..where((system) => system.id.equals(localSystemId))).getSingle();
      expect(restoredSystem.avatarUrl, startsWith('local-avatar:'));
      expect(await _testAvatarFile(restoredSystem.avatarUrl!).exists(), isTrue);
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
