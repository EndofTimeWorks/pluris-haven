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

    expect(find.text('Pluris Haven'), findsOneWidget);
    expect(find.text('Currently fronting'), findsOneWidget);
    expect(find.text('Members'), findsOneWidget);
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
}

class FakeHavenRepository implements HavenRepository {
  FakeHavenRepository(this._snapshot) {
    _controller = StreamController<HomeSnapshot>.broadcast(
      sync: true,
      onListen: () => _controller.add(_snapshot),
    );
  }

  HomeSnapshot _snapshot;
  late final StreamController<HomeSnapshot> _controller;

  @override
  Stream<HomeSnapshot> watchHomeSnapshot() => _controller.stream;

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

  Future<void> close() => _controller.close();
}
