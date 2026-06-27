part of 'home_page.dart';

class CustomFrontSheet extends StatefulWidget {
  const CustomFrontSheet({super.key, required this.repository});

  final HavenRepository repository;

  @override
  State<CustomFrontSheet> createState() => _CustomFrontSheetState();
}

class _CustomFrontSheetState extends State<CustomFrontSheet> {
  final _controller = TextEditingController();
  final _selectedMemberIds = <String>{};

  @override
  void dispose() {
    _controller.dispose();
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
              'Set front',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<MemberSummary>>(
              stream: widget.repository.watchMembers(),
              initialData: const [],
              builder: (context, snapshot) {
                final members = snapshot.data ?? const <MemberSummary>[];
                if (members.isEmpty) {
                  return const SpEmptyState(
                    title: 'No members yet',
                    body: 'Add members first, or set a custom front below.',
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final member in members)
                          FilterChip(
                            label: Text(member.displayName),
                            selected: _selectedMemberIds.contains(member.id),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedMemberIds.add(member.id);
                                } else {
                                  _selectedMemberIds.remove(member.id);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      key: const ValueKey('set-selected-members-front-button'),
                      onPressed: _selectedMemberIds.isEmpty
                          ? null
                          : _setMemberFront,
                      child: Text(
                        _selectedMemberIds.length <= 1
                            ? 'Set selected'
                            : 'Set co-front',
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            const Divider(color: _spLine),
            const SizedBox(height: 12),
            StreamBuilder<List<NamedFront>>(
              stream: widget.repository.watchNamedFronts(),
              initialData: const [],
              builder: (context, snapshot) {
                final customFronts = [
                  for (final front in snapshot.data ?? const <NamedFront>[])
                    if (front.customLabel?.trim().isNotEmpty == true) front,
                ];
                if (customFronts.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Saved custom fronts',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final front in customFronts)
                          ActionChip(
                            label: Text(front.customLabel ?? front.name),
                            onPressed: () => _applyNamedFront(front.id),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: _spLine),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
            const Text(
              'Custom front',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.done,
              onSubmitted: _setFront,
              decoration: const InputDecoration(labelText: 'Label'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => _setFront(_controller.text),
                    child: const Text('Set'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await widget.repository.clearCurrentFront();
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Clear'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setFront(String label) async {
    await widget.repository.setCustomFront(label);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _setMemberFront() async {
    await widget.repository.setFrontMembers(_selectedMemberIds.toList());
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _applyNamedFront(String namedFrontId) async {
    await widget.repository.applyNamedFront(namedFrontId);
    if (mounted) {
      Navigator.pop(context);
    }
  }
}
