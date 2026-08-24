import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import 'haven_crypto.dart';

abstract interface class SecureValueStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

abstract interface class MasterKeyProvisioningStore {
  Future<bool> isProvisioned();

  Future<void> markProvisioned();
}

class MissingMasterKeyException implements Exception {
  const MissingMasterKeyException();

  @override
  String toString() =>
      'The device encryption key is missing. Restore a backup to recover your data.';
}

class PlatformMasterKeyProvisioningStore implements MasterKeyProvisioningStore {
  static const _fileName = '.pluris-haven-master-key-v1';

  Future<File> _file() async =>
      File('${(await getApplicationDocumentsDirectory()).path}/$_fileName');

  @override
  Future<bool> isProvisioned() async => (await _file()).exists();

  @override
  Future<void> markProvisioned() async {
    await (await _file()).writeAsString('provisioned', flush: true);
  }
}

class PlatformSecureValueStore implements SecureValueStore {
  const PlatformSecureValueStore();

  static const androidOptions = AndroidOptions(
    resetOnError: false,
    keyCipherAlgorithm:
        KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
    storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
  );

  static const _storage = FlutterSecureStorage(
    aOptions: androidOptions,
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class HavenMasterKeyStore {
  HavenMasterKeyStore({
    SecureValueStore? storage,
    MasterKeyProvisioningStore? provisioningStore,
  }) : _storage = storage ?? const PlatformSecureValueStore(),
       _provisioningStore =
           provisioningStore ?? PlatformMasterKeyProvisioningStore();

  static const _masterKeyName = 'pluris_haven.master_key.v1';
  final SecureValueStore _storage;
  final MasterKeyProvisioningStore _provisioningStore;

  Future<HavenCrypto> loadOrCreateCrypto() async {
    final stored = await _storage.read(_masterKeyName);
    if (stored != null && stored.isNotEmpty) {
      final bytes = base64Url.decode(stored);
      if (bytes.length != 32) {
        throw const FormatException('Stored encryption key is invalid.');
      }
      await _provisioningStore.markProvisioned();
      return HavenCrypto(await deriveMasterKey(bytes));
    }

    if (await _provisioningStore.isProvisioned()) {
      throw const MissingMasterKeyException();
    }

    final key = await generateMasterKey();
    final bytes = await key.extractBytes();
    await _storage.write(_masterKeyName, base64UrlEncode(bytes));
    await _provisioningStore.markProvisioned();
    return HavenCrypto(await deriveMasterKey(bytes));
  }
}
