import 'package:flutter/material.dart';

import '../../data/import/import_sources.dart';
import '../../data/local/haven_repository.dart';

const _spSurface = Color(0xFF232532);
const _spCard = Color(0xFF2B2E3D);
const _spLine = Color(0xFF3A3E50);
const _spText = Color(0xFFECEAF2);
const _spMuted = Color(0xFFC4C0CE);
const _spPurple = Color(0xFF7B61FF);
const _spGold = Color(0xFFF2C75C);

enum SpSection {
  dashboard('Dashboard'),
  members('Members'),
  frontHistory('Front History'),
  groups('Groups'),
  notes('Notes'),
  analytics('Analytics'),
  chat('Chat'),
  polls('Polls'),
  friends('Friends'),
  usefulLinks('Useful Links'),
  reminders('Reminders'),
  privacyBuckets('Privacy buckets'),
  tokens('Tokens'),
  userReport('User Report'),
  notificationHistory('Notification History'),
  howtos("How-to's"),
  customFields('Custom Fields'),
  accountSettings('Account Settings'),
  importExport('Import / Export'),
  sync('Sync'),
  appOptions('App options'),
  about('About');

  const SpSection(this.label);

  final String label;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.repository});

  final HavenRepository repository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  SpSection _section = SpSection.dashboard;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<HomeSnapshot>(
      stream: widget.repository.watchHomeSnapshot(),
      builder: (context, snapshot) {
        final home = snapshot.data;

        return Scaffold(
          drawer: SpDrawer(
            snapshot: home,
            selected: _section,
            onSelect: _selectSection,
          ),
          appBar: AppBar(
            toolbarHeight: 48,
            titleSpacing: 0,
            title: Text(
              _section.label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          body: StreamBuilder<AppCustomization>(
            stream: widget.repository.watchCustomization(),
            initialData: AppCustomization.defaults,
            builder: (context, customizationSnapshot) {
              return _buildSection(
                home,
                customizationSnapshot.data ?? AppCustomization.defaults,
              );
            },
          ),
        );
      },
    );
  }

  void _selectSection(SpSection section) {
    setState(() {
      _section = section;
    });
  }

  Widget _buildSection(HomeSnapshot? home, AppCustomization customization) {
    switch (_section) {
      case SpSection.dashboard:
        return DashboardPage(
          snapshot: home,
          customization: customization,
          repository: widget.repository,
          onSelect: _selectSection,
        );
      case SpSection.members:
        return MembersPage(snapshot: home);
      case SpSection.frontHistory:
        return FrontHistoryPage(snapshot: home, repository: widget.repository);
      case SpSection.groups:
        return GroupsPage(snapshot: home);
      case SpSection.notes:
        return NotesPage(snapshot: home);
      case SpSection.analytics:
        return const OfflineFeaturePage(
          title: 'Analytics',
          body:
              'Local front and member analytics will be calculated from the device archive.',
          rows: [
            SpSettingsRow('Front time', 'not enough data'),
            SpSettingsRow('Member activity', 'empty'),
            SpSettingsRow('Trends', 'local only'),
          ],
        );
      case SpSection.chat:
        return const OfflineFeaturePage(
          title: 'Chat',
          body:
              'SP chat depends on accounts and sync. Local message boards can live here later.',
          rows: [
            SpSettingsRow('Local board', 'not created'),
            SpSettingsRow('Synced chat', 'off'),
            SpSettingsRow('Attachments', 'local only'),
          ],
        );
      case SpSection.usefulLinks:
        return const OfflineFeaturePage(
          title: 'Useful Links',
          body:
              'Useful SP links and local help pages can live here without accounts.',
          rows: [
            SpSettingsRow('Import guide', 'planned'),
            SpSettingsRow('Local backups', 'planned'),
            SpSettingsRow('Project links', 'local'),
          ],
        );
      case SpSection.polls:
        return const OfflineFeaturePage(
          title: 'Polls',
          body:
              'Polls are kept in the shell so imported SP data has a place to land.',
          rows: [
            SpSettingsRow('Active polls', '0'),
            SpSettingsRow('Closed polls', '0'),
            SpSettingsRow('Poll archive', 'empty'),
          ],
        );
      case SpSection.friends:
        return const OfflineFeaturePage(
          title: 'Friends',
          body: 'Friends are disabled until encrypted sync exists.',
          rows: [
            SpSettingsRow('Friend list', 'not shared'),
            SpSettingsRow('Privacy', 'local only'),
            SpSettingsRow('Requests', 'off'),
          ],
        );
      case SpSection.reminders:
        return const OfflineFeaturePage(
          title: 'Reminders',
          body:
              'Local reminders can work without an account once notifications are wired.',
          rows: [
            SpSettingsRow('One-time reminders', '0'),
            SpSettingsRow('Repeating reminders', '0'),
            SpSettingsRow('Notifications', 'off'),
          ],
        );
      case SpSection.privacyBuckets:
        return const OfflineFeaturePage(
          title: 'Privacy buckets',
          body:
              'SP privacy buckets map cleanly to local sharing profiles later.',
          rows: [
            SpSettingsRow('Private', 'device only'),
            SpSettingsRow('Trusted', 'not synced'),
            SpSettingsRow('Public', 'off'),
          ],
        );
      case SpSection.tokens:
        return const OfflineFeaturePage(
          title: 'Tokens',
          body: 'API tokens are hidden until account sync exists.',
          rows: [
            SpSettingsRow('Local token store', 'empty'),
            SpSettingsRow('API tokens', 'disabled'),
            SpSettingsRow('Import tokens', 'not supported'),
          ],
        );
      case SpSection.userReport:
        return const OfflineFeaturePage(
          title: 'User Report',
          body: 'Reports can be generated from local app logs later.',
          rows: [
            SpSettingsRow('Diagnostics', 'off'),
            SpSettingsRow('Export report', 'not generated'),
            SpSettingsRow('Privacy', 'device only'),
          ],
        );
      case SpSection.notificationHistory:
        return const OfflineFeaturePage(
          title: 'Notification History',
          body:
              'Notification history will show reminders and sync alerts once notifications exist.',
          rows: [
            SpSettingsRow('Unread', '0'),
            SpSettingsRow('Archived', '0'),
            SpSettingsRow('Push notifications', 'off'),
          ],
        );
      case SpSection.howtos:
        return const OfflineFeaturePage(
          title: "How-to's",
          body:
              'Short guides for fronting, importing, backups, and sync will be kept offline.',
          rows: [
            SpSettingsRow('Fronting', 'planned'),
            SpSettingsRow('Importing from SP', 'planned'),
            SpSettingsRow('Backups', 'planned'),
          ],
        );
      case SpSection.customFields:
        return const OfflineFeaturePage(
          title: 'Custom Fields',
          body: 'Custom profile fields from SP imports will appear here.',
          rows: [
            SpSettingsRow('System fields', '0'),
            SpSettingsRow('Member fields', '0'),
            SpSettingsRow('Import mapping', 'planned'),
          ],
        );
      case SpSection.accountSettings:
        return const OfflineFeaturePage(
          title: 'Account Settings',
          body:
              'There is no required cloud account. Local profile settings live here.',
          rows: [
            SpSettingsRow('Local profile', 'saved on device'),
            SpSettingsRow('Security', 'device storage'),
            SpSettingsRow('Connected accounts', 'none'),
          ],
        );
      case SpSection.importExport:
        return const ImportExportPage();
      case SpSection.sync:
        return const SyncPage();
      case SpSection.appOptions:
        return AppOptionsPage(
          customization: customization,
          repository: widget.repository,
        );
      case SpSection.about:
        return const AboutPage();
    }
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.snapshot,
    required this.customization,
    required this.repository,
    required this.onSelect,
  });

  final HomeSnapshot? snapshot;
  final AppCustomization customization;
  final HavenRepository repository;
  final ValueChanged<SpSection> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 24),
      children: [
        SystemListEntry(snapshot: snapshot),
        const SizedBox(height: 10),
        CurrentFrontEntry(snapshot: snapshot, repository: repository),
        const SizedBox(height: 18),
        const DashboardSectionTitle('Main'),
        const SizedBox(height: 8),
        DashboardActionGrid(
          items: _primaryItems(snapshot),
          customization: customization,
          onSelect: onSelect,
        ),
        const SizedBox(height: 18),
        const DashboardSectionTitle('Tools'),
        const SizedBox(height: 8),
        SpCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SpSettingsRow(
                'Import / Export',
                'bring in SP data or back this up',
                onTap: () => onSelect(SpSection.importExport),
              ),
              const Divider(height: 1, color: _spLine, indent: 16),
              SpSettingsRow(
                'Sync',
                'off until you choose otherwise',
                onTap: () => onSelect(SpSection.sync),
              ),
              const Divider(height: 1, color: _spLine, indent: 16),
              SpSettingsRow(
                'Customize',
                'theme, home layout, privacy defaults',
                onTap: () => onSelect(SpSection.appOptions),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<HomeNavigationItem> _primaryItems(HomeSnapshot? home) {
    return [
      HomeNavigationItem(
        'Members',
        '${home?.memberCount ?? 0}',
        SpSection.members,
        Icons.people_alt_rounded,
      ),
      HomeNavigationItem(
        'Front History',
        '${home?.frontHistoryCount ?? 0} entries',
        SpSection.frontHistory,
        Icons.history_rounded,
      ),
      HomeNavigationItem(
        'Groups',
        '${home?.groupCount ?? 0} groups',
        SpSection.groups,
        Icons.folder_rounded,
      ),
      HomeNavigationItem(
        'Notes',
        '${home?.noteCount ?? 0} notes',
        SpSection.notes,
        Icons.sticky_note_2_rounded,
      ),
    ];
  }
}

class MembersPage extends StatelessWidget {
  const MembersPage({super.key, required this.snapshot});

  final HomeSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    return SpPage(
      children: [
        const SpSearchField(hintText: 'Search members'),
        const SizedBox(height: 12),
        const SpFilterRow(filters: ['All', 'Fronting', 'Archived']),
        const SizedBox(height: 12),
        SpCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SpSectionHeader(
                title: 'Members',
                trailing: StatusPill(text: '${snapshot?.memberCount ?? 0}'),
              ),
              const SizedBox(height: 12),
              const SpEmptyState(
                title: 'No members saved locally',
                body: 'Imported Simply Plural members will show up here.',
              ),
              const SizedBox(height: 14),
              const SpActionRow(primary: 'Add member', secondary: 'Import'),
            ],
          ),
        ),
      ],
    );
  }
}

