import 'dart:convert';

import 'package:cryptography/cryptography.dart';

const encryptedArchiveFormat = 'pluris_haven.encrypted_archive';
const encryptedArchiveVersion = 1;
const encryptedArchiveKdf = 'PBKDF2-HMAC-SHA256';
const encryptedArchiveCipher = 'XChaCha20-Poly1305';
const defaultArchiveKdfIterations = 210000;

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
}) async {
  if (passphrase.isEmpty) {
    throw ArgumentError.value(passphrase, 'passphrase', 'must not be empty');
  }
  if (iterations < 1000) {
    throw ArgumentError.value(
      iterations,
      'iterations',
      'must be at least 1000',
    );
  }

  final salt = _archiveCipher.newNonce();
  final nonce = _archiveCipher.newNonce();
  final secretKey = await _archiveKey(
    passphrase: passphrase,
    salt: salt,
    iterations: iterations,
  );
  final box = await _archiveCipher.encrypt(
    utf8.encode(archiveJson),
    secretKey: secretKey,
    nonce: nonce,
  );
  final payload = {
    'format': encryptedArchiveFormat,
    'version': encryptedArchiveVersion,
    'cipher': encryptedArchiveCipher,
    'kdf': encryptedArchiveKdf,
    'iterations': iterations,
    'salt': base64Url.encode(salt),
    'ciphertext': base64Url.encode(box.concatenation()),
  };
  return const JsonEncoder.withIndent('  ').convert(payload);
}

Future<String> decryptArchiveJson({
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
  if (decoded['version'] != encryptedArchiveVersion) {
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
  if (iterations is! int || iterations < 1000) {
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
  final plain = await _archiveCipher.decrypt(box, secretKey: secretKey);
  return utf8.decode(plain);
}

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
