part of 'home_page.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({
    super.key,
    required this.repository,
    required this.onImport,
  });

  final HavenRepository repository;
  final VoidCallback onImport;

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MessageSummary>>(
      stream: widget.repository.watchMessages(),
      initialData: const [],
      builder: (context, snapshot) {
        final messages = (snapshot.data ?? const <MessageSummary>[])
            .where((message) => _matchesQuery(_query, [message.body]))
            .toList(growable: false);

        return SpPage(
          children: [
            SpSearchField(
              hintText: 'Search messages',
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
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
                    SpEmptyState(
                      title: _query.trim().isEmpty
                          ? 'No messages yet'
                          : 'No matching messages',
                      body: _query.trim().isEmpty
                          ? 'Leave local notes for the system here.'
                          : 'Try another search.',
                    )
                  else
                    for (final message in messages) ...[
                      MessageTile(
                        message: message,
                        repository: widget.repository,
                      ),
                      if (message != messages.last)
                        const Divider(height: 1, color: _spLine),
                    ],
                  const SizedBox(height: 14),
                  SpActionRow(
                    primary: 'Add message',
                    secondary: 'Import',
                    onPrimary: () =>
                        showMessageSheet(context, widget.repository),
                    onSecondary: widget.onImport,
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
  const MessageTile({
    super.key,
    required this.message,
    required this.repository,
  });

  final MessageSummary message;
  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const SpIconBubble(icon: Icons.forum_outlined),
        title: Text(
          message.body,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(height: 1.35),
        ),
        subtitle: Text(
          _shortDateTime(message.createdAt),
          style: const TextStyle(color: _spMuted, fontSize: 12),
        ),
        trailing: IconButton(
          tooltip: 'Delete message',
          onPressed: () => confirmDelete(
            context,
            title: 'Delete message?',
            body: 'This message will be hidden from the local board.',
            onDelete: () => repository.deleteMessage(message.id),
          ),
          icon: const Icon(Icons.delete_outline_rounded),
        ),
        onTap: () => showMessageSheet(context, repository, message: message),
      ),
    );
  }
}

void showMessageSheet(
  BuildContext context,
  HavenRepository repository, {
  MessageSummary? message,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: _spSurface,
    builder: (context) =>
        MessageSheet(repository: repository, message: message),
  );
}

class MessageSheet extends StatefulWidget {
  const MessageSheet({super.key, required this.repository, this.message});

  final HavenRepository repository;
  final MessageSummary? message;

  @override
  State<MessageSheet> createState() => _MessageSheetState();
}

class _MessageSheetState extends State<MessageSheet> {
  final _bodyController = TextEditingController();

  bool get _isEditing => widget.message != null;

  @override
  void initState() {
    super.initState();
    _bodyController.text = widget.message?.body ?? '';
  }

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
            Text(
              _isEditing ? 'Edit message' : 'Add message',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
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
              child: Text(_isEditing ? 'Save message' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final draft = MessageDraft(body: _bodyController.text);
    final message = widget.message;
    if (message == null) {
      await widget.repository.saveMessage(draft);
    } else {
      await widget.repository.updateMessage(message.id, draft);
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }
}
