import 'encrypted_backup_snapshot.dart';
import '../local/haven_repository.dart';

/// Adds device-key encrypted snapshot creation to the live local repository.
///
/// The transaction holds Drift's local write boundary while the archive is
/// read. The returned chunks contain ciphertext only and can be handed to the
/// optional backup transport without exposing the device master key.
extension LocalHavenRepositoryBackup on LocalHavenRepository {
  Future<EncryptedBackupSnapshot> buildEncryptedBackupSnapshot({
    required String snapshotId,
    DateTime? createdAt,
    int chunkSize = defaultEncryptedBackupChunkSize,
  }) {
    return database.transaction(() async {
      final archiveJson = await buildLocalArchiveJson();
      return EncryptedBackupSnapshot.create(
        snapshotId: snapshotId,
        archiveJson: archiveJson,
        crypto: crypto,
        createdAt: createdAt,
        chunkSize: chunkSize,
      );
    });
  }
}
