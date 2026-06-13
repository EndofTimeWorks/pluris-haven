import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/local/haven_repository.dart';
import 'package:pluris_haven/main.dart';

void main() {
  testWidgets('shows the offline home dashboard', (tester) async {
    final repository = FakeHavenRepository(
      const HomeSnapshot(
        systemName: 'Local system',
        memberCount: 0,
        groupCount: 0,
        noteCount: 0,
        frontHistoryCount: 0,
        currentFrontLabel: null,
      ),
    );
    addTearDown(repository.close);

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Members'), findsOneWidget);
    expect(find.text('Front History'), findsOneWidget);
    expect(find.text('Customize'), findsOneWidget);
    expect(find.text('Local system'), findsWidgets);
  });

  testWidgets('sets and clears a custom front from the home screen', (
    tester,
  ) async {
    final repository = FakeHavenRepository(
      const HomeSnapshot(
        systemName: 'Local system',
        memberCount: 0,
        groupCount: 0,
        noteCount: 0,
        frontHistoryCount: 0,
        currentFrontLabel: null,
      ),
    );
    addTearDown(repository.close);

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    await tester.tap(find.text('Front History'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('set front'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'blurry co-con');
    await tester.tap(find.text('Set'));
    await tester.pumpAndSettle();

    expect(find.text('blurry co-con'), findsOneWidget);
    expect(find.text('fronting'), findsOneWidget);

    await tester.tap(find.text('set front'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(find.text('None'), findsOneWidget);
    expect(find.text('none'), findsOneWidget);
  });

  testWidgets('opens an familiar section from the dashboard', (tester) async {
    final repository = FakeHavenRepository(
      const HomeSnapshot(
        systemName: 'Local system',
        memberCount: 0,
        groupCount: 0,
        noteCount: 0,
        frontHistoryCount: 0,
        currentFrontLabel: null,
      ),
    );
    addTearDown(repository.close);

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    await tester.tap(find.text('Members').first);
    await tester.pumpAndSettle();

    expect(find.text('Search members'), findsOneWidget);
    expect(find.text('No members saved locally'), findsOneWidget);
  });

  testWidgets('updates customization from the app options page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repository = FakeHavenRepository(
      const HomeSnapshot(
        systemName: 'Local system',
        memberCount: 0,
        groupCount: 0,
        noteCount: 0,
        frontHistoryCount: 0,
        currentFrontLabel: null,
      ),
    );
    addTearDown(repository.close);

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    await tester.ensureVisible(find.text('Customize'));
    await tester.tap(find.text('Customize'));
    await tester.pumpAndSettle();

    expect(find.text('Dark'), findsOneWidget);
    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();
    expect(find.text('Light'), findsOneWidget);

    await tester.tap(find.text('Compact dashboard'));
    await tester.pumpAndSettle();
    expect((await repository.loadCustomization()).compactDashboard, isTrue);

    await tester.scrollUntilVisible(find.text('Analytics'), 220);
    await tester.tap(find.byKey(const ValueKey('shortcut-visible-analytics')));
    await tester.pumpAndSettle();
    expect(
      (await repository.loadCustomization()).dashboardShortcutIds,
      contains('analytics'),
    );

    await tester.tap(find.byKey(const ValueKey('shortcut-up-analytics')));
    await tester.pumpAndSettle();
    final shortcutIds =
        (await repository.loadCustomization()).dashboardShortcutIds;
    expect(shortcutIds.indexOf('analytics'), shortcutIds.length - 2);

    await tester.scrollUntilVisible(find.text('Reset dashboard'), 220);
    await tester.tap(find.text('Reset dashboard'));
    await tester.pumpAndSettle();
    expect(
      (await repository.loadCustomization()).dashboardShortcutIds,
      defaultDashboardShortcutIds,
    );
  });

  testWidgets('shows supported importers and PluralKit live setup', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repository = FakeHavenRepository(
      const HomeSnapshot(
        systemName: 'Local system',
        memberCount: 0,
        groupCount: 0,
        noteCount: 0,
        frontHistoryCount: 0,
        currentFrontLabel: null,
      ),
    );
    addTearDown(repository.close);

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();

    await tester.ensureVisible(find.text('Import / Export'));
    await tester.tap(find.text('Import / Export'));
    await tester.pumpAndSettle();

    expect(find.text('Simply Plural'), findsOneWidget);
    expect(find.text('PluralKit file'), findsOneWidget);
    expect(find.text('PluralKit live'), findsOneWidget);
    expect(find.text('Tupperbox'), findsOneWidget);
    expect(find.text('PluralSpace'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Prism'), 240);
    expect(find.text('Prism'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('PluralKit live'), -240);
    await tester.tap(find.text('PluralKit live'));
    await tester.pumpAndSettle();

    expect(find.text('pk;token'), findsOneWidget);
    expect(find.text('Validate token with GET /systems/@me'), findsOneWidget);
  });
}

class FakeHavenRepository implements HavenRepository {
  FakeHavenRepository(this._snapshot) {
    _controller = StreamController<HomeSnapshot>.broadcast(
      sync: true,
      onListen: () => _controller.add(_snapshot),
    );
    _customizationController = StreamController<AppCustomization>.broadcast(
      sync: true,
      onListen: () => _customizationController.add(_customization),
    );
  }

  HomeSnapshot _snapshot;
  AppCustomization _customization = AppCustomization.defaults;
  late final StreamController<HomeSnapshot> _controller;
  late final StreamController<AppCustomization> _customizationController;

  @override
  Stream<HomeSnapshot> watchHomeSnapshot() => _controller.stream;

  @override
  Stream<AppCustomization> watchCustomization() =>
      _customizationController.stream;

  @override
  Future<AppCustomization> loadCustomization() async => _customization;

  @override
  Future<void> setThemeMode(HavenThemeMode mode) async {
    _customization = _customization.copyWith(themeMode: mode);
    _customizationController.add(_customization);
  }

  @override
  Future<void> setAccentColor(HavenAccentColor color) async {
    _customization = _customization.copyWith(accentColor: color);
    _customizationController.add(_customization);
  }

  @override
  Future<void> setCompactDashboard(bool compact) async {
    _customization = _customization.copyWith(compactDashboard: compact);
    _customizationController.add(_customization);
  }

  @override
  Future<void> setShowDashboardSubtitles(bool show) async {
    _customization = _customization.copyWith(showDashboardSubtitles: show);
    _customizationController.add(_customization);
  }

  @override
  Future<void> setDashboardShortcutIds(List<String> shortcutIds) async {
    _customization = _customization.copyWith(dashboardShortcutIds: shortcutIds);
    _customizationController.add(_customization);
  }

  @override
  Future<void> setDashboardShortcutVisible(String shortcutId, bool visible) {
    final ids = _customization.dashboardShortcutIds.toList();
    final existingIndex = ids.indexOf(shortcutId);
    if (visible && existingIndex == -1) {
      ids.add(shortcutId);
    } else if (!visible && existingIndex != -1) {
      ids.removeAt(existingIndex);
    }
    return setDashboardShortcutIds(ids);
  }

  @override
  Future<void> moveDashboardShortcut(String shortcutId, int delta) {
    final ids = _customization.dashboardShortcutIds.toList();
    final index = ids.indexOf(shortcutId);
    if (index == -1 || delta == 0) {
      return Future.value();
    }
    final newIndex = (index + delta).clamp(0, ids.length - 1);
    if (newIndex == index) {
      return Future.value();
    }
    final id = ids.removeAt(index);
    ids.insert(newIndex, id);
    return setDashboardShortcutIds(ids);
  }

  @override
  Future<void> resetDashboardShortcuts() {
    return setDashboardShortcutIds(defaultDashboardShortcutIds);
  }

  @override
  Future<void> setCustomFront(String label) async {
    _snapshot = HomeSnapshot(
      systemName: _snapshot.systemName,
      memberCount: _snapshot.memberCount,
      groupCount: _snapshot.groupCount,
      noteCount: _snapshot.noteCount,
      frontHistoryCount: _snapshot.frontHistoryCount + 1,
      currentFrontLabel: label,
    );
    _controller.add(_snapshot);
  }

  @override
  Future<void> clearCurrentFront() async {
    _snapshot = HomeSnapshot(
      systemName: _snapshot.systemName,
      memberCount: _snapshot.memberCount,
      groupCount: _snapshot.groupCount,
      noteCount: _snapshot.noteCount,
      frontHistoryCount: _snapshot.frontHistoryCount,
      currentFrontLabel: null,
    );
    _controller.add(_snapshot);
  }

  Future<void> close() async {
    await _controller.close();
    await _customizationController.close();
  }
}
