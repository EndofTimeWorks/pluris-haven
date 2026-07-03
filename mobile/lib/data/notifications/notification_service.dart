import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  FlutterLocalNotificationsPlugin? _plugin;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    _plugin = FlutterLocalNotificationsPlugin();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin!.initialize(settings);
    _initialized = true;
  }

  Future<bool> _requestPermission() async {
    if (_plugin == null) return false;
    final android = _plugin!
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return true;
    final granted = await android.requestNotificationsPermission();
    return granted ?? false;
  }

  int reminderNotificationId(String reminderId) {
    var hash = 0;
    for (final codeUnit in reminderId.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }

  Future<void> scheduleReminderNotification({
    required String reminderId,
    required String title,
    String? body,
    required TimeOfDay time,
    DateTimeComponents repeat = DateTimeComponents.time,
    int? weekday,
    int? monthDay,
  }) async {
    if (_plugin == null) return;
    await _requestPermission();

    final id = reminderNotificationId(reminderId);
    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = switch (repeat) {
      DateTimeComponents.dayOfWeekAndTime => _nextWeeklyDate(
        now,
        time,
        weekday ?? now.weekday,
      ),
      DateTimeComponents.dayOfMonthAndTime => _nextMonthlyDate(
        now,
        time,
        monthDay ?? now.day,
      ),
      _ => _nextDailyDate(now, time),
    };

    const androidDetails = AndroidNotificationDetails(
      'reminders',
      'Reminders',
      channelDescription: 'Front check-in and custom reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin!.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: repeat,
    );
  }

  Future<void> cancelReminderNotification(String reminderId) {
    return cancelNotification(reminderNotificationId(reminderId));
  }

  Future<void> cancelNotification(int id) async {
    await _plugin?.cancel(id);
  }

  Future<void> cancelAll() async {
    await _plugin?.cancelAll();
  }

  tz.TZDateTime _nextDailyDate(tz.TZDateTime now, TimeOfDay time) {
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (!scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  tz.TZDateTime _nextWeeklyDate(
    tz.TZDateTime now,
    TimeOfDay time,
    int weekday,
  ) {
    final safeWeekday = weekday.clamp(DateTime.monday, DateTime.sunday);
    var daysUntil = safeWeekday - now.weekday;
    if (daysUntil < 0) {
      daysUntil += DateTime.daysPerWeek;
    }
    var candidate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    ).add(Duration(days: daysUntil));
    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: DateTime.daysPerWeek));
    }
    return candidate;
  }

  tz.TZDateTime _nextMonthlyDate(
    tz.TZDateTime now,
    TimeOfDay time,
    int monthDay,
  ) {
    tz.TZDateTime candidateFor(int year, int month) {
      final day = monthDay.clamp(1, _daysInMonth(year, month));
      return tz.TZDateTime(tz.local, year, month, day, time.hour, time.minute);
    }

    var candidate = candidateFor(now.year, now.month);
    if (!candidate.isAfter(now)) {
      final nextMonth = now.month == DateTime.december ? 1 : now.month + 1;
      final nextYear = now.month == DateTime.december ? now.year + 1 : now.year;
      candidate = candidateFor(nextYear, nextMonth);
    }
    return candidate;
  }

  int _daysInMonth(int year, int month) {
    final nextMonth = month == DateTime.december ? 1 : month + 1;
    final nextYear = month == DateTime.december ? year + 1 : year;
    return DateTime(nextYear, nextMonth, 0).day;
  }
}
