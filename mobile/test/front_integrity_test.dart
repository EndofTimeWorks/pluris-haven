import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/local/app_database.dart';
import 'package:pluris_haven/data/local/haven_repository.dart';
import 'package:pluris_haven/data/security/archive_encryption.dart';
import 'package:pluris_haven/main.dart';

import 'test_repository.dart';

void main() {
  testWidgets('front picker keeps an archived active member selected', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = testRepository(database);
    await repository.ensureLocalSystem();
    await repository.saveMember(const MemberDraft(displayName: 'Wren'));
    await repository.saveMember(const MemberDraft(displayName: 'Kai'));
    final members = await repository.watchMembers().first;
    final wren = members.singleWhere((member) => member.displayName == 'Wren');
    final kai = members.singleWhere((member) => member.displayName == 'Kai');
    await repository.setFrontMembers([wren.id, kai.id]);
    await repository.archiveMember(wren.id);

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();
    await tester.tap(find.text('Make current front'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, 'Wren'))
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, 'Kai'))
          .selected,
      isTrue,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  test(
    'ending Kai preserves archived Wren and an active custom front',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = testRepository(database);
      await repository.ensureLocalSystem();
      for (final name in ['Wren', 'Kai', 'Sol']) {
        await repository.saveMember(MemberDraft(displayName: name));
      }
      final members = await repository.watchMembers().first;
      final ids = {for (final member in members) member.displayName: member.id};
      await repository.setFrontMembers([ids['Wren']!, ids['Kai']!]);
      await repository.addCustomFront('Away');
      final original = await repository.watchFrontHistory().first;
      final wren = original.singleWhere(
        (entry) => entry.memberIds.contains(ids['Wren']),
      );
      final kai = original.singleWhere(
        (entry) => entry.memberIds.contains(ids['Kai']),
      );
      final away = original.singleWhere((entry) => entry.label == 'Away');

      await repository.archiveMember(ids['Wren']!);
      expect(
        (await repository.watchCurrentFrontMembers().first).map(
          (member) => member.id,
        ),
        containsAll([ids['Wren'], ids['Kai']]),
      );
      await repository.endMemberFront(ids['Kai']!);
      await repository.endMemberFront(ids['Kai']!);
      final after = await repository.watchFrontHistory().first;
      expect(
        after.singleWhere((entry) => entry.id == wren.id).isActive,
        isTrue,
      );
      expect(
        after.singleWhere((entry) => entry.id == wren.id).startedAt,
        wren.startedAt,
      );
      expect(
        after.singleWhere((entry) => entry.id == kai.id).isActive,
        isFalse,
      );
      expect(
        after.singleWhere((entry) => entry.id == away.id).isActive,
        isTrue,
      );
      expect(after, hasLength(3));

      await repository.setFrontMembers([ids['Wren']!, ids['Sol']!]);
      await repository.setFrontMembers([ids['Wren']!, ids['Sol']!]);
      final replaced = await repository.watchFrontHistory().first;
      expect(
        replaced.singleWhere((entry) => entry.id == wren.id).isActive,
        isTrue,
      );
      expect(
        replaced.singleWhere((entry) => entry.id == away.id).isActive,
        isTrue,
      );
      expect(
        replaced.where((entry) => entry.memberIds.contains(ids['Sol'])),
        hasLength(1),
      );

      final recoveryCode = await generateArchiveRecoveryCode();
      final encrypted = await encryptArchiveJson(
        archiveJson: await repository.buildLocalArchiveJson(),
        recoveryCode: recoveryCode,
      );
      final archive = await decryptArchiveJson(
        encryptedArchiveJson: encrypted,
        passphrase: recoveryCode.value,
      );
      final decoded = jsonDecode(archive) as Map<String, dynamic>;
      expect(decoded['fronts'], isNotEmpty);
      await database.close();
      final freshDatabase = AppDatabase(NativeDatabase.memory());
      addTearDown(freshDatabase.close);
      final fresh = testRepository(freshDatabase);
      await fresh.ensureLocalSystem();
      await fresh.importLocalArchiveJson(archive);
      final restored = await fresh.watchFrontHistory().first;
      expect(
        restored.singleWhere((entry) => entry.id == wren.id).isActive,
        isTrue,
      );
      expect(
        restored.singleWhere((entry) => entry.id == wren.id).startedAt,
        wren.startedAt,
      );
      expect(
        restored.singleWhere((entry) => entry.id == kai.id).isActive,
        isFalse,
      );
      expect(
        restored.singleWhere((entry) => entry.id == away.id).isActive,
        isTrue,
      );
    },
  );

  test(
    'removing one member preserves a cofronter in a grouped session',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = testRepository(database);
      await repository.ensureLocalSystem();
      await repository.saveMember(const MemberDraft(displayName: 'Wren'));
      await repository.saveMember(const MemberDraft(displayName: 'Kai'));
      final members = await repository.watchMembers().first;
      final wren = members.singleWhere(
        (member) => member.displayName == 'Wren',
      );
      final kai = members.singleWhere((member) => member.displayName == 'Kai');
      final system = await database.select(database.pluralSystems).getSingle();
      final start = DateTime.now().toUtc().subtract(const Duration(hours: 2));
      await database
          .into(database.frontSessions)
          .insert(
            FrontSessionsCompanion.insert(
              id: 'grouped-front',
              systemId: system.id,
              startedAt: start,
              createdAt: start,
              updatedAt: start,
            ),
          );
      for (final member in [wren, kai]) {
        await database
            .into(database.frontSessionMembers)
            .insert(
              FrontSessionMembersCompanion.insert(
                sessionId: 'grouped-front',
                memberId: member.id,
              ),
            );
      }

      await repository.deleteMember(kai.id);
      final history = await repository.watchFrontHistory().first;
      final retained = history.singleWhere(
        (entry) => entry.id == 'grouped-front',
      );
      expect(retained.isActive, isTrue);
      expect(
        retained.startedAt.toUtc().difference(start).abs(),
        lessThan(const Duration(seconds: 1)),
      );
      expect(retained.memberIds, [wren.id]);
      final removed = history.singleWhere(
        (entry) => entry.memberIds.contains(kai.id),
      );
      expect(removed.isActive, isFalse);
      expect(
        removed.startedAt.toUtc().difference(start).abs(),
        lessThan(const Duration(seconds: 1)),
      );
      expect(
        (await repository.watchCurrentFrontMembers().first).single.id,
        wren.id,
      );
      expect((await repository.watchDeletedMembers().first).single.id, kai.id);
    },
  );

  test(
    'manual history rejects invalid intervals and duplicate active members',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = testRepository(database);
      await repository.ensureLocalSystem();
      for (final name in ['Wren', 'Kai']) {
        await repository.saveMember(MemberDraft(displayName: name));
      }
      final members = await repository.watchMembers().first;
      final ids = {for (final member in members) member.displayName: member.id};
      final start = DateTime.now().toUtc().subtract(const Duration(hours: 1));

      await expectLater(
        repository.saveFrontHistoryEntry(
          FrontHistoryDraft(
            startedAt: start,
            endedAt: start.subtract(const Duration(minutes: 1)),
            memberIds: [ids['Wren']!],
          ),
        ),
        throwsFormatException,
      );
      await expectLater(
        repository.saveFrontHistoryEntry(
          FrontHistoryDraft(
            startedAt: DateTime.now().toUtc().add(const Duration(days: 1)),
            endedAt: null,
            memberIds: [ids['Wren']!],
          ),
        ),
        throwsFormatException,
      );
      expect(await repository.watchFrontHistory().first, isEmpty);

      await repository.saveFrontHistoryEntry(
        FrontHistoryDraft(
          startedAt: start,
          endedAt: null,
          memberIds: [ids['Wren']!],
        ),
      );
      final wren = (await repository.watchFrontHistory().first).single;
      await expectLater(
        repository.saveFrontHistoryEntry(
          FrontHistoryDraft(
            startedAt: start,
            endedAt: null,
            memberIds: [ids['Wren']!],
          ),
        ),
        throwsFormatException,
      );
      await repository.saveFrontHistoryEntry(
        FrontHistoryDraft(
          startedAt: start,
          endedAt: null,
          memberIds: [ids['Kai']!],
        ),
      );
      expect(
        (await repository.watchFrontHistory().first).where(
          (entry) => entry.isActive,
        ),
        hasLength(2),
      );
      await repository.updateFrontHistoryEntry(
        wren.id,
        FrontHistoryDraft(
          startedAt: wren.startedAt,
          endedAt: null,
          memberIds: wren.memberIds,
          statusNote: 'Still fronting',
        ),
      );
      final unchanged = (await repository.watchFrontHistory().first)
          .singleWhere((entry) => entry.id == wren.id);
      expect(unchanged.isActive, isTrue);
      expect(unchanged.statusNote, 'Still fronting');
      await expectLater(
        repository.updateFrontHistoryEntry(
          wren.id,
          FrontHistoryDraft(
            startedAt: wren.startedAt,
            endedAt: null,
            memberIds: [ids['Wren']!, ids['Kai']!],
          ),
        ),
        throwsFormatException,
      );
      expect(
        (await repository.watchFrontHistory().first)
            .singleWhere((entry) => entry.id == wren.id)
            .memberIds,
        [ids['Wren']],
      );
    },
  );

  test(
    'legacy future entries stay readable and are not rewritten on read',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = testRepository(database);
      await repository.ensureLocalSystem();
      await repository.saveMember(const MemberDraft(displayName: 'Wren'));
      final member = (await repository.watchMembers().first).single;
      final system = await database.select(database.pluralSystems).getSingle();
      final future = DateTime.now().toUtc().add(const Duration(days: 1));
      await database
          .into(database.frontSessions)
          .insert(
            FrontSessionsCompanion.insert(
              id: 'legacy-future-front',
              systemId: system.id,
              startedAt: future,
              createdAt: future,
              updatedAt: future,
            ),
          );
      await database
          .into(database.frontSessionMembers)
          .insert(
            FrontSessionMembersCompanion.insert(
              sessionId: 'legacy-future-front',
              memberId: member.id,
            ),
          );

      final storedBefore = await database
          .select(database.frontSessions)
          .getSingle();
      final history = await repository.watchFrontHistory().first;
      expect(history.single.id, storedBefore.id);
      expect(history.single.isActive, isTrue);
      final archive = jsonDecode(
        await repository.buildLocalArchiveJson(),
      ) as Map<String, dynamic>;
      expect((archive['fronts'] as List).single['id'], storedBefore.id);
      final storedAfter = await database
          .select(database.frontSessions)
          .getSingle();
      expect(storedAfter.startedAt, storedBefore.startedAt);
      expect(storedAfter.endedAt, isNull);
    },
  );
}
