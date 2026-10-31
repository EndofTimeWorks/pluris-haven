import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/local/app_database.dart';
import 'package:pluris_haven/data/local/haven_repository.dart';
import 'package:pluris_haven/data/notifications/notification_service.dart';
import 'package:pluris_haven/features/home/home_page.dart';
import 'package:pluris_haven/l10n/app_localizations.dart';

import 'test_repository.dart';

void main() {
  testWidgets('a long member name fits the reminder target dropdown', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = testRepository(database);
    await repository.ensureLocalSystem();
    const memberName =
        'Juniper-Marisol the Very Long Member Name That Must Remain Readable';
    await repository.saveMember(const MemberDraft(displayName: memberName));

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: Scaffold(
          body: AddReminderSheet(
            repository: repository,
            notificationService: NotificationService.forTesting(
              permissionChecker: () async => false,
              permissionRequester: () async => false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'initial reminder form');
    await tester.tap(
      find.byKey(const ValueKey('reminder-schedule-kind-field')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('After a front starts').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'after-front form');
    final target = find.byKey(const ValueKey('reminder-front-detail-field'));
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'open member menu');
    await tester.tap(find.text(memberName).last);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(memberName), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
