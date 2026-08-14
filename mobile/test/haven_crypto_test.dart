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
    const archive =
        '{"format":"pluris_haven.local_archive","version":1,"members":[]}';
    const passphrase = 'violet river 92! lantern';
    late String encrypted;

    setUpAll(() async {
      encrypted = await encryptArchiveJson(
        archiveJson: archive,
        passphrase: passphrase,
      );
    });

    test('encrypts and decrypts a local archive JSON payload', () async {
      final decoded = jsonDecode(encrypted) as Map<String, Object?>;

      expect(encrypted, isNot(contains('local_archive')));
      expect(archiveTextLooksEncrypted(encrypted), isTrue);
      expect(decoded['version'], encryptedArchiveVersion);
      expect(decoded['kdf'], encryptedArchiveKdf);
      expect(decoded['memory_kib'], defaultArchiveKdfMemoryKib);
      expect(decoded['iterations'], defaultArchiveKdfIterations);
      expect(decoded['parallelism'], defaultArchiveKdfParallelism);
      expect(
        await decryptArchiveJson(
          encryptedArchiveJson: encrypted,
          passphrase: passphrase,
        ),
        equals(archive),
      );
    });

    test('wrong passphrase does not decrypt an archive', () async {
      expect(
        () => decryptArchiveJson(
          encryptedArchiveJson: encrypted,
          passphrase: 'copper cloud 51! maple',
        ),
        throwsA(anything),
      );
    });

    test('tampered archive metadata is rejected before decrypting', () async {
      final decoded = jsonDecode(encrypted) as Map<String, Object?>;
      decoded['cipher'] = 'AES-GCM';

      expect(
        () => decryptArchiveJson(
          encryptedArchiveJson: jsonEncode(decoded),
          passphrase: 'violet river 92! lantern',
        ),
        throwsFormatException,
      );
    });

    test('authenticated Argon2id metadata cannot be altered', () async {
      final decoded = jsonDecode(encrypted) as Map<String, Object?>;
      decoded['memory_kib'] = defaultArchiveKdfMemoryKib - 1;

      await expectLater(
        decryptArchiveJson(
          encryptedArchiveJson: jsonEncode(decoded),
          passphrase: passphrase,
        ),
        throwsA(anything),
      );
    });

    test('rejects unsafe Argon2id parameters before deriving a key', () async {
      for (final parameters in [
        {'memory_kib': maximumArchiveKdfMemoryKib + 1},
        {'iterations': maximumArchiveKdfIterations + 1},
        {'parallelism': maximumArchiveKdfParallelism + 1},
        {'memory_kib': 7},
      ]) {
        final decoded = jsonDecode(encrypted) as Map<String, Object?>;
        decoded.addAll(parameters);

        await expectLater(
          decryptArchiveJson(
            encryptedArchiveJson: jsonEncode(decoded),
            passphrase: passphrase,
          ),
          throwsFormatException,
        );
      }
    });

    test('decrypts a fixed version 2 PBKDF2 archive', () async {
      const legacy =
          '{"format":"pluris_haven.encrypted_archive","version":2,'
          '"cipher":"XChaCha20-Poly1305","kdf":"PBKDF2-HMAC-SHA256",'
          '"iterations":1200,'
          '"salt":"Er7__b-nwpv705a-J2P62-Cgb3bLQfIw",'
          '"ciphertext":"Sm5fJ7Ta7kAqEO-tYO48ytw8XKcNtG-ddc4FRSagSMRrOmuhKYZpEvLH6lnKkyeWBEMrTdjKWLQngbzbzWZj_F7ct_JM7vO-caxAHS3aR-xsYEyxNJDk1VpOUA=="}';

      expect(
        await decryptArchiveJson(
          encryptedArchiveJson: legacy,
          passphrase: passphrase,
        ),
        '{"format":"pluris_haven.local_archive","version":1}',
      );
    });

    test('refuses a weak passphrase before writing an archive', () async {
      const rejected = 'too short';
      await expectLater(
        encryptArchiveJson(
          archiveJson: '{"format":"pluris_haven.local_archive","version":1}',
          passphrase: rejected,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.toString(),
            'message',
            isNot(contains(rejected)),
          ),
        ),
      );
    });

    test('refuses common and repetitive recovery passphrases', () {
      expect(
        archivePassphraseIssue('passwordpassword'),
        ArchivePassphraseIssue.common,
      );
      expect(
        archivePassphraseIssue('PasswordPassword1!'),
        ArchivePassphraseIssue.common,
      );
      expect(
        archivePassphraseIssue('qwerty-forest-92'),
        ArchivePassphraseIssue.common,
      );
      expect(
        archivePassphraseIssue('abcdabcdabcdabcd'),
        ArchivePassphraseIssue.repetitive,
      );
      expect(archivePassphraseIssue('violet river 92! lantern'), isNull);
    });

    test('generates unique high-entropy recovery passphrases', () async {
      final generated = <String>{};
      for (var index = 0; index < 8; index++) {
        final passphrase = await generateArchivePassphrase();
        expect(
          passphrase,
          matches(RegExp(r'^[A-Za-z0-9_-]{4}(\.[A-Za-z0-9_-]{4}){7}$')),
        );
        expect(archivePassphraseIssue(passphrase), isNull);
        generated.add(passphrase);
      }
      expect(generated, hasLength(8));
    });
  });
}
