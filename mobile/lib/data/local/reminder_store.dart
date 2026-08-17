import 'package:drift/drift.dart';

import 'app_database.dart';
import 'local_text_codec.dart';

class ReminderSummary {
  const ReminderSummary({
    required this.id,
    required this.title,
    this.body,
    required this.scheduleText,
    this.scheduleKind,
    this.scheduleTime,
    this.scheduleDowMask,
    this.scheduleDom,
    this.triggerType,
    this.triggerMemberId,
    this.triggerEvent,
    this.delaySeconds,
    this.lastFiredAt,
    required this.enabled,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String? body;
  final String scheduleText;
  final String? scheduleKind;
  final String? scheduleTime;
  final int? scheduleDowMask;
  final int? scheduleDom;
  final String? triggerType;
  final String? triggerMemberId;
  final String? triggerEvent;
  final int? delaySeconds;
  final DateTime? lastFiredAt;
  final bool enabled;
  final DateTime updatedAt;
}

class ReminderDraft {
  const ReminderDraft({
    required this.title,
    this.body,
    required this.scheduleText,
    this.scheduleKind,
    this.scheduleTime,
    this.scheduleDowMask,
    this.scheduleDom,
    this.triggerType,
    this.triggerMemberId,
    this.triggerEvent,
    this.delaySeconds,
    this.enabled = true,
  });

  final String title;
  final String? body;
  final String scheduleText;
  final String? scheduleKind;
  final String? scheduleTime;
  final int? scheduleDowMask;
  final int? scheduleDom;
  final String? triggerType;
  final String? triggerMemberId;
  final String? triggerEvent;
  final int? delaySeconds;
  final bool enabled;
}

class LocalReminderStore {
  LocalReminderStore(
    this.database, {
    required this.encryptText,
    required this.encryptNullableText,
    required this.decryptText,
  });

  final AppDatabase database;
  final EncryptLocalText encryptText;
  final EncryptNullableLocalText encryptNullableText;
  final DecryptLocalText decryptText;

  Stream<List<ReminderSummary>> watch() {
    final query = database.select(database.reminders)
      ..where((reminder) => reminder.systemId.equals(localSystemId))
      ..orderBy([
        (reminder) => OrderingTerm(
          expression: reminder.updatedAt,
          mode: OrderingMode.desc,
        ),
      ]);
    return query.watch().asyncMap(
      (rows) async => [for (final row in rows) await summary(row)],
    );
  }

  Future<ReminderSummary> summary(Reminder row) async {
    return ReminderSummary(
      id: row.id,
      title: (await decryptText(row.title, 'reminders', row.id, 'title')) ?? '',
      body: await decryptText(row.body, 'reminders', row.id, 'body'),
      scheduleText:
          (await decryptText(
            row.scheduleText,
            'reminders',
            row.id,
            'schedule_text',
          )) ??
          '',
      scheduleKind: await decryptText(
        row.scheduleKind,
        'reminders',
        row.id,
        'schedule_kind',
      ),
      scheduleTime: await decryptText(
        row.scheduleTime,
        'reminders',
        row.id,
        'schedule_time',
      ),
      scheduleDowMask: row.scheduleDowMask,
      scheduleDom: row.scheduleDom,
      triggerType: row.triggerType,
      triggerMemberId: row.triggerMemberId,
      triggerEvent: await decryptText(
        row.triggerEvent,
        'reminders',
        row.id,
        'trigger_event',
      ),
      delaySeconds: row.delaySeconds,
      lastFiredAt: row.lastFiredAt,
      enabled: row.enabled,
      updatedAt: row.updatedAt,
    );
  }

  Future<String?> save(ReminderDraft draft) async {
    final title = draft.title.trim();
    final scheduleText = draft.scheduleText.trim();
    if (title.isEmpty || scheduleText.isEmpty) return null;

    final now = DateTime.now().toUtc();
    final id = 'reminder-${now.microsecondsSinceEpoch}';
    await database
        .into(database.reminders)
        .insert(
          RemindersCompanion.insert(
            id: id,
            systemId: localSystemId,
            title: await encryptText(title, 'reminders', id, 'title'),
            body: Value(
              await encryptNullableText(
                _nullIfBlank(draft.body),
                'reminders',
                id,
                'body',
              ),
            ),
            scheduleText: await encryptText(
              scheduleText,
              'reminders',
              id,
              'schedule_text',
            ),
            scheduleKind: Value(
              await encryptNullableText(
                _nullIfBlank(draft.scheduleKind),
                'reminders',
                id,
                'schedule_kind',
              ),
            ),
            scheduleTime: Value(
              await encryptNullableText(
                _nullIfBlank(draft.scheduleTime),
                'reminders',
                id,
                'schedule_time',
              ),
            ),
            scheduleDowMask: Value(draft.scheduleDowMask),
            scheduleDom: Value(draft.scheduleDom),
            triggerType: Value(_nullIfBlank(draft.triggerType) ?? 'repeated'),
            triggerMemberId: Value(_nullIfBlank(draft.triggerMemberId)),
            triggerEvent: Value(
              await encryptNullableText(
                _nullIfBlank(draft.triggerEvent),
                'reminders',
                id,
                'trigger_event',
              ),
            ),
            delaySeconds: Value(draft.delaySeconds),
            enabled: Value(draft.enabled),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  Future<void> setEnabled(String reminderId, bool enabled) async {
    await (database.update(database.reminders)..where(
          (reminder) =>
              reminder.systemId.equals(localSystemId) &
              reminder.id.equals(reminderId),
        ))
        .write(
          RemindersCompanion(
            enabled: Value(enabled),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
  }

  Future<void> delete(String reminderId) {
    return (database.delete(database.reminders)..where(
          (reminder) =>
              reminder.systemId.equals(localSystemId) &
              reminder.id.equals(reminderId),
        ))
        .go();
  }

  Future<List<ReminderSummary>> claimAfterFront({
    required Set<String> newlyStartedMemberIds,
    required bool frontStarted,
    required DateTime firedAt,
  }) async {
    if (!frontStarted) return const [];

    final rows =
        await (database.select(database.reminders)..where(
              (reminder) =>
                  reminder.systemId.equals(localSystemId) &
                  reminder.enabled.equals(true),
            ))
            .get();
    final claimed = <ReminderSummary>[];
    for (final row in rows) {
      final kind = await decryptText(
        row.scheduleKind,
        'reminders',
        row.id,
        'schedule_kind',
      );
      final event = await decryptText(
        row.triggerEvent,
        'reminders',
        row.id,
        'trigger_event',
      );
      final isAfterFront =
          kind == 'after_front' ||
          (row.triggerType == 'event' && event == 'front_started');
      final targetMatches =
          row.triggerMemberId == null ||
          newlyStartedMemberIds.contains(row.triggerMemberId);
      if (!isAfterFront || !targetMatches) continue;

      await (database.update(
        database.reminders,
      )..where((reminder) => reminder.id.equals(row.id))).write(
        RemindersCompanion(
          lastFiredAt: Value(firedAt),
          updatedAt: Value(firedAt),
        ),
      );
      claimed.add(await summary(row.copyWith(lastFiredAt: Value(firedAt))));
    }
    return claimed;
  }

  String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
