import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

QueryExecutor openDatabaseConnection() {
  return LazyDatabase(() async {
    final supportDirectory = await getApplicationSupportDirectory();
    final temporaryDirectory = await getTemporaryDirectory();
    sqlite3.tempDirectory = temporaryDirectory.path;

    // Keep the path used by drift_flutter so existing installs retain data.
    final databaseFile = File(
      p.join(supportDirectory.path, 'pluris_haven.sqlite'),
    );
    return NativeDatabase.createInBackground(databaseFile);
  });
}