class FrontHistoryPage extends StatelessWidget {
  const FrontHistoryPage({
    super.key,
    required this.snapshot,
    required this.repository,
  });

  final HomeSnapshot? snapshot;
  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
    return SpPage(
      children: [
        CurrentFrontEntry(snapshot: snapshot, repository: repository),
        const SizedBox(height: 12),
        const SpFilterRow(filters: ['Today', 'Week', 'Month', 'All']),
        const SizedBox(height: 12),
        SpCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SpSectionHeader(
                title: 'Front history',
                trailing: StatusPill(
                  text: '${snapshot?.frontHistoryCount ?? 0} entries',
                ),
              ),
              const SizedBox(height: 12),
              const SpEmptyState(
                title: 'No front history yet',
                body: 'Set a front or import an archive to fill this in.',
              ),
              const SizedBox(height: 14),
              const SpActionRow(primary: 'Add entry', secondary: 'Filter'),
            ],
          ),
        ),
      ],
    );
  }
}

class GroupsPage extends StatelessWidget {
  const GroupsPage({super.key, required this.snapshot});

  final HomeSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    return SpPage(
      children: [
        const SpSearchField(hintText: 'Search groups'),
        const SizedBox(height: 12),
        SpCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SpSectionHeader(
                title: 'Groups',
                trailing: StatusPill(text: '${snapshot?.groupCount ?? 0}'),
              ),
              const SizedBox(height: 12),
              const SpEmptyState(
                title: 'No groups yet',
                body: 'Groups keep members organized without needing sync.',
              ),
              const SizedBox(height: 14),
              const SpActionRow(primary: 'Add group', secondary: 'Import'),
            ],
          ),
        ),
      ],
    );
  }
}

