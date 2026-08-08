part of 'home_page.dart';

class SyncPage extends StatelessWidget {
  const SyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SpPage(
      children: [
        SpCard(
          outlined: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SpSectionHeader(
                title: l10n.syncOffTitle,
                trailing: StatusPill(text: l10n.localStatusPill),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.syncOffDescription,
                style: const TextStyle(color: _spMuted, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SpSettingsGroup(
          title: l10n.syncRowTitle,
          rows: [
            SpSettingsRow(l10n.encryptedSyncLabel, l10n.encryptedSyncValue),
            SpSettingsRow(l10n.friendsLabel, l10n.friendsValue),
            SpSettingsRow(l10n.backupsLabel, l10n.backupsValue),
          ],
        ),
      ],
    );
  }
}
