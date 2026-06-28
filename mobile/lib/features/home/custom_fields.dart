part of 'home_page.dart';

class CustomFieldsPage extends StatelessWidget {
  const CustomFieldsPage({
    super.key,
    required this.repository,
    required this.onImport,
  });

  final HavenRepository repository;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CustomFieldSummary>>(
      stream: repository.watchCustomFields(),
      initialData: const [],
      builder: (context, snapshot) {
        final fields = snapshot.data ?? const <CustomFieldSummary>[];
        final fieldsWithValues = fields
            .where((field) => field.valueCount > 0)
            .length;

        return StreamBuilder<List<CustomFieldValueSummary>>(
          stream: repository.watchCustomFieldValues(),
          initialData: const [],
          builder: (context, valuesSnapshot) {
            final values = valuesSnapshot.data ?? const [];
            return StreamBuilder<List<MemberSummary>>(
              stream: repository.watchMembers(includeArchived: true),
              initialData: const [],
              builder: (context, membersSnapshot) {
                final members = membersSnapshot.data ?? const <MemberSummary>[];
                return SpPage(
                  children: [
                    SpCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SpSectionHeader(
                            title: 'Custom Fields',
                            trailing: StatusPill(text: '${fields.length}'),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            fields.isEmpty
                                ? 'Import a Simply Plural export to bring custom profile fields into the local archive.'
                                : '$fieldsWithValues fields have imported values.',
                            style: const TextStyle(
                              color: _spMuted,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (fields.isEmpty)
                            const SpEmptyState(
                              title: 'No custom fields yet',
                              body:
                                  'SP custom fields will show here after import.',
                            )
                          else
                            for (
                              var index = 0;
                              index < fields.length;
                              index++
                            ) ...[
                              CustomFieldTile(
                                field: fields[index],
                                values: values
                                    .where(
                                      (value) =>
                                          value.fieldId == fields[index].id,
                                    )
                                    .toList(),
                                members: members,
                              ),
                              if (index != fields.length - 1)
                                const Divider(height: 1, color: _spLine),
                            ],
                          const SizedBox(height: 14),
                          SpActionRow(
                            primary: 'Import',
                            secondary: 'Add field',
                            onPrimary: onImport,
                            onSecondary: () =>
                                showAddCustomFieldSheet(context, repository),
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

class CustomFieldTile extends StatelessWidget {
  const CustomFieldTile({
    super.key,
    required this.field,
    required this.values,
    required this.members,
  });

  final CustomFieldSummary field;
  final List<CustomFieldValueSummary> values;
  final List<MemberSummary> members;

  @override
  Widget build(BuildContext context) {
    final privacy = field.privacy?.trim();
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: () => showCustomFieldDetailSheet(
          context,
          field: field,
          values: values,
          members: members,
        ),
        leading: const AccentDot(),
        title: Text(
          field.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          [
            field.fieldType,
            '${field.valueCount} values',
            if (privacy != null && privacy.isNotEmpty) privacy,
          ].join(' - '),
          style: const TextStyle(color: _spMuted),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

void showCustomFieldDetailSheet(
  BuildContext context, {
  required CustomFieldSummary field,
  required List<CustomFieldValueSummary> values,
  required List<MemberSummary> members,
}) {
  final namesById = {
    for (final member in members) member.id: member.displayName,
  };
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: _spSurface,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const SpIconBubble(icon: Icons.view_list_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        field.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${field.fieldType} - ${values.length} values',
                        style: const TextStyle(color: _spMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (values.isEmpty)
              const SpEmptyState(
                title: 'No values yet',
                body: 'Imported member values for this field will show here.',
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: values.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, color: _spLine),
                  itemBuilder: (context, index) {
                    final value = values[index];
                    final owner = value.memberId == null
                        ? 'System'
                        : namesById[value.memberId] ?? 'Unknown member';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const SpIconBubble(icon: Icons.person_rounded),
                      title: Text(
                        owner,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        value.value,
                        style: const TextStyle(color: _spMuted),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

void showAddCustomFieldSheet(BuildContext context, HavenRepository repository) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: _spSurface,
    builder: (context) => AddCustomFieldSheet(repository: repository),
  );
}

class AddCustomFieldSheet extends StatefulWidget {
  const AddCustomFieldSheet({super.key, required this.repository});

  final HavenRepository repository;

  @override
  State<AddCustomFieldSheet> createState() => _AddCustomFieldSheetState();
}

class _AddCustomFieldSheetState extends State<AddCustomFieldSheet> {
  final _nameController = TextEditingController();
  final _privacyController = TextEditingController();
  String _fieldType = 'text';

  @override
  void dispose() {
    _nameController.dispose();
    _privacyController.dispose();
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
              'Add custom field',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('custom-field-name-field'),
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              key: const ValueKey('custom-field-type-field'),
              initialValue: _fieldType,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: 'text', child: Text('Text')),
                DropdownMenuItem(value: 'number', child: Text('Number')),
                DropdownMenuItem(value: 'date', child: Text('Date')),
                DropdownMenuItem(value: 'boolean', child: Text('Boolean')),
                DropdownMenuItem(value: 'select', child: Text('Select')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _fieldType = value);
                }
              },
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('custom-field-privacy-field'),
              controller: _privacyController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Privacy',
                hintText: 'private, friends, public',
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              key: const ValueKey('save-custom-field-button'),
              onPressed: _save,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Save field'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    await widget.repository.saveCustomField(
      CustomFieldDraft(
        name: _nameController.text,
        fieldType: _fieldType,
        privacy: _privacyController.text,
      ),
    );
    if (mounted) {
      Navigator.pop(context);
    }
  }
}
