import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/security/archive_encryption.dart';

void main() {
  group('native archive frame', () {
    late ArchiveRecoveryCode recoveryCode;
    late Uint8List plaintext;
    late Uint8List container;

    setUpAll(() async {
      recoveryCode = await generateArchiveRecoveryCode();
      plaintext = Uint8List.fromList(
        List<int>.generate(32 * 1024, (index) => index % 251),
      );
      container = await encryptNativeArchiveFrame(
        plaintext: plaintext,
        recoveryCode: recoveryCode,
      );
    });

    test(
      'uses magic rather than a filename and round-trips a bounded frame',
      () async {
        expect(container.take(nativeArchiveMagic.length), nativeArchiveMagic);
        expect(container, isNot(contains(plaintext.take(32))));
        expect(
          await decryptNativeArchiveFrame(
            container: container,
            passphrase: recoveryCode.value,
          ),
          orderedEquals(plaintext),
        );
      },
    );

    test('rejects a wrong portable unlock key', () async {
      final wrongCode = await generateArchiveRecoveryCode();

      await expectLater(
        decryptNativeArchiveFrame(
          container: container,
          passphrase: wrongCode.value,
        ),
        throwsA(anything),
      );
    });

    test('rejects a tampered authenticated frame', () async {
      final tampered = Uint8List.fromList(container)
        ..[container.length - 1] ^= 1;

      await expectLater(
        decryptNativeArchiveFrame(
          container: tampered,
          passphrase: recoveryCode.value,
        ),
        throwsA(anything),
      );
    });

    test('rejects invalid framing before password work', () async {
      final wrongMagic = Uint8List.fromList(container)..[0] ^= 1;
      final unsupportedVersion = Uint8List.fromList(container)..[4] = 2;

      for (final invalid in [Uint8List(8), wrongMagic, unsupportedVersion]) {
        await expectLater(
          decryptNativeArchiveFrame(
            container: invalid,
            passphrase: recoveryCode.value,
          ),
          throwsFormatException,
        );
      }
    });

    test('rejects oversized and empty plaintext frames', () async {
      await expectLater(
        encryptNativeArchiveFrame(
          plaintext: Uint8List(nativeArchiveMaximumFramePlainBytes + 1),
          recoveryCode: recoveryCode,
        ),
        throwsArgumentError,
      );
      await expectLater(
        encryptNativeArchiveFrame(
          plaintext: Uint8List(0),
          recoveryCode: recoveryCode,
        ),
        throwsArgumentError,
      );
    });
  });
}
