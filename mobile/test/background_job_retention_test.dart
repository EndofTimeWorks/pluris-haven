import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/import/import_sources.dart';
import 'package:pluris_haven/data/local/app_database.dart';
import 'package:pluris_haven/data/local/haven_repository.dart';
import 'package:pluris_haven/data/local/local_migrations.dart';

import 'test_repository.dart';

void main() {
  test('completed import job no longer retains its complete source', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = testRepository(database);
    await repository.ensureLocalSystem();
    await repository.saveNote(
      const NoteDraft(title: 'Private', body: 'unique source marker'),
    );
    final archive = await repository.buildLocalArchiveJson();
    final jobId = await repository.enqueueImportArchiveJob(
      archive,
      strategy: ImportConflictStrategy.skip,
      source: ImportSource.plurisHavenArchive,
    );

    final queued = await database.select(database.backgroundJobs).getSingle();
    final aad =
        'pluris-haven:local-text:v2\u0000background_jobs\u0000$jobId\u0000payload_json';
    final queuedText = await testCrypto().decrypt(
      queued.payloadJson.substring('ph2:'.length),
      aad: aad,
    );
    expect(queuedText, contains('unique source marker'));

    expect(await repository.runQueuedImportJobs(), isTrue);
    final completed = await database
        .select(database.backgroundJobs)
        .getSingle();
    expect(completed.status, 'done');
    final completedText = await testCrypto().decrypt(
      completed.payloadJson.substring('ph2:'.length),
      aad: aad,
    );
    expect(completedText, isNot(contains('unique source marker')));
    expect(await repository.watchNotes().first, hasLength(1));
  });

  test('startup clears older completed jobs without losing queued work', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = testRepository(database);
    await repository.ensureLocalSystem();
    await repository.saveNote(
      const NoteDraft(title: 'Private', body: 'legacy source marker'),
    );
    final archive = await repository.buildLocalArchiveJson();
    final oldJobId = await repository.enqueueImportArchiveJob(
      archive,
      strategy: ImportConflictStrategy.skip,
      source: ImportSource.plurisHavenArchive,
    );
    final queuedJobId = await repository.enqueueImportArchiveJob(
      archive,
      strategy: ImportConflictStrategy.skip,
      source: ImportSource.plurisHavenArchive,
    );
    await (database.update(database.backgroundJobs)
          ..where((job) => job.id.equals(oldJobId)))
        .write(const BackgroundJobsCompanion(status: Value('done')));

    final before = await database.select(database.backgroundJobs).get();
    final oldBefore = before.singleWhere((job) => job.id == oldJobId);
    final queuedBefore = before.singleWhere((job) => job.id == queuedJobId);
    await runLocalMigrations(repository);
    final after = await database.select(database.backgroundJobs).get();
    final oldAfter = after.singleWhere((job) => job.id == oldJobId);
    final queuedAfter = after.singleWhere((job) => job.id == queuedJobId);
    expect(oldAfter.payloadJson, isNot(oldBefore.payloadJson));
    expect(
      await testCrypto().decrypt(
        oldAfter.payloadJson.substring('ph2:'.length),
        aad:
            'pluris-haven:local-text:v2\u0000background_jobs\u0000$oldJobId\u0000payload_json',
      ),
      '{}',
    );
    expect(queuedAfter.payloadJson, queuedBefore.payloadJson);
    expect(queuedAfter.status, 'queued');
    expect(await repository.runQueuedImportJobs(), isTrue);
  });
}
