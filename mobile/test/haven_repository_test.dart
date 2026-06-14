import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/local/app_database.dart';
import 'package:pluris_haven/data/local/haven_repository.dart';

void main() {
  test('stores and clears current front in the local database', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = LocalHavenRepository(database);
    await repository.ensureLocalSystem();

    var snapshot = await repository.loadHomeSnapshot();
    expect(snapshot.systemName, 'Local system');
    expect(snapshot.currentFrontText, 'None');
    expect(snapshot.frontHistoryCount, 0);

    await repository.setCustomFront('blurry co-con');
    snapshot = await repository.loadHomeSnapshot();
    expect(snapshot.currentFrontText, 'blurry co-con');
    expect(snapshot.currentFrontStatus, 'fronting');
    expect(snapshot.frontHistoryCount, 1);

    await repository.clearCurrentFront();
    snapshot = await repository.loadHomeSnapshot();
    expect(snapshot.currentFrontText, 'None');
    expect(snapshot.currentFrontStatus, 'none');
    expect(snapshot.frontHistoryCount, 1);
  });

  test('stores app customization in the local database', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = LocalHavenRepository(database);
    await repository.ensureLocalSystem();

    var customization = await repository.loadCustomization();
    expect(customization.themeMode, HavenThemeMode.dark);
    expect(customization.accentColor, HavenAccentColor.purple);
    expect(customization.compactDashboard, isFalse);
    expect(customization.showDashboardSubtitles, isTrue);
    expect(customization.dashboardShortcutIds, defaultDashboardShortcutIds);
    expect(customization.languageCode, 'system');

    await repository.setThemeMode(HavenThemeMode.system);
    await repository.setAccentColor(HavenAccentColor.teal);
    await repository.setCompactDashboard(true);
    await repository.setShowDashboardSubtitles(false);
    await repository.setDashboardShortcutVisible('analytics', true);
    await repository.moveDashboardShortcut('analytics', -10);
    await repository.setDashboardShortcutVisible('notes', false);
    await repository.setLanguageCode('pt-BR');

    customization = await repository.loadCustomization();
    expect(customization.themeMode, HavenThemeMode.system);
    expect(customization.accentColor, HavenAccentColor.teal);
    expect(customization.compactDashboard, isTrue);
    expect(customization.showDashboardSubtitles, isFalse);
    expect(customization.dashboardShortcutIds.first, 'analytics');
    expect(customization.dashboardShortcutIds, isNot(contains('notes')));
    expect(customization.languageCode, 'pt-BR');
    expect(customization.language.label, 'português brasileiro');

    await repository.resetDashboardShortcuts();
    customization = await repository.loadCustomization();
    expect(customization.dashboardShortcutIds, defaultDashboardShortcutIds);
  });

  test('stores members and links them to front sessions', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = LocalHavenRepository(database);
    await repository.ensureLocalSystem();

    await repository.saveMember(
      const MemberDraft(displayName: 'Iris', pronouns: 'she/they'),
    );

    var members = await repository.watchMembers().first;
    expect(members, hasLength(1));
    expect(members.single.displayName, 'Iris');
    expect(members.single.pronouns, 'she/they');

    var snapshot = await repository.loadHomeSnapshot();
    expect(snapshot.memberCount, 1);

    await repository.setFrontMembers([members.single.id]);
    snapshot = await repository.loadHomeSnapshot();
    expect(snapshot.currentFrontText, 'Iris');
    expect(snapshot.frontHistoryCount, 1);

    final frontLinks = await database
        .select(database.frontSessionMembers)
        .get();
    expect(frontLinks, hasLength(1));
    expect(frontLinks.single.memberId, members.single.id);

    await repository.archiveMember(members.single.id);
    members = await repository.watchMembers().first;
    expect(members, isEmpty);

    snapshot = await repository.loadHomeSnapshot();
    expect(snapshot.memberCount, 0);
  });

  test('stores groups in the local database', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = LocalHavenRepository(database);
    await repository.ensureLocalSystem();

    await repository.saveGroup(
      const GroupDraft(
        name: 'Caretakers',
        emoji: '*',
        description: 'Internal support crew',
      ),
    );

    final groups = await repository.watchGroups().first;
    expect(groups, hasLength(1));
    expect(groups.single.name, 'Caretakers');
    expect(groups.single.emoji, '*');
    expect(groups.single.description, 'Internal support crew');

    final snapshot = await repository.loadHomeSnapshot();
    expect(snapshot.groupCount, 1);
  });
}
