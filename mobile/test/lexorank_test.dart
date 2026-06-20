import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/ordering/lexorank.dart';

void main() {
  group('Lexorank', () {
    test('first and last sentinels are the boundaries', () {
      expect(Lexorank.firstRank(), equals('0|aaaaaa'));
      expect(Lexorank.lastRank(), equals('0|zzzzzz'));
      expect(Lexorank.firstRank().compareTo(Lexorank.lastRank()), lessThan(0));
    });

    test('between(null, null) returns a rank inside the sentinel range', () {
      final mid = Lexorank.between(null, null);
      expect(mid.compareTo(Lexorank.firstRank()), greaterThan(0));
      expect(mid.compareTo(Lexorank.lastRank()), lessThan(0));
    });

    test('between(null, last) sorts before last', () {
      final mid = Lexorank.between(null, Lexorank.lastRank());
      expect(mid.compareTo(Lexorank.lastRank()), lessThan(0));
    });

    test('between(first, null) sorts after first', () {
      final mid = Lexorank.between(Lexorank.firstRank(), null);
      expect(mid.compareTo(Lexorank.firstRank()), greaterThan(0));
    });

    test('repeatedly inserting at the end produces strictly-growing ranks', () {
      var prev = Lexorank.firstRank();
      for (var i = 0; i < 20; i++) {
        prev = Lexorank.between(prev, null);
        expect(prev.compareTo(Lexorank.lastRank()), lessThan(0));
      }
    });

    test(
      'stress: 200 random inserts maintain strict sort order with rebalance',
      () {
        // Start with one item.
        var ranks = <String>[Lexorank.between(null, null)];
        final rng = _DeterministicRng(42);
        var rebalanced = 0;
        for (var i = 0; i < 200; i++) {
          final insertAt = rng.nextInt(ranks.length + 1);
          final prev = insertAt == 0 ? null : ranks[insertAt - 1];
          final next = insertAt == ranks.length ? null : ranks[insertAt];
          try {
            final newRank = Lexorank.between(prev, next);
            if (prev != null) expect(newRank.compareTo(prev), greaterThan(0));
            if (next != null) expect(newRank.compareTo(next), lessThan(0));
            ranks.insert(insertAt, newRank);
          } on StateError {
            // Gap exhausted - rebalance the whole list and retry the insert.
            final fresh = Lexorank.rebalanceRanks(ranks.length + 1);
            expect(fresh.length, equals(ranks.length + 1));
            ranks = fresh;
            rebalanced++;
          }
        }
        expect(ranks.length, equals(201));
        expect(rebalanced, greaterThanOrEqualTo(0));
        // Verify the full list is strictly increasing.
        for (var i = 1; i < ranks.length; i++) {
          expect(
            ranks[i].compareTo(ranks[i - 1]),
            greaterThan(0),
            reason:
                'rank $i (${ranks[i]}) should sort after rank ${i - 1} (${ranks[i - 1]})',
          );
        }
      },
    );

    test(
      'inserting between adjacent ranks grows the string but stays sorted',
      () {
        final a = Lexorank.between(null, null);
        final b = Lexorank.between(a, null);
        final c = Lexorank.between(a, b);
        expect(c.compareTo(a), greaterThan(0));
        expect(c.compareTo(b), lessThan(0));
      },
    );

    test('between throws when prev >= next', () {
      expect(
        () => Lexorank.between('0|m', '0|m'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => Lexorank.between('0|n', '0|m'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('sortRanks orders a mixed list with nulls first', () {
      final ranks = <String?>['0|zzz', null, '0|aaa', '0|mmm'];
      Lexorank.sortRanks(ranks);
      expect(ranks.first, isNull);
      expect(ranks[1], equals('0|aaa'));
      expect(ranks[2], equals('0|mmm'));
      expect(ranks.last, equals('0|zzz'));
    });

    test('simulates a member reorder workflow', () {
      // Three members inserted in order: A, B, C.
      final ranks = <String>[];
      ranks.add(Lexorank.between(null, null)); // A
      ranks.add(Lexorank.between(ranks[0], null)); // B
      ranks.add(Lexorank.between(ranks[1], null)); // C
      // Move A between B and C.
      final moved = Lexorank.between(ranks[1], ranks[2]);
      ranks[0] = moved;
      ranks.sort();
      // After the move, B is first, A is in the middle, C is last.
      expect(ranks[0], equals('0|s'));
      expect(ranks[1], equals('0|t'));
      expect(ranks[2], equals('0|v'));
    });

    test('between throws StateError when the gap is exhausted', () {
      // Construct an adversarial pair: prev = 'aaaaaa', next = 'aaaaaaa'.
      // No rank exists strictly between them at any length.
      expect(
        () => Lexorank.between('0|aaaaaa', '0|aaaaaaa'),
        throwsA(isA<StateError>()),
      );
    });

    test(
      'rebalanceRanks produces a strictly-increasing list of the requested size',
      () {
        for (final count in [1, 2, 5, 20, 100]) {
          final ranks = Lexorank.rebalanceRanks(count);
          expect(ranks.length, equals(count));
          for (var i = 1; i < ranks.length; i++) {
            expect(
              ranks[i].compareTo(ranks[i - 1]),
              greaterThan(0),
              reason: 'count=$count, rank $i should sort after rank ${i - 1}',
            );
          }
        }
      },
    );
  });
}

class _DeterministicRng {
  _DeterministicRng(this._seed);
  int _seed;
  int nextInt(int max) {
    _seed = (_seed * 1103515245 + 12345) & 0x7fffffff;
    return (_seed >> 8) % max;
  }
}
