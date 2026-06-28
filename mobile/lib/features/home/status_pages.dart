part of 'home_page.dart';

class LocalPrivacyPage extends StatelessWidget {
  const LocalPrivacyPage({super.key, required this.onSelect});

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
                title: 'Privacy buckets',
                trailing: StatusPill(text: 'local'),
              ),
              SizedBox(height: 8),
              Text(
                'Buckets are kept as local visibility notes until friend sync is enabled.',
                style: TextStyle(color: _spMuted, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SpSettingsGroup(
          title: 'Current buckets',
          rows: [
            const SpSettingsRow(
              'Private',
              'stored on this device',
              interactive: false,
            ),
            const SpSettingsRow(
              'Trusted',
              'ready for future sharing rules',
              interactive: false,
            ),
            const SpSettingsRow(
              'Public',
              'off unless sync is configured',
              interactive: false,
            ),
            SpSettingsRow(
              'Custom fields privacy',
              'edit field-level labels',
              onTap: () => onSelect(SpSection.customFields),
            ),
          ],
        ),
      ],
    );
  }
}

class LocalTokensPage extends StatelessWidget {
  const LocalTokensPage({super.key, required this.onSelect});

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
                title: 'Tokens',
                trailing: StatusPill(text: 'disabled'),
              ),
              SizedBox(height: 8),
              Text(
                'There is no local API token surface yet. Imports do not need a Pluris Haven token.',
                style: TextStyle(color: _spMuted, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SpSettingsGroup(
          title: 'Token status',
          rows: [
            const SpSettingsRow(
              'Local token store',
              'empty',
              interactive: false,
            ),
            SpSettingsRow(
              'PluralKit live import',
              'paste a token during import',
              onTap: () => onSelect(SpSection.importExport),
            ),
            SpSettingsRow(
              'Sync tokens',
              'requires sync setup',
              onTap: () => onSelect(SpSection.sync),
            ),
          ],
        ),
      ],
    );
  }
}

class UserReportPage extends StatelessWidget {
  const UserReportPage({
    super.key,
    required this.snapshot,
    required this.onSelect,
  });

  final HomeSnapshot? snapshot;
  final ValueChanged<SpSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final report = _buildReport(snapshot);

    return SpPage(
      children: [
        SpCard(
          outlined: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SpSectionHeader(
                title: 'User Report',
                trailing: StatusPill(text: 'local'),
              ),
              const SizedBox(height: 8),
              const Text(
                'A small local snapshot you can copy before filing a bug.',
                style: TextStyle(color: _spMuted, height: 1.35),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _copyReport(context, report),
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy report'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SpCard(
          child: SelectableText(
            report,
            style: const TextStyle(color: _spMuted, height: 1.35),
          ),
        ),
        const SizedBox(height: 12),
        SpSettingsGroup(
          title: 'Related',
          rows: [
            SpSettingsRow(
              'Import jobs',
              'open import details and errors',
              onTap: () => onSelect(SpSection.importExport),
            ),
            SpSettingsRow(
              'Notification history',
              'local event log',
              onTap: () => onSelect(SpSection.notificationHistory),
            ),
          ],
        ),
      ],
    );
  }

  String _buildReport(HomeSnapshot? snapshot) {
    final home = snapshot;
    return [
      'Pluris Haven local report',
      'stage: pre-alpha',
      'system: ${home?.systemName ?? 'Local system'}',
      'members: ${home?.memberCount ?? 0}',
      'groups: ${home?.groupCount ?? 0}',
      'notes: ${home?.noteCount ?? 0}',
      'front history: ${home?.frontHistoryCount ?? 0}',
      'current front: ${home?.currentFrontLabel ?? 'none'}',
      'storage: device',
      'sync: off by default',
    ].join('\n');
  }

  Future<void> _copyReport(BuildContext context, String report) async {
    await Clipboard.setData(ClipboardData(text: report));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Report copied')));
    }
  }
}

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({
    super.key,
    required this.snapshot,
    required this.onSelect,
  });

  final HomeSnapshot? snapshot;
  final ValueChanged<SpSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final home = snapshot;

    return SpPage(
      children: [
        SpCard(
          outlined: true,
          child: Row(
            children: [
              SpAvatar(
                size: 52,
                color: Theme.of(context).colorScheme.primary,
                label: 'PH',
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      home?.systemName ?? 'Local system',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'saved on device',
                      style: TextStyle(color: _spMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SpSettingsGroup(
          title: 'Account',
          rows: [
            const SpSettingsRow(
              'Cloud account',
              'not required',
              interactive: false,
            ),
            SpSettingsRow(
              'Import / Export',
              'move data in or out',
              onTap: () => onSelect(SpSection.importExport),
            ),
            SpSettingsRow(
              'App options',
              'theme, language, dashboard',
              onTap: () => onSelect(SpSection.appOptions),
            ),
            SpSettingsRow(
              'Sync',
              'off by default',
              onTap: () => onSelect(SpSection.sync),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const SpSettingsGroup(
          title: 'Security',
          rows: [
            SpSettingsRow('Storage', 'device database', interactive: false),
            SpSettingsRow(
              'Field encryption',
              'local crypto enabled',
              interactive: false,
            ),
            SpSettingsRow(
              'Destructive actions',
              'confirmed with dialogs',
              interactive: false,
            ),
          ],
        ),
      ],
    );
  }
}
