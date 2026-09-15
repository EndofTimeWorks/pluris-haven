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
        return StreamBuilder<List<ChatChannelSummary>>(
          stream: widget.repository.watchChatChannels(includeArchived: true),
          initialData: const [],
          builder: (context, channelSnapshot) {
            final channelNamesById = {
              for (final channel
                  in channelSnapshot.data ?? const <ChatChannelSummary>[])
                channel.id: channel.name,
            };
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
                            channelNamesById[message.channelId] ?? '',
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
                        ButtonSegment(
                          value: 'all',
                          label: Text(l10n.allFilter),
                        ),
                        ButtonSegment(
                          value: 'system',
                          label: Text(l10n.systemFilter),
                        ),
                        ButtonSegment(
                          value: 'member',
                          label: Text(l10n.memberFilter),
                        ),
                        ButtonSegment(
                          value: 'channel',
                          label: Text(l10n.channelFilter),
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
                                channelName: message.channelId == null
                                    ? null
                                    : channelNamesById[message.channelId],
                              ),
                              if (message != messages.last)
                                const Divider(height: 1),
                            ],
                          const SizedBox(height: 14),
                          SpActionRow(
                            primary: l10n.addMessageButton,
                            secondary: l10n.manageChannelsButton,
                            onPrimary: () =>
                                showMessageSheet(context, widget.repository),
                            onSecondary: () => showChatOrganisationSheet(
                              context,
                              widget.repository,
                            ),
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
    this.channelName,
  });

  final MessageSummary message;
  final HavenRepository repository;
  final String? memberName;
  final String? boardMemberName;
  final String? channelName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
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
              : message.boardKind == 'channel'
              ? l10n.channelBoardMessageMetadata(
                  channelName ?? l10n.channelBoardLabel,
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
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.edited)
              Tooltip(
                message: l10n.messageEditedLabel,
                child: const Icon(Icons.edit_outlined, size: 18),
              ),
            PopupMenuButton<String>(
              tooltip: l10n.messageActionsTooltip,
              onSelected: (action) {
                if (action == 'reply') {
                  showMessageSheet(context, repository, parentMessage: message);
                } else if (action == 'history') {
                  showMessageRevisionHistory(context, repository, message);
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
                PopupMenuItem(
                  value: 'history',
                  child: Text(l10n.revisionHistoryButton),
                ),
                PopupMenuItem(value: 'delete', child: Text(l10n.deleteButton)),
              ],
            ),
          ],
        ),
        onTap: () => showMessageSheet(context, repository, message: message),
      ),
    );
  }
}

