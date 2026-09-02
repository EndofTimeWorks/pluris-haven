import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'local_time_zone.dart';

class NotificationCopy {
  const NotificationCopy({
    required this.appName,
    required this.privateReminderTitle,
    required this.privateBody,
    required this.currentlyFrontingTitle,
    required this.remindersChannelName,
    required this.remindersChannelDescription,
    required this.frontStatusChannelName,
    required this.frontStatusChannelDescription,
  });

  final String appName;
  final String privateReminderTitle;
  final String privateBody;
  final String currentlyFrontingTitle;
  final String remindersChannelName;
  final String remindersChannelDescription;
  final String frontStatusChannelName;
  final String frontStatusChannelDescription;
}

class NotificationService {
  NotificationService._([
    this._permissionChecker,
    this._permissionRequester,
    this._triggeredReminderDelivery,
  ]);
  static final NotificationService instance = NotificationService._();
  static const frontStatusNotificationId = 1001;

  @visibleForTesting
  factory NotificationService.forTesting({
    required Future<bool> Function() permissionChecker,
    required Future<bool> Function() permissionRequester,
    Future<bool> Function()? triggeredReminderDelivery,
  }) {
    return NotificationService._(
      permissionChecker,
      permissionRequester,
      triggeredReminderDelivery,
    );
  }

  FlutterLocalNotificationsPlugin? _plugin;
  final Future<bool> Function()? _permissionChecker;
  final Future<bool> Function()? _permissionRequester;
  final Future<bool> Function()? _triggeredReminderDelivery;
  bool _initialized = false;
  bool _setupFailed = false;

  bool get setupFailed => _setupFailed;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await configureLocalTimeZone();

      final plugin = FlutterLocalNotificationsPlugin();
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const settings = InitializationSettings(android: android, iOS: ios);
      await plugin.initialize(settings: settings);
      _plugin = plugin;
      _initialized = true;
      _setupFailed = false;
    } on Object {
      _plugin = null;
      _setupFailed = true;
      rethrow;
    }
  }

  Future<bool> _requestPermission() async {
    if (_plugin == null) return false;
    final ios = _plugin!
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: false,
        sound: true,
      );
      return granted ?? false;
    }
    final android = _plugin!
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return true;
    final granted = await android.requestNotificationsPermission();
    return granted ?? false;
  }

  /// Requests permission only from an explicit notification-delivery action.
  Future<bool> requestPermission() =>
      _permissionRequester?.call() ?? _requestPermission();

  Future<bool> notificationsPermitted() async {
    final permissionChecker = _permissionChecker;
    if (permissionChecker != null) return permissionChecker();
    if (_plugin == null) return false;
    final ios = _plugin!
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) return (await ios.checkPermissions())?.isEnabled ?? false;
    final android = _plugin!
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return android == null ||
        (await android.areNotificationsEnabled() ?? false);
  }

  int reminderNotificationId(String reminderId) {
    var hash = 0;
    for (final codeUnit in reminderId.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }

  Future<bool> scheduleReminderNotification({
    required String reminderId,
    required String title,
    String? body,
    required TimeOfDay time,
    DateTimeComponents repeat = DateTimeComponents.time,
    int? weekday,
    int? monthDay,
    required NotificationCopy copy,
  }) async {
    if (!await notificationsPermitted() || _plugin == null) return false;

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

    final androidDetails = AndroidNotificationDetails(
      'reminders',
      copy.remindersChannelName,
      channelDescription: copy.remindersChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      visibility: NotificationVisibility.secret,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );
    final hideAppleContent = defaultTargetPlatform == TargetPlatform.iOS;

    await _plugin!.zonedSchedule(
      id: id,
      title: hideAppleContent ? copy.privateReminderTitle : title,
      body: hideAppleContent ? null : body,
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: repeat,
    );
    return true;
  }

  Future<void> cancelReminderNotification(String reminderId) {
    return cancelNotification(reminderNotificationId(reminderId));
  }

  Future<bool> showTriggeredReminderNotification({
    required String reminderId,
    required String title,
    String? body,
    Duration delay = Duration.zero,
    required NotificationCopy copy,
  }) async {
    if (!await notificationsPermitted()) return false;
    final triggeredReminderDelivery = _triggeredReminderDelivery;
    if (triggeredReminderDelivery != null) return triggeredReminderDelivery();
    if (_plugin == null) return false;

    final androidDetails = AndroidNotificationDetails(
      'reminders',
      copy.remindersChannelName,
      channelDescription: copy.remindersChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      visibility: NotificationVisibility.secret,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );
    final hideAppleContent = defaultTargetPlatform == TargetPlatform.iOS;
    final notificationTitle = hideAppleContent
        ? copy.privateReminderTitle
        : title;
    final notificationBody = hideAppleContent ? null : body;
    final id = reminderNotificationId(reminderId);

    if (delay <= Duration.zero) {
      await _plugin!.show(
        id: id,
        title: notificationTitle,
        body: notificationBody,
        notificationDetails: details,
      );
      return true;
    }

    await _plugin!.zonedSchedule(
      id: id,
      title: notificationTitle,
      body: notificationBody,
      scheduledDate: tz.TZDateTime.now(tz.local).add(delay),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
    return true;
  }

  Future<bool> showFrontStatusNotification({
    required String? frontLabel,
    required NotificationCopy copy,
    bool showOnLockScreen = false,
    bool revealMemberName = false,
  }) async {
    if (_plugin == null) return false;
    final label = frontLabel?.trim();
    if (label == null || label.isEmpty) {
      await cancelFrontStatusNotification();
      return false;
    }
    if (!await notificationsPermitted()) return false;

    final androidDetails = AndroidNotificationDetails(
      'front_status',
      copy.frontStatusChannelName,
      channelDescription: copy.frontStatusChannelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      showWhen: false,
      silent: true,
      category: AndroidNotificationCategory.status,
      visibility: showOnLockScreen
          ? NotificationVisibility.public
          : NotificationVisibility.secret,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
      ),
    );

    // iOS has no persistent-notification affordance equivalent to Android's
    // status-bar icon, so it always uses the generic copy regardless of
    // revealMemberName.
    final hideContent =
        defaultTargetPlatform == TargetPlatform.iOS || !revealMemberName;
    await _plugin!.show(
      id: frontStatusNotificationId,
      title: hideContent ? copy.appName : copy.currentlyFrontingTitle,
      body: hideContent ? copy.privateBody : label,
      notificationDetails: details,
    );
    return true;
  }

  Future<void> cancelFrontStatusNotification() {
    return cancelNotification(frontStatusNotificationId);
  }

  Future<void> cancelNotification(int id) async {
    await _plugin?.cancel(id: id);
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
