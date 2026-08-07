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
  String _boardFilter = 'all';

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
        return StreamBuilder<List<MemberSummary>>(
          stream: widget.repository.watchMembers(includeArchived: true),
          initialData: const [],
          builder: (context, memberSnapshot) {
            final memberNamesById = {
              for (final member
                  in memberSnapshot.data ?? const <MemberSummary>[])
                member.id: member.displayName,
            };
            final messages = (snapshot.data ?? const <MessageSummary>[])
                .where(
                  (message) =>
                      (_boardFilter == 'all' ||
                          message.boardKind == _boardFilter) &&
                      _matchesQuery(_query, [
                        message.body,
                        _messageSenderLabel(
                          message,
                          memberNamesById[message.memberId],
                        ),
                        memberNamesById[message.boardMemberId] ?? '',
                      ]),
                )
                .toList(growable: false);

            return SpPage(
              children: [
                SpSearchField(
                  hintText: 'Search messages',
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 10),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'all', label: Text('All')),
                    ButtonSegment(value: 'system', label: Text('System')),
                    ButtonSegment(value: 'member', label: Text('Member')),
                  ],
                  selected: {_boardFilter},
                  onSelectionChanged: (value) =>
                      setState(() => _boardFilter = value.single),
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
                            memberName: message.memberId == null
                                ? null
                                : memberNamesById[message.memberId],
                            boardMemberName: message.boardMemberId == null
                                ? null
                                : memberNamesById[message.boardMemberId],
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
      },
    );
  }
}

class MessageTile extends StatelessWidget {
  const MessageTile({
    super.key,
    required this.message,
    required this.repository,
    this.memberName,
    this.boardMemberName,
  });

  final MessageSummary message;
  final HavenRepository repository;
  final String? memberName;
  final String? boardMemberName;

  @override
  Widget build(BuildContext context) {
    final senderLabel = _messageSenderLabel(message, memberName);

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
          '${message.boardKind == 'member' ? '${boardMemberName ?? 'Unknown'} board - ' : ''}$senderLabel - ${_shortDateTime(message.createdAt)}${message.parentMessageId == null ? '' : ' - reply'}',
          style: const TextStyle(color: _spMuted, fontSize: 12),
        ),
        trailing: PopupMenuButton<String>(
          tooltip: 'Message actions',
          onSelected: (action) {
            if (action == 'reply') {
              showMessageSheet(context, repository, parentMessage: message);
            } else if (action == 'delete') {
              confirmDelete(
                context,
                title: 'Delete message?',
                body: 'This message will be hidden from the local board.',
                onDelete: () => repository.deleteMessage(message.id),
              );
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'reply', child: Text('Reply')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
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
  MessageSummary? parentMessage,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: _spSurface,
    builder: (context) => MessageSheet(
      repository: repository,
      message: message,
      parentMessage: parentMessage,
    ),
  );
}

class MessageSheet extends StatefulWidget {
  const MessageSheet({
    super.key,
    required this.repository,
    this.message,
    this.parentMessage,
  });

  final HavenRepository repository;
  final MessageSummary? message;
  final MessageSummary? parentMessage;

  @override
  State<MessageSheet> createState() => _MessageSheetState();
}

String _messageSenderLabel(MessageSummary message, String? memberName) {
  if (message.memberId == null) {
    return 'System message';
  }
  final name = memberName?.trim();
  return name == null || name.isEmpty ? 'Unknown sender' : name;
}

class _MessageSheetState extends State<MessageSheet> {
  static const _systemMessageValue = '__system_message__';

  final _bodyController = TextEditingController();
  String? _memberId;
  String _boardKind = 'system';
  String? _boardMemberId;

  bool get _isEditing => widget.message != null;

  @override
  void initState() {
    super.initState();
    final message = widget.message;
    _bodyController.text = message?.body ?? '';
    _memberId = message?.memberId;
    _boardKind =
        message?.boardKind ?? widget.parentMessage?.boardKind ?? 'system';
    _boardMemberId =
        message?.boardMemberId ?? widget.parentMessage?.boardMemberId;
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
            StreamBuilder<List<MemberSummary>>(
              stream: widget.repository.watchMembers(includeArchived: true),
              initialData: const [],
              builder: (context, snapshot) {
                final members = snapshot.data ?? const <MemberSummary>[];
                final value = _memberId == null
                    ? _systemMessageValue
                    : members.any((member) => member.id == _memberId)
                    ? _memberId!
                    : _systemMessageValue;
                return DropdownButtonFormField<String>(
                  key: const ValueKey('message-member-field'),
                  initialValue: value,
                  decoration: const InputDecoration(labelText: 'From'),
                  items: [
                    const DropdownMenuItem(
                      value: _systemMessageValue,
                      child: Text('System message'),
                    ),
                    for (final member in members)
                      DropdownMenuItem(
                        value: member.id,
                        child: Text(member.displayName),
                      ),
                  ],
                  onChanged: (value) => setState(() {
                    _memberId = value == _systemMessageValue ? null : value;
                  }),
                );
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              key: const ValueKey('message-board-kind-field'),
              initialValue: _boardKind,
              decoration: const InputDecoration(labelText: 'Board'),
              items: const [
                DropdownMenuItem(value: 'system', child: Text('System board')),
                DropdownMenuItem(value: 'member', child: Text('Member board')),
              ],
              onChanged: (value) => setState(() {
                _boardKind = value ?? 'system';
                if (_boardKind == 'system') _boardMemberId = null;
              }),
            ),
            if (_boardKind == 'member') ...[
              const SizedBox(height: 10),
              StreamBuilder<List<MemberSummary>>(
                stream: widget.repository.watchMembers(includeArchived: true),
                initialData: const [],
                builder: (context, snapshot) {
                  final members = snapshot.data ?? const <MemberSummary>[];
                  return DropdownButtonFormField<String>(
                    key: const ValueKey('message-board-member-field'),
                    initialValue:
                        members.any((member) => member.id == _boardMemberId)
                        ? _boardMemberId
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Member board',
                    ),
                    items: [
                      for (final member in members)
                        DropdownMenuItem(
                          value: member.id,
                          child: Text(member.displayName),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => _boardMemberId = value),
                  );
                },
              ),
            ],
            if (widget.parentMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                'Replying to: ${widget.parentMessage!.body}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _spMuted),
              ),
            ],
            const SizedBox(height: 10),
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
    if (_boardKind == 'member' && _boardMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a member board first.')),
      );
      return;
    }
    final draft = MessageDraft(
      body: _bodyController.text,
      memberId: _memberId,
      boardKind: _boardKind,
      boardMemberId: _boardMemberId,
      parentMessageId:
          widget.message?.parentMessageId ?? widget.parentMessage?.id,
    );
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
