part of 'home_page.dart';

class SyncPage extends StatelessWidget {
  const SyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SpPage(
      children: [
        SpCard(
          outlined: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SpSectionHeader(
                title: 'Sync is off',
                trailing: StatusPill(text: 'local'),
              ),
              SizedBox(height: 8),
              Text(
                'Pluris Haven keeps data on this device unless sync is turned on.',
                style: TextStyle(color: _spMuted, height: 1.35),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        SpSettingsGroup(
          title: 'Sync',
          rows: [
            SpSettingsRow('Encrypted sync', 'not configured'),
            SpSettingsRow('Friends', 'not shared'),
            SpSettingsRow('Backups', 'manual for now'),
          ],
        ),
      ],
    );
  }
}
