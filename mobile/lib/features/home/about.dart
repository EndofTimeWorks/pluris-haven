part of 'home_page.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SpPage(
      children: [
        const SpCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pluris Haven',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 8),
              Text(
                'Offline-first plural system tracker.',
                style: TextStyle(color: _spMuted, height: 1.35),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        SpSettingsGroup(
          title: 'About',
          rows: [
            SpSettingsRow('Storage', 'saved on device'),
            SpSettingsRow(
              'Compatibility',
              'Simply Plural, PluralKit, OpenPlural',
              trailing: SizedBox.shrink(),
              interactive: false,
            ),
            SpSettingsRow(
              'Source',
              'github.com/EndofTimeWorks/pluris-haven',
              onTap: () => launchExternalUrl(
                context,
                Uri.https('github.com', '/EndofTimeWorks/pluris-haven'),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        SpSettingsGroup(
          title: 'Optional support',
          rows: [
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
        SizedBox(height: 12),
        SpCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Monero',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('copy-monero-address-button'),
                    tooltip: 'Copy Monero address',
                    onPressed: () => _copyMoneroAddress(context),
                    icon: const Icon(Icons.copy_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const SelectableText(
                _moneroAddress,
                style: TextStyle(color: _spMuted, fontSize: 12, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

const _moneroAddress =
    '85xURN4NDUbULxsVcVMA8EQSLDonAYvuc945g1sQckZvXXeTXg9dLnB7tHmNqKEUFzGEkquDqCTuHS1Ca9yPCjXcNXrTvvZ';

void _copyMoneroAddress(BuildContext context) {
  final messenger = ScaffoldMessenger.of(context);
  Clipboard.setData(const ClipboardData(text: _moneroAddress));
  messenger.showSnackBar(
    const SnackBar(content: Text('Monero address copied')),
  );
}

Future<void> launchExternalUrl(BuildContext context, Uri url) async {
  final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Could not open $url')));
  }
}

Future<void> confirmDelete(
  BuildContext context, {
  required String title,
  required String body,
  required Future<void> Function() onDelete,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    await onDelete();
  }
}
