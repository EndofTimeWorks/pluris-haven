import 'package:drift/drift.dart';

import 'app_database.dart';

class LocalPendingActionStore {
  LocalPendingActionStore(
    this.database, {
    required this.deleteMember,
    required this.deleteNote,
    required this.deleteReminder,
    required this.deletePoll,
    required this.deleteJournal,
    required this.deleteTag,
    required this.deleteNamedFront,
  });

  final AppDatabase database;
  final Future<void> Function(String id) deleteMember;
  final Future<void> Function(String id) deleteNote;
  final Future<void> Function(String id) deleteReminder;
  final Future<void> Function(String id) deletePoll;
  final Future<void> Function(String id) deleteJournal;
  final Future<void> Function(String id) deleteTag;
  final Future<void> Function(String id) deleteNamedFront;

  Stream<List<PendingAction>> watch() {
    final query = database.select(database.pendingActions)
      ..where(
        (action) =>
            action.systemId.equals(localSystemId) &
            action.status.equals('pending'),
      )
      ..orderBy([
        (action) => OrderingTerm(
          expression: action.finalizeAfter,
          mode: OrderingMode.asc,
        ),
      ]);
    return query.watch();
  }

  Future<void> cancel(String actionId) async {
    final now = DateTime.now().toUtc();
    await (database.update(
      database.pendingActions,
    )..where((action) => action.id.equals(actionId))).write(
      PendingActionsCompanion(
        status: const Value('cancelled'),
        cancelledAt: Value(now),
      ),
    );
  }

  Future<void> finalize() async {
    final now = DateTime.now().toUtc();
    final due =
        await (database.select(database.pendingActions)..where(
              (action) =>
                  action.systemId.equals(localSystemId) &
                  action.status.equals('pending') &
                  action.finalizeAfter.isSmallerOrEqualValue(now),
            ))
            .get();

    for (final action in due) {
      switch (action.actionType) {
        case 'member_delete':
          await deleteMember(action.targetId);
        case 'note_delete':
          await deleteNote(action.targetId);
        case 'reminder_delete':
          await deleteReminder(action.targetId);
        case 'poll_delete':
          await deletePoll(action.targetId);
        case 'journal_delete':
          await deleteJournal(action.targetId);
        case 'tag_delete':
          await deleteTag(action.targetId);
        case 'named_front_delete':
          await deleteNamedFront(action.targetId);
      }
      await (database.update(
        database.pendingActions,
      )..where((row) => row.id.equals(action.id))).write(
        PendingActionsCompanion(
          status: const Value('completed'),
          completedAt: Value(now),
        ),
      );
    }
  }
}
