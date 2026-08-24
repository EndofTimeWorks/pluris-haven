import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/avatar/local_avatar_store.dart';
import 'package:pluris_haven/data/security/master_key_store.dart';

void main() {
  late Directory root;
  late LocalAvatarStore store;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('pluris-avatar-test-');
    store = LocalAvatarStore(
      keyStore: HavenMasterKeyStore(storage: _MemorySecureValueStore()),
      rootDirectory: () async => root,
    );
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('encrypts avatar bytes at rest and reads them back', () async {
    final original = Uint8List.fromList([137, 80, 78, 71, 1, 2, 3]);

    await store.write('member.png', original);

    final stored = await File('${root.path}/member.png').readAsBytes();
    expect(stored, isNot(orderedEquals(original)));
    expect(String.fromCharCodes(stored).startsWith('v2:'), isTrue);
    expect(
      await store.read('local-avatar:member.png'),
      orderedEquals(original),
    );
  });

  test('migrates legacy plaintext avatar files in place', () async {
    final original = Uint8List.fromList([255, 216, 255, 4, 5, 6]);
    final file = File('${root.path}/member.jpg');
    await file.writeAsBytes(original);

    await store.migrateLegacyFiles();

    expect(await file.readAsBytes(), isNot(orderedEquals(original)));
    expect(
      await store.read('local-avatar:member.jpg'),
      orderedEquals(original),
    );
  });
}

final class _MemorySecureValueStore implements SecureValueStore {
  final values = <String, String>{};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
