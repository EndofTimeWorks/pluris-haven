import 'package:flutter_test/flutter_test.dart';
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

    test(
      'deriveMasterKey produces a 32-byte key from arbitrary input',
      () async {
        final key = await deriveMasterKey('any long passphrase'.codeUnits);
        final extracted = await key.extractBytes();
        expect(extracted.length, equals(32));
      },
    );

    test('derived keys decrypt across crypto instances', () async {
      final key = await deriveMasterKey('shared local secret'.codeUnits);
      final first = HavenCrypto(key);
      final second = HavenCrypto(key);
      final cipher = await first.encrypt('portable encrypted note');
      expect(await second.decrypt(cipher), equals('portable encrypted note'));
    });
  });
}