Future<void> showMessageRevisionHistory(
  BuildContext context,
  HavenRepository repository,
  MessageSummary message,
) async {
  await showContentRevisionSheet(
    context,
    repository: repository,
    targetType: 'message',
    targetId: message.id,
  );
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
    backgroundColor: Theme.of(context).colorScheme.surface,
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
  String? _channelId;

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
    _channelId = message?.channelId ?? widget.parentMessage?.channelId;
  }

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
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
                DropdownMenuItem(
                  value: 'channel',
                  child: Text(l10n.channelBoardLabel),
                ),
              ],
              onChanged: (value) => setState(() {
                _boardKind = value ?? 'system';
                if (_boardKind == 'system') _boardMemberId = null;
                if (_boardKind != 'channel') _channelId = null;
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
            if (_boardKind == 'channel') ...[
              const SizedBox(height: 10),
              StreamBuilder<List<ChatChannelSummary>>(
                stream: widget.repository.watchChatChannels(),
                initialData: const [],
                builder: (context, snapshot) {
                  final channels =
                      snapshot.data ?? const <ChatChannelSummary>[];
                  return DropdownButtonFormField<String>(
                    key: const ValueKey('message-channel-field'),
                    initialValue:
                        channels.any((channel) => channel.id == _channelId)
                        ? _channelId
                        : null,
                    decoration: InputDecoration(
                      labelText: l10n.channelBoardLabel,
                    ),
                    items: [
                      for (final channel in channels)
                        DropdownMenuItem(
                          value: channel.id,
                          child: Text(channel.name),
                        ),
                    ],
                    onChanged: (value) => setState(() => _channelId = value),
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
                style: TextStyle(color: scheme.onSurfaceVariant),
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
            if (_isEditing)
              OutlinedButton.icon(
                onPressed: _showHistory,
                icon: const Icon(Icons.history_rounded),
                label: Text(l10n.revisionHistoryButton),
              ),
            if (_isEditing) const SizedBox(height: 10),
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
    if (_boardKind == 'channel' && _channelId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).chooseChannelFirst),
        ),
      );
      return;
    }
    final draft = MessageDraft(
      body: _bodyController.text,
      memberId: _memberId,
      boardKind: _boardKind,
      boardMemberId: _boardMemberId,
      channelId: _channelId,
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

  Future<void> _showHistory() async {
    final message = widget.message;
    if (message == null) return;
    final restored = await showContentRevisionSheet(
      context,
      repository: widget.repository,
      targetType: 'message',
      targetId: message.id,
    );
    if (restored && mounted) Navigator.pop(context);
  }
}

void showChatOrganisationSheet(
  BuildContext context,
  HavenRepository repository,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (context) => _ChatOrganisationSheet(repository: repository),
  );
}

class _ChatOrganisationSheet extends StatelessWidget {
  const _ChatOrganisationSheet({required this.repository});

  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: StreamBuilder<List<ChatCategorySummary>>(
        stream: repository.watchChatCategories(),
        initialData: const [],
        builder: (context, categorySnapshot) {
          final categories =
              categorySnapshot.data ?? const <ChatCategorySummary>[];
          return StreamBuilder<List<ChatChannelSummary>>(
            stream: repository.watchChatChannels(),
            initialData: const [],
            builder: (context, channelSnapshot) {
              final channels =
                  channelSnapshot.data ?? const <ChatChannelSummary>[];
              final categoryNames = {
                for (final category in categories) category.id: category.name,
              };
              return ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                children: [
                  Text(
                    l10n.channelsTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final channel in channels)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.tag_rounded),
                      title: Text(channel.name),
                      subtitle: Text(
                        channel.description?.trim().isNotEmpty == true
                            ? '${categoryNames[channel.categoryId] ?? l10n.noCategoryLabel}\n${channel.description}'
                            : categoryNames[channel.categoryId] ??
                                  l10n.noCategoryLabel,
                      ),
                      isThreeLine:
                          channel.description?.trim().isNotEmpty == true,
                      trailing: IconButton(
                        tooltip: l10n.deleteButton,
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: () => confirmDelete(
                          context,
                          title: l10n.deleteChannelTitle,
                          body: l10n.deleteChannelBody,
                          onDelete: () =>
                              repository.deleteChatChannel(channel.id),
                        ),
                      ),
                      onTap: () => showChatChannelEditor(
                        context,
                        repository: repository,
                        categories: categories,
                        channel: channel,
                      ),
                    ),
                  OutlinedButton.icon(
                    key: const ValueKey('add-chat-channel-button'),
                    onPressed: () => showChatChannelEditor(
                      context,
                      repository: repository,
                      categories: categories,
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l10n.addChannelButton),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    l10n.categoriesTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final category in categories)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(category.name),
                      subtitle: category.description?.trim().isNotEmpty == true
                          ? Text(category.description!)
                          : null,
                      trailing: IconButton(
                        tooltip: l10n.deleteButton,
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: () => confirmDelete(
                          context,
                          title: l10n.deleteCategoryTitle,
                          body: l10n.deleteCategoryBody,
                          onDelete: () =>
                              repository.deleteChatCategory(category.id),
                        ),
                      ),
                      onTap: () => showChatCategoryEditor(
                        context,
                        repository: repository,
                        category: category,
                      ),
                    ),
                  OutlinedButton.icon(
                    key: const ValueKey('add-chat-category-button'),
                    onPressed: () =>
                        showChatCategoryEditor(context, repository: repository),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l10n.addCategoryButton),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

void showChatCategoryEditor(
  BuildContext context, {
  required HavenRepository repository,
  ChatCategorySummary? category,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (context) =>
        _ChatCategoryEditor(repository: repository, category: category),
  );
}

class _ChatCategoryEditor extends StatefulWidget {
  const _ChatCategoryEditor({required this.repository, this.category});

  final HavenRepository repository;
  final ChatCategorySummary? category;

  @override
  State<_ChatCategoryEditor> createState() => _ChatCategoryEditorState();
}

class _ChatCategoryEditorState extends State<_ChatCategoryEditor> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.category?.name ?? '';
    _descriptionController.text = widget.category?.description ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
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
              widget.category == null
                  ? l10n.addCategoryButton
                  : l10n.editCategoryTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('chat-category-name-field'),
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.categoryNameFieldLabel,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l10n.descriptionFieldLabel,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              key: const ValueKey('save-chat-category-button'),
              onPressed: _save,
              child: Text(l10n.saveButtonLabel),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final draft = ChatCategoryDraft(
      name: _nameController.text,
      description: _descriptionController.text,
    );
    final category = widget.category;
    if (category == null) {
      await widget.repository.saveChatCategory(draft);
    } else {
      await widget.repository.updateChatCategory(category.id, draft);
    }
    if (mounted) Navigator.pop(context);
  }
}

void showChatChannelEditor(
  BuildContext context, {
  required HavenRepository repository,
  required List<ChatCategorySummary> categories,
  ChatChannelSummary? channel,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (context) => _ChatChannelEditor(
      repository: repository,
      categories: categories,
      channel: channel,
    ),
  );
}

class _ChatChannelEditor extends StatefulWidget {
  const _ChatChannelEditor({
    required this.repository,
    required this.categories,
    this.channel,
  });

  final HavenRepository repository;
  final List<ChatCategorySummary> categories;
  final ChatChannelSummary? channel;

  @override
  State<_ChatChannelEditor> createState() => _ChatChannelEditorState();
}

class _ChatChannelEditorState extends State<_ChatChannelEditor> {
  static const _noCategory = '__no_chat_category__';

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _categoryId;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.channel?.name ?? '';
    _descriptionController.text = widget.channel?.description ?? '';
    _categoryId = widget.channel?.categoryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selected =
        widget.categories.any((category) => category.id == _categoryId)
        ? _categoryId!
        : _noCategory;
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
              widget.channel == null
                  ? l10n.addChannelButton
                  : l10n.editChannelTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('chat-channel-name-field'),
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.channelNameFieldLabel,
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              key: const ValueKey('chat-channel-category-field'),
              initialValue: selected,
              decoration: InputDecoration(labelText: l10n.categoryFieldLabel),
              items: [
                DropdownMenuItem(
                  value: _noCategory,
                  child: Text(l10n.noCategoryLabel),
                ),
                for (final category in widget.categories)
                  DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name),
                  ),
              ],
              onChanged: (value) => setState(
                () => _categoryId = value == _noCategory ? null : value,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l10n.descriptionFieldLabel,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              key: const ValueKey('save-chat-channel-button'),
              onPressed: _save,
              child: Text(l10n.saveButtonLabel),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final draft = ChatChannelDraft(
      name: _nameController.text,
      categoryId: _categoryId,
      description: _descriptionController.text,
    );
    final channel = widget.channel;
    if (channel == null) {
      await widget.repository.saveChatChannel(draft);
    } else {
      await widget.repository.updateChatChannel(channel.id, draft);
    }
    if (mounted) Navigator.pop(context);
  }
}
