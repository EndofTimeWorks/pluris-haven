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
                    title: 'Polls',
                    trailing: StatusPill(text: '$openCount open'),
                  ),
                  const SizedBox(height: 12),
                  if (polls.isEmpty)
                    const SpEmptyState(
                      title: 'No polls yet',
                      body: 'Create a local vote for system decisions.',
                    )
                  else
                    for (final poll in polls) ...[
                      PollTile(poll: poll, repository: repository),
                      if (poll != polls.last)
                        const Divider(height: 1, color: _spLine),
                    ],
                  const SizedBox(height: 14),
                  SpActionRow(
                    primary: 'Create poll',
                    secondary: 'Import',
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

class PollTile extends StatelessWidget {
  const PollTile({super.key, required this.poll, required this.repository});

  final PollSummary poll;
  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
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
                    Text(
                      poll.question,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    if (poll.description?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        poll.description!,
                        style: const TextStyle(color: _spMuted, height: 1.35),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(text: poll.statusLabel),
            ],
          ),
          const SizedBox(height: 10),
          for (final option in poll.options)
            Semantics(
              button: true,
              selected: option.selected,
              enabled: !poll.closed,
              label:
                  '${option.body}, ${option.selected ? 'selected' : 'not selected'}',
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: poll.closed
                    ? null
                    : () => repository.togglePollOption(poll.id, option.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        option.selected
                            ? Icons.check_circle_rounded
                            : poll.kind == PollKind.singleChoice
                            ? Icons.radio_button_unchecked_rounded
                            : Icons.check_box_outline_blank_rounded,
                        color: option.selected ? _spGold : _spMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(option.body)),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${poll.kind.label} - ${poll.selectedCount} selected',
                style: const TextStyle(color: _spMuted, fontSize: 12),
              ),
              const Spacer(),
              if (!poll.closed)
                TextButton(
                  onPressed: () => repository.closePoll(poll.id),
                  child: const Text('Close'),
                ),
              IconButton(
                tooltip: 'Delete poll',
                onPressed: () => confirmDelete(
                  context,
                  title: 'Delete poll?',
                  body: 'This poll and its local responses will be removed.',
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

void showAddPollSheet(BuildContext context, HavenRepository repository) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: _spSurface,
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
              'Create poll',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('poll-question-field'),
              controller: _questionController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Question'),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('poll-description-field'),
              controller: _descriptionController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                helperText: 'Optional context for the vote',
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<PollKind>(
              key: const ValueKey('poll-kind-field'),
              initialValue: _kind,
              decoration: const InputDecoration(labelText: 'Voting'),
              items: [
                for (final kind in PollKind.values)
                  DropdownMenuItem(value: kind, child: Text(kind.label)),
              ],
              onChanged: (kind) {
                if (kind != null) {
                  setState(() => _kind = kind);
                }
              },
            ),
            const SizedBox(height: 12),
            for (var index = 0; index < _optionControllers.length; index++) ...[
              TextField(
                key: ValueKey('poll-option-field-$index'),
                controller: _optionControllers[index],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: 'Option ${index + 1}'),
              ),
              const SizedBox(height: 10),
            ],
            OutlinedButton.icon(
              onPressed: _addOption,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add option'),
            ),
            const SizedBox(height: 14),
            FilledButton(
              key: const ValueKey('save-poll-button'),
              onPressed: _save,
              child: const Text('Save poll'),
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
        options: [for (final controller in _optionControllers) controller.text],
      ),
    );
    if (mounted) {
      Navigator.pop(context);
    }
  }
}
