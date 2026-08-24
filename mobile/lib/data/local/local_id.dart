import 'dart:math';

final _localIdRandom = Random.secure();

/// Generates an opaque local identifier without exposing its creation time.
String newLocalId(String prefix) {
  final value = List.generate(
    4,
    (_) => _localIdRandom.nextInt(1 << 32).toRadixString(16).padLeft(8, '0'),
    growable: false,
  ).join();
  return '$prefix-$value';
}
