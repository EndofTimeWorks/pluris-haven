import 'dart:io';

import 'package:workmanager/workmanager.dart';

import '../data/local/app_database.dart';
import '../data/local/haven_repository.dart';
import '../data/security/master_key_store.dart';

const importArchiveTaskName = 'pluris_haven.import_archive';
const iosImportArchiveTaskIdentifier =
    'works.endoftime.plurishaven.import_archive';
const syncTaskName = 'pluris_haven.sync';

@pragma('vm:entry-point')
void plurisHavenBackgroundDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final database = AppDatabase();
    final crypto = await HavenMasterKeyStore().loadOrCreateCrypto();
    final repository = LocalHavenRepository(database, crypto: crypto);
    try {
      await repository.ensureLocalSystem();
      switch (task) {
        case importArchiveTaskName:
          final jobId = inputData?['job_id'] as String?;
          if (jobId == null || jobId.isEmpty) {
            return false;
          }
          return repository.runBackgroundJob(jobId);
        case iosImportArchiveTaskIdentifier:
          return repository.runQueuedImportJobs();
        case syncTaskName:
          return true;
        default:
          return false;
      }
    } finally {
      await database.close();
    }
  });
}

Future<void> initializeBackgroundTasks() {
  return Workmanager().initialize(plurisHavenBackgroundDispatcher);
}

Future<void> scheduleImportArchiveJob(String jobId) {
  if (Platform.isIOS) {
    return Workmanager().registerProcessingTask(
      iosImportArchiveTaskIdentifier,
      importArchiveTaskName,
      inputData: {'job_id': jobId},
      constraints: Constraints(networkType: NetworkType.notRequired),
    );
  }

  return Workmanager().registerOneOffTask(
    'import-$jobId',
    importArchiveTaskName,
    inputData: {'job_id': jobId},
    constraints: Constraints(
      networkType: NetworkType.notRequired,
      requiresStorageNotLow: true,
    ),
    existingWorkPolicy: ExistingWorkPolicy.replace,
    backoffPolicy: BackoffPolicy.exponential,
    backoffPolicyDelay: const Duration(minutes: 1),
    tag: 'imports',
  );
}
