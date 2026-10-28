import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/local/app_database.dart';
import 'package:pluris_haven/data/local/haven_repository.dart';
import 'package:pluris_haven/features/home/home_page.dart';
import 'package:pluris_haven/l10n/app_localizations.dart';

import 'test_repository.dart';

void main() {
  test('notification clear copy resolves for UK and US English', () {
    for (final locale in const [Locale('en', 'GB'), Locale('en', 'US')]) {
      final l10n = lookupAppLocalizations(locale);
      expect(l10n.clearNotificationHistoryButton, 'Clear history');
      expect(l10n.clearNotificationHistoryBody, contains('future exports'));
      expect(l10n.clearNotificationHistoryBody, contains('unchanged'));
    }
  });

  test('purge leaves notification text until history is cleared', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = testRepository(database);
    await repository.ensureLocalSystem();
    await repository.saveMember(const MemberDraft(displayName: 'Private Name'));
    final member = (await repository.watchMembers().first).single;
    await repository.recordNotificationEvent(
      const NotificationEventDraft(
        kind: 'front',
        title: 'Front changed',
        body: 'Private Name is fronting',
      ),
    );
    await repository.deleteMember(member.id);
    await repository.purgeMember(member.id);

    final retained = await repository.watchNotificationEvents().first;
    expect(retained.single.body, contains('Private Name'));
    final before = jsonDecode(
      await repository.buildLocalArchiveJson(),
    ) as Map<String, dynamic>;
    expect(before['notification_events'], hasLength(1));

    await repository.clearNotificationHistory();
    expect(await database.select(database.notificationEvents).get(), isEmpty);
    expect(await repository.watchNotificationEvents().first, isEmpty);
    final after = jsonDecode(
      await repository.buildLocalArchiveJson(),
    ) as Map<String, dynamic>;
    expect(after['notification_events'], isEmpty);
  });

  testWidgets('history clear requires confirmation', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = testRepository(database);
    await repository.ensureLocalSystem();
    await repository.recordNotificationEvent(
      const NotificationEventDraft(
        kind: 'front',
        title: 'Front changed',
        body: 'Private Name is fronting',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: NotificationHistoryPage(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Private Name is fronting'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('clear-notification-history')));
    await tester.pumpAndSettle();
    expect(
      await database.select(database.notificationEvents).get(),
      hasLength(1),
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(
      await database.select(database.notificationEvents).get(),
      hasLength(1),
    );

    await tester.tap(find.byKey(const ValueKey('clear-notification-history')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear history').last);
    await tester.pumpAndSettle();
    expect(await database.select(database.notificationEvents).get(), isEmpty);
    expect(find.text('No notifications yet'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
