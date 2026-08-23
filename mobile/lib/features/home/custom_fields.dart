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
    final l10n = AppLocalizations.of(context);
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
                            title: l10n.navigationCustomFields,
                            trailing: StatusPill(text: '${fields.length}'),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            fields.isEmpty
                                ? l10n.customFieldsImportDescription
                                : l10n.customFieldsWithValues(fieldsWithValues),
                            style: const TextStyle(
                              color: _spMuted,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (fields.isEmpty)
                            SpEmptyState(
                              title: l10n.noCustomFieldsYet,
                              body: l10n.customFieldsEmptyBody,
                            )
                          else
                            for (
                              var index = 0;
                              index < fields.length;
                              index++
                            ) ...[
                              CustomFieldTile(
                                repository: repository,
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
                            primary: l10n.importTitle,
                            secondary: l10n.addFieldButton,
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
    required this.repository,
    required this.field,
    required this.values,
    required this.members,
  });

  final HavenRepository repository;
  final CustomFieldSummary field;
  final List<CustomFieldValueSummary> values;
  final List<MemberSummary> members;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final privacy = field.privacy?.trim();
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: () => showCustomFieldDetailSheet(
          context,
          repository: repository,
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
            l10n.valueCount(field.valueCount),
            if (privacy != null && privacy.isNotEmpty) privacy,
          ].join(' - '),
          style: const TextStyle(color: _spMuted),
        ),
        trailing: PopupMenuButton<String>(
          tooltip: l10n.customFieldActionsTooltip,
          onSelected: (value) {
            if (value == 'edit') {
              showCustomFieldSheet(context, repository, field: field);
            } else if (value == 'delete') {
              confirmDelete(
                context,
                title: l10n.deleteCustomFieldTitle,
                body: l10n.deleteCustomFieldBody(field.name, field.valueCount),
                onDelete: () => repository.deleteCustomField(field.id),
              );
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'edit', child: Text(l10n.editButton)),
            PopupMenuItem(value: 'delete', child: Text(l10n.deleteButton)),
          ],
        ),
      ),
    );
  }
}

void showCustomFieldDetailSheet(
  BuildContext context, {
  required HavenRepository repository,
  required CustomFieldSummary field,
  required List<CustomFieldValueSummary> values,
  required List<MemberSummary> members,
}) {
  final namesById = {
    for (final member in members) member.id: member.displayName,
  };
  CustomFieldValueSummary? systemValue;
  for (final value in values) {
    if (value.memberId == null) {
      systemValue = value;
      break;
    }
  }
  final memberValues = values
      .where((value) => value.memberId != null)
      .toList(growable: false);

  void openValueEditor(CustomFieldValueSummary? value, String? memberId) {
    Navigator.pop(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) {
        return;
      }
      showCustomFieldValueSheet(
        context,
        repository: repository,
        field: field,
        value: value,
        memberId: memberId,
      );
    });
  }

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      return SafeArea(
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
                          l10n.customFieldValueSummary(
                            field.fieldType,
                            values.length,
                          ),
                          style: const TextStyle(color: _spMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                key: const ValueKey('custom-field-system-value-row'),
                contentPadding: EdgeInsets.zero,
                leading: const SpIconBubble(icon: Icons.home_work_rounded),
                title: Text(
                  l10n.systemLabel,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  systemValue == null || systemValue.value.trim().isEmpty
                      ? l10n.notSetLabel
                      : systemValue.value,
                  style: const TextStyle(color: _spMuted),
                ),
                trailing: const Icon(Icons.edit_rounded, size: 18),
                onTap: () => openValueEditor(systemValue, null),
              ),
              if (memberValues.isNotEmpty)
                const Divider(height: 1, color: _spLine),
              if (memberValues.isEmpty)
                SpEmptyState(
                  title: l10n.noMemberValuesYet,
                  body: l10n.memberValuesEmptyBody,
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: memberValues.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: _spLine),
                    itemBuilder: (context, index) {
                      final value = memberValues[index];
                      final memberId = value.memberId;
                      final owner =
                          namesById[memberId] ?? l10n.unknownMemberLabel;
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
                        trailing: const Icon(Icons.edit_rounded, size: 18),
                        onTap: () => openValueEditor(value, memberId),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

void showAddCustomFieldSheet(BuildContext context, HavenRepository repository) {
  showCustomFieldSheet(context, repository);
}

void showCustomFieldSheet(
  BuildContext context,
  HavenRepository repository, {
  CustomFieldSummary? field,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (context) =>
        AddCustomFieldSheet(repository: repository, field: field),
  );
}

class AddCustomFieldSheet extends StatefulWidget {
  const AddCustomFieldSheet({super.key, required this.repository, this.field});

  final HavenRepository repository;
  final CustomFieldSummary? field;

  @override
  State<AddCustomFieldSheet> createState() => _AddCustomFieldSheetState();
}

class _AddCustomFieldSheetState extends State<AddCustomFieldSheet> {
  final _nameController = TextEditingController();
  final _privacyController = TextEditingController();
  String _fieldType = 'text';
  bool get _isEditing => widget.field != null;

  @override
  void initState() {
    super.initState();
    final field = widget.field;
    if (field == null) {
      return;
    }
    _nameController.text = field.name;
    _privacyController.text = field.privacy ?? '';
    _fieldType = field.fieldType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _privacyController.dispose();
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
              l10n.customFieldTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              _isEditing
                  ? l10n.editCustomFieldDescription
                  : l10n.createCustomFieldDescription,
              style: const TextStyle(color: _spMuted, height: 1.35),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('custom-field-name-field'),
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: l10n.nameFieldLabel),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              key: const ValueKey('custom-field-type-field'),
              initialValue: _fieldType,
              decoration: InputDecoration(labelText: l10n.typeFieldLabel),
              items: [
                DropdownMenuItem(value: 'text', child: Text(l10n.textType)),
                DropdownMenuItem(value: 'number', child: Text(l10n.numberType)),
                DropdownMenuItem(value: 'date', child: Text(l10n.dateType)),
                DropdownMenuItem(
                  value: 'boolean',
                  child: Text(l10n.booleanType),
                ),
                DropdownMenuItem(value: 'select', child: Text(l10n.selectType)),
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
              decoration: InputDecoration(
                labelText: l10n.privacyFieldLabel,
                hintText: l10n.privacyOptionsHint,
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              key: const ValueKey('save-custom-field-button'),
              onPressed: _save,
              icon: Icon(_isEditing ? Icons.save_outlined : Icons.add_rounded),
              label: Text(
                _isEditing ? l10n.saveFieldButton : l10n.createFieldButton,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final draft = CustomFieldDraft(
      name: _nameController.text,
      fieldType: _fieldType,
      privacy: _privacyController.text,
    );
    final field = widget.field;
    if (field == null) {
      await widget.repository.saveCustomField(draft);
    } else {
      await widget.repository.updateCustomField(field.id, draft);
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }
}
