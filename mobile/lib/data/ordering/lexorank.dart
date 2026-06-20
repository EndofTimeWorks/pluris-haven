/// Lexorank gives every item a string rank. Reordering an item between two
/// siblings computes a new rank that sorts between them, so only the
/// moved item needs to be persisted - no renumbering of the whole list.
///
/// Format: `<bucket>|<rank>` where bucket is currently always "0" and
/// rank is a lowercase ASCII string from the alphabet 'a'..='z'. The
/// sentinel ranks are '0|aaaaaa' (before everything) and '0|zzzzzz'
/// (after everything).
///
/// When the gap between two ranks is too small to insert a new rank
/// between them at the current length, [between] grows the string by
/// appending a midpoint character to the smaller rank.
class Lexorank {
  const Lexorank._();

  static const String bucket = '0';
  static const String separator = '|';
  static const String minRank = 'aaaaaa';
  static const String maxRank = 'zzzzzz';
  static const String first = '$bucket$separator$minRank';
  static const String last = '$bucket$separator$maxRank';
  static const String alphabet = 'abcdefghijklmnopqrstuvwxyz';

  /// The smallest possible rank. New items prepended to the start of a
  /// list should use this.
  static String firstRank() => first;

  /// The largest possible rank. New items appended to the end of a list
  /// should use this.
  static String lastRank() => last;

  /// Computes a rank that sorts strictly between [prev] and [next].
  /// Either argument may be null - null [prev] is treated as the head
  /// sentinel; null [next] is treated as the tail sentinel.
  ///
  /// Throws [ArgumentError] if [prev] and [next] are both non-null and
  /// [prev] does not sort strictly before [next].
  ///
  /// Throws [StateError] if no rank exists between [prev] and [next]
  /// at any reasonable length - this happens when the gap has been
  /// exhausted by repeated insertions. Callers should catch this and
  /// trigger [rebalanceRanks] on the full list, then retry.
  ///
  /// Strategy: walk the strings in lockstep. When characters differ,
  /// try to find an integer midpoint character between them. If none
  /// exists (adjacent codes), append the alphabet midpoint to [prev]
  /// - this guarantees a rank strictly greater than [prev] (because
  /// it has [prev] as a strict prefix) and strictly less than [next]
  /// (because at the differing position [prev] < [next], so any
  /// extension of [prev] sorts before [next]).
  static String between(String? prev, String? next) {
    final prevRank = _strip(prev) ?? minRank;
    final nextRank = _strip(next) ?? maxRank;
    if (prevRank.compareTo(nextRank) >= 0) {
      throw ArgumentError('prev ($prevRank) must sort before next ($nextRank)');
    }
    final buffer = StringBuffer();
    var i = 0;
    while (i < prevRank.length && i < nextRank.length) {
      final a = prevRank.codeUnitAt(i);
      final b = nextRank.codeUnitAt(i);
      if (a == b) {
        buffer.writeCharCode(a);
        i++;
        continue;
      }
      // Differ at this position. Try integer midpoint.
      final mid = (a + b) ~/ 2;
      if (mid > a) {
        // mid < b is implied because a < b and (a+b)/2 < b for a < b.
        buffer.writeCharCode(mid);
        return '$bucket$separator${buffer.toString()}';
      }
      // Adjacent codes - no integer midpoint. The new rank is prev
      // with a midpoint character appended. This sorts strictly after
      // prev (because it has prev as a strict prefix) and strictly
      // before next (because at position i, prev's character a < b =
      // next's character, so any string with prev as a prefix sorts
      // before next regardless of what follows).
      return '$bucket$separator$prevRank$_midAlphabetChar';
    }
    // One string is a strict prefix of the other.
    if (prevRank.length < nextRank.length) {
      // prevRank is a prefix of nextRank. We need a rank that:
      //   - is strictly greater than prevRank (so it must have prev
      //     as a prefix and then more, OR differ from prev at some
      //     position with a greater character)
      //   - is strictly less than nextRank (so at the first differing
      //     position with nextRank, it must have a smaller character)
      //
      // The first character we add to prevRank is compared against
      // nextRank[i] (the first char of nextRank past the prefix). If
      // nextRank[i] > 'a', we can append 'a' and be done. If
      // nextRank[i] == 'a', no single character will work - we'd need
      // 'a' followed by something smaller than end-of-string, which
      // is impossible. In that case, throw and let the caller
      // rebalance.
      final nextChar = nextRank.codeUnitAt(i);
      if (nextChar > alphabet.codeUnitAt(0)) {
        return '$bucket$separator$prevRank${alphabet[0]}';
      }
      // nextChar is 'a' (smallest in alphabet). No rank exists at
      // this gap without rebalancing.
      throw StateError(
        'lexorank gap exhausted between "$prevRank" and "$nextRank"; '
        'call rebalanceRanks and retry',
      );
    }
    // prevRank and nextRank have the same length and matched at every
    // position - impossible because we already verified prev < next.
    // Defensive: grow prevRank by a midpoint character.
    return '$bucket$separator$prevRank$_midAlphabetChar';
  }

  /// The midpoint character of the alphabet ('n'). Used as the default
  /// growth character because it leaves the most room on both sides
  /// for future insertions.
  static const String _midAlphabetChar = 'n';

  /// Returns a fresh list of evenly-spaced ranks for [count] items.
  /// Use this when [between] throws [StateError] - replace every rank
  /// in the list with the corresponding entry from this output, then
  /// retry the insertion.
  ///
  /// The output is sorted ascending and contains exactly [count] ranks.
  /// The first rank is strictly greater than [firstRank] and the last
  /// is strictly less than [lastRank], leaving headroom for future
  /// prepends and appends without immediately requiring another
  /// rebalance.
  static List<String> rebalanceRanks(int count) {
    if (count <= 0) return const [];
    if (count == 1) return [between(null, null)];
    final ranks = <String>[];
    // Start at the midpoint of the sentinel range so we leave headroom
    // on both ends for future prepends and appends.
    var prev = between(first, last); // midpoint of the full range
    ranks.add(prev);
    for (var i = 1; i < count; i++) {
      // Walk forward from prev toward the tail, leaving headroom.
      final next = between(prev, last);
      ranks.add(next);
      prev = next;
    }
    return ranks;
  }

  /// Strips the bucket prefix and returns the rank portion. Returns null
  /// for null input. Returns the rank unchanged if no separator is found.
  static String? _strip(String? rank) {
    if (rank == null) return null;
    final sep = rank.indexOf(separator);
    if (sep < 0) return rank;
    return rank.substring(sep + 1);
  }

  /// Sorts a list of ranks in place. Items without a rank (null) sort
  /// first.
  static void sortRanks(List<String?> ranks) {
    ranks.sort((a, b) {
      if (a == null && b == null) return 0;
      if (a == null) return -1;
      if (b == null) return 1;
      return a.compareTo(b);
    });
  }
}
