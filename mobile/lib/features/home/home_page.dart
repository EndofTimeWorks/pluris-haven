import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/import/import_plan.dart';
import '../../data/import/import_preview.dart';
import '../../data/import/import_sources.dart';
import '../../data/local/haven_repository.dart';
import '../../data/local/supported_language.dart';

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
        return MembersPage(snapshot: home, repository: widget.repository);
      case SpSection.frontHistory:
        return FrontHistoryPage(snapshot: home, repository: widget.repository);
      case SpSection.groups:
        return GroupsPage(snapshot: home, repository: widget.repository);
      case SpSection.notes:
        return NotesPage(snapshot: home, repository: widget.repository);
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
        return MessagesPage(repository: widget.repository);
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
        return RemindersPage(repository: widget.repository);
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
        return NotificationHistoryPage(repository: widget.repository);
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
        return ImportExportPage(repository: widget.repository);
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
          items: _dashboardItems(snapshot, customization.dashboardShortcutIds),
          customization: customization,
          onSelect: onSelect,
        ),
        if (customization.dashboardShortcutIds.isEmpty) ...[
          const SizedBox(height: 10),
          const SpEmptyState(
            title: 'No dashboard shortcuts',
            body: 'Open Customize to add shortcuts back.',
          ),
        ],
      ],
    );
  }

  List<HomeNavigationItem> _dashboardItems(
    HomeSnapshot? home,
    List<String> ids,
  ) {
    final definitions = {for (final item in dashboardShortcuts) item.id: item};

    return [
      for (final id in ids)
        if (definitions[id] case final definition?) definition.item(home),
    ];
  }
}

const dashboardShortcuts = [
  DashboardShortcutDefinition(
    id: 'members',
    title: 'Members',
    section: SpSection.members,
    icon: Icons.people_alt_rounded,
    countKind: DashboardCountKind.members,
  ),
  DashboardShortcutDefinition(
    id: 'front-history',
    title: 'Front History',
    section: SpSection.frontHistory,
    icon: Icons.history_rounded,
    countKind: DashboardCountKind.frontHistory,
  ),
  DashboardShortcutDefinition(
    id: 'groups',
    title: 'Groups',
    section: SpSection.groups,
    icon: Icons.folder_rounded,
    countKind: DashboardCountKind.groups,
  ),
  DashboardShortcutDefinition(
    id: 'notes',
    title: 'Notes',
    section: SpSection.notes,
    icon: Icons.sticky_note_2_rounded,
    countKind: DashboardCountKind.notes,
  ),
  DashboardShortcutDefinition(
    id: 'import-export',
    title: 'Import / Export',
    subtitle: 'local archive',
    section: SpSection.importExport,
    icon: Icons.archive_rounded,
  ),
  DashboardShortcutDefinition(
    id: 'sync',
    title: 'Sync',
    subtitle: 'off by default',
    section: SpSection.sync,
    icon: Icons.sync_disabled_rounded,
  ),
  DashboardShortcutDefinition(
    id: 'customize',
    title: 'Customize',
    subtitle: 'layout and theme',
    section: SpSection.appOptions,
    icon: Icons.tune_rounded,
  ),
  DashboardShortcutDefinition(
    id: 'analytics',
    title: 'Analytics',
    subtitle: 'local stats',
    section: SpSection.analytics,
    icon: Icons.analytics_rounded,
  ),
  DashboardShortcutDefinition(
    id: 'reminders',
    title: 'Reminders',
    subtitle: '0 scheduled',
    section: SpSection.reminders,
    icon: Icons.notification_add_rounded,
  ),
  DashboardShortcutDefinition(
    id: 'custom-fields',
    title: 'Custom Fields',
    subtitle: 'profile fields',
    section: SpSection.customFields,
    icon: Icons.table_rows_rounded,
  ),
  DashboardShortcutDefinition(
    id: 'friends',
    title: 'Friends',
    subtitle: 'sync required',
    section: SpSection.friends,
    icon: Icons.people_rounded,
  ),
  DashboardShortcutDefinition(
    id: 'chat',
    title: 'Chat',
    subtitle: 'offline board',
    section: SpSection.chat,
    icon: Icons.chat_rounded,
  ),
  DashboardShortcutDefinition(
    id: 'polls',
    title: 'Polls',
    subtitle: '0 active',
    section: SpSection.polls,
    icon: Icons.how_to_vote_rounded,
  ),
];

enum DashboardCountKind { members, frontHistory, groups, notes }

class DashboardShortcutDefinition {
  const DashboardShortcutDefinition({
    required this.id,
    required this.title,
    required this.section,
    required this.icon,
    this.subtitle,
    this.countKind,
  });

  final String id;
  final String title;
  final SpSection section;
  final IconData icon;
  final String? subtitle;
  final DashboardCountKind? countKind;

  HomeNavigationItem item(HomeSnapshot? home) {
    return HomeNavigationItem(title, _subtitle(home), section, icon);
  }

