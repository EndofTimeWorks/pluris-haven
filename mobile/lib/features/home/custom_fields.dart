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
                    style: const TextStyle(color: _spMuted, height: 1.35),
                  ),
                  const SizedBox(height: 14),
                  if (fields.isEmpty)
                    const SpEmptyState(
                      title: 'No custom fields yet',
                      body: 'SP custom fields will show here after import.',
                    )
                  else
                    for (var index = 0; index < fields.length; index++) ...[
                      CustomFieldTile(field: fields[index]),
                      if (index != fields.length - 1)
                        const Divider(height: 1, color: _spLine),
                    ],
                  const SizedBox(height: 14),
                  SpActionRow(
                    primary: 'Import',
                    secondary: 'Add field',
                    onPrimary: onImport,
                    onSecondary: () => showPlannedFeaturePopup(
                      context,
                      title: 'Custom field editor',
                      detail:
                          'Creating and editing custom fields locally is planned next. Imported fields are readable now.',
                    ),
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
  const CustomFieldTile({super.key, required this.field});

  final CustomFieldSummary field;

  @override
  Widget build(BuildContext context) {
    final privacy = field.privacy?.trim();
    return ListTile(
      contentPadding: EdgeInsets.zero,
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
    );
  }
}
