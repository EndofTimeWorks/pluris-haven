import 'package:drift/drift.dart';
import 'package:drift/native.dart';

Future<QueryExecutor> openRehearsalDatabaseConnection() async {
  return NativeDatabase.memory();
}