  String _subtitle(HomeSnapshot? home) {
    return switch (countKind) {
      DashboardCountKind.members => '${home?.memberCount ?? 0}',
      DashboardCountKind.frontHistory =>
        '${home?.frontHistoryCount ?? 0} entries',
      DashboardCountKind.groups => '${home?.groupCount ?? 0} groups',
      DashboardCountKind.notes => '${home?.noteCount ?? 0} notes',
      null => subtitle ?? '',
    };
  }
}

class MembersPage extends StatelessWidget {
  const MembersPage({
    super.key,
    required this.snapshot,
    required this.repository,
  });

  final HomeSnapshot? snapshot;
  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MemberSummary>>(
      stream: repository.watchMembers(),
      initialData: const [],
      builder: (context, membersSnapshot) {
        final members = membersSnapshot.data ?? const <MemberSummary>[];

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
                  if (members.isEmpty)
                    const SpEmptyState(
                      title: 'No members saved locally',
                      body:
                          'Add members here or import a Simply Plural export.',
                    )
                  else
                    for (final member in members) ...[
                      MemberListTile(member: member, repository: repository),
                      if (member != members.last)
                        const Divider(height: 1, color: _spLine),
                    ],
                  const SizedBox(height: 14),
                  SpActionRow(
                    primary: 'Add member',
                    secondary: 'Import',
                    onPrimary: () => showAddMemberSheet(context, repository),
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

class MemberListTile extends StatelessWidget {
  const MemberListTile({
    super.key,
    required this.member,
    required this.repository,
  });

  final MemberSummary member;
  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: SpAvatar(size: 42, color: _memberColor(member), label: _initial),
      title: Text(
        member.displayName,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        member.pronouns?.isNotEmpty == true ? member.pronouns! : 'no pronouns',
        style: const TextStyle(color: _spMuted),
      ),
      trailing: PopupMenuButton<String>(
        tooltip: 'Member actions',
        onSelected: (value) {
          if (value == 'front') {
            repository.setFrontMembers([member.id]);
          } else if (value == 'archive') {
            repository.archiveMember(member.id);
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'front', child: Text('Set front')),
          PopupMenuItem(value: 'archive', child: Text('Archive')),
        ],
      ),
    );
  }

  String get _initial {
    return _initialFor(member.displayName);
  }

  Color _memberColor(MemberSummary member) {
    return _colorFromHex(member.colorHex);
  }
}

String _initialFor(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();
}

Color _colorFromHex(String? colorHex, {Color fallback = _spPurple}) {
  final value = colorHex?.replaceFirst('#', '');
  if (value == null || value.length != 6) {
    return fallback;
  }

  final parsed = int.tryParse('FF$value', radix: 16);
  return parsed == null ? fallback : Color(parsed);
}

void showAddMemberSheet(BuildContext context, HavenRepository repository) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: _spSurface,
    builder: (context) => AddMemberSheet(repository: repository),
  );
}

class AddMemberSheet extends StatefulWidget {
  const AddMemberSheet({super.key, required this.repository});

  final HavenRepository repository;

