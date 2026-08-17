import 'package:drift/drift.dart';

import 'app_database.dart';
import 'local_text_codec.dart';

enum PollKind {
  singleChoice('single_choice', 'Single choice'),
  multipleChoice('multiple_choice', 'Multiple choice');

  const PollKind(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static PollKind fromStorage(String? value) {
    return PollKind.values.firstWhere(
      (kind) => kind.storageValue == value,
      orElse: () => PollKind.singleChoice,
    );
  }
}

class PollOptionSummary {
  const PollOptionSummary({
    required this.id,
    required this.body,
    required this.position,
    required this.selected,
  });

  final String id;
  final String body;
  final int position;
  final bool selected;
}

class PollSummary {
  const PollSummary({
    required this.id,
    required this.question,
    this.description,
    required this.kind,
    required this.closed,
    required this.options,
    required this.updatedAt,
  });

  final String id;
  final String question;
  final String? description;
  final PollKind kind;
  final bool closed;
  final List<PollOptionSummary> options;
  final DateTime updatedAt;

  int get selectedCount => options.where((option) => option.selected).length;

  String get statusLabel => closed ? 'closed' : 'open';
}

class PollDraft {
  const PollDraft({
    required this.question,
    this.description,
    required this.kind,
    required this.options,
  });

  final String question;
  final String? description;
  final PollKind kind;
  final List<String> options;
}

class LocalPollStore {
  LocalPollStore(
    this.database, {
    required this.encryptText,
    required this.encryptNullableText,
    required this.decryptText,
  });

  final AppDatabase database;
  final EncryptLocalText encryptText;
  final EncryptNullableLocalText encryptNullableText;
  final DecryptLocalText decryptText;

  Stream<List<PollSummary>> watch() {
    final query = database.select(database.polls)
      ..where((poll) => poll.systemId.equals(localSystemId))
      ..orderBy([
        (poll) =>
            OrderingTerm(expression: poll.updatedAt, mode: OrderingMode.desc),
      ]);
    return query.watch().asyncMap(_summaries);
  }

  Future<List<PollSummary>> _summaries(List<Poll> rows) async {
    if (rows.isEmpty) return const [];

    final pollIds = rows.map((row) => row.id).toList(growable: false);
    final options =
        await (database.select(database.pollOptions)
              ..where((option) => option.pollId.isIn(pollIds))
              ..orderBy([
                (option) => OrderingTerm(
                  expression: option.position,
                  mode: OrderingMode.asc,
                ),
              ]))
            .get();
    final votes = await (database.select(
      database.pollVotes,
    )..where((vote) => vote.pollId.isIn(pollIds))).get();
    final optionsByPoll = <String, List<PollOption>>{};
    for (final option in options) {
      optionsByPoll.putIfAbsent(option.pollId, () => []).add(option);
    }
    final selectedByPoll = <String, Set<String>>{};
    for (final vote in votes) {
      selectedByPoll.putIfAbsent(vote.pollId, () => {}).add(vote.optionId);
    }

    return [
      for (final row in rows)
        await _summary(
          row,
          optionsByPoll[row.id] ?? const [],
          selectedByPoll[row.id] ?? const {},
        ),
    ];
  }

  Future<PollSummary> _summary(
    Poll row,
    List<PollOption> options,
    Set<String> selectedOptionIds,
  ) async {
    final question = await decryptText(
      row.question,
      'polls',
      row.id,
      'question',
    );
    if (question == null) {
      throw StateError('Protected poll question is unexpectedly null.');
    }
    return PollSummary(
      id: row.id,
      question: question,
      description: await decryptText(
        row.description,
        'polls',
        row.id,
        'description',
      ),
      kind: PollKind.fromStorage(row.kind),
      closed: row.closed,
      updatedAt: row.updatedAt,
      options: [
        for (final option in options)
          PollOptionSummary(
            id: option.id,
            body:
                (await decryptText(
                  option.body,
                  'poll_options',
                  option.id,
                  'body',
                )) ??
                '',
            position: option.position,
            selected: selectedOptionIds.contains(option.id),
          ),
      ],
    );
  }

