import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/notifications/local_time_zone.dart';
import 'package:pluris_haven/data/notifications/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;

const _copy = NotificationCopy(
  appName: 'Pluris Haven',
  privateReminderTitle: 'Reminder',
  privateBody: 'Private reminder',
  currentlyFrontingTitle: 'Currently fronting',
  remindersChannelName: 'Reminders',
  remindersChannelDescription: 'Local reminders',
  frontStatusChannelName: 'Fronting',
  frontStatusChannelDescription: 'Current front',
);

void main() {
  test('weekly reminder schedules each selected day with stable IDs', () async {
    await configureLocalTimeZone(readIdentifier: () async => 'America/Phoenix');
    final scheduled = <int, tz.TZDateTime>{};
    final cancelled = <int>[];
    final service = NotificationService.forTesting(
      permissionChecker: () async => true,
      permissionRequester: () async => true,
      scheduledNotificationForTesting: (id, date) async {
        scheduled[id] = date;
      },
      cancelNotificationForTesting: (id) async {
        cancelled.add(id);
        scheduled.remove(id);
      },
    );
    final mondayId = service.weeklyReminderNotificationId(
      'meds',
      DateTime.monday,
    );
    final fridayId = service.weeklyReminderNotificationId(
      'meds',
      DateTime.friday,
    );

    Future<void> schedule(int mask) => service
        .scheduleReminderNotification(
          reminderId: 'meds',
          title: 'Medication',
          time: const TimeOfDay(hour: 8, minute: 30),
          repeat: DateTimeComponents.dayOfWeekAndTime,
          weekdaysMask: mask,
          copy: _copy,
        )
        .then((result) => expect(result, isTrue));

    await schedule((1 << 0) | (1 << 4));
    expect(scheduled.keys, containsAll([mondayId, fridayId]));
    expect(scheduled, hasLength(2));
    expect(
      scheduled.values.every((date) => date.hour == 8 && date.minute == 30),
      isTrue,
    );

    await schedule((1 << 0) | (1 << 4));
    expect(scheduled.keys, containsAll([mondayId, fridayId]));
    expect(scheduled, hasLength(2));

    await schedule(1 << 4);
    expect(scheduled.keys, [fridayId]);
    expect(cancelled, contains(mondayId));

    await service.cancelReminderNotification('meds');
    expect(scheduled, isEmpty);
    expect(cancelled, contains(fridayId));
  });

  test(
    'denied permission does not leave obsolete weekly notifications',
    () async {
      final cancelled = <int>[];
      final service = NotificationService.forTesting(
        permissionChecker: () async => false,
        permissionRequester: () async => false,
        cancelNotificationForTesting: (id) async => cancelled.add(id),
      );

      expect(
        await service.scheduleReminderNotification(
          reminderId: 'meds',
          title: 'Medication',
          time: const TimeOfDay(hour: 8, minute: 30),
          repeat: DateTimeComponents.dayOfWeekAndTime,
          weekdaysMask: 1 << 0,
          copy: _copy,
        ),
        isFalse,
      );
      expect(
        cancelled,
        contains(service.weeklyReminderNotificationId('meds', DateTime.monday)),
      );
    },
  );
}
