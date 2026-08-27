import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../data/local/app_database.dart';
import '../data/local/haven_repository.dart';
import '../data/security/master_key_store.dart';

const importArchiveTaskName = 'pluris_haven.import_archive';
const iosImportArchiveTaskIdentifier =
    'works.endoftime.plurishaven.import_archive';
const syncTaskName = 'pluris_haven.sync';

const _controlChannel = MethodChannel(
  'works.endoftime.plurishaven/background_tasks',
);
const _workerChannel = MethodChannel(
  'works.endoftime.plurishaven/background_tasks/worker',
);

@pragma('vm:entry-point')
void plurisHavenBackgroundDispatcher() {
  WidgetsFlutterBinding.ensureInitialized();
  _workerChannel.setMethodCallHandler((call) async {
    if (call.method != 'runTask') return false;
    final arguments = call.arguments;
    final values = arguments is Map
        ? Map<String, Object?>.from(arguments)
        : const <String, Object?>{};
    final task = values['task'] as String?;
    final input = values['inputData'];
    final inputData = input is Map
        ? Map<String, Object?>.from(input)
        : const <String, Object?>{};
    return _runBackgroundTask(task, inputData);
  });
  _workerChannel.invokeMethod<void>('backgroundReady');
}

Future<bool> _runBackgroundTask(
  String? task,
  Map<String, Object?> inputData,
) async {
  final database = AppDatabase();
  final crypto = await HavenMasterKeyStore().loadOrCreateCrypto();
  final repository = LocalHavenRepository(database, crypto: crypto);
  try {
    await repository.ensureLocalSystem();
    await repository.migrateUnauthenticatedEmptyCiphertexts();
    await repository.migrateMemberNamesToEncryption();
    await repository.migrateBlindIndexesToUnicodeNormalization();
    switch (task) {
      case importArchiveTaskName:
        final jobId = inputData['job_id'] as String?;
        if (jobId == null || jobId.isEmpty) return false;
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
}

Future<void> initializeBackgroundTasks() async {
  if (!Platform.isAndroid && !Platform.isIOS) return;
  final callback = PluginUtilities.getCallbackHandle(
    plurisHavenBackgroundDispatcher,
  );
  if (callback == null) {
    throw StateError('Could not resolve the background dispatcher.');
  }
  await _controlChannel.invokeMethod<void>('initialize', {
    'callbackHandle': callback.toRawHandle(),
  });
}

Future<void> scheduleImportArchiveJob(String jobId) async {
  if (!Platform.isAndroid && !Platform.isIOS) return;
  await _controlChannel.invokeMethod<void>('scheduleImport', {
    'job_id': jobId,
    'task': Platform.isIOS
        ? iosImportArchiveTaskIdentifier
        : importArchiveTaskName,
  });
}