  @override
  State<AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<AddMemberSheet> {
  final _nameController = TextEditingController();
  final _pronounsController = TextEditingController();
  final _descriptionController = TextEditingController();
  HavenAccentColor _color = HavenAccentColor.purple;

  @override
  void dispose() {
    _nameController.dispose();
    _pronounsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          18,
          0,
          18,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add member',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('member-name-field'),
              controller: _nameController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('member-pronouns-field'),
              controller: _pronounsController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Pronouns'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final color in HavenAccentColor.values)
                  ChoiceChip(
                    label: Text(color.label),
                    selected: _color == color,
                    onSelected: (_) => setState(() => _color = color),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            FilledButton(
              key: const ValueKey('save-member-button'),
              onPressed: _save,
              child: const Text('Save member'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    await widget.repository.saveMember(
      MemberDraft(
        displayName: _nameController.text,
        pronouns: _pronounsController.text,
        colorHex: '#${_color.argb.toRadixString(16).substring(2)}',
        description: _descriptionController.text,
      ),
    );

    if (mounted) {
      Navigator.pop(context);
    }
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
    return StreamBuilder<List<FrontHistoryEntry>>(
      stream: repository.watchFrontHistory(),
      initialData: const [],
      builder: (context, historySnapshot) {
        final entries = historySnapshot.data ?? const <FrontHistoryEntry>[];

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
                  if (entries.isEmpty)
                    const SpEmptyState(
                      title: 'No front history yet',
                      body: 'Set a front or import an archive to fill this in.',
                    )
                  else
                    for (final entry in entries) ...[
                      FrontHistoryTile(entry: entry),
                      if (entry != entries.last)
                        const Divider(height: 1, color: _spLine),
                    ],
                  const SizedBox(height: 14),
                  SpActionRow(
                    primary: 'Add entry',
                    secondary: 'Filter',
                    onPrimary: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      backgroundColor: _spSurface,
                      builder: (context) =>
                          CustomFrontSheet(repository: repository),
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

class FrontHistoryTile extends StatelessWidget {
  const FrontHistoryTile({super.key, required this.entry});

  final FrontHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: SpIconBubble(
        icon: entry.isActive
            ? Icons.radio_button_checked_rounded
            : Icons.history_rounded,
      ),
      title: Text(
        entry.label,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        _frontTimingLabel(entry),
        style: const TextStyle(color: _spMuted),
      ),
    );
  }
}

String _frontTimingLabel(FrontHistoryEntry entry) {
  final started = _shortDateTime(entry.startedAt);
  if (entry.endedAt == null) {
    return 'started $started - active';
  }

  return 'started $started - ended ${_shortDateTime(entry.endedAt!)}';
}

String _shortDateTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.month}/${local.day} $hour:$minute';
}

class GroupsPage extends StatelessWidget {
  const GroupsPage({
    super.key,
    required this.snapshot,
    required this.repository,
  });

  final HomeSnapshot? snapshot;
  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<GroupSummary>>(
      stream: repository.watchGroups(),
      initialData: const [],
      builder: (context, groupSnapshot) {
        final groups = groupSnapshot.data ?? const <GroupSummary>[];

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
                  if (groups.isEmpty)
                    const SpEmptyState(
                      title: 'No groups yet',
                      body:
                          'Groups keep members organized without needing sync.',
                    )
                  else
                    for (final group in groups) ...[
                      GroupListTile(group: group),
                      if (group != groups.last)
                        const Divider(height: 1, color: _spLine),
                    ],
                  const SizedBox(height: 14),
                  SpActionRow(
                    primary: 'Add group',
                    secondary: 'Import',
                    onPrimary: () => showAddGroupSheet(context, repository),
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

class GroupListTile extends StatelessWidget {
  const GroupListTile({super.key, required this.group});

  final GroupSummary group;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: SpAvatar(
        size: 42,
        color: _colorFromHex(group.colorHex, fallback: _spGold),
        label: group.emoji?.trim().isNotEmpty == true
            ? group.emoji!.trim()
            : _initialFor(group.name),
      ),
      title: Text(
        group.name,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        group.description?.isNotEmpty == true
            ? group.description!
            : 'no description',
        style: const TextStyle(color: _spMuted),
      ),
    );
  }
}

void showAddGroupSheet(BuildContext context, HavenRepository repository) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: _spSurface,
    builder: (context) => AddGroupSheet(repository: repository),
  );
}

class AddGroupSheet extends StatefulWidget {
  const AddGroupSheet({super.key, required this.repository});

  final HavenRepository repository;

  @override
  State<AddGroupSheet> createState() => _AddGroupSheetState();
}

class _AddGroupSheetState extends State<AddGroupSheet> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _emojiController = TextEditingController();
  HavenAccentColor _color = HavenAccentColor.gold;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          18,
          0,
          18,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add group',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('group-name-field'),
              controller: _nameController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('group-emoji-field'),
              controller: _emojiController,
              maxLength: 4,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Emoji'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final color in HavenAccentColor.values)
                  ChoiceChip(
                    label: Text(color.label),
                    selected: _color == color,
                    onSelected: (_) => setState(() => _color = color),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            FilledButton(
              key: const ValueKey('save-group-button'),
              onPressed: _save,
              child: const Text('Save group'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    await widget.repository.saveGroup(
      GroupDraft(
        name: _nameController.text,
        emoji: _emojiController.text,
        colorHex: '#${_color.argb.toRadixString(16).substring(2)}',
        description: _descriptionController.text,
      ),
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }
}

class NotesPage extends StatelessWidget {
  const NotesPage({
    super.key,
    required this.snapshot,
    required this.repository,
  });

  final HomeSnapshot? snapshot;
  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NoteSummary>>(
      stream: repository.watchNotes(),
      initialData: const [],
      builder: (context, noteSnapshot) {
        final notes = noteSnapshot.data ?? const <NoteSummary>[];

        return SpPage(
          children: [
            const SpSearchField(hintText: 'Search notes'),
            const SizedBox(height: 12),
            const SpFilterRow(filters: ['All', 'Member', 'System']),
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
                  if (notes.isEmpty)
                    const SpEmptyState(
                      title: 'No notes yet',
                      body:
                          'Local notes can be attached to members or kept general.',
                    )
                  else
                    for (final note in notes) ...[
                      NoteListTile(note: note),
                      if (note != notes.last)
                        const Divider(height: 1, color: _spLine),
                    ],
                  const SizedBox(height: 14),
                  SpActionRow(
                    primary: 'Add note',
                    secondary: 'Import',
                    onPrimary: () => showAddNoteSheet(context, repository),
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

class NoteListTile extends StatelessWidget {
  const NoteListTile({super.key, required this.note});

  final NoteSummary note;

  @override
  Widget build(BuildContext context) {
    final body = note.body.trim();

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const SpIconBubble(icon: Icons.sticky_note_2_outlined),
      title: Text(
        note.title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        body.isEmpty ? 'empty note' : body,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: _spMuted),
      ),
    );
  }
}

void showAddNoteSheet(BuildContext context, HavenRepository repository) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: _spSurface,
    builder: (context) => AddNoteSheet(repository: repository),
  );
}

class AddNoteSheet extends StatefulWidget {
  const AddNoteSheet({super.key, required this.repository});

  final HavenRepository repository;

  @override
  State<AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends State<AddNoteSheet> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          18,
          0,
          18,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add note',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('note-title-field'),
              controller: _titleController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('note-body-field'),
              controller: _bodyController,
              minLines: 5,
              maxLines: 8,
              decoration: const InputDecoration(labelText: 'Note'),
            ),
            const SizedBox(height: 14),
            FilledButton(
              key: const ValueKey('save-note-button'),
              onPressed: _save,
              child: const Text('Save note'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    await widget.repository.saveNote(
      NoteDraft(title: _titleController.text, body: _bodyController.text),
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }
}

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key, required this.repository});

  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MessageSummary>>(
      stream: repository.watchMessages(),
      initialData: const [],
      builder: (context, snapshot) {
        final messages = snapshot.data ?? const <MessageSummary>[];

        return SpPage(
          children: [
            SpCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SpSectionHeader(
                    title: 'Messages',
                    trailing: StatusPill(text: '${messages.length}'),
                  ),
                  const SizedBox(height: 12),
                  if (messages.isEmpty)
                    const SpEmptyState(
                      title: 'No messages yet',
                      body: 'Leave local notes for the system here.',
                    )
                  else
                    for (final message in messages) ...[
                      MessageTile(message: message),
                      if (message != messages.last)
                        const Divider(height: 1, color: _spLine),
                    ],
                  const SizedBox(height: 14),
                  SpActionRow(
                    primary: 'Add message',
                    secondary: 'Import',
                    onPrimary: () => showAddMessageSheet(context, repository),
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

class MessageTile extends StatelessWidget {
  const MessageTile({super.key, required this.message});

  final MessageSummary message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message.body, style: const TextStyle(height: 1.35)),
          const SizedBox(height: 4),
          Text(
            _shortDateTime(message.createdAt),
            style: const TextStyle(color: _spMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

void showAddMessageSheet(BuildContext context, HavenRepository repository) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: _spSurface,
    builder: (context) => AddMessageSheet(repository: repository),
  );
}

class AddMessageSheet extends StatefulWidget {
  const AddMessageSheet({super.key, required this.repository});

  final HavenRepository repository;

  @override
  State<AddMessageSheet> createState() => _AddMessageSheetState();
}

class _AddMessageSheetState extends State<AddMessageSheet> {
  final _bodyController = TextEditingController();

  @override
  void dispose() {
    _bodyController.dispose();
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
              'Add message',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('message-body-field'),
              controller: _bodyController,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Message'),
            ),
            const SizedBox(height: 14),
            FilledButton(
              key: const ValueKey('save-message-button'),
              onPressed: _save,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    await widget.repository.saveMessage(
      MessageDraft(body: _bodyController.text),
    );
    if (mounted) {
      Navigator.pop(context);
    }
  }
}

class RemindersPage extends StatelessWidget {
  const RemindersPage({super.key, required this.repository});

  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReminderSummary>>(
      stream: repository.watchReminders(),
      initialData: const [],
      builder: (context, snapshot) {
        final reminders = snapshot.data ?? const <ReminderSummary>[];

        return SpPage(
          children: [
            SpCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SpSectionHeader(
                    title: 'Reminders',
                    trailing: StatusPill(text: '${reminders.length}'),
                  ),
                  const SizedBox(height: 12),
                  if (reminders.isEmpty)
                    const SpEmptyState(
                      title: 'No reminders yet',
                      body:
                          'Create local reminders before notification scheduling is wired.',
                    )
                  else
                    for (final reminder in reminders) ...[
                      ReminderTile(reminder: reminder),
                      if (reminder != reminders.last)
                        const Divider(height: 1, color: _spLine),
                    ],
                  const SizedBox(height: 14),
                  SpActionRow(
                    primary: 'Add reminder',
                    secondary: 'Notification settings',
                    onPrimary: () => showAddReminderSheet(context, repository),
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

class ReminderTile extends StatelessWidget {
  const ReminderTile({super.key, required this.reminder});

  final ReminderSummary reminder;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            reminder.enabled
                ? Icons.notifications_active_rounded
                : Icons.notifications_off_rounded,
            color: _spGold,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  reminder.scheduleText,
                  style: const TextStyle(color: _spMuted, fontSize: 12),
                ),
                if (reminder.body?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  Text(reminder.body!, style: const TextStyle(height: 1.35)),
                ],
              ],
            ),
          ),
          StatusPill(text: reminder.enabled ? 'on' : 'off'),
        ],
      ),
    );
  }
}

void showAddReminderSheet(BuildContext context, HavenRepository repository) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: _spSurface,
    builder: (context) => AddReminderSheet(repository: repository),
  );
}

class AddReminderSheet extends StatefulWidget {
  const AddReminderSheet({super.key, required this.repository});

  final HavenRepository repository;

  @override
  State<AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<AddReminderSheet> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _scheduleController = TextEditingController(text: 'Daily');

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _scheduleController.dispose();
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
              'Add reminder',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('reminder-title-field'),
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('reminder-schedule-field'),
              controller: _scheduleController,
              decoration: const InputDecoration(
                labelText: 'Schedule',
                helperText: 'Example: Daily, Weekly, After Iris fronts',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('reminder-body-field'),
              controller: _bodyController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Note'),
            ),
            const SizedBox(height: 14),
            FilledButton(
              key: const ValueKey('save-reminder-button'),
              onPressed: _save,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    await widget.repository.saveReminder(
      ReminderDraft(
        title: _titleController.text,
        body: _bodyController.text,
        scheduleText: _scheduleController.text,
      ),
    );
    if (mounted) {
      Navigator.pop(context);
    }
  }
}

class NotificationHistoryPage extends StatelessWidget {
  const NotificationHistoryPage({super.key, required this.repository});

  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NotificationEventSummary>>(
      stream: repository.watchNotificationEvents(),
      initialData: const [],
      builder: (context, snapshot) {
        final events = snapshot.data ?? const <NotificationEventSummary>[];

        return SpPage(
          children: [
            SpCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SpSectionHeader(
                    title: 'Notification history',
                    trailing: StatusPill(text: '${events.length}'),
                  ),
                  const SizedBox(height: 12),
                  if (events.isEmpty)
                    const SpEmptyState(
                      title: 'No notifications yet',
                      body:
                          'Front notifications and reminders will be recorded here.',
                    )
                  else
                    for (final event in events) ...[
                      NotificationEventTile(event: event),
                      if (event != events.last)
                        const Divider(height: 1, color: _spLine),
                    ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class NotificationEventTile extends StatelessWidget {
  const NotificationEventTile({super.key, required this.event});

  final NotificationEventSummary event;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.notifications_rounded, color: _spGold, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(event.body, style: const TextStyle(height: 1.35)),
                const SizedBox(height: 4),
                Text(
                  '${event.kind} - ${_shortDateTime(event.createdAt)}',
                  style: const TextStyle(color: _spMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          if (event.isUnread) const StatusPill(text: 'new'),
        ],
      ),
    );
  }
}

class ImportExportPage extends StatefulWidget {
  const ImportExportPage({super.key, required this.repository});

  final HavenRepository repository;

  @override
  State<ImportExportPage> createState() => _ImportExportPageState();
}

class _ImportExportPageState extends State<ImportExportPage> {
  ImportSource _source = ImportSource.simplyPlural;
  ImportConflictStrategy _strategy = ImportConflictStrategy.skip;
  String? _fileName;
  int? _fileSize;
  String? _fileText;
  ImportFileGuess? _guess;
  ImportPreview? _preview;

  ImportSourcePlan get _plan => importPlanFor(_source);

  @override
  Widget build(BuildContext context) {
    final plan = _plan;

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
        ImportSetupCard(
          source: _source,
          strategy: _strategy,
          fileName: _fileName,
          fileSize: _fileSize,
          guess: _guess,
          preview: _preview,
          plan: plan,
          onPickFile: _pickImportFile,
          onSourceChanged: _selectImportSource,
          onStrategyChanged: (strategy) => setState(() => _strategy = strategy),
        ),
        const SizedBox(height: 12),
        ImportPlanCard(plan: plan),
        if (_preview != null) ...[
          const SizedBox(height: 12),
          ImportPreviewCard(
            preview: _preview!,
            onApply: _preview!.source == ImportSource.plurisHavenArchive
                ? _applyLocalArchive
                : null,
          ),
        ],
        const SizedBox(height: 2),
        SpSettingsGroup(
          title: 'Export',
          rows: [
            SpSettingsRow(
              'Export local archive',
              'portable JSON',
              onTap: () => showLocalArchiveSheet(context, widget.repository),
            ),
            const SpSettingsRow('Encrypted export', 'password protected'),
            const SpSettingsRow('Backup folder', 'choose later'),
          ],
        ),
      ],
    );
  }

  Future<void> _pickImportFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Choose import file',
      type: FileType.custom,
      allowedExtensions: ['json', 'zip', 'prism', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty || !mounted) {
      return;
    }

    final file = result.files.single;
    final text = _decodeFileText(file.bytes);
    final guess = guessImportSourceFromFile(
      fileName: file.name,
      textPreview: text,
    );
    final preview = text == null
        ? null
        : previewImportText(
            fileName: file.name,
            text: text,
            selectedSource: guess.source,
          );

    setState(() {
      _fileName = file.name;
      _fileSize = file.size;
      _fileText = text;
      _guess = guess;
      _preview = preview;
      if (guess.source != null) {
        _source = guess.source!;
      }
    });
  }

  void _selectImportSource(ImportSource source) {
    final fileName = _fileName;
    final text = _fileText;

    setState(() {
      _source = source;
      _preview = fileName == null || text == null
          ? null
          : previewImportText(
              fileName: fileName,
              text: text,
              selectedSource: source,
            );
    });
  }

  String? _decodeFileText(Uint8List? bytes) {
    if (bytes == null || bytes.isEmpty) {
      return null;
    }

    return utf8.decode(bytes, allowMalformed: true);
  }

  Future<void> _applyLocalArchive() async {
    final text = _fileText;
    if (text == null) {
      return;
    }

    await widget.repository.importLocalArchiveJson(
      text,
      strategy: _strategy,
      fileName: _fileName,
    );

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Archive imported')));
    }
  }
}

void showLocalArchiveSheet(BuildContext context, HavenRepository repository) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: _spSurface,
    builder: (context) => LocalArchiveSheet(repository: repository),
  );
}

class LocalArchiveSheet extends StatelessWidget {
  const LocalArchiveSheet({super.key, required this.repository});

  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<String>(
        future: repository.buildLocalArchiveJson(),
        builder: (context, snapshot) {
          final archive = snapshot.data;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              18,
              0,
              18,
              18 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Local archive',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'JSON export for backup or migration. It includes local members, groups, notes, fronts, and app preferences.',
                  style: TextStyle(color: _spMuted, height: 1.35),
                ),
                const SizedBox(height: 14),
                if (snapshot.connectionState != ConnectionState.done)
                  const Center(child: CircularProgressIndicator())
                else if (snapshot.hasError)
                  Text(
                    'Could not build archive: ${snapshot.error}',
                    style: const TextStyle(color: _spMuted),
                  )
                else ...[
                  FilledButton.icon(
                    key: const ValueKey('copy-local-archive-button'),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: archive!));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Archive copied')),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy JSON'),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 320),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _spSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _spLine),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        archive!,
                        style: const TextStyle(
                          color: _spMuted,
                          fontFamily: 'monospace',
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class ImportSetupCard extends StatelessWidget {
  const ImportSetupCard({
    super.key,
    required this.source,
    required this.strategy,
    required this.fileName,
    required this.fileSize,
    required this.guess,
    required this.preview,
    required this.plan,
    required this.onPickFile,
    required this.onSourceChanged,
    required this.onStrategyChanged,
  });

  final ImportSource source;
  final ImportConflictStrategy strategy;
  final String? fileName;
  final int? fileSize;
  final ImportFileGuess? guess;
  final ImportPreview? preview;
  final ImportSourcePlan plan;
  final VoidCallback onPickFile;
  final ValueChanged<ImportSource> onSourceChanged;
  final ValueChanged<ImportConflictStrategy> onStrategyChanged;

  @override
  Widget build(BuildContext context) {
    return SpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SpSectionHeader(
            title: 'Import setup',
            trailing: StatusPill(text: plan.status.label),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            key: const ValueKey('choose-import-file-button'),
            onPressed: onPickFile,
            icon: const Icon(Icons.upload_file_rounded),
            label: Text(
              fileName == null ? 'Upload file' : 'Choose another file',
            ),
          ),
          if (fileName != null) ...[
            const SizedBox(height: 10),
            ImportFileSummary(
              fileName: fileName!,
              fileSize: fileSize,
              guess: guess,
            ),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<ImportSource>(
            key: const ValueKey('import-source-dropdown'),
            initialValue: source,
            decoration: const InputDecoration(labelText: 'Service'),
            items: [
              for (final source in ImportSource.values)
                DropdownMenuItem(value: source, child: Text(source.label)),
            ],
            onChanged: (source) {
              if (source != null) {
                onSourceChanged(source);
              }
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<ImportConflictStrategy>(
            initialValue: strategy,
            decoration: const InputDecoration(labelText: 'When a match exists'),
            items: [
              for (final strategy in ImportConflictStrategy.values)
                DropdownMenuItem(value: strategy, child: Text(strategy.label)),
            ],
            onChanged: (strategy) {
              if (strategy != null) {
                onStrategyChanged(strategy);
              }
            },
          ),
          if (plan.requiresToken) ...[
            const SizedBox(height: 10),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'pk;token',
                helperText: 'Used for live import; not exported.',
              ),
            ),
          ],
          if (plan.requiresPassphrase) ...[
            const SizedBox(height: 10),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Passphrase',
                helperText: 'Used locally to decrypt the preview.',
              ),
            ),
          ],
          const SizedBox(height: 12),
          ImportMetaRow(label: 'Input', value: source.inputLabel),
          const SizedBox(height: 8),
          ImportMetaRow(label: 'Job', value: source.jobSource),
          const SizedBox(height: 8),
          ImportMetaRow(label: 'Dedupe', value: source.dedupeLabel),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.fact_check_rounded),
            label: Text(
              preview == null ? 'Preview import' : 'Preview ready - write next',
            ),
          ),
        ],
      ),
    );
  }
}

class ImportFileSummary extends StatelessWidget {
  const ImportFileSummary({
    super.key,
    required this.fileName,
    required this.fileSize,
    required this.guess,
  });

