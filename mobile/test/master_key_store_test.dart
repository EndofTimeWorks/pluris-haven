import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pluris_haven/data/security/master_key_store.dart';

void main() {
  test('fails closed instead of deleting secure Android values on error', () {
    expect(
      PlatformSecureValueStore.androidOptions.toMap(),
      containsPair('resetOnError', 'false'),
    );
    expect(
      PlatformSecureValueStore.androidOptions.toMap(),
      containsPair(
        'keyCipherAlgorithm',
        'RSA_ECB_OAEPwithSHA_256andMGF1Padding',
      ),
    );
    expect(
      PlatformSecureValueStore.androidOptions.toMap(),
      containsPair('storageCipherAlgorithm', 'AES_GCM_NoPadding'),
    );
  });

  test(
    'describes secure-storage upgrade failures without exposing details',
    () {
      const error = SecureStorageUpgradeException(
        SecureStorageUpgradeStatus(
          state: SecureStorageUpgradeState.legacyDataUnreadable,
          reason: SecureStorageUpgradeReason.removedCipher,
          entryCount: 1,
          details: 'sensitive platform detail',
        ),
      );

      expect(error.toString(), contains('removedCipher'));
      expect(error.toString(), isNot(contains('sensitive platform detail')));
    },
  );

  test('creates and reuses the same secure master key', () async {
    final storage = MemorySecureValueStore();
    final provisioned = MemoryMasterKeyProvisioningStore();
    final first = await HavenMasterKeyStore(
      storage: storage,
      provisioningStore: provisioned,
    ).loadOrCreateCrypto();
    final ciphertext = await first.encrypt('River');

    final second = await HavenMasterKeyStore(
      storage: storage,
      provisioningStore: provisioned,
    ).loadOrCreateCrypto();
    expect(await second.decrypt(ciphertext), 'River');
    expect(storage.values, hasLength(1));
    expect(provisioned.provisioned, isTrue);
  });

  test('caches the derived crypto for repeated reads', () async {
    final storage = MemorySecureValueStore();
    final store = HavenMasterKeyStore(
      storage: storage,
      provisioningStore: MemoryMasterKeyProvisioningStore(),
    );

    await Future.wait([
      store.loadOrCreateCrypto(),
      store.loadOrCreateCrypto(),
      store.loadOrCreateCrypto(),
    ]);

    expect(storage.readCount, 1);
  });

  test('rejects a malformed stored master key', () async {
    final storage = MemorySecureValueStore()
      ..values['pluris_haven.master_key.v1'] = 'aW52YWxpZA==';

    expect(
      HavenMasterKeyStore(storage: storage).loadOrCreateCrypto,
      throwsFormatException,
    );
  });

  test('does not replace a missing provisioned master key', () async {
    final storage = MemorySecureValueStore();
    final provisioned = MemoryMasterKeyProvisioningStore()..provisioned = true;

    expect(
      HavenMasterKeyStore(
        storage: storage,
        provisioningStore: provisioned,
      ).loadOrCreateCrypto,
      throwsA(isA<MissingMasterKeyException>()),
    );
    expect(storage.values, isEmpty);
  });

  test(
    'iOS restores a marker alone without stranding a fresh install',
    () async {
      final root = await Directory.systemTemp.createTemp('haven-key-restore-');
      addTearDown(() => root.delete(recursive: true));
      final documents = Directory('${root.path}/Documents')..createSync();
      final support = Directory('${root.path}/Application Support');
      final legacyMarker = File('${documents.path}/.pluris-haven-master-key-v1')
        ..writeAsStringSync('provisioned');
      final provisioning = PlatformMasterKeyProvisioningStore(
        documentsDirectory: documents,
        supportDirectory: support,
        isIos: true,
      );
      final storage = MemorySecureValueStore();

      expect(await provisioning.isProvisioned(), isFalse);
      final crypto = await HavenMasterKeyStore(
        storage: storage,
        provisioningStore: provisioning,
      ).loadOrCreateCrypto();
      expect(await crypto.decrypt(await crypto.encrypt('River')), 'River');
      expect(storage.values, hasLength(1));
      expect(legacyMarker.existsSync(), isFalse);
      expect(
        File('${support.path}/.pluris-haven-master-key-v1').existsSync(),
        isTrue,
      );
    },
  );

  test('iOS refuses a new key when any local database file remains', () async {
    for (final suffix in ['', '-wal', '-shm']) {
      final root = await Directory.systemTemp.createTemp('haven-key-data-');
      addTearDown(() => root.delete(recursive: true));
      final documents = Directory('${root.path}/Documents')..createSync();
      final support = Directory('${root.path}/Application Support')
        ..createSync();
      File('${support.path}/pluris_haven.sqlite$suffix').createSync();
      final storage = MemorySecureValueStore();

      expect(
        HavenMasterKeyStore(
          storage: storage,
          provisioningStore: PlatformMasterKeyProvisioningStore(
            documentsDirectory: documents,
            supportDirectory: support,
            isIos: true,
          ),
        ).loadOrCreateCrypto,
        throwsA(isA<MissingMasterKeyException>()),
      );
      expect(storage.values, isEmpty);
    }
  });

  test('iOS refuses a new key when a restored avatar remains', () async {
    final root = await Directory.systemTemp.createTemp('haven-key-avatar-');
    addTearDown(() => root.delete(recursive: true));
    final documents = Directory('${root.path}/Documents')..createSync();
    final support = Directory('${root.path}/Application Support');
    final avatars = Directory('${documents.path}/avatars')..createSync();
    File('${avatars.path}/river').writeAsStringSync('encrypted avatar');
    final storage = MemorySecureValueStore();

    expect(
      HavenMasterKeyStore(
        storage: storage,
        provisioningStore: PlatformMasterKeyProvisioningStore(
          documentsDirectory: documents,
          supportDirectory: support,
          isIos: true,
        ),
      ).loadOrCreateCrypto,
      throwsA(isA<MissingMasterKeyException>()),
    );
    expect(storage.values, isEmpty);
  });

  test(
    'iOS migrates an old marker without changing an available key',
    () async {
      final root = await Directory.systemTemp.createTemp('haven-key-legacy-');
      addTearDown(() => root.delete(recursive: true));
      final documents = Directory('${root.path}/Documents')..createSync();
      final support = Directory('${root.path}/Application Support');
      final legacyMarker = File('${documents.path}/.pluris-haven-master-key-v1')
        ..writeAsStringSync('provisioned');
      final storage = MemorySecureValueStore();
      final existingCrypto = await HavenMasterKeyStore(
        storage: storage,
        provisioningStore: MemoryMasterKeyProvisioningStore(),
      ).loadOrCreateCrypto();
      final ciphertext = await existingCrypto.encrypt('Wren');

      final recoveredCrypto = await HavenMasterKeyStore(
        storage: storage,
        provisioningStore: PlatformMasterKeyProvisioningStore(
          documentsDirectory: documents,
          supportDirectory: support,
          isIos: true,
        ),
      ).loadOrCreateCrypto();
      expect(await recoveredCrypto.decrypt(ciphertext), 'Wren');
      expect(legacyMarker.existsSync(), isFalse);
      expect(
        File('${support.path}/.pluris-haven-master-key-v1').existsSync(),
        isTrue,
      );
    },
  );
}

class MemorySecureValueStore implements SecureValueStore {
  final values = <String, String>{};
  var readCount = 0;

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<String?> read(String key) async {
    readCount++;
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

class MemoryMasterKeyProvisioningStore implements MasterKeyProvisioningStore {
  var provisioned = false;

  @override
  Future<bool> isProvisioned() async => provisioned;

  @override
  Future<void> markProvisioned() async {
    provisioned = true;
  }
}
