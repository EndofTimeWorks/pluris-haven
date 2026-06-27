import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/import/import_archive_mapper.dart';
import '../../data/import/import_file_decoder.dart';
import '../../data/import/import_plan.dart';
import '../../data/import/import_preview.dart';
import '../../data/import/import_sources.dart';
import '../../data/local/app_database.dart' show NamedFront;
import '../../data/local/haven_repository.dart';
import '../../data/local/supported_language.dart';
import '../../debug/debug_log.dart';

part 'dashboard.dart';
part 'members.dart';
part 'front_history.dart';
part 'groups.dart';
part 'notes.dart';
part 'messages.dart';
part 'custom_fields.dart';
part 'polls.dart';
part 'reminders.dart';
part 'notifications.dart';
part 'import_export.dart';
part 'sync.dart';
part 'app_options.dart';
part 'about.dart';
part 'navigation.dart';
part 'dashboard_widgets.dart';
part 'custom_front.dart';
part 'sp_widgets.dart';

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

        return PopScope(
          canPop: _section == SpSection.dashboard,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && _section != SpSection.dashboard) {
              _selectSection(SpSection.dashboard);
            }
          },
          child: Scaffold(
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
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            body: SafeArea(
              top: false,
              child: StreamBuilder<AppCustomization>(
                stream: widget.repository.watchCustomization(),
                initialData: AppCustomization.defaults,
                builder: (context, customizationSnapshot) {
                  return _buildSection(
                    home,
                    customizationSnapshot.data ?? AppCustomization.defaults,
                  );
                },
              ),
            ),
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
        return MembersPage(
          snapshot: home,
          repository: widget.repository,
          onImport: () => _selectSection(SpSection.importExport),
        );
      case SpSection.frontHistory:
        return FrontHistoryPage(snapshot: home, repository: widget.repository);
      case SpSection.groups:
        return GroupsPage(
          snapshot: home,
          repository: widget.repository,
          onImport: () => _selectSection(SpSection.importExport),
        );
      case SpSection.notes:
        return NotesPage(
          snapshot: home,
          repository: widget.repository,
          onImport: () => _selectSection(SpSection.importExport),
        );
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
        return MessagesPage(
          repository: widget.repository,
          onImport: () => _selectSection(SpSection.importExport),
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
        return PollsPage(
          repository: widget.repository,
          onImport: () => _selectSection(SpSection.importExport),
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
        return CustomFieldsPage(
          repository: widget.repository,
          onImport: () => _selectSection(SpSection.importExport),
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
