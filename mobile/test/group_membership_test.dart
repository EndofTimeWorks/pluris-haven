import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/local/app_database.dart';
import 'package:pluris_haven/data/local/haven_repository.dart';
import 'package:pluris_haven/main.dart';

import 'test_repository.dart';

void main() {
  test('group membership changes are atomic and keep hidden links', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = testRepository(database);
    await repository.ensureLocalSystem();
    await repository.saveMember(const MemberDraft(displayName: 'Kai'));
    await repository.saveMember(const MemberDraft(displayName: 'Wren'));
    final members = await repository.watchMembers().first;
    final kai = members.singleWhere((member) => member.displayName == 'Kai');
    final wren = members.singleWhere((member) => member.displayName == 'Wren');

    await repository.saveGroup(
      GroupDraft(name: 'Team', memberIds: [kai.id, wren.id]),
    );
    final group = (await repository.watchGroups().first).single;
    expect(group.memberCount, 2);
    await repository.updateMember(
      kai.id,
      MemberDraft(displayName: 'Kai', folderId: group.id, groupIds: [group.id]),
    );
    await repository.updateGroup(
      group.id,
      const GroupDraft(name: 'Team details changed'),
    );
    expect((await repository.watchGroups().first).single.memberCount, 2);

    await repository.deleteMember(wren.id);
    await repository.updateGroup(
      group.id,
      GroupDraft(name: 'Team renamed', memberIds: const []),
    );
    expect((await repository.watchGroups().first).single.memberCount, 1);
    await repository.restoreDeletedMember(wren.id);
    final restoredWren = (await repository.watchMembers().first).singleWhere(
      (member) => member.id == wren.id,
    );
    expect(restoredWren.groupIds, contains(group.id));
    final remainingKai = (await repository.watchMembers().first).singleWhere(
      (member) => member.id == kai.id,
    );
    expect(remainingKai.groupIds, isNot(contains(group.id)));
    expect(remainingKai.folderId, isNull);

    await expectLater(
      repository.updateGroup(
        group.id,
        const GroupDraft(name: 'Wrong name', memberIds: ['missing-member']),
      ),
      throwsStateError,
    );
    expect((await repository.watchGroups().first).single.name, 'Team renamed');
    await expectLater(
      repository.saveGroup(
        const GroupDraft(
          name: 'Should roll back',
          memberIds: ['missing-member'],
        ),
      ),
      throwsStateError,
    );
    expect(await repository.watchGroups().first, hasLength(1));
  });

  testWidgets('group editor assigns and retains members', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = testRepository(database);
    await repository.ensureLocalSystem();
    await repository.saveMember(const MemberDraft(displayName: 'Kai'));
    await repository.saveMember(const MemberDraft(displayName: 'Wren'));
    final members = await repository.watchMembers().first;
    final kai = members.singleWhere((member) => member.displayName == 'Kai');
    final wren = members.singleWhere((member) => member.displayName == 'Wren');

    await tester.pumpWidget(PlurisHavenApp(repository: repository));
    await tester.pump();
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .descendant(of: find.byType(Drawer), matching: find.text('Groups'))
          .last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add group'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('group-name-field')),
      'Team',
    );
    await tester.tap(find.byKey(ValueKey('group-member-${kai.id}')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('save-group-button')));
    await tester.tap(find.byKey(const ValueKey('save-group-button')));
    await tester.pumpAndSettle();

    final group = (await repository.watchGroups().first).single;
    expect(group.memberCount, 1);
    expect(
      (await repository.watchMembers().first)
          .singleWhere((member) => member.id == kai.id)
          .groupIds,
      contains(group.id),
    );
    await tester.tap(find.text('Team'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(ValueKey('group-member-${kai.id}')),
          )
          .value,
      isTrue,
    );
    await tester.tap(find.byKey(ValueKey('group-member-${wren.id}')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('save-group-button')));
    await tester.tap(find.byKey(const ValueKey('save-group-button')));
    await tester.pumpAndSettle();
    expect((await repository.watchGroups().first).single.memberCount, 2);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
  });
}
