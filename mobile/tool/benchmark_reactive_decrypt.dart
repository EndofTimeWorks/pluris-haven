import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:pluris_haven/data/security/haven_crypto.dart';

const _fieldCount = 9;
const _rowCounts = [10, 50, 200];
const _measuredPasses = 5;

Future<void> main() async {
  final crypto = HavenCrypto(
    SecretKey(List<int>.generate(32, (index) => index)),
  );

  stdout.writeln('Reactive member decrypt baseline');
  stdout.writeln('fields per row: $_fieldCount');
  stdout.writeln('passes per size: $_measuredPasses');

  for (final rowCount in _rowCounts) {
    final fields = <({String aad, String ciphertext})>[];
    for (var row = 0; row < rowCount; row++) {
      for (var field = 0; field < _fieldCount; field++) {
        final aad = 'members:member-$row:field-$field';
        fields.add((
          aad: aad,
          ciphertext: (await crypto.encrypt('value-$row-$field', aad: aad))!,
        ));
      }
    }

    await _decryptPass(crypto, fields);
    final stopwatch = Stopwatch()..start();
    for (var pass = 0; pass < _measuredPasses; pass++) {
      await _decryptPass(crypto, fields);
    }
    stopwatch.stop();

    final decryptions = fields.length * _measuredPasses;
    final averageMilliseconds =
        stopwatch.elapsedMicroseconds / 1000 / _measuredPasses;
    final perSecond = decryptions * 1000000 / stopwatch.elapsedMicroseconds;
    stdout.writeln(
      '$rowCount rows: ${averageMilliseconds.toStringAsFixed(2)} ms/pass, '
      '${perSecond.toStringAsFixed(0)} decryptions/s',
    );
  }
}

Future<void> _decryptPass(
  HavenCrypto crypto,
  List<({String aad, String ciphertext})> fields,
) async {
  for (final field in fields) {
    await crypto.decrypt(field.ciphertext, aad: field.aad);
  }
}
