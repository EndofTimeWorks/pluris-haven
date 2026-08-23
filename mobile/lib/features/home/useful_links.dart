part of 'home_page.dart';

class UsefulLinksPage extends StatelessWidget {
  const UsefulLinksPage({super.key, required this.onSelect});

  final ValueChanged<SpSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return SpPage(
      children: [
        SpCard(
          outlined: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SpSectionHeader(
                title: l10n.navigationUsefulLinks,
                trailing: StatusPill(text: l10n.localStatusLabel),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.usefulLinksDescription,
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SpSettingsGroup(
          title: l10n.inThisAppTitle,
          rows: [
            SpSettingsRow(
              l10n.importFromSimplyPluralTitle,
              l10n.openImportSetupSubtitle,
              onTap: () => onSelect(SpSection.importExport),
            ),
            SpSettingsRow(
              l10n.backUpLocalDataTitle,
              l10n.exportDeviceArchiveSubtitle,
              onTap: () => onSelect(SpSection.importExport),
            ),
            SpSettingsRow(
              l10n.customizeDashboardTitle,
              l10n.dashboardOptionsSubtitle,
              onTap: () => onSelect(SpSection.appOptions),
            ),
            SpSettingsRow(
              l10n.howToGuidesTitle,
              l10n.shortOfflineNotesSubtitle,
              onTap: () => onSelect(SpSection.howtos),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SpSettingsGroup(
          title: l10n.projectTitle,
          rows: [
            SpSettingsRow(
              l10n.sourceTitle,
              'github.com/EndofTimeWorks/pluris-haven',
              onTap: () => launchExternalUrl(
                context,
                Uri.https('github.com', '/EndofTimeWorks/pluris-haven'),
              ),
            ),
            SpSettingsRow(
              l10n.whatsNewTitle,
              'pluris.endoftime.works/changelog',
              onTap: () => launchExternalUrl(
                context,
                Uri.https('pluris.endoftime.works', '/changelog'),
              ),
            ),
            SpSettingsRow(
              l10n.apkReleasesTitle,
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
              l10n.githubSponsorsTitle,
              'EndofTimeWorks',
              onTap: () => launchExternalUrl(
                context,
                Uri.https('github.com', '/sponsors/EndofTimeWorks'),
              ),
            ),
            SpSettingsRow(
              l10n.patreonTitle,
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
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return SpPage(
      children: [
        SpCard(
          outlined: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SpSectionHeader(
                title: l10n.navigationHowTos,
                trailing: StatusPill(text: l10n.offlineStatusLabel),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.howTosDescription,
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        HowToCard(
          title: l10n.importFromSimplyPluralTitle,
          steps: [
            l10n.howToImportSimplyPluralStep1,
            l10n.howToImportSimplyPluralStep2,
            l10n.howToImportSimplyPluralStep3,
            l10n.howToImportSimplyPluralStep4,
          ],
          actionLabel: l10n.openImportAction,
          onAction: () => onSelect(SpSection.importExport),
        ),
        const SizedBox(height: 10),
        HowToCard(
          title: l10n.trackFrontTitle,
          steps: [
            l10n.howToTrackFrontStep1,
            l10n.howToTrackFrontStep2,
            l10n.howToTrackFrontStep3,
            l10n.howToTrackFrontStep4,
          ],
          actionLabel: l10n.openHistoryAction,
          onAction: () => onSelect(SpSection.frontHistory),
        ),
        const SizedBox(height: 10),
        HowToCard(
          title: l10n.saveCustomFrontsTitle,
          steps: [
            l10n.howToCustomFrontsStep1,
            l10n.howToCustomFrontsStep2,
            l10n.howToCustomFrontsStep3,
          ],
          actionLabel: l10n.openCustomFrontsAction,
          onAction: () => onSelect(SpSection.customFronts),
        ),
        const SizedBox(height: 10),
        HowToCard(
          title: l10n.backUpDeviceTitle,
          steps: [
            l10n.howToBackupStep1,
            l10n.howToBackupStep2,
            l10n.howToBackupStep3,
          ],
          actionLabel: l10n.openExportAction,
          onAction: () => onSelect(SpSection.importExport),
        ),
        const SizedBox(height: 10),
        HowToCard(
          title: l10n.useCustomFieldsTitle,
          steps: [
            l10n.howToCustomFieldsStep1,
            l10n.howToCustomFieldsStep2,
            l10n.howToCustomFieldsStep3,
            l10n.howToCustomFieldsStep4,
          ],
          actionLabel: l10n.openCustomFieldsAction,
          onAction: () => onSelect(SpSection.customFields),
        ),
        const SizedBox(height: 10),
        HowToCard(
          title: l10n.setRemindersTitle,
          steps: [
            l10n.howToRemindersStep1,
            l10n.howToRemindersStep2,
            l10n.howToRemindersStep3,
            l10n.howToRemindersStep4,
          ],
          actionLabel: l10n.openRemindersAction,
          onAction: () => onSelect(SpSection.reminders),
        ),
        const SizedBox(height: 10),
        HowToCard(
          title: l10n.voteOnDecisionsTitle,
          steps: [
            l10n.howToPollsStep1,
            l10n.howToPollsStep2,
            l10n.howToPollsStep3,
            l10n.howToPollsStep4,
          ],
          actionLabel: l10n.openPollsAction,
          onAction: () => onSelect(SpSection.polls),
        ),
        const SizedBox(height: 10),
        HowToCard(
          title: l10n.importOtherAppsTitle,
          steps: [
            l10n.howToOtherImportsStep1,
            l10n.howToOtherImportsStep2,
            l10n.howToOtherImportsStep3,
            l10n.howToOtherImportsStep4,
          ],
          actionLabel: l10n.openImportAction,
          onAction: () => onSelect(SpSection.importExport),
        ),
        const SizedBox(height: 10),
        HowToCard(
          title: l10n.useSubsystemsTitle,
          steps: [
            l10n.howToSubsystemsStep1,
            l10n.howToSubsystemsStep2,
            l10n.howToSubsystemsStep3,
            l10n.howToSubsystemsStep4,
          ],
          actionLabel: l10n.openGroupsAction,
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
