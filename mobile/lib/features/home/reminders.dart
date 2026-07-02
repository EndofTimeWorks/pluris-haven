part of 'home_page.dart';

class RemindersPage extends StatelessWidget {
  const RemindersPage({super.key, required this.repository});

  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReminderSummary>>(
      stream: repository.watchReminders(),
      initialData: const [],
      builder: (context, snapshot) {
        final reminders = snapshot.data ?? const <ReminderSummary>[];

        return SpPage(
          children: [
            SpCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SpSectionHeader(
                    title: 'Reminders',
                    trailing: StatusPill(text: '${reminders.length}'),
                  ),
                  const SizedBox(height: 12),
                  if (reminders.isEmpty)
                    const SpEmptyState(
                      title: 'No reminders yet',
                      body:
                          'Create local reminders before notification scheduling is wired.',
                    )
                  else
                    for (final reminder in reminders) ...[
                      ReminderTile(reminder: reminder, repository: repository),
                      if (reminder != reminders.last)
                        const Divider(height: 1, color: _spLine),
                    ],
                  const SizedBox(height: 14),
                  SpActionRow(
                    primary: 'Add reminder',
                    secondary: 'Notification settings',
                    onPrimary: () => showAddReminderSheet(context, repository),
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
  });

  final ReminderSummary reminder;
  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            reminder.enabled
                ? Icons.notifications_active_rounded
                : Icons.notifications_off_rounded,
            color: _spGold,
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
                  style: const TextStyle(color: _spMuted, fontSize: 12),
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
              StatusPill(text: reminder.enabled ? 'on' : 'off'),
              Switch(
                value: reminder.enabled,
                onChanged: (enabled) =>
                    repository.setReminderEnabled(reminder.id, enabled),
              ),
              IconButton(
                tooltip: 'Delete reminder',
                onPressed: () => confirmDelete(
                  context,
                  title: 'Delete reminder?',
                  body: 'This reminder will be permanently removed.',
                  onDelete: () => repository.deleteReminder(reminder.id),
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

void showAddReminderSheet(BuildContext context, HavenRepository repository) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: _spSurface,
    builder: (context) => AddReminderSheet(repository: repository),
  );
}

class AddReminderSheet extends StatefulWidget {
  const AddReminderSheet({super.key, required this.repository});

  final HavenRepository repository;

  @override
  State<AddReminderSheet> createState() => _AddReminderSheetState();
}

enum ReminderScheduleKind {
  daily('Daily'),
  weekly('Weekly'),
  monthly('Monthly'),
  afterFront('After member fronts');

  const ReminderScheduleKind(this.label);

  final String label;
}

class _AddReminderSheetState extends State<AddReminderSheet> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _timeController = TextEditingController(text: '09:00');
  final _detailController = TextEditingController();
  ReminderScheduleKind _scheduleKind = ReminderScheduleKind.daily;
  String _weekday = 'Monday';
  int _monthDay = 1;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _timeController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            const Text(
              'Add reminder',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('reminder-title-field'),
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<ReminderScheduleKind>(
              key: const ValueKey('reminder-schedule-kind-field'),
              initialValue: _scheduleKind,
              decoration: const InputDecoration(labelText: 'Schedule'),
              items: [
                for (final kind in ReminderScheduleKind.values)
                  DropdownMenuItem(value: kind, child: Text(kind.label)),
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
                decoration: const InputDecoration(labelText: 'Day'),
                items: const [
                  DropdownMenuItem(value: 'Monday', child: Text('Monday')),
                  DropdownMenuItem(value: 'Tuesday', child: Text('Tuesday')),
                  DropdownMenuItem(
                    value: 'Wednesday',
                    child: Text('Wednesday'),
                  ),
                  DropdownMenuItem(value: 'Thursday', child: Text('Thursday')),
                  DropdownMenuItem(value: 'Friday', child: Text('Friday')),
                  DropdownMenuItem(value: 'Saturday', child: Text('Saturday')),
                  DropdownMenuItem(value: 'Sunday', child: Text('Sunday')),
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
                decoration: const InputDecoration(labelText: 'Day of month'),
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
              TextField(
                key: const ValueKey('reminder-front-detail-field'),
                controller: _detailController,
                decoration: const InputDecoration(
                  labelText: 'Member or front label',
                  helperText: 'Queued until this member or label fronts',
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (_scheduleKind != ReminderScheduleKind.afterFront) ...[
              TextField(
                key: const ValueKey('reminder-time-field'),
                controller: _timeController,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                  labelText: 'Time',
                  helperText: '24-hour local time, like 09:00',
                ),
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              key: const ValueKey('reminder-body-field'),
              controller: _bodyController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Note'),
            ),
            const SizedBox(height: 14),
            FilledButton(
              key: const ValueKey('save-reminder-button'),
              onPressed: _save,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    await widget.repository.saveReminder(
      ReminderDraft(
        title: title,
        body: body,
        scheduleText: _scheduleText,
      ),
    );
    if (mounted) {
      final time = _parseTime(_timeController.text.trim());
      if (time != null && _scheduleKind != ReminderScheduleKind.afterFront) {
        NotificationService.instance.scheduleReminderNotification(
          id: title.hashCode,
          title: title,
          body: body.isEmpty ? null : body,
          time: time,
        );
      }
      Navigator.pop(context);
    }
  }

  TimeOfDay? _parseTime(String text) {
    final parts = text.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String get _scheduleText {
    final time = _timeController.text.trim();
    final detail = _detailController.text.trim();
    return switch (_scheduleKind) {
      ReminderScheduleKind.daily => 'Daily${time.isEmpty ? '' : ' at $time'}',
      ReminderScheduleKind.weekly =>
        'Weekly on $_weekday${time.isEmpty ? '' : ' at $time'}',
      ReminderScheduleKind.monthly =>
        'Monthly on day $_monthDay${time.isEmpty ? '' : ' at $time'}',
      ReminderScheduleKind.afterFront =>
        detail.isEmpty
            ? 'After a selected front starts'
            : 'After $detail fronts',
    };
  }
}
