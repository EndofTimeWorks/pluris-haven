import 'package:flutter_test/flutter_test.dart';
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