class NotesPage extends StatelessWidget {
  const NotesPage({super.key, required this.snapshot});

  final HomeSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    return SpPage(
      children: [
        const SpSearchField(hintText: 'Search notes'),
        const SizedBox(height: 12),
        const SpFilterRow(filters: ['All', 'Pinned', 'Private']),
        const SizedBox(height: 12),
        SpCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SpSectionHeader(
                title: 'Notes',
                trailing: StatusPill(text: '${snapshot?.noteCount ?? 0}'),
              ),
              const SizedBox(height: 12),
              const SpEmptyState(
                title: 'No notes yet',
                body: 'Local notes can be attached to members or kept general.',
              ),
              const SizedBox(height: 14),
              const SpActionRow(primary: 'Add note', secondary: 'Import'),
            ],
          ),
        ),
      ],
    );
  }
}

class ImportExportPage extends StatelessWidget {
  const ImportExportPage({super.key});

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
                title: 'Importers',
                trailing: StatusPill(text: 'dedupe first'),
              ),
              SizedBox(height: 8),
              Text(
                'Every import stages a review and matches against existing members before saving.',
                style: TextStyle(color: _spMuted, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final source in ImportSource.values) ...[
          ImportSourceCard(source: source),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 2),
        const SpSettingsGroup(
          title: 'Export',
          rows: [
            SpSettingsRow('Export local archive', 'portable JSON'),
            SpSettingsRow('Encrypted export', 'password protected'),
            SpSettingsRow('Backup folder', 'choose later'),
          ],
        ),
      ],
    );
  }
}