  final String fileName;
  final int? fileSize;
  final ImportFileGuess? guess;

  @override
  Widget build(BuildContext context) {
    final detected = guess?.source;
    final label = detected == null
        ? 'Choose service'
        : '${detected.label} (${((guess?.confidence ?? 0) * 100).round()}%)';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _spSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _spLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(fileName, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            [
              if (fileSize != null) _formatBytes(fileSize!),
              guess?.reason ?? 'waiting for detection',
            ].join(' - '),
            style: const TextStyle(color: _spMuted, fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 8),
          StatusPill(text: label),
        ],
      ),
    );
  }
}

class ImportPreviewCard extends StatelessWidget {
  const ImportPreviewCard({super.key, required this.preview, this.onApply});

  final ImportPreview preview;
  final Future<void> Function()? onApply;

  @override
  Widget build(BuildContext context) {
    final notableEvents = preview.warningsAndErrors;

    return SpCard(
      outlined: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SpSectionHeader(
            title: 'Preview',
            trailing: StatusPill(
              text: preview.canApply ? 'valid shape' : 'needs attention',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${preview.source.label} - ${preview.fileName}',
            style: const TextStyle(color: _spMuted, height: 1.35),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in preview.counts.entries)
                if (entry.value > 0)
                  StatusPill(text: '${entry.key}: ${entry.value}'),
              if (!preview.counts.values.any((count) => count > 0))
                const StatusPill(text: 'no records found'),
            ],
          ),
          if (notableEvents.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (final event in notableEvents) ...[
              Text(
                '${event.stage}: ${event.message}',
                style: TextStyle(
                  color: event.severity == ImportPreviewSeverity.error
                      ? Theme.of(context).colorScheme.error
                      : _spMuted,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 6),
            ],
          ],
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: preview.canApply && onApply != null
                ? () async => onApply!()
                : null,
            icon: const Icon(Icons.restore_rounded),
            label: Text(
              onApply == null ? 'Write support coming next' : 'Import archive',
            ),
          ),
        ],
      ),
    );
  }
}

