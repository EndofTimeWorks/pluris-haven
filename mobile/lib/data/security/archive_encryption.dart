import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:libcompress/libcompress.dart';

const nativeArchiveMagic = <int>[0x50, 0x4c, 0x55, 0x52]; // PLUR
const nativeArchiveVersion = 1;
const nativeArchiveMaximumFramePlainBytes = 256 * 1024;

const encryptedArchiveFormat = 'pluris_haven.encrypted_archive';
const encryptedArchiveVersion = 3;
const encryptedArchiveKdf = 'Argon2id';
const encryptedArchiveCipher = 'XChaCha20-Poly1305';

/// A recovery archive can be copied anywhere and attacked offline. Keep the
/// creation cost deliberately high. These are OWASP's Argon2id minimums.
const defaultArchiveKdfMemoryKib = 19456;
const defaultArchiveKdfIterations = 2;
const defaultArchiveKdfParallelism = 1;
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

/// Internal v1 native container. It is intentionally not wired to the export
/// UI until streaming file finalisation and multi-slot management exist.
Future<Uint8List> encryptNativeArchiveFrame({
  required Uint8List plaintext,
  required ArchiveRecoveryCode recoveryCode,
}) async {
  if (plaintext.isEmpty ||
      plaintext.length > nativeArchiveMaximumFramePlainBytes) {
    throw ArgumentError.value(
      plaintext,
      'plaintext',
      'must be a bounded non-empty frame',
    );
  }
  final salt = _archiveCipher.newNonce();
  final kek = await _argon2ArchiveKey(
    passphrase: recoveryCode.value,
    salt: salt,
    memoryKib: defaultArchiveKdfMemoryKib,
    iterations: defaultArchiveKdfIterations,
    parallelism: defaultArchiveKdfParallelism,
  );
  final dekBytes = await SecretKeyData.random(length: 32).extractBytes();
  final wrapNonce = _archiveCipher.newNonce();
  final wrappedDek = await _archiveCipher.encrypt(
    dekBytes,
    secretKey: kek,
    nonce: wrapNonce,
    aad: utf8.encode('pluris.native.slot.v1'),
  );
  final compressed = ZstdCodec(
    enableChecksum: true,
    strict: true,
    maxDecompressedSize: nativeArchiveMaximumFramePlainBytes,
  ).compress(plaintext);
  final header = <String, Object?>{
    'version': nativeArchiveVersion,
    'compression': 'zstd',
    'plain_bytes': plaintext.length,
    'slot': {
      'type': 'password',
      'kdf': encryptedArchiveKdf,
      'salt': base64Url.encode(salt),
      'wrapped_dek': base64Url.encode(wrappedDek.concatenation()),
    },
  };
  final headerBytes = utf8.encode(jsonEncode(header));
  final frame = await _archiveCipher.encrypt(
    compressed,
    secretKey: SecretKey(dekBytes),
    aad: headerBytes,
  );
  final out = BytesBuilder(copy: false)
    ..add(nativeArchiveMagic)
    ..addByte(nativeArchiveVersion)
    ..addByte((headerBytes.length >> 24) & 0xff)
    ..addByte((headerBytes.length >> 16) & 0xff)
    ..addByte((headerBytes.length >> 8) & 0xff)
    ..addByte(headerBytes.length & 0xff)
    ..add(headerBytes)
    ..add(frame.concatenation());
  return out.toBytes();
}

Future<Uint8List> decryptNativeArchiveFrame({
  required Uint8List container,
  required String passphrase,
}) async {
  if (container.length < 9) {
    throw const FormatException('Not a native Pluris archive.');
  }
  for (var index = 0; index < nativeArchiveMagic.length; index++) {
    if (container[index] != nativeArchiveMagic[index]) {
      throw const FormatException('Not a native Pluris archive.');
    }
  }
  if (container[4] != nativeArchiveVersion) {
    throw const FormatException('Unsupported native archive version.');
  }
  final length =
      (container[5] << 24) |
      (container[6] << 16) |
      (container[7] << 8) |
      container[8];
  if (length < 2 || length > 16 * 1024 || container.length <= 9 + length) {
    throw const FormatException('Invalid native archive header.');
  }
  final headerBytes = container.sublist(9, 9 + length);
  final header = jsonDecode(utf8.decode(headerBytes));
  if (header is! Map<String, dynamic> ||
      header['version'] != nativeArchiveVersion ||
      header['compression'] != 'zstd' ||
      header['plain_bytes'] is! int ||
      header['plain_bytes'] <= 0 ||
      header['plain_bytes'] > nativeArchiveMaximumFramePlainBytes) {
    throw const FormatException('Unsupported native archive header.');
  }
  final slot = header['slot'];
  if (slot is! Map<String, dynamic> ||
      slot['type'] != 'password' ||
      slot['kdf'] != encryptedArchiveKdf ||
      slot['salt'] is! String ||
      slot['wrapped_dek'] is! String) {
    throw const FormatException('No supported portable unlock slot.');
  }
  final kek = await _argon2ArchiveKey(
    passphrase: passphrase,
    salt: base64Url.decode(slot['salt'] as String),
    memoryKib: defaultArchiveKdfMemoryKib,
    iterations: defaultArchiveKdfIterations,
    parallelism: defaultArchiveKdfParallelism,
  );
  final dek = await _archiveCipher.decrypt(
    SecretBox.fromConcatenation(
      base64Url.decode(slot['wrapped_dek'] as String),
      nonceLength: _archiveCipher.nonceLength,
      macLength: _archiveCipher.macAlgorithm.macLength,
    ),
    secretKey: kek,
    aad: utf8.encode('pluris.native.slot.v1'),
  );
  final compressed = await _archiveCipher.decrypt(
    SecretBox.fromConcatenation(
      container.sublist(9 + length),
      nonceLength: _archiveCipher.nonceLength,
      macLength: _archiveCipher.macAlgorithm.macLength,
    ),
    secretKey: SecretKey(dek),
    aad: headerBytes,
  );
  final plaintext = ZstdCodec(maxDecompressedSize: header['plain_bytes'] as int)
      .decompress(Uint8List.fromList(compressed));
  if (plaintext.length != header['plain_bytes']) {
    throw const FormatException('Native archive frame size mismatch.');
  }
  return plaintext;
}

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
    if (memoryKib != defaultArchiveKdfMemoryKib ||
        iterations != defaultArchiveKdfIterations ||
        parallelism != defaultArchiveKdfParallelism) {
      throw const FormatException(
        'Encrypted archive uses an unsupported Argon2id profile.',
      );
    }
    secretKey = await _argon2ArchiveKey(
      passphrase: passphrase,
      salt: saltBytes,
      memoryKib: defaultArchiveKdfMemoryKib,
      iterations: defaultArchiveKdfIterations,
      parallelism: defaultArchiveKdfParallelism,
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