class ImportSourceCard extends StatelessWidget {
  const ImportSourceCard({super.key, required this.source});

  final ImportSource source;

  @override
  Widget build(BuildContext context) {
    return SpCard(
      onTap: source == ImportSource.pluralKitLive
          ? () => _showPluralKitLiveSheet(context)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SpSectionHeader(
            title: source.label,
            trailing: StatusPill(text: source.status.label),
          ),
          const SizedBox(height: 6),
          Text(
            source.subtitle,
            style: const TextStyle(color: _spMuted, height: 1.35),
          ),
          const SizedBox(height: 12),
          ImportMetaRow(label: 'Input', value: source.inputLabel),
          const SizedBox(height: 8),
          ImportMetaRow(label: 'Job', value: source.jobSource),
          const SizedBox(height: 8),
          ImportMetaRow(label: 'Dedupe', value: source.dedupeLabel),
        ],
      ),
    );
  }

  void _showPluralKitLiveSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: _spSurface,
      builder: (context) => const PluralKitLiveSheet(),
    );
  }
}

class ImportMetaRow extends StatelessWidget {
  const ImportMetaRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: const TextStyle(
              color: _spMuted,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class PluralKitLiveSheet extends StatelessWidget {
  const PluralKitLiveSheet({super.key});

  @override
  Widget build(BuildContext context) {
    const shape = PluralKitLiveImportShape();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'PluralKit live import',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            const Text(
              'Use the pk;token as the Authorization header. Tokens should stay request-scoped for one-shot import and must never be exported.',
              style: TextStyle(color: _spMuted, height: 1.35),
            ),
            const SizedBox(height: 14),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'pk;token',
                helperText: 'Stored later in secure storage',
              ),
            ),
            const SizedBox(height: 14),
            const SpSettingsGroup(
              title: 'Conflict strategy',
              rows: [
                SpSettingsRow('Skip', 'default re-import behavior'),
                SpSettingsRow('Update', 'refresh matched imported fields'),
                SpSettingsRow('Create', 'always append new records'),
              ],
            ),
            const SizedBox(height: 14),
            SpSettingsGroup(
              title: 'First import plan',
              rows: [
                for (final step in shape.firstImportSteps)
                  SpSettingsRow(step, 'local staging'),
              ],
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

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

class AppOptionsPage extends StatelessWidget {
  const AppOptionsPage({
    super.key,
    required this.customization,
    required this.repository,
  });

  final AppCustomization customization;
  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
    return SpPage(
      children: [
        SpSettingsGroup(
          title: 'Customize',
          rows: [
            SpSettingsRow(
              'Theme',
              customization.themeMode.label,
              onTap: () => repository.setThemeMode(
                _nextThemeMode(customization.themeMode),
              ),
            ),
            SpSettingsRow(
              'Accent color',
              customization.accentColor.label,
              trailing: AccentSwatch(
                color: Color(customization.accentColor.argb),
              ),
              onTap: () => repository.setAccentColor(
                _nextAccentColor(customization.accentColor),
              ),
            ),
            SpSwitchRow(
              title: 'Compact dashboard',
              subtitle: 'smaller shortcuts, more room',
              value: customization.compactDashboard,
              onChanged: repository.setCompactDashboard,
            ),
            SpSwitchRow(
              title: 'Dashboard subtitles',
              subtitle: 'show counts under shortcuts',
              value: customization.showDashboardSubtitles,
              onChanged: repository.setShowDashboardSubtitles,
            ),
          ],
        ),
        const SizedBox(height: 12),
        const SpSettingsGroup(
          title: 'Local defaults',
          rows: [
            SpSettingsRow('Language', 'system default'),
            SpSettingsRow('Security', 'device storage'),
            SpSettingsRow('Sync', 'off by default'),
            SpSettingsRow('Accessibility', 'default sizing'),
          ],
        ),
      ],
    );
  }

  HavenThemeMode _nextThemeMode(HavenThemeMode current) {
    return switch (current) {
      HavenThemeMode.dark => HavenThemeMode.light,
      HavenThemeMode.light => HavenThemeMode.system,
      HavenThemeMode.system => HavenThemeMode.dark,
    };
  }

  HavenAccentColor _nextAccentColor(HavenAccentColor current) {
    final values = HavenAccentColor.values;
    final nextIndex = (values.indexOf(current) + 1) % values.length;
    return values[nextIndex];
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SpPage(
      children: [
        SpCard(
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
            SpSettingsRow('Compatibility', 'Simply Plural import planned'),
            SpSettingsRow('Source', 'local project'),
          ],
        ),
      ],
    );
  }
}

class OfflineFeaturePage extends StatelessWidget {
  const OfflineFeaturePage({
    super.key,
    required this.title,
    required this.body,
    required this.rows,
  });

