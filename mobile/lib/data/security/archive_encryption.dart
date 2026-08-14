import 'dart:convert';
import 'dart:isolate';

import 'package:cryptography/cryptography.dart';

const encryptedArchiveFormat = 'pluris_haven.encrypted_archive';
const encryptedArchiveVersion = 3;
const encryptedArchiveKdf = 'Argon2id';
const encryptedArchiveCipher = 'XChaCha20-Poly1305';

/// A recovery archive can be copied anywhere and attacked offline. Keep the
/// creation cost deliberately high. These are OWASP's Argon2id minimums.
const defaultArchiveKdfMemoryKib = 19456;
const defaultArchiveKdfIterations = 2;
const defaultArchiveKdfParallelism = 1;
const maximumArchiveKdfMemoryKib = 65536;
const maximumArchiveKdfIterations = 10;
const maximumArchiveKdfParallelism = 4;
const minimumArchivePassphraseCharacters = 16;

const _legacyArchiveKdf = 'PBKDF2-HMAC-SHA256';
const _maximumLegacyArchiveKdfIterations = 1000000;

enum ArchivePassphraseIssue { tooShort, common, repetitive }

const _commonArchivePassphraseFragments = {
  '123456',
  'correcthorsebatterystaple',
  'iloveyou',
  'letmein',
  'password',
  'qwerty',
};

final _archiveCipher = Xchacha20.poly1305Aead();

final class ArchiveRecoveryCode {
  const ArchiveRecoveryCode._(this.value);

  final String value;
}

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
  required ArchiveRecoveryCode recoveryCode,
}) {
  return Isolate.run(
    () => _encryptArchiveJson(
      archiveJson: archiveJson,
      passphrase: recoveryCode.value,
    ),
  );
}

