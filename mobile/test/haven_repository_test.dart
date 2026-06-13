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

    await repository.setThemeMode(HavenThemeMode.system);
    await repository.setAccentColor(HavenAccentColor.teal);
    await repository.setCompactDashboard(true);
    await repository.setShowDashboardSubtitles(false);

    customization = await repository.loadCustomization();
    expect(customization.themeMode, HavenThemeMode.system);
    expect(customization.accentColor, HavenAccentColor.teal);
    expect(customization.compactDashboard, isTrue);
    expect(customization.showDashboardSubtitles, isFalse);
  });
}