  final String title;
  final String body;
  final List<SpSettingsRow> rows;

  @override
  Widget build(BuildContext context) {
    return SpPage(
      children: [
        SpCard(
          outlined: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SpSectionHeader(
                title: title,
                trailing: const StatusPill(text: 'offline'),
              ),
              const SizedBox(height: 8),
              Text(body, style: const TextStyle(color: _spMuted, height: 1.35)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SpSettingsGroup(title: title, rows: rows),
      ],
    );
  }
}

class SpDrawer extends StatelessWidget {
  const SpDrawer({
    super.key,
    required this.snapshot,
    required this.selected,
    required this.onSelect,
  });

  final HomeSnapshot? snapshot;
  final SpSection selected;
  final ValueChanged<SpSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final home = snapshot;

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
              child: Row(
                children: [
                  const SpAvatar(size: 52, color: _spPurple),
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
                        Text(
                          '${home?.memberCount ?? 0} members - ${home?.groupCount ?? 0} groups',
                          style: const TextStyle(color: _spMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            DrawerEntry(
              label: 'Dashboard',
              section: SpSection.dashboard,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: 'Members',
              section: SpSection.members,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: 'Front History',
              section: SpSection.frontHistory,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: 'Groups',
              section: SpSection.groups,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: 'Notes',
              section: SpSection.notes,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: 'Chat',
              section: SpSection.chat,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: 'Polls',
              section: SpSection.polls,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: 'Friends',
              section: SpSection.friends,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: 'Privacy buckets',
              section: SpSection.privacyBuckets,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: 'Reminders',
              section: SpSection.reminders,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: 'Import / Export',
              section: SpSection.importExport,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: 'Sync',
              section: SpSection.sync,
              selected: selected,
              onSelect: onSelect,
            ),
            const Divider(height: 24),
            DrawerEntry(
              label: 'App options',
              section: SpSection.appOptions,
              selected: selected,
              onSelect: onSelect,
            ),
            DrawerEntry(
              label: 'About',
              section: SpSection.about,
              selected: selected,
              onSelect: onSelect,
            ),
          ],
        ),
      ),
    );
  }
}

class DrawerEntry extends StatelessWidget {
  const DrawerEntry({
    super.key,
    required this.label,
    required this.section,
    required this.selected,
    required this.onSelect,
  });