  Future<void> save(PollDraft draft) async {
    final question = draft.question.trim();
    final options = _cleanOptions(draft.options);
    if (question.isEmpty || options.length < 2) return;

    final now = DateTime.now().toUtc();
    final pollId = 'poll-${now.microsecondsSinceEpoch}';
    await database.transaction(() async {
      await database
          .into(database.polls)
          .insert(
            PollsCompanion.insert(
              id: pollId,
              systemId: localSystemId,
              question: await encryptText(
                question,
                'polls',
                pollId,
                'question',
              ),
              description: Value(
                await encryptNullableText(
                  _nullIfBlank(draft.description),
                  'polls',
                  pollId,
                  'description',
                ),
              ),
              kind: Value(draft.kind.storageValue),
              createdAt: now,
              updatedAt: now,
            ),
          );

      final encryptedOptions = [
        for (var index = 0; index < options.length; index++)
          await encryptText(
            options[index],
            'poll_options',
            '$pollId-option-$index',
            'body',
          ),
      ];
      await database.batch((batch) {
        batch.insertAll(database.pollOptions, [
          for (var index = 0; index < encryptedOptions.length; index++)
            PollOptionsCompanion.insert(
              id: '$pollId-option-$index',
              pollId: pollId,
              body: encryptedOptions[index],
              position: index,
            ),
        ]);
      });
    });
  }

  Future<void> toggleOption(String pollId, String optionId) async {
    final poll =
        await (database.select(database.polls)..where(
              (poll) =>
                  poll.systemId.equals(localSystemId) & poll.id.equals(pollId),
            ))
            .getSingleOrNull();
    if (poll == null || poll.closed) return;

    final option =
        await (database.select(database.pollOptions)..where(
              (option) =>
                  option.pollId.equals(pollId) & option.id.equals(optionId),
            ))
            .getSingleOrNull();
    if (option == null) return;

    final existing =
        await (database.select(database.pollVotes)..where(
              (vote) =>
                  vote.pollId.equals(pollId) & vote.optionId.equals(optionId),
            ))
            .getSingleOrNull();
    final now = DateTime.now().toUtc();

    await database.transaction(() async {
      if (PollKind.fromStorage(poll.kind) == PollKind.singleChoice) {
        await (database.delete(
          database.pollVotes,
        )..where((vote) => vote.pollId.equals(pollId))).go();
        if (existing == null) {
          await database
              .into(database.pollVotes)
              .insert(
                PollVotesCompanion.insert(
                  pollId: pollId,
                  optionId: optionId,
                  createdAt: now,
                ),
              );
        }
      } else if (existing == null) {
        await database
            .into(database.pollVotes)
            .insert(
              PollVotesCompanion.insert(
                pollId: pollId,
                optionId: optionId,
                createdAt: now,
              ),
            );
      } else {
        await (database.delete(database.pollVotes)..where(
              (vote) =>
                  vote.pollId.equals(pollId) & vote.optionId.equals(optionId),
            ))
            .go();
      }

      await (database.update(database.polls)
            ..where((poll) => poll.id.equals(pollId)))
          .write(PollsCompanion(updatedAt: Value(now)));
    });
  }

  Future<void> close(String pollId) {
    return (database.update(database.polls)..where(
          (poll) =>
              poll.systemId.equals(localSystemId) & poll.id.equals(pollId),
        ))
        .write(
          PollsCompanion(
            closed: const Value(true),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
  }

  Future<void> delete(String pollId) {
    return database.transaction(() async {
      await (database.delete(
        database.pollVotes,
      )..where((vote) => vote.pollId.equals(pollId))).go();
      await (database.delete(
        database.pollOptions,
      )..where((option) => option.pollId.equals(pollId))).go();
      await (database.delete(database.polls)..where(
            (poll) =>
                poll.systemId.equals(localSystemId) & poll.id.equals(pollId),
          ))
          .go();
    });
  }

  Stream<List<PollVoteEvent>> watchVoteEvents(String pollId) {
    final query = database.select(database.pollVoteEvents)
      ..where((event) => event.pollId.equals(pollId))
      ..orderBy([
        (event) =>
            OrderingTerm(expression: event.createdAt, mode: OrderingMode.desc),
      ]);
    return query.watch();
  }

  List<String> _cleanOptions(List<String> options) {
    final seen = <String>{};
    final cleaned = <String>[];
    for (final option in options) {
      final trimmed = option.trim();
      if (trimmed.isEmpty) continue;
      if (seen.add(trimmed.toLowerCase())) cleaned.add(trimmed);
    }
    return cleaned;
  }

  String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
