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
  test(
    'archive, removal and purge retain vote history without profile data',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = testRepository(database);
      await repository.ensureLocalSystem();
      await repository.saveMember(
        const MemberDraft(
          displayName: 'Private voter',
          description: 'Private bio',
        ),
      );
      final member = (await repository.watchMembers().first).single;
      await repository.savePoll(
        const PollDraft(
          question: 'Dinner?',
          kind: PollKind.singleChoice,
          voteMode: PollVoteMode.perMember,
          options: ['Soup', 'Rice'],
        ),
      );
      final poll = (await repository.watchPolls().first).single;
      await repository.togglePollOption(
        poll.id,
        poll.options.first.id,
        memberId: member.id,
      );

      Future<void> expectVotePreserved() async {
        final current = (await repository.watchPolls().first).single;
        expect(current.options.first.memberIds, {member.id});
        expect(
          (await repository.watchPollVoteEvents(poll.id).first).single.memberId,
          member.id,
        );
      }

      await repository.archiveMember(member.id);
      await expectVotePreserved();
      await repository.restoreMember(member.id);
      await expectVotePreserved();
      await repository.deleteMember(member.id);
      expect(
        await repository.watchMembers(includeArchived: true).first,
        isEmpty,
      );
      expect(
        (await repository.watchDeletedMembers().first).single.id,
        member.id,
      );
      await expectVotePreserved();
      await repository.restoreDeletedMember(member.id);
      expect((await repository.watchMembers().first).single.id, member.id);
      await expectVotePreserved();

      await repository.deleteMember(member.id);
      await repository.purgeMember(member.id);
      expect(await repository.watchDeletedMembers().first, isEmpty);
      await expectVotePreserved();
      final archive = jsonDecode(
        await repository.buildLocalArchiveJson(),
      ) as Map<String, dynamic>;
      final encoded = jsonEncode(archive);
      expect(encoded, isNot(contains('Private voter')));
      expect(encoded, isNot(contains('Private bio')));
      expect(encoded, contains(member.id));
    },
  );

  testWidgets('vote history names a recoverably removed voter', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = testRepository(database);
    await repository.ensureLocalSystem();
    await repository.saveMember(const MemberDraft(displayName: 'Kai'));
    final kai = (await repository.watchMembers().first).single;
    await repository.savePoll(
      const PollDraft(
        question: 'Dinner?',
        kind: PollKind.singleChoice,
        voteMode: PollVoteMode.perMember,
        options: ['Soup', 'Rice'],
      ),
    );
    final poll = (await repository.watchPolls().first).single;
    await repository.togglePollOption(
      poll.id,
      poll.options.first.id,
      memberId: kai.id,
    );
    await repository.deleteMember(kai.id);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showPollVoteHistory(
                context,
                repository: repository,
                poll: poll,
              ),
              child: const Text('Open history'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open history'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Kai ·'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