class ImportPlanCard extends StatelessWidget {
  const ImportPlanCard({super.key, required this.plan});

  final ImportSourcePlan plan;

  @override
  Widget build(BuildContext context) {
    return SpCard(
      outlined: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SpSectionHeader(
            title: '${plan.source.label} plan',
            trailing: StatusPill(
              text: plan.canPreviewOffline
                  ? 'offline preview'
                  : 'needs network',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final count in plan.previewCounts)
                StatusPill(text: count.label),
            ],
          ),
          const SizedBox(height: 14),
          for (final step in plan.steps) ...[
            Text(
              step.title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 3),
            Text(
              step.detail,
              style: const TextStyle(
                color: _spMuted,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
          ],
          const Divider(height: 18),
          for (final note in plan.privacyNotes) ...[
            Text(
              note,
              style: const TextStyle(
                color: _spMuted,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
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

String _formatBytes(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
            SpSettingsRow(
              'Language',
              customization.language.label,
              key: const ValueKey('language-setting-row'),
              onTap: () => showLanguagePicker(
                context,
                selectedCode: customization.languageCode,
                repository: repository,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DashboardShortcutManager(
          customization: customization,
          repository: repository,
        ),
        const SizedBox(height: 12),
        const SpSettingsGroup(
          title: 'Local defaults',
          rows: [
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

void showLanguagePicker(
  BuildContext context, {
  required String selectedCode,
  required HavenRepository repository,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: _spSurface,
    builder: (context) =>
        LanguagePickerSheet(selectedCode: selectedCode, repository: repository),
  );
}

class LanguagePickerSheet extends StatelessWidget {
  const LanguagePickerSheet({
    super.key,
    required this.selectedCode,
    required this.repository,
  });

  final String selectedCode;
  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        children: [
          const Text(
            'Choose your language',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Interface text stays English until translations are added.',
            style: TextStyle(color: _spMuted, height: 1.35),
          ),
          const SizedBox(height: 14),
          for (final language in supportedLanguages)
            SpLanguageOption(
              key: ValueKey('language-option-${language.code}'),
              language: language,
              selected: language.code == selectedCode,
              onTap: () async {
                await repository.setLanguageCode(language.code);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
            ),
        ],
      ),
    );
  }
}

class SpLanguageOption extends StatelessWidget {
  const SpLanguageOption({
    super.key,
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final SupportedLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? _spLine : _spCard,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          title: Text(
            language.label,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            language.code,
            style: const TextStyle(color: _spMuted),
          ),
          trailing: selected
              ? Icon(
                  Icons.check_circle_rounded,
                  color: Theme.of(context).colorScheme.primary,
                )
              : null,
          onTap: onTap,
        ),
      ),
    );
  }
}

class DashboardShortcutManager extends StatelessWidget {
  const DashboardShortcutManager({
    super.key,
    required this.customization,
    required this.repository,
  });

  final AppCustomization customization;
  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
    final activeIds = customization.dashboardShortcutIds;
    final rows = <Widget>[
      for (final shortcut in _orderedShortcutDefinitions(activeIds))
        DashboardShortcutRow(
          shortcut: shortcut,
          visible: activeIds.contains(shortcut.id),
          canMoveUp: activeIds.indexOf(shortcut.id) > 0,
          canMoveDown:
              activeIds.contains(shortcut.id) &&
              activeIds.indexOf(shortcut.id) < activeIds.length - 1,
          onVisibleChanged: (visible) =>
              repository.setDashboardShortcutVisible(shortcut.id, visible),
          onMoveUp: () => repository.moveDashboardShortcut(shortcut.id, -1),
          onMoveDown: () => repository.moveDashboardShortcut(shortcut.id, 1),
        ),
      DashboardResetRow(onReset: repository.resetDashboardShortcuts),
    ];

    return SpSettingsGroup(title: 'Dashboard shortcuts', rows: rows);
  }

  List<DashboardShortcutDefinition> _orderedShortcutDefinitions(
    List<String> activeIds,
  ) {
    final definitions = {for (final item in dashboardShortcuts) item.id: item};
    final ordered = <DashboardShortcutDefinition>[
      for (final id in activeIds) ?definitions.remove(id),
      ...definitions.values,
    ];
    return ordered;
  }
}

class DashboardShortcutRow extends StatelessWidget {
  const DashboardShortcutRow({
    super.key,
    required this.shortcut,
    required this.visible,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onVisibleChanged,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final DashboardShortcutDefinition shortcut;
  final bool visible;
  final bool canMoveUp;
  final bool canMoveDown;
  final ValueChanged<bool> onVisibleChanged;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          SpIconBubble(
            icon: shortcut.icon,
            color: visible ? _spGold : _spMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shortcut.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  visible ? 'shown on dashboard' : 'hidden',
                  style: const TextStyle(color: _spMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            key: ValueKey('shortcut-up-${shortcut.id}'),
            tooltip: 'Move up',
            onPressed: visible && canMoveUp ? onMoveUp : null,
            icon: const Icon(Icons.keyboard_arrow_up_rounded),
          ),
          IconButton(
            key: ValueKey('shortcut-down-${shortcut.id}'),
            tooltip: 'Move down',
            onPressed: visible && canMoveDown ? onMoveDown : null,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
          ),
          Switch(
            key: ValueKey('shortcut-visible-${shortcut.id}'),
            value: visible,
            onChanged: onVisibleChanged,
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

class DashboardResetRow extends StatelessWidget {
  const DashboardResetRow({super.key, required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return SpSettingsRow(
      'Reset dashboard',
      'restore default shortcut order',
      trailing: const Icon(Icons.restart_alt_rounded, color: _spMuted),
      onTap: onReset,
    );
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
        SizedBox(height: 12),
        SpSettingsGroup(
          title: 'Support',
          rows: [
            SpSettingsRow('GitHub Sponsors', 'EndofTimeWorks'),
            SpSettingsRow('Patreon', 'patreon.com/EndofTimeWorks'),
          ],
        ),
        SizedBox(height: 12),
        SpCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monero',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 8),
              SelectableText(
                '85xURN4NDUbULxsVcVMA8EQSLDonAYvuc945g1sQckZvXXeTXg9dLnB7tHmNqKEUFzGEkquDqCTuHS1Ca9yPCjXcNXrTvvZ',
                style: TextStyle(color: _spMuted, fontSize: 12, height: 1.35),
              ),
            ],
          ),
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
  final _selectedMemberIds = <String>{};

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
            const Text(
              'Set front',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<MemberSummary>>(
              stream: widget.repository.watchMembers(),
              initialData: const [],
              builder: (context, snapshot) {
                final members = snapshot.data ?? const <MemberSummary>[];
                if (members.isEmpty) {
                  return const SpEmptyState(
                    title: 'No members yet',
                    body: 'Add members first, or set a custom front below.',
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final member in members)
                          FilterChip(
                            label: Text(member.displayName),
                            selected: _selectedMemberIds.contains(member.id),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedMemberIds.add(member.id);
                                } else {
                                  _selectedMemberIds.remove(member.id);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      key: const ValueKey('set-selected-members-front-button'),
                      onPressed: _selectedMemberIds.isEmpty
                          ? null
                          : _setMemberFront,
                      child: Text(
                        _selectedMemberIds.length <= 1
                            ? 'Set selected'
                            : 'Set co-front',
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            const Divider(color: _spLine),
            const SizedBox(height: 12),
            const Text(
              'Custom front',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
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

  Future<void> _setMemberFront() async {
    await widget.repository.setFrontMembers(_selectedMemberIds.toList());
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
    this.onPrimary,
    this.onSecondary,
  });

  final String primary;
  final String secondary;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FilledButton(onPressed: onPrimary ?? () {}, child: Text(primary)),
        const SizedBox(width: 10),
        OutlinedButton(onPressed: onSecondary ?? () {}, child: Text(secondary)),
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
