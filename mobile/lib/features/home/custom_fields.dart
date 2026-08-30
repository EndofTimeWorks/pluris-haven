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
    final scheme = Theme.of(context).colorScheme;
    return StreamBuilder<List<CustomFieldSummary>>(
      stream: repository.watchCustomFields(),
      initialData: const [],
      builder: (context, snapshot) {
        final fields = snapshot.data ?? const <CustomFieldSummary>[];
        final fieldsWithValues = fields
            .where((field) => field.valueCount > 0)
            .length;

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
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
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
                    for (var index = 0; index < fields.length; index++) ...[
                      CustomFieldTile(
                        repository: repository,
                        field: fields[index],
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
  }
}

class CustomFieldTile extends StatelessWidget {
  const CustomFieldTile({
    super.key,
    required this.repository,
    required this.field,
  });

  final HavenRepository repository;
  final CustomFieldSummary field;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final privacy = field.privacy?.trim();
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: () => showCustomFieldDetailSheet(
          context,
          repository: repository,
          field: field,
        ),
        leading: const AccentDot(),
        title: Text(
          field.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          [
            customFieldTypeLabel(l10n, field.fieldType),
            l10n.valueCount(field.valueCount),
            if (privacy != null && privacy.isNotEmpty) privacy,
          ].join(' - '),
          style: TextStyle(color: scheme.onSurfaceVariant),
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
}) {
  final originContext = context;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (context) => _CustomFieldDetailSheet(
      repository: repository,
      field: field,
      originContext: originContext,
    ),
  );
}

class _CustomFieldDetailSheet extends StatelessWidget {
  const _CustomFieldDetailSheet({
    required this.repository,
    required this.field,
    required this.originContext,
  });

  final HavenRepository repository;
  final CustomFieldSummary field;
  final BuildContext originContext;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CustomFieldValueSummary>>(
      stream: repository.watchCustomFieldValues(fieldId: field.id),
      initialData: const [],
      builder: (context, valuesSnapshot) {
        final values = valuesSnapshot.data ?? const [];
        final hasMemberValues = values.any((value) => value.memberId != null);
        if (!hasMemberValues) return _buildContent(context, values, const []);
        return StreamBuilder<List<MemberSummary>>(
          stream: repository.watchMembers(includeArchived: true),
          initialData: const [],
          builder: (context, membersSnapshot) =>
              _buildContent(context, values, membersSnapshot.data ?? const []),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<CustomFieldValueSummary> values,
    List<MemberSummary> members,
  ) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final namesById = {
      for (final member in members) member.id: member.displayName,
    };
    final systemValue = values
        .where((value) => value.memberId == null)
        .firstOrNull;
    final memberValues = values
        .where((value) => value.memberId != null)
        .toList(growable: false);

    void openValueEditor(CustomFieldValueSummary? value, String? memberId) {
      Navigator.pop(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!originContext.mounted) return;
        showCustomFieldValueSheet(
          originContext,
          repository: repository,
          field: field,
          value: value,
          memberId: memberId,
        );
      });
    }

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
                          customFieldTypeLabel(l10n, field.fieldType),
                          values.length,
                        ),
                        style: TextStyle(color: scheme.onSurfaceVariant),
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
              subtitle: CustomFieldValueDisplay(
                field: field,
                value: systemValue,
                emptyLabel: l10n.notSetLabel,
                style: TextStyle(color: scheme.onSurfaceVariant),
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
                      Divider(height: 1, color: scheme.outlineVariant),
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
                      subtitle: CustomFieldValueDisplay(
                        field: field,
                        value: value,
                        style: TextStyle(color: scheme.onSurfaceVariant),
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
  }
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
  final _choicesController = TextEditingController();
  final _configurationController = TextEditingController();
  final _customTypeController = TextEditingController();
  String _fieldType = 'text';
  String? _typeError;
  String? _choicesError;
  String? _configurationError;
  late bool _showConfiguration;
  bool get _isEditing => widget.field != null;

  @override
  void initState() {
    super.initState();
    final field = widget.field;
    _showConfiguration = field?.configuration.isNotEmpty ?? false;
    if (field == null) {
      return;
    }
    _nameController.text = field.name;
    _privacyController.text = field.privacy ?? '';
    if (customFieldTypes.contains(field.fieldType)) {
      _fieldType = field.fieldType;
    } else {
      _fieldType = _customFieldTypeSentinel;
      _customTypeController.text = field.fieldType;
    }
    _choicesController.text = customFieldChoices(field).join('\n');
    if (field.configuration.isNotEmpty) {
      _configurationController.text = const JsonEncoder.withIndent(
        '  ',
      ).convert(field.configuration);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _privacyController.dispose();
    _choicesController.dispose();
    _configurationController.dispose();
    _customTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .85,
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
                l10n.customFieldTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isEditing
                    ? l10n.editCustomFieldDescription
                    : l10n.createCustomFieldDescription,
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.35),
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
                items: _customFieldTypeItems(l10n),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _fieldType = value;
                      _typeError = null;
                      _choicesError = null;
                    });
                  }
                },
              ),
              if (_fieldType == _customFieldTypeSentinel) ...[
                const SizedBox(height: 10),
                TextField(
                  key: const ValueKey('custom-field-type-id-field'),
                  controller: _customTypeController,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: l10n.customFieldTypeIdLabel,
                    hintText: l10n.customFieldTypeIdHint,
                    errorText: _typeError,
                  ),
                ),
              ],
              if (_fieldType == 'select' || _fieldType == 'multiselect') ...[
                const SizedBox(height: 10),
                TextField(
                  key: const ValueKey('custom-field-choices-field'),
                  controller: _choicesController,
                  minLines: 3,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: l10n.customFieldChoicesLabel,
                    hintText: l10n.customFieldChoicesHint,
                    errorText: _choicesError,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              if (_showConfiguration)
                TextField(
                  key: const ValueKey('custom-field-configuration-field'),
                  controller: _configurationController,
                  autocorrect: false,
                  minLines: 3,
                  maxLines: 8,
                  decoration: InputDecoration(
                    labelText: l10n.customFieldConfigurationLabel,
                    hintText: l10n.customFieldConfigurationHint,
                    errorText: _configurationError,
                  ),
                )
              else
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _showConfiguration = true),
                    icon: const Icon(Icons.tune_rounded),
                    label: Text(l10n.customFieldConfigurationLabel),
                  ),
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
                icon: Icon(
                  _isEditing ? Icons.save_outlined : Icons.add_rounded,
                ),
                label: Text(
                  _isEditing ? l10n.saveFieldButton : l10n.createFieldButton,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final selectedType = _fieldType == _customFieldTypeSentinel
        ? _customTypeController.text.trim()
        : _fieldType;
    if (selectedType.isEmpty) {
      setState(() => _typeError = l10n.customFieldTypeIdRequired);
      return;
    }
    final choices = _parseCustomFieldChoices(_choicesController.text);
    if (choices.length > 100) {
      setState(() => _choicesError = l10n.customFieldChoicesTooMany);
      return;
    }
    if (choices.any((choice) => choice.length > 100)) {
      setState(() => _choicesError = l10n.customFieldChoiceTooLong);
      return;
    }
    final configurationText = _configurationController.text.trim();
    final configuration = <String, Object?>{};
    if (configurationText.isNotEmpty) {
      try {
        final decoded = jsonDecode(configurationText);
        if (decoded is! Map) {
          setState(
            () => _configurationError =
                l10n.customFieldConfigurationObjectRequired,
          );
          return;
        }
        configuration.addAll(Map<String, Object?>.from(decoded));
      } on FormatException {
        setState(() => _configurationError = l10n.customFieldInvalidJson);
        return;
      } on TypeError {
        setState(
          () =>
              _configurationError = l10n.customFieldConfigurationObjectRequired,
        );
        return;
      }
    }
    if (selectedType == 'select' || selectedType == 'multiselect') {
      configuration['choices'] = choices;
    } else if (widget.field?.fieldType == 'select' ||
        widget.field?.fieldType == 'multiselect') {
      configuration.remove('choices');
    }
    if (jsonEncode(configuration).length >
        maximumCustomFieldConfigurationCharacters) {
      setState(
        () => _configurationError = l10n.customFieldConfigurationTooLarge,
      );
      return;
    }
    final draft = CustomFieldDraft(
      name: _nameController.text,
      fieldType: selectedType,
      privacy: _privacyController.text,
      configuration: configuration,
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

const _customFieldTypeSentinel = '__custom__';

List<DropdownMenuItem<String>> _customFieldTypeItems(AppLocalizations l10n) => [
  DropdownMenuItem(value: 'text', child: Text(l10n.textType)),
  DropdownMenuItem(value: 'long_text', child: Text(l10n.longTextType)),
  DropdownMenuItem(value: 'markdown', child: Text(l10n.markdownType)),
  DropdownMenuItem(value: 'number', child: Text(l10n.numberType)),
  DropdownMenuItem(value: 'date', child: Text(l10n.dateType)),
  DropdownMenuItem(value: 'datetime', child: Text(l10n.dateTimeType)),
  DropdownMenuItem(value: 'boolean', child: Text(l10n.booleanType)),
  DropdownMenuItem(value: 'url', child: Text(l10n.urlType)),
  DropdownMenuItem(value: 'color', child: Text(l10n.colorType)),
  DropdownMenuItem(value: 'select', child: Text(l10n.selectType)),
  DropdownMenuItem(value: 'multiselect', child: Text(l10n.multiselectType)),
  DropdownMenuItem(value: 'json', child: Text(l10n.jsonType)),
  DropdownMenuItem(
    value: _customFieldTypeSentinel,
    child: Text(l10n.customFieldType),
  ),
];

String customFieldTypeLabel(AppLocalizations l10n, String type) =>
    switch (type) {
      'text' => l10n.textType,
      'long_text' => l10n.longTextType,
      'markdown' => l10n.markdownType,
      'number' => l10n.numberType,
      'date' => l10n.dateType,
      'datetime' => l10n.dateTimeType,
      'boolean' => l10n.booleanType,
      'url' => l10n.urlType,
      'color' => l10n.colorType,
      'select' => l10n.selectType,
      'multiselect' => l10n.multiselectType,
      'json' => l10n.jsonType,
      _ => type,
    };

List<String> customFieldChoices(CustomFieldSummary field) {
  Object? choices = field.configuration['choices'];
  final options = field.configuration['options'];
  if (choices == null && options is Map) choices = options['choices'];
  if (choices is! List) return const [];
  return [
    for (final choice in choices)
      if (choice is String && choice.trim().isNotEmpty) choice.trim(),
  ];
}

List<String> _parseCustomFieldChoices(String text) {
  final seen = <String>{};
  final choices = <String>[];
  for (final line in text.split('\n')) {
    final choice = line.trim();
    if (choice.isEmpty || !seen.add(choice.toLowerCase())) continue;
    choices.add(choice);
  }
  return choices;
}

class CustomFieldValueDisplay extends StatelessWidget {
  const CustomFieldValueDisplay({
    super.key,
    required this.field,
    required this.value,
    this.emptyLabel = '',
    this.style,
  });

  final CustomFieldSummary field;
  final CustomFieldValueSummary? value;
  final String emptyLabel;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final text = value?.displayValue.trim() ?? '';
    if (text.isEmpty) return Text(emptyLabel, style: style);
    if (field.fieldType == 'markdown') {
      return MarkdownBody(
        data: text,
        selectable: true,
        shrinkWrap: true,
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
          p: style,
          a: style?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
        ),
        imageBuilder: (uri, title, alt) => Semantics(
          label: AppLocalizations.of(context).markdownImageBlockedLabel,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hide_image_outlined, size: 16),
              if (alt != null && alt.isNotEmpty) ...[
                const SizedBox(width: 4),
                Flexible(child: Text(alt, style: style)),
              ],
            ],
          ),
        ),
        onTapLink: (label, href, title) => _openCustomFieldLink(href),
      );
    }
    if (field.fieldType == 'url') {
      return InkWell(
        onTap: () => _openCustomFieldLink(text),
        child: Text(
          text,
          style: style?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
        ),
      );
    }
    if (field.fieldType == 'color') {
      final color = _customFieldColor(text);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (color != null) ...[
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(child: Text(text, style: style)),
        ],
      );
    }
    return Text(text, style: style);
  }
}

Future<void> _openCustomFieldLink(String? value) async {
  final uri = Uri.tryParse(value ?? '');
  if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Color? _customFieldColor(String value) {
  final normalized = value.trim().replaceFirst('#', '');
  if (!RegExp(r'^[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$').hasMatch(normalized)) {
    return null;
  }
  final argb = normalized.length == 6 ? 'ff$normalized' : normalized;
  return Color(int.parse(argb, radix: 16));
}
