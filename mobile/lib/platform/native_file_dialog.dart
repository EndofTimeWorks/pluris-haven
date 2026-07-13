import 'dart:io';
import 'package:flutter/services.dart';

enum NativeFileType { custom, image }

class NativePlatformFile {
  const NativePlatformFile({
    required this.name,
    required this.path,
    required this.size,
  });

  final String name;
  final String path;
  final int size;

  Future<Uint8List> readBytes() => File(path).readAsBytes();
}

class NativeFileResult {
  const NativeFileResult(this.files);

  final List<NativePlatformFile> files;
}

class NativeFileDialog {
  NativeFileDialog._();

  static const _channel = MethodChannel(
    'works.endoftime.plurishaven/file_dialog',
  );

  static Future<NativeFileResult?> pickFiles({
    NativeFileType type = NativeFileType.custom,
    List<String> allowedExtensions = const [],
    bool allowMultiple = false,
    String? dialogTitle,
  }) async {
    final response = await _channel
        .invokeListMethod<Object?>('pickFiles', <String, Object?>{
          'type': type.name,
          'allowedExtensions': allowedExtensions,
          'allowMultiple': allowMultiple,
          'dialogTitle': dialogTitle,
        });
    if (response == null) return null;
    final files = <NativePlatformFile>[];
    for (final item in response) {
      if (item is! Map) continue;
      final path = item['path'];
      final name = item['name'];
      final size = item['size'];
      if (path is String && name is String && size is num) {
        files.add(
          NativePlatformFile(name: name, path: path, size: size.toInt()),
        );
      }
    }
    return files.isEmpty ? null : NativeFileResult(List.unmodifiable(files));
  }

  static Future<bool> saveBytes({
    required String fileName,
    required Uint8List bytes,
    String? dialogTitle,
    String mimeType = 'application/octet-stream',
  }) async {
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'pluris-haven-export-',
    );
    final source = File('${temporaryDirectory.path}/$fileName');
    try {
      await source.writeAsBytes(bytes, flush: true);
      return await _channel.invokeMethod<bool>('saveFile', <String, Object?>{
            'sourcePath': source.path,
            'fileName': fileName,
            'dialogTitle': dialogTitle,
            'mimeType': mimeType,
          }) ??
          false;
    } finally {
      try {
        await temporaryDirectory.delete(recursive: true);
      } on FileSystemException {
        // The platform may still be finishing a coordinated copy.
      }
    }
  }
}
