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
                      PollTile(poll: poll, repository: repository),
                      if (poll != polls.last)
                        const Divider(height: 1, color: _spLine),
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

class PollTile extends StatelessWidget {
  const PollTile({super.key, required this.poll, required this.repository});

  final PollSummary poll;
  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
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
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                        ),
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
              label: l10n.pollOptionSemanticLabel(
                option.body,
                option.selected ? l10n.selectedStatus : l10n.notSelectedStatus,
              ),
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
                        color: option.selected
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
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
                l10n.pollSelectionSummary(
                  _pollKindLabel(poll.kind, l10n),
                  poll.selectedCount,
                ),
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              ),
              const Spacer(),
              if (!poll.closed)
                TextButton(
                  onPressed: () => repository.closePoll(poll.id),
                  child: Text(l10n.closeButton),
                ),
              IconButton(
                tooltip: l10n.deletePollTooltip,
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
        options: [for (final controller in _optionControllers) controller.text],
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
