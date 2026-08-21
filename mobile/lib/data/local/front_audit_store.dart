import 'package:drift/drift.dart';

import 'app_database.dart';
import 'local_text_codec.dart';

class LocalFrontAuditStore {
  LocalFrontAuditStore(this.database, {required this.decryptText});

  final AppDatabase database;
  final DecryptLocalText decryptText;

  Stream<List<FrontAuditEvent>> watch(String frontSessionId) {
    final query = database.select(database.frontAuditEvents)
      ..where((event) => event.frontId.equals(frontSessionId))
      ..orderBy([
        (event) =>
            OrderingTerm(expression: event.createdAt, mode: OrderingMode.desc),
      ]);
    return query.watch().asyncMap(
      (rows) async => [
        for (final row in rows)
          row.copyWith(
            beforeSnapshot: Value(
              await decryptText(
                row.beforeSnapshot,
                'front_audit_events',
                row.id,
                'before_snapshot',
              ),
            ),
            afterSnapshot: Value(
              await decryptText(
                row.afterSnapshot,
                'front_audit_events',
                row.id,
                'after_snapshot',
              ),
            ),
          ),
      ],
    );
  }
}
