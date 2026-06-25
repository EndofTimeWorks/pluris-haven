part of 'home_page.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({
    super.key,
    required this.repository,
    required this.onImport,
  });

  final HavenRepository repository;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MessageSummary>>(
      stream: repository.watchMessages(),
      initialData: const [],
      builder: (context, snapshot) {
        final messages = snapshot.data ?? const <MessageSummary>[];

        return SpPage(
          children: [
            SpCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SpSectionHeader(
                    title: 'Messages',
                    trailing: StatusPill(text: '${messages.length}'),
                  ),
                  const SizedBox(height: 12),
                  if (messages.isEmpty)
                    const SpEmptyState(
                      title: 'No messages yet',
                      body: 'Leave local notes for the system here.',
                    )
                  else
                    for (final message in messages) ...[
                      MessageTile(message: message),
                      if (message != messages.last)
                        const Divider(height: 1, color: _spLine),
                    ],
                  const SizedBox(height: 14),
                  SpActionRow(
                    primary: 'Add message',
                    secondary: 'Import',
                    onPrimary: () => showAddMessageSheet(context, repository),
                    onSecondary: onImport,
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

class MessageTile extends StatelessWidget {
  const MessageTile({super.key, required this.message});

  final MessageSummary message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message.body, style: const TextStyle(height: 1.35)),
          const SizedBox(height: 4),
          Text(
            _shortDateTime(message.createdAt),
            style: const TextStyle(color: _spMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

void showAddMessageSheet(BuildContext context, HavenRepository repository) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: _spSurface,
    builder: (context) => AddMessageSheet(repository: repository),
  );
}

class AddMessageSheet extends StatefulWidget {
  const AddMessageSheet({super.key, required this.repository});

  final HavenRepository repository;

  @override
  State<AddMessageSheet> createState() => _AddMessageSheetState();
}

class _AddMessageSheetState extends State<AddMessageSheet> {
  final _bodyController = TextEditingController();

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
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
              'Add message',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('message-body-field'),
              controller: _bodyController,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Message'),
            ),
            const SizedBox(height: 14),
            FilledButton(
              key: const ValueKey('save-message-button'),
              onPressed: _save,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    await widget.repository.saveMessage(
      MessageDraft(body: _bodyController.text),
    );
    if (mounted) {
      Navigator.pop(context);
    }
  }
}
