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
    final l10n = AppLocalizations.of(context);
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
                          l10n,
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
                  hintText: l10n.searchMessagesHint,
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 10),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'all', label: Text(l10n.allFilter)),
                    ButtonSegment(
                      value: 'system',
                      label: Text(l10n.systemFilter),
                    ),
                    ButtonSegment(
                      value: 'member',
                      label: Text(l10n.memberFilter),
                    ),
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
                        title: l10n.messagesTitle,
                        trailing: StatusPill(text: '${messages.length}'),
                      ),
                      const SizedBox(height: 12),
                      if (messages.isEmpty)
                        SpEmptyState(
                          title: _query.trim().isEmpty
                              ? l10n.noMessagesYet
                              : l10n.noMatchingMessages,
                          body: _query.trim().isEmpty
                              ? l10n.messagesEmptyBody
                              : l10n.tryAnotherSearch,
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
                        primary: l10n.addMessageButton,
                        secondary: l10n.importTitle,
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
    final l10n = AppLocalizations.of(context);
    final senderLabel = _messageSenderLabel(l10n, message, memberName);

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
          message.boardKind == 'member'
              ? l10n.memberBoardMessageMetadata(
                  boardMemberName ?? l10n.unknownMemberLabel,
                  senderLabel,
                  _shortDateTime(message.createdAt),
                  message.parentMessageId == null
                      ? ''
                      : l10n.messageReplyMarker,
                )
              : l10n.messageMetadata(
                  senderLabel,
                  _shortDateTime(message.createdAt),
                  message.parentMessageId == null
                      ? ''
                      : l10n.messageReplyMarker,
                ),
          style: const TextStyle(color: _spMuted, fontSize: 12),
        ),
        trailing: PopupMenuButton<String>(
          tooltip: l10n.messageActionsTooltip,
          onSelected: (action) {
            if (action == 'reply') {
              showMessageSheet(context, repository, parentMessage: message);
            } else if (action == 'delete') {
              confirmDelete(
                context,
                title: l10n.deleteMessageTitle,
                body: l10n.deleteMessageBody,
                onDelete: () => repository.deleteMessage(message.id),
              );
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'reply', child: Text(l10n.replyButton)),
            PopupMenuItem(value: 'delete', child: Text(l10n.deleteButton)),
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

String _messageSenderLabel(
  AppLocalizations l10n,
  MessageSummary message,
  String? memberName,
) {
  if (message.memberId == null) {
    return l10n.systemMessageLabel;
  }
  final name = memberName?.trim();
  return name == null || name.isEmpty ? l10n.unknownSenderLabel : name;
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
    final l10n = AppLocalizations.of(context);
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
              _isEditing ? l10n.editMessageTitle : l10n.addMessageButton,
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
                  decoration: InputDecoration(labelText: l10n.fromFieldLabel),
                  items: [
                    DropdownMenuItem(
                      value: _systemMessageValue,
                      child: Text(l10n.systemMessageLabel),
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
              decoration: InputDecoration(labelText: l10n.boardFieldLabel),
              items: [
                DropdownMenuItem(
                  value: 'system',
                  child: Text(l10n.systemBoardLabel),
                ),
                DropdownMenuItem(
                  value: 'member',
                  child: Text(l10n.memberBoardLabel),
                ),
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
                    decoration: InputDecoration(
                      labelText: l10n.memberBoardLabel,
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
                l10n.replyingToMessage(widget.parentMessage!.body),
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
              decoration: InputDecoration(labelText: l10n.messageFieldLabel),
            ),
            const SizedBox(height: 14),
            FilledButton(
              key: const ValueKey('save-message-button'),
              onPressed: _save,
              child: Text(
                _isEditing ? l10n.saveMessageButton : l10n.saveButtonLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_boardKind == 'member' && _boardMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).chooseMemberBoardFirst),
        ),
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
