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
                  if (events.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        key: const ValueKey('clear-notification-history'),
                        onPressed: () => confirmDelete(
                          context,
                          title: l10n.clearNotificationHistoryTitle,
                          body: l10n.clearNotificationHistoryBody,
                          confirmLabel: l10n.clearNotificationHistoryButton,
                          onDelete: repository.clearNotificationHistory,
                        ),
                        icon: const Icon(Icons.delete_sweep_rounded),
                        label: Text(l10n.clearNotificationHistoryButton),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (events.isEmpty)
                    SpEmptyState(
                      title: l10n.noNotificationsYetTitle,
                      body: l10n.noNotificationsYetBody,
                    )
                  else
                    for (final event in events) ...[
                      NotificationEventTile(
                        key: ValueKey('notification-${event.id}'),
                        event: event,
                        onMarkRead: () =>
                            repository.markNotificationRead(event.id),
                      ),
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
  const NotificationEventTile({
    super.key,
    required this.event,
    required this.onMarkRead,
  });

  final NotificationEventSummary event;
  final Future<void> Function() onMarkRead;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.notifications_rounded,
                color: scheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Semantics(
                label:
                    '${event.title}. ${event.body} ${event.kind}, ${_shortDateTime(context, event.createdAt)}${event.isUnread ? ', ${l10n.newStatusPill}' : ''}',
                child: ExcludeSemantics(
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
                        '${event.kind} - ${_shortDateTime(context, event.createdAt)}',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (event.isUnread) ...[
              ExcludeSemantics(child: StatusPill(text: l10n.newStatusPill)),
              IconButton(
                tooltip: l10n.markNotificationReadButton(event.title),
                onPressed: onMarkRead,
                icon: const Icon(Icons.done_rounded),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
