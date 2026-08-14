import 'dart:convert';
import 'dart:isolate';

import 'package:cryptography/cryptography.dart';

const encryptedArchiveFormat = 'pluris_haven.encrypted_archive';
const encryptedArchiveVersion = 2;
const encryptedArchiveKdf = 'PBKDF2-HMAC-SHA256';
const encryptedArchiveCipher = 'XChaCha20-Poly1305';

/// A recovery archive can be copied anywhere and attacked offline. Keep the
/// creation cost deliberately high; existing archives retain their recorded
/// value so they can still be recovered.
const defaultArchiveKdfIterations = 600000;
const maximumArchiveKdfIterations = 1000000;
const minimumArchivePassphraseCharacters = 14;

enum ArchivePassphraseIssue { tooShort, common, repetitive }

const _commonArchivePassphrases = {
  '12345678901234',
  'correcthorsebatterystaple',
  'iloveyouiloveyou',
  'letmeinletmein',
  'password123456',
  'passwordpassword',
  'qwertyuiopasdfgh',
  'thisismypassword',
};

final _archiveCipher = Xchacha20.poly1305Aead();

bool archiveTextLooksEncrypted(String text) {
  try {
    final decoded = jsonDecode(text);
    return decoded is Map<String, Object?> &&
        decoded['format'] == encryptedArchiveFormat;
  } on FormatException {
    return false;
  }
}

Future<String> encryptArchiveJson({
  required String archiveJson,
  required String passphrase,
  int iterations = defaultArchiveKdfIterations,
}) {
  return Isolate.run(
    () => _encryptArchiveJson(
      archiveJson: archiveJson,
      passphrase: passphrase,
      iterations: iterations,
    ),
  );
}

Future<String> _encryptArchiveJson({
  required String archiveJson,
  required String passphrase,
  required int iterations,
}) async {
  if (!isArchivePassphraseValid(passphrase)) {
    throw ArgumentError.value(
      passphrase,
      'passphrase',
      'must contain at least $minimumArchivePassphraseCharacters characters',
    );
  }
  if (iterations < 1000 || iterations > maximumArchiveKdfIterations) {
    throw ArgumentError.value(
      iterations,
      'iterations',
      'must be between 1000 and $maximumArchiveKdfIterations',
    );
  }

  final salt = _archiveCipher.newNonce();
  final nonce = _archiveCipher.newNonce();
  final secretKey = await _archiveKey(
    passphrase: passphrase,
    salt: salt,
    iterations: iterations,
  );
  final header = <String, Object?>{
    'format': encryptedArchiveFormat,
    'version': encryptedArchiveVersion,
    'cipher': encryptedArchiveCipher,
    'kdf': encryptedArchiveKdf,
    'iterations': iterations,
    'salt': base64Url.encode(salt),
  };
  final box = await _archiveCipher.encrypt(
    utf8.encode(archiveJson),
    secretKey: secretKey,
    nonce: nonce,
    aad: _archiveHeaderAad(header),
  );
  final payload = {
    ...header,
    'ciphertext': base64Url.encode(box.concatenation()),
  };
  return const JsonEncoder.withIndent('  ').convert(payload);
}

ArchivePassphraseIssue? archivePassphraseIssue(String passphrase) {
  final trimmed = passphrase.trim();
  final runes = trimmed.runes.toList(growable: false);
  if (runes.length < minimumArchivePassphraseCharacters) {
    return ArchivePassphraseIssue.tooShort;
  }

  final normalized = trimmed.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  if (_commonArchivePassphrases.contains(normalized)) {
    return ArchivePassphraseIssue.common;
  }
  if (runes.toSet().length < 4 || _isRepeatedPassphrase(runes)) {
    return ArchivePassphraseIssue.repetitive;
  }
  return null;
}

bool isArchivePassphraseValid(String passphrase) =>
    archivePassphraseIssue(passphrase) == null;

bool _isRepeatedPassphrase(List<int> runes) {
  for (var unitLength = 1; unitLength <= runes.length ~/ 2; unitLength++) {
    if (runes.length % unitLength != 0) continue;
    var matches = true;
    for (var index = unitLength; index < runes.length; index++) {
      if (runes[index] != runes[index % unitLength]) {
        matches = false;
        break;
      }
    }
    if (matches) return true;
  }
  return false;
}

Future<String> decryptArchiveJson({
  required String encryptedArchiveJson,
  required String passphrase,
}) {
  return Isolate.run(
    () => _decryptArchiveJson(
      encryptedArchiveJson: encryptedArchiveJson,
      passphrase: passphrase,
    ),
  );
}

Future<String> _decryptArchiveJson({
  required String encryptedArchiveJson,
  required String passphrase,
}) async {
  if (passphrase.isEmpty) {
    throw ArgumentError.value(passphrase, 'passphrase', 'must not be empty');
  }

  final decoded = jsonDecode(encryptedArchiveJson);
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('Expected an encrypted archive JSON object.');
  }
  if (decoded['format'] != encryptedArchiveFormat) {
    throw const FormatException(
      'This is not an encrypted Pluris Haven archive.',
    );
  }
  final version = decoded['version'];
  if (version != 1 && version != encryptedArchiveVersion) {
    throw FormatException(
      'Unsupported encrypted archive version: ${decoded['version']}.',
    );
  }
  if (decoded['cipher'] != encryptedArchiveCipher) {
    throw FormatException('Unsupported archive cipher: ${decoded['cipher']}.');
  }
  if (decoded['kdf'] != encryptedArchiveKdf) {
    throw FormatException('Unsupported archive KDF: ${decoded['kdf']}.');
  }

  final iterations = decoded['iterations'];
  final salt = decoded['salt'];
  final ciphertext = decoded['ciphertext'];
  if (iterations is! int ||
      iterations < 1000 ||
      iterations > maximumArchiveKdfIterations) {
    throw const FormatException(
      'Encrypted archive has invalid KDF iterations.',
    );
  }
  if (salt is! String || ciphertext is! String) {
    throw const FormatException('Encrypted archive is missing salt or data.');
  }

  final secretKey = await _archiveKey(
    passphrase: passphrase,
    salt: base64Url.decode(salt),
    iterations: iterations,
  );
  final box = SecretBox.fromConcatenation(
    base64Url.decode(ciphertext),
    nonceLength: _archiveCipher.nonceLength,
    macLength: _archiveCipher.macAlgorithm.macLength,
    copy: false,
  );
  final plain = await _archiveCipher.decrypt(
    box,
    secretKey: secretKey,
    aad: version == encryptedArchiveVersion
        ? _archiveHeaderAad(decoded)
        : const [],
  );
  return utf8.decode(plain);
}

List<int> _archiveHeaderAad(Map<String, Object?> header) => utf8.encode(
  jsonEncode({
    'format': header['format'],
    'version': header['version'],
    'cipher': header['cipher'],
    'kdf': header['kdf'],
    'iterations': header['iterations'],
    'salt': header['salt'],
  }),
);

Future<SecretKey> _archiveKey({
  required String passphrase,
  required List<int> salt,
  required int iterations,
}) {
  return Pbkdf2.hmacSha256(
    iterations: iterations,
    bits: 256,
  ).deriveKeyFromPassword(password: passphrase, nonce: salt);
}