  final String label;
  final SpSection section;
  final SpSection selected;
  final ValueChanged<SpSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == section;

    return ListTile(
      dense: true,
      selected: isSelected,
      selectedColor: _spText,
      selectedTileColor: _spCard,
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Text('>', style: TextStyle(color: _spMuted)),
      onTap: () {
        Navigator.pop(context);
        onSelect(section);
      },
    );
  }
}

class DashboardSystemHeader extends StatelessWidget {
  const DashboardSystemHeader({super.key, required this.snapshot});

  final HomeSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final home = snapshot;

    return SizedBox(
      height: 58,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const SpAvatar(size: 24, color: _spPurple, label: 'PH'),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                home?.systemName ?? 'Local system',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, color: _spText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SpDashboardTile extends StatelessWidget {
  const SpDashboardTile({
    super.key,
    required this.item,
    required this.compact,
    required this.showSubtitle,
    required this.onTap,
  });

  final HomeNavigationItem item;
  final bool compact;
  final bool showSubtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _spCard,
          foregroundColor: _spText,
          elevation: 0,
          padding: const EdgeInsets.all(10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: _spGold, size: 22),
            SizedBox(height: compact ? 10 : 14),
            Text(
              item.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, height: 1.15),
            ),
            if (showSubtitle && !compact) ...[
              const SizedBox(height: 5),
              Text(
                item.subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _spMuted, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class DashboardSectionTitle extends StatelessWidget {
  const DashboardSectionTitle(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: _spMuted,
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class DashboardActionGrid extends StatelessWidget {
  const DashboardActionGrid({
    super.key,
    required this.items,
    required this.customization,
    required this.onSelect,
  });

  final List<HomeNavigationItem> items;
  final AppCustomization customization;
  final ValueChanged<SpSection> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 170,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.15,
      ),
      children: [
        for (final item in items)
          SpDashboardTile(
            item: item,
            compact: customization.compactDashboard,
            showSubtitle: customization.showDashboardSubtitles,
            onTap: () => onSelect(item.section),
          ),
      ],
    );
  }
}

class SystemListEntry extends StatelessWidget {
  const SystemListEntry({super.key, required this.snapshot});

  final HomeSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final home = snapshot;

    return SpCard(
      child: Row(
        children: [
          const SpAvatar(size: 52, color: _spPurple, label: 'PH'),
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
                Text(
                  '${home?.memberCount ?? 0} members - ${home?.groupCount ?? 0} groups',
                  style: const TextStyle(color: _spMuted, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CurrentFrontEntry extends StatelessWidget {
  const CurrentFrontEntry({
    super.key,
    required this.snapshot,
    required this.repository,
  });

  final HomeSnapshot? snapshot;
  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
    final home = snapshot;

    return SpCard(
      outlined: true,
      onTap: () => _showFrontSheet(context),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 56,
            decoration: BoxDecoration(
              color: _spPurple,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Currently fronting',
                  style: TextStyle(
                    color: _spMuted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  home?.currentFrontText ?? 'None',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _spText,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusPill(text: home?.currentFrontStatus ?? 'none'),
              const SizedBox(height: 8),
              const Text(
                'set front',
                style: TextStyle(color: _spMuted, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showFrontSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: _spSurface,
      builder: (context) => CustomFrontSheet(repository: repository),
    );
  }
}

class CustomFrontSheet extends StatefulWidget {
  const CustomFrontSheet({super.key, required this.repository});

  final HavenRepository repository;

  @override
  State<CustomFrontSheet> createState() => _CustomFrontSheetState();
}

class _CustomFrontSheetState extends State<CustomFrontSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            const Text(
              'Set custom front',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: _setFront,
              decoration: const InputDecoration(labelText: 'Label'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => _setFront(_controller.text),
                    child: const Text('Set'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await widget.repository.clearCurrentFront();
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Clear'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setFront(String label) async {
    await widget.repository.setCustomFront(label);
    if (mounted) {
      Navigator.pop(context);
    }
  }
}

class SpNavigationEntry extends StatelessWidget {
  const SpNavigationEntry({super.key, required this.item, this.onTap});

  final HomeNavigationItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SpCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Row(
        children: [
          SpIconBubble(icon: item.icon),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: const TextStyle(color: _spMuted, fontSize: 14),
                ),
              ],
            ),
          ),
          const Text(
            '>',
            style: TextStyle(
              color: _spMuted,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class SpIconBubble extends StatelessWidget {
  const SpIconBubble({super.key, required this.icon, this.color = _spGold});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      child: SizedBox(
        width: 38,
        height: 38,
        child: Icon(icon, color: color, size: 21),
      ),
    );
  }
}

class SpPage extends StatelessWidget {
  const SpPage({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 24),
      children: children,
    );
  }
}

class SpSearchField extends StatelessWidget {
  const SpSearchField({super.key, required this.hintText});

  final String hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: true,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: _spCard,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _spLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _spPurple),
        ),
      ),
    );
  }
}

class SpFilterRow extends StatelessWidget {
  const SpFilterRow({super.key, required this.filters});

  final List<String> filters;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in filters) ...[
            StatusPill(text: filter),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class SpSectionHeader extends StatelessWidget {
  const SpSectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class SpEmptyState extends StatelessWidget {
  const SpEmptyState({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _spSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _spLine),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(body, style: const TextStyle(color: _spMuted, height: 1.35)),
          ],
        ),
      ),
    );
  }
}

class SpActionRow extends StatelessWidget {
  const SpActionRow({
    super.key,
    required this.primary,
    required this.secondary,
  });

  final String primary;
  final String secondary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FilledButton(onPressed: () {}, child: Text(primary)),
        const SizedBox(width: 10),
        OutlinedButton(onPressed: () {}, child: Text(secondary)),
      ],
    );
  }
}

class SpSettingsGroup extends StatelessWidget {
  const SpSettingsGroup({super.key, required this.title, required this.rows});

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return SpCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1)
              const Divider(height: 1, color: _spLine, indent: 16),
          ],
        ],
      ),
    );
  }
}

