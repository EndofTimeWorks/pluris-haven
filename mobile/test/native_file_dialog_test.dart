import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/avatar/avatar_file_policy.dart';
import 'package:pluris_haven/platform/native_file_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  test('maps the native size rejection to a typed exception', () async {
    const channel = MethodChannel('works.endoftime.plurishaven/file_dialog');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'pick_too_large');
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    await expectLater(
      NativeFileDialog.pickFiles(
        type: NativeFileType.image,
        maximumBytes: maximumAvatarBytes,
      ),
      throwsA(isA<NativePickedFileTooLargeException>()),
    );
  });

  test('stages one temporary file for native avatar sharing', () async {
    const channel = MethodChannel('works.endoftime.plurishaven/file_dialog');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    String? sourcePath;
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'shareFile');
      final arguments = call.arguments! as Map<Object?, Object?>;
      expect(arguments['fileName'], 'River.png');
      expect(arguments['mimeType'], 'image/png');
      sourcePath = arguments['sourcePath']! as String;
      expect(await File(sourcePath!).readAsBytes(), <int>[1, 2, 3]);
      return true;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    final shared = await NativeFileDialog.shareBytes(
      fileName: 'River.png',
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
      mimeType: 'image/png',
    );

    expect(shared, isTrue);
    expect(sourcePath, isNotNull);
    expect(await File(sourcePath!).exists(), isFalse);
  });

  test(
    'refuses export filenames that could escape temporary staging',
    () async {
      for (final fileName in const [
        '',
        '.',
        '..',
        '../archive.json',
        'nested/archive.json',
        r'nested\\archive.json',
      ]) {
        await expectLater(
          NativeFileDialog.saveBytes(
            fileName: fileName,
            bytes: Uint8List.fromList(<int>[1, 2, 3]),
          ),
          throwsA(isA<ArgumentError>()),
          reason: fileName,
        );
        await expectLater(
          NativeFileDialog.shareBytes(
            fileName: fileName,
            bytes: Uint8List.fromList(<int>[1, 2, 3]),
          ),
          throwsA(isA<ArgumentError>()),
          reason: fileName,
        );
      }
    },
  );
}
