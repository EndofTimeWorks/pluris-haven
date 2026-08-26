import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// Field-level encryption and blind-index HMAC for Pluris Haven.
///
/// Uses XChaCha20-Poly1305 AEAD for ciphertext and keyed HMAC-SHA256 for
/// blind indexes. The master key is held by the caller (typically secure
/// platform storage) and never leaves the device.
///
/// Current ciphertext format: v2:base64url(nonce || ciphertext || mac).
/// Version 2 derives subkeys with HKDF and authenticates caller-provided AAD.
/// Blind index format: hex(Hmac-SHA256(key, normalize(plaintext))).
///
/// The same plaintext encrypts to a different ciphertext every time because
/// each encryption uses a random nonce. Use [blindIndex] for exact-match
/// lookup columns instead of comparing ciphertext.
class HavenCrypto {
  HavenCrypto(SecretKey masterKey)
    : _legacyContentKey = _deriveLegacySubkey(
        masterKey,
        _legacyContentKeyLabel,
      ),
      _contentKey = _deriveSubkey(masterKey, _contentKeyLabel),
      _blindIndexKey = _deriveSubkey(masterKey, _blindIndexKeyLabel);

  final Future<SecretKey> _legacyContentKey;
  final Future<SecretKey> _contentKey;
  final Future<SecretKey> _blindIndexKey;

  static final _aead = Xchacha20.poly1305Aead();
  static final _mac = Hmac.sha256();
  static const _ciphertextV2Prefix = 'v2:';
  static const _legacyContentKeyLabel = 'pluris-haven:content:v1';
  static const _contentKeyLabel = 'pluris-haven:content:v2';
  static const _blindIndexKeyLabel = 'pluris-haven:blind-index:v2';
  static const _hkdfSalt = 'pluris-haven:hkdf:v2';
  var _legacyCiphertextAllowed = true;

  /// Encrypts [plaintext] and returns base64url(nonce || ciphertext || mac).
  ///
  /// Returns null for null input so callers can pass nullable columns
  /// through unchanged. Empty input is encrypted and authenticated like every
  /// other value.
  Future<String?> encrypt(String? plaintext, {String aad = ''}) async {
    if (plaintext == null) return null;
    return encryptBytes(utf8.encode(plaintext), aad: utf8.encode(aad));
  }

  /// Encrypts bytes with versioned HKDF-derived key material and AAD.
  Future<String> encryptBytes(
    List<int> plaintext, {
    List<int> aad = const [],
  }) async {
    final secretBox = await _aead.encrypt(
      plaintext,
      secretKey: await _contentKey,
      aad: aad,
    );
    final combined = secretBox.concatenation();
    return '$_ciphertextV2Prefix${base64Url.encode(combined)}';
  }

  /// Decrypts a value produced by [encrypt]. Returns null for null input.
  /// Throws on tampering or key mismatch. Callers should treat throws as data
  /// corruption and surface a clear error to the user (the master key is
  /// unrecoverable).
  Future<String?> decrypt(String? ciphertext, {String aad = ''}) async {
    if (ciphertext == null) return null;
    final plainBytes = await decryptBytes(ciphertext, aad: utf8.encode(aad));
    return utf8.decode(plainBytes);
  }

  /// Decrypts current ciphertext with AAD and legacy v1 ciphertext without it.
  Future<List<int>> decryptBytes(
    String ciphertext, {
    List<int> aad = const [],
  }) async {
    if (ciphertext.isEmpty) {
      throw const FormatException('Ciphertext is empty.');
    }
    final isCurrent = ciphertext.startsWith(_ciphertextV2Prefix);
    if (!isCurrent && !_legacyCiphertextAllowed) {
      throw const FormatException('Legacy ciphertext is no longer supported.');
    }
    final encoded = isCurrent
        ? ciphertext.substring(_ciphertextV2Prefix.length)
        : ciphertext;
    final combined = base64Url.decode(encoded);
    final secretBox = SecretBox.fromConcatenation(
      combined,
      nonceLength: _aead.nonceLength,
      macLength: _aead.macAlgorithm.macLength,
      copy: false,
    );
    return _aead.decrypt(
      secretBox,
      secretKey: await (isCurrent ? _contentKey : _legacyContentKey),
      aad: isCurrent ? aad : const [],
    );
  }

  /// Retires v1 ciphertext after the local migration has completed.
  void rejectLegacyCiphertext() {
    _legacyCiphertextAllowed = false;
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
}

Future<SecretKey> _deriveLegacySubkey(SecretKey masterKey, String label) async {
  final raw = await masterKey.extractBytes();
  final hash = await Sha256().hash([...utf8.encode(label), 0, ...raw]);
  return SecretKey(hash.bytes.sublist(0, 32));
}

Future<SecretKey> _deriveSubkey(SecretKey masterKey, String label) {
  return Hkdf(hmac: Hmac.sha256(), outputLength: 32).deriveKey(
    secretKey: masterKey,
    nonce: utf8.encode(HavenCrypto._hkdfSalt),
    info: utf8.encode(label),
  );
}

/// Normalizes raw key material into a 32-byte SecretKey suitable for
/// XChaCha20-Poly1305.
Future<SecretKey> deriveMasterKey(List<int> rawKey) async {
  if (rawKey.length != 32) {
    throw ArgumentError.value(
      rawKey.length,
      'rawKey',
      'must contain exactly 32 random bytes',
    );
  }
  return SecretKey(List<int>.unmodifiable(rawKey));
}

/// Generates a fresh 32-byte random master key. Use on first run when
/// no existing key is found.
Future<SecretKey> generateMasterKey() async {
  final algorithm = Xchacha20.poly1305Aead();
  return algorithm.newSecretKey();
}
