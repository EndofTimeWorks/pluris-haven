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
  testWidgets('reminder form shows missing title and time at their fields', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final repository = testRepository(database);
    addTearDown(database.close);
    await repository.ensureLocalSystem();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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

    final save = find.byKey(const ValueKey('save-reminder-button'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('This field is required.'), findsOneWidget);
    expect(await repository.watchReminders().first, isEmpty);

    await tester.enterText(
      find.byKey(const ValueKey('reminder-title-field')),
      'Medication',
    );
    await tester.enterText(
      find.byKey(const ValueKey('reminder-time-field')),
      '',
    );
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(
      find.text('Enter a valid time, such as 09:00 or 9am.'),
      findsOneWidget,
    );
    expect(await repository.watchReminders().first, isEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
  });

  testWidgets('reminder form offers a time picker alongside typed time', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final repository = testRepository(database);
    addTearDown(database.close);
    await repository.ensureLocalSystem();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: AddReminderSheet(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Choose reminder time'));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('reminder-time-field')),
    );
    expect(field.controller?.text, '09:00');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
  });

  testWidgets('invalid after-front delay is shown at its field', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final repository = testRepository(database);
    addTearDown(database.close);
    await repository.ensureLocalSystem();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: AddReminderSheet(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('reminder-title-field')),
      'After front',
    );
    await tester.tap(
      find.byKey(const ValueKey('reminder-schedule-kind-field')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('After member fronts').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('reminder-after-front-delay-field')),
      '-1',
    );
    final save = find.byKey(const ValueKey('save-reminder-button'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(
      find.text('Enter zero or a positive whole number of seconds.'),
      findsOneWidget,
    );
    expect(await repository.watchReminders().first, isEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
  });

  testWidgets('reminder action names include title and schedule', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final repository = testRepository(database);
    addTearDown(database.close);
    await repository.ensureLocalSystem();
    final updatedAt = DateTime.now();
    final notificationService = NotificationService.forTesting(
      permissionChecker: () async => false,
      permissionRequester: () async => false,
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Column(
            children: [
              ReminderTile(
                reminder: ReminderSummary(
                  id: 'morning',
                  title: 'Medication',
                  scheduleText: 'Daily at 09:00',
                  enabled: true,
                  updatedAt: updatedAt,
                ),
                repository: repository,
                notificationService: notificationService,
              ),
              ReminderTile(
                reminder: ReminderSummary(
                  id: 'evening',
                  title: 'Medication',
                  scheduleText: 'Daily at 21:00',
                  enabled: true,
                  updatedAt: updatedAt,
                ),
                repository: repository,
                notificationService: notificationService,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byTooltip('Delete reminder Medication, Daily at 09:00'),
      findsOneWidget,
    );
    expect(
      find.byTooltip('Delete reminder Medication, Daily at 21:00'),
      findsOneWidget,
    );
    expect(
      find.byTooltip('Edit reminder Medication, Daily at 09:00'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
  });

  testWidgets(
    'after-front reminders can be edited without losing their target',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      final repository = testRepository(database);
      addTearDown(database.close);
      await repository.ensureLocalSystem();
      await repository.saveMember(const MemberDraft(displayName: 'River'));
      final member = (await repository.watchMembers().first).single;
      final reminderId = await repository.saveReminder(
        ReminderDraft(
          title: 'Check in',
          scheduleText: '30 seconds after River fronts',
          scheduleKind: 'after_front',
          triggerType: 'event',
          triggerMemberId: member.id,
          triggerEvent: 'front_started',
          delaySeconds: 30,
        ),
      );
      final reminder = (await repository.watchReminders().first).single;
      final notificationService = NotificationService.forTesting(
        permissionChecker: () async => true,
        permissionRequester: () async => true,
      );
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ReminderTile(
              reminder: reminder,
              repository: repository,
              notificationService: notificationService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('reminder-front-detail-field')),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey('reminder-after-front-delay-field')),
        '45',
      );
      final save = find.byKey(const ValueKey('save-reminder-button'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      final updated = (await repository.watchReminders().first).single;
      expect(updated.id, reminderId);
      expect(updated.triggerMemberId, member.id);
      expect(updated.delaySeconds, 45);
      expect(updated.scheduleText, contains('River'));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 10));
    },
  );
}
