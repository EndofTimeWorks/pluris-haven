import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// Field-level encryption and blind-index HMAC for Pluris Haven.
///
/// Uses XChaCha20-Poly1305 AEAD for ciphertext and keyed HMAC-SHA256 for
/// blind indexes. The master key is held by the caller (typically secure
/// platform storage) and never leaves the device.
///
/// Ciphertext format: base64url(nonce || ciphertext || mac).
/// Blind index format: hex(Hmac-SHA256(key, normalize(plaintext))).
///
/// The same plaintext encrypts to a different ciphertext every time because
/// each encryption uses a random nonce. Use [blindIndex] for exact-match
/// lookup columns instead of comparing ciphertext.
class HavenCrypto {
  HavenCrypto(SecretKey masterKey)
    : _contentKey = _deriveSubkey(masterKey, _contentKeyLabel),
      _blindIndexKey = _deriveSubkey(masterKey, _blindIndexKeyLabel);

  final Future<SecretKey> _contentKey;
  final Future<SecretKey> _blindIndexKey;

  static final _aead = Xchacha20.poly1305Aead();
  static final _mac = Hmac.sha256();
  static const _contentKeyLabel = 'pluris-haven:content:v1';
  static const _blindIndexKeyLabel = 'pluris-haven:blind-index:v1';

  /// Encrypts [plaintext] and returns base64url(nonce || ciphertext || mac).
  ///
  /// Returns null for null input so callers can pass nullable columns
  /// through unchanged. Returns '' for empty input.
  Future<String?> encrypt(String? plaintext) async {
    if (plaintext == null) return null;
    if (plaintext.isEmpty) return '';
    final secretBox = await _aead.encrypt(
      utf8.encode(plaintext),
      secretKey: await _contentKey,
    );
    final combined = secretBox.concatenation();
    return base64Url.encode(combined);
  }

  /// Decrypts a value produced by [encrypt]. Returns null for null input.
  /// Returns the empty string for empty input. Throws on tampering or
  /// key mismatch. Callers should treat throws as data corruption and
  /// surface a clear error to the user (the master key is unrecoverable).
  Future<String?> decrypt(String? ciphertext) async {
    if (ciphertext == null) return null;
    if (ciphertext.isEmpty) return '';
    final combined = base64Url.decode(ciphertext);
    final secretBox = SecretBox.fromConcatenation(
      combined,
      nonceLength: _aead.nonceLength,
      macLength: _aead.macAlgorithm.macLength,
      copy: false,
    );
    final plainBytes = await _aead.decrypt(
      secretBox,
      secretKey: await _contentKey,
    );
    return utf8.decode(plainBytes);
  }

  /// Returns a stable hex-encoded HMAC-SHA256 of the normalized plaintext
  /// for use as a blind-index column. Two plaintexts that differ only in
  /// case or whitespace produce the same index.
  ///
  /// Normalization: lowercase + trim + collapse internal whitespace.
  Future<String> blindIndex(String plaintext) async {
    final normalized = plaintext.toLowerCase().trim().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    final mac = await _mac.calculateMac(
      utf8.encode(normalized),
      secretKey: await _blindIndexKey,
    );
    return mac.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Constant-time string comparison for blind-index lookups. Reduces the
  /// timing-oracle surface compared to == on hex strings.
  bool blindIndexEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}

Future<SecretKey> _deriveSubkey(SecretKey masterKey, String label) async {
  final raw = await masterKey.extractBytes();
  final hash = await Sha256().hash([...utf8.encode(label), 0, ...raw]);
  return SecretKey(hash.bytes.sublist(0, 32));
}

/// Normalizes raw key material into a 32-byte SecretKey suitable for
/// XChaCha20-Poly1305.
Future<SecretKey> deriveMasterKey(List<int> rawKey) async {
  final hash = await Sha256().hash(rawKey);
  return SecretKey(hash.bytes.sublist(0, 32));
}

/// Generates a fresh 32-byte random master key. Use on first run when
/// no existing key is found.
Future<SecretKey> generateMasterKey() async {
  final algorithm = Xchacha20.poly1305Aead();
  return algorithm.newSecretKey();
}