class SpSettingsRow extends StatelessWidget {
  const SpSettingsRow(
    this.title,
    this.subtitle, {
    super.key,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          const AccentDot(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: _spMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          trailing ??
              const Text(
                '>',
                style: TextStyle(color: _spMuted, fontWeight: FontWeight.w800),
              ),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return InkWell(onTap: onTap, child: content);
  }
}

class SpSwitchRow extends StatelessWidget {
  const SpSwitchRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      activeThumbColor: Theme.of(context).colorScheme.primary,
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: _spMuted, fontSize: 13),
      ),
    );
  }
}

class AccentSwatch extends StatelessWidget {
  const AccentSwatch({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: const SizedBox(width: 22, height: 22),
    );
  }
}

class SpCard extends StatelessWidget {
  const SpCard({
    super.key,
    required this.child,
    this.onTap,
    this.outlined = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool outlined;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: _spCard,
        borderRadius: BorderRadius.circular(12),
        border: outlined ? Border.all(color: _spLine) : null,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class SpAvatar extends StatelessWidget {
  const SpAvatar({
    super.key,
    required this.size,
    required this.color,
    this.label,
  });

  final double size;
  final Color color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: label == null
          ? null
          : Text(
              label!,
              style: TextStyle(
                color: _spText,
                fontSize: size * 0.3,
                fontWeight: FontWeight.w900,
              ),
            ),
    );
  }
}

class AccentDot extends StatelessWidget {
  const AccentDot({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: _spGold, shape: BoxShape.circle),
      child: SizedBox(width: 20, height: 20),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _spSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          text,
          style: const TextStyle(color: _spMuted, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class HomeNavigationItem {
  const HomeNavigationItem(this.title, this.subtitle, this.section, this.icon);

  final String title;
  final String subtitle;
  final SpSection section;
  final IconData icon;
}
