part of 'home_page.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SpPage(
      children: [
        SpCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pluris Haven',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.appTagline,
                style: const TextStyle(color: _spMuted, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SpSettingsGroup(
          title: l10n.aboutGroupTitle,
          rows: [
            SpSettingsRow(l10n.storageLabel, l10n.storageValue),
            SpSettingsRow(
              l10n.compatibilityLabel,
              'Simply Plural, PluralKit, OpenPlural',
              trailing: const SizedBox.shrink(),
              interactive: false,
            ),
            SpSettingsRow(
              l10n.sourceLabel,
              'github.com/EndofTimeWorks/pluris-haven',
              onTap: () => launchExternalUrl(
                context,
                Uri.https('github.com', '/EndofTimeWorks/pluris-haven'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SpSettingsGroup(
          title: l10n.optionalSupportTitle,
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
                    tooltip: l10n.copyMoneroTooltip,
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
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  Clipboard.setData(const ClipboardData(text: _moneroAddress));
  messenger.showSnackBar(SnackBar(content: Text(l10n.moneroAddressCopied)));
}

Future<void> launchExternalUrl(BuildContext context, Uri url) async {
  final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.couldNotOpenUrl(url.toString()))),
    );
  }
}

Future<void> confirmDelete(
  BuildContext context, {
  required String title,
  required String body,
  required Future<void> Function() onDelete,
}) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.deleteButtonLabel),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    await onDelete();
  }
}
