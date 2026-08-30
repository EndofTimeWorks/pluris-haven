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
        final l10n = AppLocalizations.of(context);

        return SpPage(
          children: [
            SpCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SpSectionHeader(
                    title: l10n.notificationHistoryTitle,
                    trailing: StatusPill(text: '${events.length}'),
                  ),
                  const SizedBox(height: 12),
                  if (events.isEmpty)
                    SpEmptyState(
                      title: l10n.noNotificationsYetTitle,
                      body: l10n.noNotificationsYetBody,
                    )
                  else
                    for (final event in events) ...[
                      NotificationEventTile(event: event),
                      if (event != events.last) const Divider(height: 1),
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
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.notifications_rounded, color: scheme.primary, size: 20),
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
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (event.isUnread) StatusPill(text: l10n.newStatusPill),
        ],
      ),
    );
  }
}
