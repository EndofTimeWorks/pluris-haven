import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/security/master_key_store.dart';

void main() {
  test('creates and reuses the same secure master key', () async {
    final storage = MemorySecureValueStore();
    final first = await HavenMasterKeyStore(
      storage: storage,
    ).loadOrCreateCrypto();
    final ciphertext = await first.encrypt('River');

    final second = await HavenMasterKeyStore(
      storage: storage,
    ).loadOrCreateCrypto();
    expect(await second.decrypt(ciphertext), 'River');
    expect(storage.values, hasLength(1));
  });

  test('rejects a malformed stored master key', () async {
    final storage = MemorySecureValueStore()
      ..values['pluris_haven.master_key.v1'] = 'aW52YWxpZA==';

    expect(
      HavenMasterKeyStore(storage: storage).loadOrCreateCrypto,
      throwsFormatException,
    );
  });
}

class MemorySecureValueStore implements SecureValueStore {
  final values = <String, String>{};

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}
