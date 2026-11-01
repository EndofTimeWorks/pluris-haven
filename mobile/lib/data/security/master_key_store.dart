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

class CorruptMasterKeyException implements Exception {
  const CorruptMasterKeyException();

  @override
  String toString() => 'The stored device encryption key is invalid.';
}

class SecureStorageUpgradeException implements Exception {
  const SecureStorageUpgradeException(this.status);

  final SecureStorageUpgradeStatus status;

  @override
  String toString() =>
      'Secure storage upgrade could not preserve the device encryption key: '
      '${status.reason.name}.';
}

class PlatformMasterKeyProvisioningStore implements MasterKeyProvisioningStore {
  PlatformMasterKeyProvisioningStore({
    this.documentsDirectory,
    this.supportDirectory,
    bool? isIos,
  }) : _isIos = isIos ?? Platform.isIOS;

  static const _fileName = '.pluris-haven-master-key-v1';
  final Directory? documentsDirectory;
  final Directory? supportDirectory;
  final bool _isIos;

  Future<Directory> _documents() async =>
      documentsDirectory ?? await getApplicationDocumentsDirectory();

  Future<Directory> _support() async =>
      supportDirectory ?? await getApplicationSupportDirectory();

  Future<File> _file() async => File(
    '${(_isIos ? await _support() : await _documents()).path}/$_fileName',
  );

  @override
  Future<bool> isProvisioned() async {
    final support = await _support();
    for (final suffix in ['', '-wal', '-shm']) {
      if (await File('${support.path}/pluris_haven.sqlite$suffix').exists()) {
        return true;
      }
    }
    final documents = await _documents();
    final avatars = Directory('${documents.path}/avatars');
    if (await avatars.exists() &&
        !await avatars.list(followLinks: false).isEmpty) {
      return true;
    }
    // Older iOS builds wrote the marker into Documents. A backup can restore
    // that marker without the device-bound key or any encrypted local files.
    // On other platforms, retain the existing marker as evidence of a key.
    return !_isIos && await (await _file()).exists();
  }

  @override
  Future<void> markProvisioned() async {
    final marker = await _file();
    await marker.parent.create(recursive: true);
    await marker.writeAsString('provisioned', flush: true);
    if (_isIos) {
      final legacyMarker = File('${(await _documents()).path}/$_fileName');
      if (await legacyMarker.exists()) await legacyMarker.delete();
    }
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

  Future<void> _ensureUpgradeSafe() async {
    final status = await _storage.checkUpgradeStatus(aOptions: androidOptions);
    if (status.hasDataLoss ||
        status.state == SecureStorageUpgradeState.unknown) {
      throw SecureStorageUpgradeException(status);
    }
  }

  @override
  Future<String?> read(String key) async {
    await _ensureUpgradeSafe();
    return _storage.read(key: key);
  }

  @override
  Future<void> write(String key, String value) async {
    await _ensureUpgradeSafe();
    await _storage.write(key: key, value: value);
  }

  @override
  Future<void> delete(String key) async {
    await _ensureUpgradeSafe();
    await _storage.delete(key: key);
  }
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
  late final Future<HavenCrypto> _crypto = _loadOrCreateCrypto();

  Future<HavenCrypto> loadOrCreateCrypto() => _crypto;

  Future<HavenCrypto> _loadOrCreateCrypto() async {
    final stored = await _storage.read(_masterKeyName);
    if (stored != null) {
      if (stored.isEmpty) throw const CorruptMasterKeyException();
      late final List<int> bytes;
      try {
        bytes = base64Url.decode(stored);
      } on FormatException {
        throw const CorruptMasterKeyException();
      }
      if (bytes.length != 32) {
        throw const CorruptMasterKeyException();
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
