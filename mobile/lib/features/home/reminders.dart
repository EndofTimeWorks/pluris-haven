part of 'home_page.dart';

NotificationCopy _notificationCopy(AppLocalizations l10n) {
  return NotificationCopy(
    appName: l10n.plurisHavenAppName,
    privateReminderTitle: l10n.privateReminderNotificationTitle,
    privateBody: l10n.privateNotificationBody,
    currentlyFrontingTitle: l10n.currentlyFrontingNotificationTitle,
    remindersChannelName: l10n.remindersChannelName,
    remindersChannelDescription: l10n.remindersChannelDescription,
    frontStatusChannelName: l10n.frontStatusChannelName,
    frontStatusChannelDescription: l10n.frontStatusChannelDescription,
  );
}

class RemindersPage extends StatefulWidget {
  RemindersPage({
    super.key,
    required this.repository,
    required this.onNotificationSettings,
    NotificationService? notificationService,
  }) : notificationService =
           notificationService ?? NotificationService.instance;

  final HavenRepository repository;
  final VoidCallback onNotificationSettings;
  final NotificationService notificationService;

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReminderSummary>>(
      stream: widget.repository.watchReminders(),
      builder: (context, snapshot) {
        if (snapshot.hasError && !snapshot.hasData) {
          return SpPage(
            children: [
              SpDataLoadState(
                error: snapshot.error,
                onRetry: () => setState(() {}),
              ),
            ],
          );
        }
        if (!snapshot.hasData) {
          return const SpPage(children: [SpDataLoadState()]);
        }
        final reminders = snapshot.data!;
        final l10n = AppLocalizations.of(context);

        return SpPage(
          children: [
            if (widget.notificationService.setupFailed) ...[
              SpCard(
                child: SpEmptyState(
                  title: l10n.notificationsUnavailableTitle,
                  body: l10n.notificationsUnavailableBody,
                ),
              ),
              const SizedBox(height: 12),
            ],
            SpCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SpSectionHeader(
                    title: l10n.remindersTitle,
                    trailing: StatusPill(text: '${reminders.length}'),
                  ),
                  const SizedBox(height: 12),
                  if (reminders.isEmpty)
                    SpEmptyState(
                      title: l10n.noRemindersYetTitle,
                      body: l10n.noRemindersYetBody,
                    )
                  else
                    for (final reminder in reminders) ...[
                      ReminderTile(
                        reminder: reminder,
                        repository: widget.repository,
                        notificationService: widget.notificationService,
                      ),
                      if (reminder != reminders.last) const Divider(height: 1),
                    ],
                  const SizedBox(height: 14),
                  SpActionRow(
                    primary: l10n.addReminderButton,
                    secondary: l10n.notificationSettingsButton,
                    onPrimary: () => showAddReminderSheet(
                      context,
                      widget.repository,
                      notificationService: widget.notificationService,
                    ),
                    onSecondary: widget.onNotificationSettings,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class ReminderTile extends StatelessWidget {
  const ReminderTile({
    super.key,
    required this.reminder,
    required this.repository,
    required this.notificationService,
  });

  final ReminderSummary reminder;
  final HavenRepository repository;
  final NotificationService notificationService;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            reminder.enabled
                ? Icons.notifications_active_rounded
                : Icons.notifications_off_rounded,
            color: scheme.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  reminder.scheduleText,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                if (reminder.body?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  Text(reminder.body!, style: const TextStyle(height: 1.35)),
                ],
              ],
            ),
          ),
          Column(
            children: [
              StatusPill(
                text: reminder.enabled ? l10n.onStatus : l10n.offValue,
              ),
              Semantics(
                label:
                    '${l10n.reminderSemanticLabel(reminder.title)}, ${reminder.scheduleText}',
                toggled: reminder.enabled,
                child: Switch(
                  value: reminder.enabled,
                  onChanged: (enabled) async {
                    await repository.setReminderEnabled(reminder.id, enabled);
                    if (enabled) {
                      await scheduleReminderSummary(
                        reminder.copyWithEnabled(),
                        l10n,
                      );
                    } else {
                      await NotificationService.instance
                          .cancelReminderNotification(reminder.id);
                    }
                  },
                ),
              ),
              IconButton(
                tooltip: l10n.editReminderFor(
                  reminder.title,
                  reminder.scheduleText,
                ),
                onPressed: () => showAddReminderSheet(
                  context,
                  repository,
                  notificationService: notificationService,
                  reminder: reminder,
                ),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: l10n.deleteReminderFor(
                  reminder.title,
                  reminder.scheduleText,
                ),
                onPressed: () => confirmDelete(
                  context,
                  title: l10n.deleteReminderTitle,
                  body: l10n.deleteReminderBody,
                  onDelete: () async {
                    await NotificationService.instance
                        .cancelReminderNotification(reminder.id);
                    await repository.deleteReminder(reminder.id);
                  },
                ),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void showAddReminderSheet(
  BuildContext context,
  HavenRepository repository, {
  NotificationService? notificationService,
  ReminderSummary? reminder,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (context) => AddReminderSheet(
      repository: repository,
      notificationService: notificationService,
      reminder: reminder,
    ),
  );
}

class AddReminderSheet extends StatefulWidget {
  AddReminderSheet({
    super.key,
    required this.repository,
    NotificationService? notificationService,
    this.reminder,
  }) : notificationService =
           notificationService ?? NotificationService.instance;

  final HavenRepository repository;
  final NotificationService notificationService;
  final ReminderSummary? reminder;

  @override
  State<AddReminderSheet> createState() => _AddReminderSheetState();
}

enum ReminderScheduleKind {
  daily('daily'),
  weekly('weekly'),
  monthly('monthly'),
  afterFront('after_front');

  const ReminderScheduleKind(this.storageValue);

  final String storageValue;

  static ReminderScheduleKind? fromStorage(String? value) {
    for (final kind in values) {
      if (kind.storageValue == value) return kind;
    }
    return null;
  }
}

class _AddReminderSheetState extends State<AddReminderSheet> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _timeController = TextEditingController(text: '09:00');
  final _afterFrontDelayController = TextEditingController(text: '0');
  ReminderScheduleKind _scheduleKind = ReminderScheduleKind.daily;
  String _weekday = 'Monday';
  int _monthDay = 1;
  String? _triggerMemberId;
  String? _triggerMemberName;
  bool _invalidTitle = false;
  bool _invalidTime = false;
  bool _invalidDelay = false;

  @override
  void initState() {
    super.initState();
    final reminder = widget.reminder;
    if (reminder == null) return;
    _titleController.text = reminder.title;
    _bodyController.text = reminder.body ?? '';
    _timeController.text =
        reminder.scheduleTime ??
        _timeFromScheduleText(reminder.scheduleText) ??
        '';
    _scheduleKind =
        ReminderScheduleKind.fromStorage(reminder.scheduleKind) ??
        _kindFromScheduleText(reminder.scheduleText) ??
        ReminderScheduleKind.daily;
    final weekday =
        _weekdayFromMask(reminder.scheduleDowMask) ??
        _weekdayFromScheduleText(reminder.scheduleText);
    if (weekday != null) {
      _weekday = const [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ][weekday - 1];
    }
    _monthDay =
        reminder.scheduleDom ??
        _monthDayFromScheduleText(reminder.scheduleText) ??
        1;
    _triggerMemberId = reminder.triggerMemberId;
    _afterFrontDelayController.text = '${reminder.delaySeconds ?? 0}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _timeController.dispose();
    _afterFrontDelayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          18,
          0,
          18,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.reminder == null
                  ? l10n.addReminderButton
                  : l10n.editReminderTooltip,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('reminder-title-field'),
              controller: _titleController,
              onChanged: (_) {
                if (_invalidTitle) setState(() => _invalidTitle = false);
              },
              decoration: InputDecoration(
                labelText: l10n.titleFieldLabel,
                errorText: _invalidTitle ? l10n.requiredFieldError : null,
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<ReminderScheduleKind>(
              key: const ValueKey('reminder-schedule-kind-field'),
              initialValue: _scheduleKind,
              decoration: InputDecoration(labelText: l10n.scheduleFieldLabel),
              items: [
                for (final kind in ReminderScheduleKind.values)
                  DropdownMenuItem(
                    value: kind,
                    child: Text(_reminderScheduleLabel(l10n, kind)),
                  ),
              ],
              onChanged: (kind) {
                if (kind != null) {
                  setState(() => _scheduleKind = kind);
                }
              },
            ),
            const SizedBox(height: 10),
            if (_scheduleKind == ReminderScheduleKind.weekly) ...[
              DropdownButtonFormField<String>(
                key: const ValueKey('reminder-weekday-field'),
                initialValue: _weekday,
                decoration: InputDecoration(labelText: l10n.dayFieldLabel),
                items: [
                  DropdownMenuItem(value: 'Monday', child: Text(l10n.monday)),
                  DropdownMenuItem(value: 'Tuesday', child: Text(l10n.tuesday)),
                  DropdownMenuItem(
                    value: 'Wednesday',
                    child: Text(l10n.wednesday),
                  ),
                  DropdownMenuItem(
                    value: 'Thursday',
                    child: Text(l10n.thursday),
                  ),
                  DropdownMenuItem(value: 'Friday', child: Text(l10n.friday)),
                  DropdownMenuItem(
                    value: 'Saturday',
                    child: Text(l10n.saturday),
                  ),
                  DropdownMenuItem(value: 'Sunday', child: Text(l10n.sunday)),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _weekday = value);
                  }
                },
              ),
              const SizedBox(height: 10),
            ],
            if (_scheduleKind == ReminderScheduleKind.monthly) ...[
              DropdownButtonFormField<int>(
                key: const ValueKey('reminder-month-day-field'),
                initialValue: _monthDay,
                decoration: InputDecoration(
                  labelText: l10n.dayOfMonthFieldLabel,
                ),
                items: [
                  for (var day = 1; day <= 31; day++)
                    DropdownMenuItem(value: day, child: Text('$day')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _monthDay = value);
                  }
                },
              ),
              const SizedBox(height: 10),
            ],
            if (_scheduleKind == ReminderScheduleKind.afterFront) ...[
              StreamBuilder<List<MemberSummary>>(
                stream: widget.repository.watchMembers(),
                initialData: const [],
                builder: (context, snapshot) {
                  final members = snapshot.data ?? const <MemberSummary>[];
                  return DropdownButtonFormField<String?>(
                    key: const ValueKey('reminder-front-detail-field'),
                    initialValue: _triggerMemberId,
                    decoration: InputDecoration(
                      labelText: l10n.afterFrontTargetLabel,
                      helperText: l10n.afterFrontTargetHelper,
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(l10n.anyFrontStartsOption),
                      ),
                      if (_triggerMemberId != null &&
                          !members.any(
                            (member) => member.id == _triggerMemberId,
                          ))
                        DropdownMenuItem<String?>(
                          value: _triggerMemberId,
                          child: Text(l10n.unknownMemberLabel),
                        ),
                      for (final member in members)
                        DropdownMenuItem<String?>(
                          value: member.id,
                          child: Text(member.displayName),
                        ),
                    ],
                    onChanged: (memberId) {
                      setState(() {
                        _triggerMemberId = memberId;
                        _triggerMemberName = null;
                        for (final member in members) {
                          if (member.id == memberId) {
                            _triggerMemberName = member.displayName;
                            break;
                          }
                        }
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 10),
              TextField(
                key: const ValueKey('reminder-after-front-delay-field'),
                controller: _afterFrontDelayController,
                keyboardType: TextInputType.number,
                onChanged: (_) {
                  if (_invalidDelay) setState(() => _invalidDelay = false);
                },
                decoration: InputDecoration(
                  labelText: l10n.afterFrontDelayLabel,
                  helperText: l10n.afterFrontDelayHelper,
                  errorText: _invalidDelay ? l10n.afterFrontDelayError : null,
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (_scheduleKind != ReminderScheduleKind.afterFront) ...[
              TextField(
                key: const ValueKey('reminder-time-field'),
                controller: _timeController,
                keyboardType: TextInputType.datetime,
                onChanged: (_) {
                  if (_invalidTime) setState(() => _invalidTime = false);
                },
                decoration: InputDecoration(
                  labelText: l10n.timeFieldLabel,
                  helperText: l10n.timeFieldHelper,
                  errorText: _invalidTime ? l10n.reminderTimeError : null,
                  suffixIcon: IconButton(
                    tooltip: l10n.chooseReminderTime,
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              key: const ValueKey('reminder-body-field'),
              controller: _bodyController,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(labelText: l10n.noteFieldLabel),
            ),
            const SizedBox(height: 14),
            FilledButton(
              key: const ValueKey('save-reminder-button'),
              onPressed: _save,
              child: Text(l10n.saveButtonLabel),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime:
          _parseTime(_timeController.text.trim()) ??
          const TimeOfDay(hour: 9, minute: 0),
    );
    if (selected == null || !mounted) return;
    _timeController.text =
        '${selected.hour.toString().padLeft(2, '0')}:'
        '${selected.minute.toString().padLeft(2, '0')}';
    setState(() => _invalidTime = false);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty) {
      setState(() => _invalidTitle = true);
      return;
    }
    if (_scheduleKind == ReminderScheduleKind.afterFront &&
        !_hasValidAfterFrontDelay) {
      setState(() => _invalidDelay = true);
      return;
    }
    if (_scheduleKind != ReminderScheduleKind.afterFront &&
        _parseTime(_timeController.text.trim()) == null) {
      setState(() => _invalidTime = true);
      return;
    }
    if (_scheduleKind == ReminderScheduleKind.afterFront &&
        _triggerMemberId != null &&
        _triggerMemberName == null) {
      final members = await widget.repository.watchMembers().first;
      for (final member in members) {
        if (member.id == _triggerMemberId) {
          _triggerMemberName = member.displayName;
          break;
        }
      }
      if (!mounted) return;
    }
    final scheduleTime = _scheduleKind == ReminderScheduleKind.afterFront
        ? null
        : _normalisedTimeValue;
    final reminderId = await widget.repository.saveReminder(
      ReminderDraft(
        title: title,
        body: body,
        scheduleText: _scheduleText(context, l10n),
        scheduleKind: _scheduleKind.storageValue,
        scheduleTime: scheduleTime,
        scheduleDowMask: _scheduleKind == ReminderScheduleKind.weekly
            ? _weekdayMask(_weekdayNumber(_weekday))
            : null,
        scheduleDom: _scheduleKind == ReminderScheduleKind.monthly
            ? _monthDay
            : null,
        triggerType: _scheduleKind == ReminderScheduleKind.afterFront
            ? 'event'
            : 'repeated',
        triggerMemberId: _scheduleKind == ReminderScheduleKind.afterFront
            ? _triggerMemberId
            : null,
        triggerEvent: _scheduleKind == ReminderScheduleKind.afterFront
            ? 'front_started'
            : null,
        delaySeconds: _scheduleKind == ReminderScheduleKind.afterFront
            ? _afterFrontDelaySeconds
            : null,
        enabled: widget.reminder?.enabled ?? true,
      ),
      reminderId: widget.reminder?.id,
    );
    if (reminderId == null) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.couldNotSaveReminder)),
        );
      }
      return;
    }
    if (mounted) {
      final notificationPermission = await ensureNotificationPermissionForSetup(
        widget.notificationService,
      );
      if (widget.reminder != null) {
        await widget.notificationService.cancelReminderNotification(reminderId);
      }
      final time = _parseTime(scheduleTime ?? '');
      if (time != null &&
          _scheduleKind != ReminderScheduleKind.afterFront &&
          (widget.reminder?.enabled ?? true)) {
        await widget.notificationService.scheduleReminderNotification(
          reminderId: reminderId,
          title: title,
          body: body.isEmpty ? null : body,
          time: time,
          repeat: switch (_scheduleKind) {
            ReminderScheduleKind.weekly => DateTimeComponents.dayOfWeekAndTime,
            ReminderScheduleKind.monthly =>
              DateTimeComponents.dayOfMonthAndTime,
            _ => DateTimeComponents.time,
          },
          weekday: _scheduleKind == ReminderScheduleKind.weekly
              ? _weekdayNumber(_weekday)
              : null,
          monthDay: _scheduleKind == ReminderScheduleKind.monthly
              ? _monthDay
              : null,
          copy: _notificationCopy(l10n),
        );
      }
      if (mounted) Navigator.pop(context);
      if (!notificationPermission) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.notificationsPermissionDeniedBody)),
        );
      }
    }
  }

  TimeOfDay? _parseTime(String text) {
    final twelveHour = RegExp(
      r'^(\d{1,2})(?::(\d{2}))?\s*(am|pm)$',
      caseSensitive: false,
    ).firstMatch(text.trim());
    if (twelveHour != null) {
      final hour = int.parse(twelveHour.group(1)!);
      final minute = int.tryParse(twelveHour.group(2) ?? '00');
      if (hour < 1 || hour > 12 || minute == null || minute > 59) return null;
      return TimeOfDay(
        hour: hour % 12 + (twelveHour.group(3)!.toLowerCase() == 'pm' ? 12 : 0),
        minute: minute,
      );
    }
    final parts = text.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _scheduleText(BuildContext context, AppLocalizations l10n) {
    final time = _normalisedTimeText(context);
    final detail = _triggerMemberName?.trim() ?? '';
    return switch (_scheduleKind) {
      ReminderScheduleKind.daily =>
        time.isEmpty ? l10n.dailySchedule : l10n.dailyScheduleAt(time),
      ReminderScheduleKind.weekly =>
        time.isEmpty
            ? '${l10n.weeklySchedule} ${_localisedWeekday(l10n, _weekday)}'
            : l10n.weeklyScheduleAt(_localisedWeekday(l10n, _weekday), time),
      ReminderScheduleKind.monthly =>
        time.isEmpty
            ? '${l10n.monthlySchedule} ${l10n.dayFieldLabel.toLowerCase()} $_monthDay'
            : l10n.monthlyScheduleAt(_monthDay, time),
      ReminderScheduleKind.afterFront =>
        _afterFrontDelaySeconds > 0
            ? l10n.afterFrontDelayedLabel(
                _afterFrontDelaySeconds,
                detail.isEmpty
                    ? (_triggerMemberId == null
                          ? l10n.anyFrontStartsOption
                          : l10n.unknownMemberLabel)
                    : detail,
              )
            : detail.isEmpty
            ? _triggerMemberId == null
                  ? l10n.afterSelectedFrontStarts
                  : l10n.afterFrontLabel(l10n.unknownMemberLabel)
            : l10n.afterFrontLabel(detail),
    };
  }

  String _normalisedTimeText(BuildContext context) {
    final time = _parseTime(_timeController.text.trim());
    if (time == null) return '';
    return MaterialLocalizations.of(context).formatTimeOfDay(
      time,
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
  }

  String get _normalisedTimeValue {
    final time = _parseTime(_timeController.text.trim());
    if (time == null) return '';
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  int get _afterFrontDelaySeconds {
    final value = int.tryParse(_afterFrontDelayController.text.trim());
    return value == null || value < 0 ? 0 : value;
  }

  bool get _hasValidAfterFrontDelay {
    final value = int.tryParse(_afterFrontDelayController.text.trim());
    return value != null && value >= 0;
  }
}

String _reminderScheduleLabel(
  AppLocalizations l10n,
  ReminderScheduleKind kind,
) {
  return switch (kind) {
    ReminderScheduleKind.daily => l10n.dailySchedule,
    ReminderScheduleKind.weekly => l10n.weeklySchedule,
    ReminderScheduleKind.monthly => l10n.monthlySchedule,
    ReminderScheduleKind.afterFront => l10n.afterFrontSchedule,
  };
}

String _localisedWeekday(AppLocalizations l10n, String weekday) {
  return switch (weekday) {
    'Monday' => l10n.monday,
    'Tuesday' => l10n.tuesday,
    'Wednesday' => l10n.wednesday,
    'Thursday' => l10n.thursday,
    'Friday' => l10n.friday,
    'Saturday' => l10n.saturday,
    'Sunday' => l10n.sunday,
    _ => weekday,
  };
}

extension on ReminderSummary {
  ReminderSummary copyWithEnabled() {
    return ReminderSummary(
      id: id,
      title: title,
      body: body,
      scheduleText: scheduleText,
      scheduleKind: scheduleKind,
      scheduleTime: scheduleTime,
      scheduleDowMask: scheduleDowMask,
      scheduleDom: scheduleDom,
      triggerType: triggerType,
      triggerMemberId: triggerMemberId,
      triggerEvent: triggerEvent,
      delaySeconds: delaySeconds,
      lastFiredAt: lastFiredAt,
      enabled: true,
      updatedAt: updatedAt,
    );
  }
}

Future<void> scheduleReminderSummary(
  ReminderSummary reminder,
  AppLocalizations l10n,
) async {
  if (!reminder.enabled) return;
  final kind =
      ReminderScheduleKind.fromStorage(reminder.scheduleKind) ??
      _kindFromScheduleText(reminder.scheduleText);
  if (kind == null || kind == ReminderScheduleKind.afterFront) return;

  final time = _parseReminderTime(
    reminder.scheduleTime ?? _timeFromScheduleText(reminder.scheduleText) ?? '',
  );
  if (time == null) return;

  await NotificationService.instance.scheduleReminderNotification(
    reminderId: reminder.id,
    title: reminder.title,
    body: reminder.body,
    time: time,
    repeat: switch (kind) {
      ReminderScheduleKind.weekly => DateTimeComponents.dayOfWeekAndTime,
      ReminderScheduleKind.monthly => DateTimeComponents.dayOfMonthAndTime,
      _ => DateTimeComponents.time,
    },
    weekday: kind == ReminderScheduleKind.weekly
        ? _weekdayFromMask(reminder.scheduleDowMask) ??
              _weekdayFromScheduleText(reminder.scheduleText)
        : null,
    monthDay: kind == ReminderScheduleKind.monthly
        ? reminder.scheduleDom ??
              _monthDayFromScheduleText(reminder.scheduleText)
        : null,
    copy: _notificationCopy(l10n),
  );
}

Future<void> deliverAfterFrontReminders(
  BuildContext context,
  HavenRepository repository,
  List<ReminderSummary> reminders, {
  NotificationService? notificationService,
}) async {
  if (reminders.isEmpty) return;
  final notifications = notificationService ?? NotificationService.instance;
  final l10n = AppLocalizations.of(context);
  final copy = _notificationCopy(l10n);
  for (final reminder in reminders) {
    final delivered = await notifications.showTriggeredReminderNotification(
      reminderId: reminder.id,
      title: reminder.title,
      body: reminder.body,
      delay: Duration(seconds: reminder.delaySeconds ?? 0),
      copy: copy,
    );
    if (delivered) {
      await repository.recordNotificationEvent(
        NotificationEventDraft(
          kind: 'reminder',
          title: reminder.title,
          body: reminder.body ?? reminder.scheduleText,
        ),
      );
    }
  }
}

/// Requests notification permission only after a user explicitly configures
/// notification delivery, and avoids repeating the OS request when it is
/// already granted.
Future<bool> ensureNotificationPermissionForSetup(
  NotificationService notifications,
) async {
  if (await notifications.notificationsPermitted()) return true;
  return notifications.requestPermission();
}

ReminderScheduleKind? _kindFromScheduleText(String text) {
  final lower = text.toLowerCase();
  if (lower.startsWith('daily')) return ReminderScheduleKind.daily;
  if (lower.startsWith('weekly')) return ReminderScheduleKind.weekly;
  if (lower.startsWith('monthly')) return ReminderScheduleKind.monthly;
  if (lower.startsWith('after')) return ReminderScheduleKind.afterFront;
  return null;
}

TimeOfDay? _parseReminderTime(String text) {
  final parts = text.trim().split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

String? _timeFromScheduleText(String text) {
  final match = RegExp(r'\bat\s+(\d{1,2}:\d{2})\b').firstMatch(text);
  return match?.group(1);
}

int _weekdayNumber(String weekday) {
  return switch (weekday) {
    'Monday' => DateTime.monday,
    'Tuesday' => DateTime.tuesday,
    'Wednesday' => DateTime.wednesday,
    'Thursday' => DateTime.thursday,
    'Friday' => DateTime.friday,
    'Saturday' => DateTime.saturday,
    'Sunday' => DateTime.sunday,
    _ => DateTime.monday,
  };
}

int _weekdayMask(int weekday) {
  return 1 << (weekday - 1);
}

int? _weekdayFromMask(int? mask) {
  if (mask == null) return null;
  for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
    if ((mask & _weekdayMask(weekday)) != 0) return weekday;
  }
  return null;
}

int? _weekdayFromScheduleText(String text) {
  for (final weekday in const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ]) {
    if (text.contains(weekday)) return _weekdayNumber(weekday);
  }
  return null;
}

int? _monthDayFromScheduleText(String text) {
  final match = RegExp(r'\bday\s+(\d{1,2})\b').firstMatch(text);
  final value = int.tryParse(match?.group(1) ?? '');
  if (value == null || value < 1 || value > 31) return null;
  return value;
}
