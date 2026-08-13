import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/platform/native_file_dialog.dart';

void main() {
  test('reading a staged picker file removes the plaintext copy', () async {
    final directory = await Directory.systemTemp.createTemp(
      'pluris-haven-picker-test-',
    );
    addTearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });
    final staged = File('${directory.path}/private-import.json');
    await staged.writeAsString('{"private":true}', flush: true);
    final picked = NativePlatformFile(
      name: 'private-import.json',
      path: staged.path,
      size: await staged.length(),
    );

    final bytes = await picked.readBytes();

    expect(String.fromCharCodes(bytes), '{"private":true}');
    expect(await staged.exists(), isFalse);
  });

  test('startup cleanup removes stale plaintext export staging', () async {
    final staleDirectory = await Directory.systemTemp.createTemp(
      'pluris-haven-export-test-',
    );
    final unrelatedDirectory = await Directory.systemTemp.createTemp(
      'pluris-haven-unrelated-test-',
    );
    addTearDown(() async {
      if (await unrelatedDirectory.exists()) {
        await unrelatedDirectory.delete(recursive: true);
      }
    });
    await File(
      '${staleDirectory.path}/archive.json',
    ).writeAsString('{"private":true}', flush: true);

    final removed =
        await NativeFileDialog.clearStaleExportTemporaryDirectories();

    expect(removed, greaterThanOrEqualTo(1));
    expect(await staleDirectory.exists(), isFalse);
    expect(await unrelatedDirectory.exists(), isTrue);
  });
}
