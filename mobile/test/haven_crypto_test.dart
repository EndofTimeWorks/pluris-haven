import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/security/archive_encryption.dart';
import 'package:pluris_haven/data/security/haven_crypto.dart';

void main() {
  group('HavenCrypto', () {
    late HavenCrypto crypto;

    setUp(() async {
      crypto = HavenCrypto(await generateMasterKey());
    });

    test('encrypt + decrypt round-trips a non-empty string', () async {
      const plain = 'Alice (she/her) - host';
      final cipher = await crypto.encrypt(plain);
      expect(cipher, isNot(equals(plain)));
      expect(cipher, isNotNull);
      final decrypted = await crypto.decrypt(cipher);
      expect(decrypted, equals(plain));
    });

    test(
      'encrypting the same plaintext twice produces different ciphertexts',
      () async {
        const plain = 'same plaintext should encrypt differently';
        final a = await crypto.encrypt(plain);
        final b = await crypto.encrypt(plain);
        expect(a, isNot(equals(b)));
        expect(await crypto.decrypt(a), equals(plain));
        expect(await crypto.decrypt(b), equals(plain));
      },
    );

    test('null and empty pass through unchanged', () async {
      expect(await crypto.encrypt(null), isNull);
      expect(await crypto.encrypt(''), equals(''));
      expect(await crypto.decrypt(null), isNull);
      expect(await crypto.decrypt(''), equals(''));
    });

    test('decrypt throws on tampered ciphertext', () async {
      final cipher = await crypto.encrypt('secret') ?? '';
      // Flip the last character so base64 still decodes, then MAC check fails.
      final tampered =
          cipher.substring(0, cipher.length - 1) +
          (cipher[cipher.length - 1] == 'A' ? 'B' : 'A');
      expect(() => crypto.decrypt(tampered), throwsA(anything));
    });

    test(
      'blindIndex is stable for the same input and case-insensitive',
      () async {
        final a = await crypto.blindIndex('Alice');
        final b = await crypto.blindIndex('alice');
        final c = await crypto.blindIndex('  ALICE  ');
        expect(a, equals(b));
        expect(a, equals(c));
        expect(a.length, equals(64)); // SHA-256 hex
      },
    );

    test('blindIndex differs for different plaintexts', () async {
      final a = await crypto.blindIndex('Alice');
      final b = await crypto.blindIndex('Bob');
      expect(a, isNot(equals(b)));
    });

    test('blindIndexEquals is true for matching indexes', () async {
      final a = await crypto.blindIndex('Alice');
      expect(crypto.blindIndexEquals(a, a), isTrue);
      expect(crypto.blindIndexEquals(a, 'deadbeef'), isFalse);
    });

    test('deriveMasterKey accepts only 32 random bytes', () async {
      final key = await deriveMasterKey(
        List<int>.generate(32, (index) => index),
      );
      expect((await key.extractBytes()).length, equals(32));
      await expectLater(deriveMasterKey(const [1, 2, 3]), throwsArgumentError);
    });

    test('derived keys decrypt across crypto instances', () async {
      final key = await deriveMasterKey(List<int>.filled(32, 7));
      final first = HavenCrypto(key);
      final second = HavenCrypto(key);
      final cipher = await first.encrypt('portable encrypted note');
      expect(await second.decrypt(cipher), equals('portable encrypted note'));
    });

    test('AAD binds ciphertext to its storage context', () async {
      final cipher = await crypto.encrypt('private note', aad: 'notes:1:body');
      expect(
        await crypto.decrypt(cipher, aad: 'notes:1:body'),
        equals('private note'),
      );
      await expectLater(
        crypto.decrypt(cipher, aad: 'notes:2:body'),
        throwsA(anything),
      );
    });
  });

  group('archive encryption', () {
    test('encrypts and decrypts a local archive JSON payload', () async {
      const archive =
          '{"format":"pluris_haven.local_archive","version":1,"members":[]}';
      final encrypted = await encryptArchiveJson(
        archiveJson: archive,
        passphrase: 'correct horse battery staple',
        iterations: 1200,
      );

      expect(encrypted, isNot(contains('local_archive')));
      expect(archiveTextLooksEncrypted(encrypted), isTrue);
      expect(
        await decryptArchiveJson(
          encryptedArchiveJson: encrypted,
          passphrase: 'correct horse battery staple',
        ),
        equals(archive),
      );
    });

    test('wrong passphrase does not decrypt an archive', () async {
      final encrypted = await encryptArchiveJson(
        archiveJson: '{"format":"pluris_haven.local_archive","version":1}',
        passphrase: 'right-password',
        iterations: 1200,
      );

      expect(
        () => decryptArchiveJson(
          encryptedArchiveJson: encrypted,
          passphrase: 'wrong-password',
        ),
        throwsA(anything),
      );
    });

    test('tampered archive metadata is rejected before decrypting', () async {
      final encrypted = await encryptArchiveJson(
        archiveJson: '{"format":"pluris_haven.local_archive","version":1}',
        passphrase: 'right-password',
        iterations: 1200,
      );
      final decoded = jsonDecode(encrypted) as Map<String, Object?>;
      decoded['cipher'] = 'AES-GCM';

      expect(
        () => decryptArchiveJson(
          encryptedArchiveJson: jsonEncode(decoded),
          passphrase: 'right-password',
        ),
        throwsFormatException,
      );
    });

    test('authenticated archive metadata cannot be lowered', () async {
      final encrypted = await encryptArchiveJson(
        archiveJson: '{"format":"pluris_haven.local_archive","version":1}',
        passphrase: 'right-password',
        iterations: 1200,
      );
      final decoded = jsonDecode(encrypted) as Map<String, Object?>;
      decoded['iterations'] = 1000;

      await expectLater(
        decryptArchiveJson(
          encryptedArchiveJson: jsonEncode(decoded),
          passphrase: 'right-password',
        ),
        throwsA(anything),
      );
    });
  });
}
