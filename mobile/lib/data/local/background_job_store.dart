part of 'haven_repository.dart';

extension LocalHavenRepositoryBackgroundJobs on LocalHavenRepository {
  Stream<List<BackgroundJobSummary>> _backgroundWatchJobs() {
    final query = database.select(database.backgroundJobs)
      ..where((job) => job.systemId.equals(localSystemId))
      ..orderBy([
        (job) =>
            OrderingTerm(expression: job.createdAt, mode: OrderingMode.desc),
      ])
      ..limit(8);

    return query.watch().asyncMap(
      (rows) async => [
        for (final row in rows) await _backgroundJobSummary(row),
      ],
    );
  }

  Stream<List<RetainedImportPayloadSummary>>
  _backgroundWatchRetainedImportPayloads() {
    return database
        .customSelect(
          '''
SELECT
  import_record_id,
  source,
  imported_at,
  COUNT(*) AS payload_count,
  GROUP_CONCAT(collection, char(31)) AS collections
FROM import_payloads
WHERE system_id = ?
GROUP BY import_record_id, source, imported_at
ORDER BY imported_at DESC
''',
          variables: [Variable(localSystemId)],
          readsFrom: {database.importPayloads},
        )
        .watch()
        .map(
          (rows) => [
            for (final row in rows)
              RetainedImportPayloadSummary(
                importRecordId: row.read<String>('import_record_id'),
                source: row.read<String>('source'),
                collections:
                    row
                        .read<String>('collections')
                        .split(String.fromCharCode(31))
                      ..sort(),
                payloadCount: row.read<int>('payload_count'),
                importedAt: row.read<DateTime>('imported_at'),
              ),
          ],
        );
  }

  Future<void> _backgroundDeleteRetainedImportPayloads(String importRecordId) {
    return (database.delete(database.importPayloads)..where(
          (payload) =>
              payload.systemId.equals(localSystemId) &
              payload.importRecordId.equals(importRecordId),
        ))
        .go();
  }

  Future<BackgroundJobSummary> _backgroundJobSummary(BackgroundJob row) async {
    return BackgroundJobSummary(
      id: row.id,
      type: row.type,
      status: row.status,
      source: row.source,
      fileName: await _decryptLocalText(
        row.fileName,
        'background_jobs',
        row.id,
        'file_name',
      ),
      error: await _decryptLocalText(
        row.error,
        'background_jobs',
        row.id,
        'error',
      ),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
