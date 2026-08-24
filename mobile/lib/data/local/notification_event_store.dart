import 'package:drift/drift.dart';

import 'app_database.dart';
import 'local_id.dart';
import 'local_text_codec.dart';

class NotificationEventSummary {
  const NotificationEventSummary({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    this.readAt,
    required this.createdAt,
  });

  final String id;
  final String kind;
  final String title;
  final String body;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isUnread => readAt == null;
}

class NotificationEventDraft {
  const NotificationEventDraft({
    required this.kind,
    required this.title,
    required this.body,
  });

  final String kind;
  final String title;
  final String body;
}

class LocalNotificationEventStore {
  LocalNotificationEventStore(
    this.database, {
    required this.encryptText,
    required this.decryptText,
  });

  final AppDatabase database;
  final EncryptLocalText encryptText;
  final DecryptLocalText decryptText;

  Stream<List<NotificationEventSummary>> watch() {
    final query = database.select(database.notificationEvents)
      ..where((event) => event.systemId.equals(localSystemId))
      ..orderBy([
        (event) =>
            OrderingTerm(expression: event.createdAt, mode: OrderingMode.desc),
      ]);

    return query.watch().asyncMap(
      (rows) async => [
        for (final row in rows)
          NotificationEventSummary(
            id: row.id,
            kind: row.kind,
            title:
                (await decryptText(
                  row.title,
                  'notification_events',
                  row.id,
                  'title',
                )) ??
                '',
            body:
                (await decryptText(
                  row.body,
                  'notification_events',
                  row.id,
                  'body',
                )) ??
                '',
            readAt: row.readAt,
            createdAt: row.createdAt,
          ),
      ],
    );
  }

  Future<void> record(NotificationEventDraft draft) async {
    final title = draft.title.trim();
    final body = draft.body.trim();
    if (title.isEmpty && body.isEmpty) return;

    final now = DateTime.now().toUtc();
    final eventId = newLocalId('notification');
    await database
        .into(database.notificationEvents)
        .insert(
          NotificationEventsCompanion.insert(
            id: eventId,
            systemId: localSystemId,
            kind: draft.kind.trim().isEmpty ? 'general' : draft.kind.trim(),
            title: await encryptText(
              title.isEmpty ? 'Notification' : title,
              'notification_events',
              eventId,
              'title',
            ),
            body: await encryptText(
              body,
              'notification_events',
              eventId,
              'body',
            ),
            createdAt: now,
          ),
        );
  }
}
