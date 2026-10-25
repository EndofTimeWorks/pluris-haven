import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/local/app_database.dart';

import 'test_repository.dart';

void main() {
  test(
    'failed archive import removes only newly written avatar files',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = testRepository(database);
      await repository.ensureLocalSystem();
      final bytes = [0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10];
      final digest = base64UrlEncode((await Sha256().hash(bytes)).bytes)
          .replaceAll('=', '')
          .substring(0, 24);
      final reference = 'local-avatar:avatar-1-$digest.jpg';
      final archive = jsonDecode(
        await repository.buildLocalArchiveJson(),
      ) as Map<String, dynamic>;
      (archive['members'] as List).add({
        'id': 'avatar-member',
        'display_name': 'Private member',
        'avatar_url': 'local-avatar:avatar-1',
      });
      (archive['avatar_assets'] as List).add({
        'id': 'avatar-1',
        'name': 'avatar-1.jpg',
        'mime_type': 'image/jpeg',
        'bytes_base64': base64Encode(bytes),
      });
      (archive['groups'] as List).add({'id': 'broken-group'});

      await expectLater(
        repository.importLocalArchiveJson(jsonEncode(archive)),
        throwsFormatException,
      );
      expect(await repository.readAvatar(reference), isNull);
      expect(await database.select(database.members).get(), isEmpty);
    },
  );
}
