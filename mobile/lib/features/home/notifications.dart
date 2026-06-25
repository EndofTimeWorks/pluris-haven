part of 'home_page.dart';

class NotificationHistoryPage extends StatelessWidget {
  const NotificationHistoryPage({super.key, required this.repository});

  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NotificationEventSummary>>(
      stream: repository.watchNotificationEvents(),
      initialData: const [],
      builder: (context, snapshot) {
        final events = snapshot.data ?? const <NotificationEventSummary>[];

        return SpPage(
          children: [
            SpCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SpSectionHeader(
                    title: 'Notification history',
                    trailing: StatusPill(text: '${events.length}'),
                  ),
                  const SizedBox(height: 12),
                  if (events.isEmpty)
                    const SpEmptyState(
                      title: 'No notifications yet',
                      body:
                          'Front notifications and reminders will be recorded here.',
                    )
                  else
                    for (final event in events) ...[
                      NotificationEventTile(event: event),
                      if (event != events.last)
                        const Divider(height: 1, color: _spLine),
                    ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class NotificationEventTile extends StatelessWidget {
  const NotificationEventTile({super.key, required this.event});

  final NotificationEventSummary event;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.notifications_rounded, color: _spGold, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(event.body, style: const TextStyle(height: 1.35)),
                const SizedBox(height: 4),
                Text(
                  '${event.kind} - ${_shortDateTime(event.createdAt)}',
                  style: const TextStyle(color: _spMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          if (event.isUnread) const StatusPill(text: 'new'),
        ],
      ),
    );
  }
}
