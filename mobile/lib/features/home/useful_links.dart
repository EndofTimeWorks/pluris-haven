part of 'home_page.dart';

class UsefulLinksPage extends StatelessWidget {
  const UsefulLinksPage({super.key, required this.onSelect});

  final ValueChanged<SpSection> onSelect;

  @override
  Widget build(BuildContext context) {
    return SpPage(
      children: [
        const SpCard(
          outlined: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SpSectionHeader(
                title: 'Useful Links',
                trailing: StatusPill(text: 'local'),
              ),
              SizedBox(height: 8),
              Text(
                'Quick places for importing, backing up, support, and project links.',
                style: TextStyle(color: _spMuted, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SpSettingsGroup(
          title: 'In this app',
          rows: [
            SpSettingsRow(
              'Import from Simply Plural',
              'open import setup',
              onTap: () => onSelect(SpSection.importExport),
            ),
            SpSettingsRow(
              'Back up local data',
              'export a device archive',
              onTap: () => onSelect(SpSection.importExport),
            ),
            SpSettingsRow(
              'Customize dashboard',
              'tiles, theme, and language',
              onTap: () => onSelect(SpSection.appOptions),
            ),
            SpSettingsRow(
              'How-to guides',
              'short offline notes',
              onTap: () => onSelect(SpSection.howtos),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SpSettingsGroup(
          title: 'Project',
          rows: [
            SpSettingsRow(
              'Source',
              'github.com/EndofTimeWorks/pluris-haven',
              onTap: () => launchExternalUrl(
                context,
                Uri.https('github.com', '/EndofTimeWorks/pluris-haven'),
              ),
            ),
            SpSettingsRow(
              "What's new",
              'pluris.endoftime.works/changelog',
              onTap: () => launchExternalUrl(
                context,
                Uri.https('pluris.endoftime.works', '/changelog'),
              ),
            ),
            SpSettingsRow(
              'APK releases',
              'github.com/EndofTimeWorks/pluris-haven/releases',
              onTap: () => launchExternalUrl(
                context,
                Uri.https(
                  'github.com',
                  '/EndofTimeWorks/pluris-haven/releases',
                ),
              ),
            ),
            SpSettingsRow(
              'GitHub Sponsors',
              'EndofTimeWorks',
              onTap: () => launchExternalUrl(
                context,
                Uri.https('github.com', '/sponsors/EndofTimeWorks'),
              ),
            ),
            SpSettingsRow(
              'Patreon',
              'patreon.com/EndofTimeWorks',
              onTap: () => launchExternalUrl(
                context,
                Uri.https('patreon.com', '/EndofTimeWorks'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class HowTosPage extends StatelessWidget {
  const HowTosPage({super.key, required this.onSelect});

  final ValueChanged<SpSection> onSelect;

  @override
  Widget build(BuildContext context) {
    return SpPage(
      children: [
        const SpCard(
          outlined: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SpSectionHeader(
                title: "How-to's",
                trailing: StatusPill(text: 'offline'),
              ),
              SizedBox(height: 8),
              Text(
                'Short local notes for the flows people usually need first.',
                style: TextStyle(color: _spMuted, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        HowToCard(
          title: 'Import from Simply Plural',
          steps: [
            'Export your Simply Plural data as JSON.',
            'Open Import / Export and choose the file or paste JSON.',
            'Review the preview, then apply it to the local archive.',
            'Check members, groups, fronts, notes, and avatars after import.',
          ],
          actionLabel: 'Open import',
          onAction: () => onSelect(SpSection.importExport),
        ),
        const SizedBox(height: 10),
        HowToCard(
          title: 'Track a front',
          steps: [
            'Open Dashboard or Front History.',
            'Use Set front to pick members or a saved custom front.',
            'Use Clear when nobody is fronting or the state ended.',
            'Front History keeps the local timeline.',
          ],
          actionLabel: 'Open history',
          onAction: () => onSelect(SpSection.frontHistory),
        ),
        const SizedBox(height: 10),
        HowToCard(
          title: 'Save custom fronts',
          steps: [
            'Open Custom Fronts.',
            'Add statuses like Asleep, Away, or blended front states.',
            'Set them from the dashboard without creating extra members.',
          ],
          actionLabel: 'Open custom fronts',
          onAction: () => onSelect(SpSection.customFronts),
        ),
        const SizedBox(height: 10),
        HowToCard(
          title: 'Back up this device',
          steps: [
            'Open Import / Export.',
            'Create a Pluris Haven archive.',
            'Keep the file somewhere outside this phone too.',
          ],
          actionLabel: 'Open export',
          onAction: () => onSelect(SpSection.importExport),
        ),
        const SizedBox(height: 10),
        HowToCard(
          title: 'Use custom fields',
          steps: [
            'Open Custom Fields.',
            'Add a field like "age", "role", or "species".',
            'Set values per member from their profile.',
            'Fields import from Simply Plural automatically.',
          ],
          actionLabel: 'Open custom fields',
          onAction: () => onSelect(SpSection.customFields),
        ),
        const SizedBox(height: 10),
        HowToCard(
          title: 'Set reminders',
          steps: [
            'Open Reminders.',
            'Pick a daily, weekly, or monthly schedule.',
            'Notifications will fire at the set time.',
            'Turn any reminder off without deleting it.',
          ],
          actionLabel: 'Open reminders',
          onAction: () => onSelect(SpSection.reminders),
        ),
        const SizedBox(height: 10),
        HowToCard(
          title: 'Vote on system decisions',
          steps: [
            'Open Polls and create a new poll.',
            'Add options and choose single or multiple choice.',
            'Share the poll with members in the same space.',
            'Results stay on this device until you delete them.',
          ],
          actionLabel: 'Open polls',
          onAction: () => onSelect(SpSection.polls),
        ),
        const SizedBox(height: 10),
        HowToCard(
          title: 'Import from other apps',
          steps: [
            'Export JSON from PluralKit, Tupperbox, or PluralSpace.',
            'Open Import / Export and upload the file.',
            'Select the matching service from the dropdown.',
            'Preview the records, then import into local storage.',
          ],
          actionLabel: 'Open import',
          onAction: () => onSelect(SpSection.importExport),
        ),
        const SizedBox(height: 10),
        HowToCard(
          title: 'Use subsystems',
          steps: [
            'Open Groups and add or edit a group.',
            'Turn on "Subgroup / subsystem".',
            'Members in subsystems can also be in the main group.',
            'The layers icon shows which groups are subsystems.',
          ],
          actionLabel: 'Open groups',
          onAction: () => onSelect(SpSection.groups),
        ),
      ],
    );
  }
}

class HowToCard extends StatelessWidget {
  const HowToCard({
    super.key,
    required this.title,
    required this.steps,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final List<String> steps;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return SpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < steps.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${i + 1}.',
                  style: const TextStyle(
                    color: _spGold,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    steps[i],
                    style: const TextStyle(color: _spMuted, height: 1.35),
                  ),
                ),
              ],
            ),
            if (i != steps.length - 1) const SizedBox(height: 7),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ),
        ],
      ),
    );
  }
}
