import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/notifications/local_time_zone.dart';
import 'package:pluris_haven/data/notifications/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  test(
    'configures the scheduling timezone from the device identifier',
    () async {
      await configureLocalTimeZone(
        readIdentifier: () async => 'America/Phoenix',
      );

      expect(tz.local.name, 'America/Phoenix');
      expect(tz.TZDateTime(tz.local, 2026, 8, 16, 9).hour, 9);
    },
  );

  test(
    'daily and weekly reminders retain their local time across DST',
    () async {
      await configureLocalTimeZone(
        readIdentifier: () async => 'America/New_York',
      );
      final now = tz.TZDateTime(tz.local, 2026, 3, 7, 12);

      final daily = NotificationService.nextDailyDateForTesting(
        now,
        const TimeOfDay(hour: 10, minute: 0),
      );
      final weekly = NotificationService.nextWeeklyDateForTesting(
        now,
        const TimeOfDay(hour: 10, minute: 0),
        DateTime.sunday,
      );

      expect(daily, tz.TZDateTime(tz.local, 2026, 3, 8, 10));
      expect(weekly, tz.TZDateTime(tz.local, 2026, 3, 8, 10));
    },
  );
}
