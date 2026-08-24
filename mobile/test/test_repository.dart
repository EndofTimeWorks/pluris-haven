import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/avatar/local_avatar_store.dart';
import 'package:pluris_haven/data/local/app_database.dart';
import 'package:pluris_haven/data/local/haven_repository.dart';
import 'package:pluris_haven/data/security/haven_crypto.dart';
import 'package:pluris_haven/data/security/master_key_store.dart';

/// Stable test-only key material. Production repositories always receive the
/// key loaded from platform secure storage.
HavenCrypto testCrypto() =>
    HavenCrypto(SecretKey(List<int>.filled(32, 0x42, growable: false)));

LocalHavenRepository testRepository(AppDatabase database) {
  final root = Directory.systemTemp.createTempSync('pluris-haven-test-');
  addTearDown(() => root.delete(recursive: true));
  return LocalHavenRepository(
    database,
    crypto: testCrypto(),
    avatarStore: LocalAvatarStore(
      keyStore: HavenMasterKeyStore(
        storage: _MemorySecureValueStore(),
        provisioningStore: _MemoryProvisioningStore(),
      ),
      rootDirectory: () async => root,
    ),
  );
}

final class _MemorySecureValueStore implements SecureValueStore {
  final _values = <String, String>{};

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }
}

final class _MemoryProvisioningStore implements MasterKeyProvisioningStore {
  var _provisioned = false;

  @override
  Future<bool> isProvisioned() async => _provisioned;

  @override
  Future<void> markProvisioned() async {
    _provisioned = true;
  }
}
