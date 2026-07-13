import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'haven_crypto.dart';

abstract interface class SecureValueStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);
}

class PlatformSecureValueStore implements SecureValueStore {
  const PlatformSecureValueStore();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

class HavenMasterKeyStore {
  HavenMasterKeyStore({SecureValueStore? storage})
    : _storage = storage ?? const PlatformSecureValueStore();

  static const _masterKeyName = 'pluris_haven.master_key.v1';
  final SecureValueStore _storage;

  Future<HavenCrypto> loadOrCreateCrypto() async {
    final stored = await _storage.read(_masterKeyName);
    if (stored != null && stored.isNotEmpty) {
      final bytes = base64Url.decode(stored);
      if (bytes.length != 32) {
        throw const FormatException('Stored encryption key is invalid.');
      }
      return HavenCrypto(await deriveMasterKey(bytes));
    }

    final key = await generateMasterKey();
    final bytes = await key.extractBytes();
    await _storage.write(_masterKeyName, base64UrlEncode(bytes));
    return HavenCrypto(await deriveMasterKey(bytes));
  }
}
