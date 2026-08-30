import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/import/import_archive_mapper.dart';
import 'package:pluris_haven/data/import/import_file_decoder.dart';
import 'package:pluris_haven/data/import/import_sources.dart';
import 'package:pluris_haven/data/local/app_database.dart';

import '../tool/generate_stress_import_fixture.dart';
import 'test_repository.dart';

void main() {
  test('generates a complete Simply Plural stress import fixture', () async {
    final fixture = buildStressImportFixture(65);
    final source = jsonDecode(fixture.exportJson) as Map<String, Object?>;
    final decodedAvatars = await decodeImportFileBytes(
      fileName: 'stress-avatars.zip',
      bytes: fixture.avatarZip,
    );
    final normalized = normalizeImportTextToLocalArchive(
      source: ImportSource.simplyPlural,
      fileName: 'stress.json',
      text: fixture.exportJson,
      avatarAssets: decodedAvatars.avatarAssets,
      importedAt: DateTime.utc(2026),
    );

    expect((source['members'] as List<Object?>), hasLength(65));
    expect(decodedAvatars.avatarAssets, hasLength(18));
    expect(normalized.warnings, isEmpty);
    expect(normalized.counts, containsPair('members', 65));
    expect(normalized.counts, containsPair('custom_field_values', 520));
    expect(normalized.counts, containsPair('fronts', 195));
    expect(normalized.counts, containsPair('avatar_assets', 18));
    expect(normalized.counts, containsPair('journals', 13));
    expect(normalized.counts, containsPair('polls', 1));
  });

  test('imports a large fixture through encrypted local storage', () async {
    final fixture = buildStressImportFixture(250);
    final decodedAvatars = await decodeImportFileBytes(
      fileName: 'stress-avatars.zip',
      bytes: fixture.avatarZip,
    );
    final normalized = normalizeImportTextToLocalArchive(
      source: ImportSource.simplyPlural,
      fileName: 'stress.json',
      text: fixture.exportJson,
      avatarAssets: decodedAvatars.avatarAssets,
      importedAt: DateTime.utc(2026),
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

    expect(
      await repository
          .watchMembers(includeArchived: true, listOnly: true)
          .first,
      hasLength(250),
    );
    expect(await repository.watchCustomFieldValues().first, hasLength(2000));
    expect(await repository.watchFrontHistory().first, hasLength(750));
    expect(await repository.watchNamedFronts().first, hasLength(6));
  });
}