Future<String> _encryptArchiveJson({
  required String archiveJson,
  required String passphrase,
}) async {
  if (!isArchivePassphraseValid(passphrase)) {
    throw ArgumentError(
      'Recovery passphrase does not meet the safety requirements.',
    );
  }

  final salt = _archiveCipher.newNonce();
  final nonce = _archiveCipher.newNonce();
  final secretKey = await _argon2ArchiveKey(
    passphrase: passphrase,
    salt: salt,
    memoryKib: defaultArchiveKdfMemoryKib,
    iterations: defaultArchiveKdfIterations,
    parallelism: defaultArchiveKdfParallelism,
  );
  final header = <String, Object?>{
    'format': encryptedArchiveFormat,
    'version': encryptedArchiveVersion,
    'cipher': encryptedArchiveCipher,
    'kdf': encryptedArchiveKdf,
    'memory_kib': defaultArchiveKdfMemoryKib,
    'iterations': defaultArchiveKdfIterations,
    'parallelism': defaultArchiveKdfParallelism,
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
  if (_commonArchivePassphraseFragments.any(normalized.contains)) {
    return ArchivePassphraseIssue.common;
  }
  if (runes.toSet().length < 4 || _isRepeatedPassphrase(runes)) {
    return ArchivePassphraseIssue.repetitive;
  }
  return null;
}

bool isArchivePassphraseValid(String passphrase) =>
    archivePassphraseIssue(passphrase) == null;

/// Generates a 192-bit recovery code locally using the platform CSPRNG.
Future<ArchiveRecoveryCode> generateArchiveRecoveryCode() async {
  for (var attempt = 0; attempt < 8; attempt++) {
    final bytes = await SecretKeyData.random(length: 24).extractBytes();
    final encoded = base64Url.encode(bytes).replaceAll('=', '');
    final grouped = List.generate(
      encoded.length ~/ 4,
      (index) => encoded.substring(index * 4, index * 4 + 4),
      growable: false,
    ).join('.');
    if (isArchivePassphraseValid(grouped)) {
      return ArchiveRecoveryCode._(grouped);
    }
  }
  throw StateError('Could not generate a recovery passphrase.');
}

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
  if (version != 1 && version != 2 && version != encryptedArchiveVersion) {
    throw FormatException(
      'Unsupported encrypted archive version: ${decoded['version']}.',
    );
  }
  if (decoded['cipher'] != encryptedArchiveCipher) {
    throw FormatException('Unsupported archive cipher: ${decoded['cipher']}.');
  }
  final salt = decoded['salt'];
  final ciphertext = decoded['ciphertext'];
  if (salt is! String || ciphertext is! String) {
    throw const FormatException('Encrypted archive is missing salt or data.');
  }
  final saltBytes = base64Url.decode(salt);
  if (saltBytes.length != _archiveCipher.nonceLength) {
    throw const FormatException('Encrypted archive has an invalid salt.');
  }

  final SecretKey secretKey;
  if (version == encryptedArchiveVersion) {
    if (decoded['kdf'] != encryptedArchiveKdf) {
      throw FormatException('Unsupported archive KDF: ${decoded['kdf']}.');
    }
    final memoryKib = decoded['memory_kib'];
    final iterations = decoded['iterations'];
    final parallelism = decoded['parallelism'];
    if (memoryKib is! int ||
        iterations is! int ||
        parallelism is! int ||
        parallelism < 1 ||
        parallelism > maximumArchiveKdfParallelism ||
        memoryKib < 8 * parallelism ||
        memoryKib > maximumArchiveKdfMemoryKib ||
        iterations < 1 ||
        iterations > maximumArchiveKdfIterations) {
      throw const FormatException(
        'Encrypted archive has invalid Argon2id parameters.',
      );
    }
    secretKey = await _argon2ArchiveKey(
      passphrase: passphrase,
      salt: saltBytes,
      memoryKib: memoryKib,
      iterations: iterations,
      parallelism: parallelism,
    );
  } else {
    if (decoded['kdf'] != _legacyArchiveKdf) {
      throw FormatException('Unsupported archive KDF: ${decoded['kdf']}.');
    }
    final iterations = decoded['iterations'];
    if (iterations is! int ||
        iterations < 1000 ||
        iterations > _maximumLegacyArchiveKdfIterations) {
      throw const FormatException(
        'Encrypted archive has invalid KDF iterations.',
      );
    }
    secretKey = await _legacyArchiveKey(
      passphrase: passphrase,
      salt: saltBytes,
      iterations: iterations,
    );
  }
  final box = SecretBox.fromConcatenation(
    base64Url.decode(ciphertext),
    nonceLength: _archiveCipher.nonceLength,
    macLength: _archiveCipher.macAlgorithm.macLength,
    copy: false,
  );
  final plain = await _archiveCipher.decrypt(
    box,
    secretKey: secretKey,
    aad: version == 1 ? const [] : _archiveHeaderAad(decoded),
  );
  return utf8.decode(plain);
}

List<int> _archiveHeaderAad(Map<String, Object?> header) {
  final aad = <String, Object?>{
    'format': header['format'],
    'version': header['version'],
    'cipher': header['cipher'],
    'kdf': header['kdf'],
  };
  if (header['version'] == encryptedArchiveVersion) {
    aad.addAll({
      'memory_kib': header['memory_kib'],
      'iterations': header['iterations'],
      'parallelism': header['parallelism'],
    });
  } else {
    aad['iterations'] = header['iterations'];
  }
  aad['salt'] = header['salt'];
  return utf8.encode(jsonEncode(aad));
}

Future<SecretKey> _argon2ArchiveKey({
  required String passphrase,
  required List<int> salt,
  required int memoryKib,
  required int iterations,
  required int parallelism,
}) {
  return Argon2id(
    memory: memoryKib,
    iterations: iterations,
    parallelism: parallelism,
    hashLength: 32,
  ).deriveKey(secretKey: SecretKey(utf8.encode(passphrase)), nonce: salt);
}

Future<SecretKey> _legacyArchiveKey({
  required String passphrase,
  required List<int> salt,
  required int iterations,
}) {
  return Pbkdf2.hmacSha256(
    iterations: iterations,
    bits: 256,
  ).deriveKeyFromPassword(password: passphrase, nonce: salt);
}
