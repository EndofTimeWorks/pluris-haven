part of 'home_page.dart';

class PollsPage extends StatelessWidget {
  const PollsPage({
    super.key,
    required this.repository,
    required this.onImport,
  });

  final HavenRepository repository;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<List<PollSummary>>(
      stream: repository.watchPolls(),
      initialData: const [],
      builder: (context, snapshot) {
        final polls = snapshot.data ?? const <PollSummary>[];
        final openCount = polls.where((poll) => !poll.closed).length;

        return SpPage(
          children: [
            SpCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SpSectionHeader(
                    title: l10n.pollsTitle,
                    trailing: StatusPill(text: l10n.openPollCount(openCount)),
                  ),
                  const SizedBox(height: 12),
                  if (polls.isEmpty)
                    SpEmptyState(
                      title: l10n.noPollsYet,
                      body: l10n.pollsEmptyBody,
                    )
                  else
                    for (final poll in polls) ...[
                      Semantics(
                        container: true,
                        explicitChildNodes: true,
                        header: true,
                        label: poll.question,
                        child: PollTile(
                          key: ValueKey(poll.id),
                          poll: poll,
                          repository: repository,
                        ),
                      ),
                      if (poll != polls.last) const Divider(height: 1),
                    ],
                  const SizedBox(height: 14),
                  SpActionRow(
                    primary: l10n.createPollButton,
                    secondary: l10n.importTitle,
                    onPrimary: () => showAddPollSheet(context, repository),
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

class PollTile extends StatefulWidget {
  const PollTile({super.key, required this.poll, required this.repository});

  final PollSummary poll;
  final HavenRepository repository;

  @override
  State<PollTile> createState() => _PollTileState();
}

class _PollTileState extends State<PollTile> {
  String? _voterId;
  bool _voting = false;

  Future<void> _vote(PollSummary poll, PollOptionSummary option) async {
    if (_voting) return;
    final memberId = poll.voteMode == PollVoteMode.perMember ? _voterId : null;
    setState(() => _voting = true);
    try {
      if (poll.restrictVotingToFronters) {
        final activeIds =
            (await widget.repository.watchCurrentFrontMembers().first)
                .map((member) => member.id)
                .toSet();
        if (activeIds.isEmpty ||
            (memberId != null && !activeIds.contains(memberId))) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context).pollFrontersOnlyHelper,
                ),
              ),
            );
          }
          return;
        }
      }
      await widget.repository.togglePollOption(
        poll.id,
        option.id,
        memberId: memberId,
      );
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).pollCouldNotVote),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _voting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final poll = widget.poll;
    final repository = widget.repository;
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                      child: Text(
                        poll.question,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (poll.description?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        poll.description!,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                    if (poll.restrictVotingToFronters) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.pollFrontersOnlyLabel,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (poll.voteMode == PollVoteMode.perMember) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.pollMemberVoteLabel,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(
                text: poll.closed ? l10n.pollClosedStatus : l10n.pollOpenStatus,
              ),
            ],
          ),
          if (poll.voteMode == PollVoteMode.perMember && !poll.closed) ...[
            const SizedBox(height: 10),
            StreamBuilder<List<MemberSummary>>(
              stream: poll.restrictVotingToFronters
                  ? repository.watchCurrentFrontMembers()
                  : repository.watchMembers(includeArchived: true),
              initialData: const [],
              builder: (context, snapshot) {
                final members = snapshot.data ?? const <MemberSummary>[];
                final duplicateNames = <String, int>{};
                for (final member in members) {
                  duplicateNames.update(
                    memberNameComparisonKey(member.displayName),
                    (count) => count + 1,
                    ifAbsent: () => 1,
                  );
                }
                final selectedId =
                    members.any((member) => member.id == _voterId)
                    ? _voterId
                    : null;
                return DropdownButtonFormField<String>(
                  key: ValueKey('poll-voter-${poll.id}'),
                  initialValue: selectedId,
                  decoration: InputDecoration(
                    labelText: l10n.pollVoteAsMemberLabel,
                  ),
                  hint: Text(l10n.pollChooseMemberHint),
                  items: [
                    for (final member in members)
                      DropdownMenuItem(
                        value: member.id,
                        child: Text(_pollMemberLabel(member, duplicateNames)),
                      ),
                  ],
                  onChanged: members.isEmpty
                      ? null
                      : (id) => setState(() => _voterId = id),
                );
              },
            ),
          ],
          const SizedBox(height: 10),
          for (final option in poll.options)
            Builder(
              builder: (context) {
                final selected = poll.voteMode == PollVoteMode.perMember
                    ? option.memberIds.contains(_voterId)
                    : option.selected;
                final canVote =
                    !poll.closed &&
                    !_voting &&
                    (poll.voteMode == PollVoteMode.shared || _voterId != null);
                return Semantics(
                  container: true,
                  button: true,
                  selected: selected,
                  enabled: canVote,
                  label: option.body,
                  onTap: !canVote ? null : () => _vote(poll, option),
                  child: ExcludeSemantics(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: !canVote ? null : () => _vote(poll, option),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selected
                                  ? Icons.check_circle_rounded
                                  : poll.kind == PollKind.singleChoice
                                  ? Icons.radio_button_unchecked_rounded
                                  : Icons.check_box_outline_blank_rounded,
                              color: selected
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(option.body)),
                            if (poll.voteMode == PollVoteMode.perMember)
                              Text(l10n.pollVoteCount(option.voteCount)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              Text(
                l10n.pollSelectionSummary(
                  _pollKindLabel(poll.kind, l10n),
                  poll.selectedCount,
                ),
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              ),
              if (!poll.closed)
                TextButton(
                  onPressed: () => repository.closePoll(poll.id),
                  child: Semantics(
                    label: '${l10n.closeButton}: ${poll.question}',
                    child: ExcludeSemantics(child: Text(l10n.closeButton)),
                  ),
                ),
              TextButton(
                onPressed: () => showPollVoteHistory(
                  context,
                  repository: repository,
                  poll: poll,
                ),
                child: Semantics(
                  label: '${l10n.pollVoteHistoryButton}: ${poll.question}',
                  child: ExcludeSemantics(
                    child: Text(l10n.pollVoteHistoryButton),
                  ),
                ),
              ),
              IconButton(
                tooltip: '${l10n.deletePollTooltip}: ${poll.question}',
                onPressed: () => confirmDelete(
                  context,
                  title: l10n.deletePollTitle,
                  body: l10n.deletePollBody,
                  onDelete: () => repository.deletePoll(poll.id),
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

Future<void> showPollVoteHistory(
  BuildContext context, {
  required HavenRepository repository,
  required PollSummary poll,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      final optionNames = {
        for (final option in poll.options) option.id: option.body,
      };
      return SafeArea(
        child: StreamBuilder<List<PollVoteEvent>>(
          stream: repository.watchPollVoteEvents(poll.id),
          initialData: const [],
          builder: (context, snapshot) {
            final events = snapshot.data ?? const <PollVoteEvent>[];
            return ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              children: [
                Text(
                  l10n.pollVoteHistoryTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                if (events.isEmpty)
                  Text(l10n.noPollVoteEvents)
                else
                  StreamBuilder<List<MemberSummary>>(
                    stream: repository.watchMembers(includeArchived: true),
                    initialData: const [],
                    builder: (context, memberSnapshot) {
                      final members =
                          memberSnapshot.data ?? const <MemberSummary>[];
                      final names = <String, int>{};
                      for (final member in members) {
                        names.update(
                          memberNameComparisonKey(member.displayName),
                          (count) => count + 1,
                          ifAbsent: () => 1,
                        );
                      }
                      final membersById = {
                        for (final member in members) member.id: member,
                      };
                      return Column(
                        children: [
                          for (final event in events)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                l10n.pollVoteEventLabel(
                                  optionNames[event.optionId] ??
                                      l10n.unknownPollOptionLabel,
                                  event.action == 'selected'
                                      ? l10n.pollVoteSelected
                                      : l10n.pollVoteCleared,
                                ),
                              ),
                              subtitle: Text(
                                '${_pollVoterLabel(event.memberId, membersById, names, l10n)} · ${_shortDateTime(context, event.createdAt)}',
                              ),
                            ),
                        ],
                      );
                    },
                  ),
              ],
            );
          },
        ),
      );
    },
  );
}

String _pollVoterLabel(
  String? memberId,
  Map<String, MemberSummary> members,
  Map<String, int> nameCounts,
  AppLocalizations l10n,
) {
  if (memberId == null) return l10n.pollSharedChoiceLabel;
  final member = members[memberId];
  if (member == null) return l10n.unknownMemberLabel;
  return _pollMemberLabel(member, nameCounts);
}

String _pollMemberLabel(MemberSummary member, Map<String, int> nameCounts) {
  if (nameCounts[memberNameComparisonKey(member.displayName)] == 1) {
    return member.displayName;
  }
  final shortId = member.id.length <= 6 ? member.id : member.id.substring(0, 6);
  return '${member.displayName} ($shortId)';
}

void showAddPollSheet(BuildContext context, HavenRepository repository) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (context) => AddPollSheet(repository: repository),
  );
}

class AddPollSheet extends StatefulWidget {
  const AddPollSheet({super.key, required this.repository});

  final HavenRepository repository;

  @override
  State<AddPollSheet> createState() => _AddPollSheetState();
}

class _AddPollSheetState extends State<AddPollSheet> {
  final _questionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _optionControllers = [TextEditingController(), TextEditingController()];
  PollKind _kind = PollKind.singleChoice;
  PollVoteMode _voteMode = PollVoteMode.shared;
  bool _restrictVotingToFronters = false;

  @override
  void dispose() {
    _questionController.dispose();
    _descriptionController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
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
              l10n.createPollButton,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('poll-question-field'),
              controller: _questionController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: l10n.questionFieldLabel),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('poll-description-field'),
              controller: _descriptionController,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l10n.descriptionFieldLabel,
                helperText: l10n.pollDescriptionHelper,
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<PollKind>(
              key: const ValueKey('poll-kind-field'),
              initialValue: _kind,
              decoration: InputDecoration(labelText: l10n.votingFieldLabel),
              items: [
                for (final kind in PollKind.values)
                  DropdownMenuItem(
                    value: kind,
                    child: Text(_pollKindLabel(kind, l10n)),
                  ),
              ],
              onChanged: (kind) {
                if (kind != null) {
                  setState(() => _kind = kind);
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PollVoteMode>(
              key: const ValueKey('poll-vote-mode-field'),
              initialValue: _voteMode,
              decoration: InputDecoration(labelText: l10n.pollVoteModeLabel),
              items: [
                DropdownMenuItem(
                  value: PollVoteMode.shared,
                  child: Text(l10n.pollSharedChoiceLabel),
                ),
                DropdownMenuItem(
                  value: PollVoteMode.perMember,
                  child: Text(l10n.pollMemberVoteLabel),
                ),
              ],
              onChanged: (mode) {
                if (mode != null) setState(() => _voteMode = mode);
              },
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.pollFrontersOnlyLabel),
              subtitle: Text(l10n.pollFrontersOnlyHelper),
              value: _restrictVotingToFronters,
              onChanged: (value) =>
                  setState(() => _restrictVotingToFronters = value),
            ),
            const SizedBox(height: 12),
            for (var index = 0; index < _optionControllers.length; index++) ...[
              TextField(
                key: ValueKey('poll-option-field-$index'),
                controller: _optionControllers[index],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.pollOptionFieldLabel(index + 1),
                ),
              ),
              const SizedBox(height: 10),
            ],
            OutlinedButton.icon(
              onPressed: _addOption,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.addPollOptionButton),
            ),
            const SizedBox(height: 14),
            FilledButton(
              key: const ValueKey('save-poll-button'),
              onPressed: _save,
              child: Text(l10n.savePollButton),
            ),
          ],
        ),
      ),
    );
  }

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  Future<void> _save() async {
    await widget.repository.savePoll(
      PollDraft(
        question: _questionController.text,
        description: _descriptionController.text,
        kind: _kind,
        voteMode: _voteMode,
        options: [for (final controller in _optionControllers) controller.text],
        restrictVotingToFronters: _restrictVotingToFronters,
      ),
    );
    if (mounted) {
      Navigator.pop(context);
    }
  }
}

String _pollKindLabel(PollKind kind, AppLocalizations l10n) => switch (kind) {
  PollKind.singleChoice => l10n.singleChoicePollKind,
  PollKind.multipleChoice => l10n.multipleChoicePollKind,
};
