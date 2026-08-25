import 'dart:io';
import 'package:flutter/services.dart';

enum NativeFileType { custom, image }

const maximumNativePickedFileBytes = 32 * 1024 * 1024;
const maximumOverriddenPickedFileBytes = 200 * 1024 * 1024;
const _exportTemporaryDirectoryPrefix = 'pluris-haven-export-';

final class NativePickedFileTooLargeException implements Exception {
  const NativePickedFileTooLargeException();
}

final class NativePickedFileUnsupportedTypeException implements Exception {
  const NativePickedFileUnsupportedTypeException();
}

class NativePlatformFile {
  const NativePlatformFile({
    required this.name,
    required this.path,
    required this.size,
  });

  final String name;
  final String path;
  final int size;

  Future<Uint8List> readBytes() async {
    final file = File(path);
    try {
      return await file.readAsBytes();
    } finally {
      await dispose();
    }
  }

  Future<void> dispose() => _deleteStagedFile(File(path));
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

  /// Removes plaintext export staging left behind if the app was interrupted
  /// while Android or iOS was copying a file selected by the user.
  ///
  /// This is deliberately best-effort: a cache-cleanup failure must not stop
  /// the app from starting, and the operating system can still evict its cache.
  static Future<int> clearStaleExportTemporaryDirectories() async {
    var removed = 0;
    try {
      await for (final entity in Directory.systemTemp.list(
        followLinks: false,
      )) {
        if (entity is! Directory ||
            !entity.uri.pathSegments
                .where((segment) => segment.isNotEmpty)
                .last
                .startsWith(_exportTemporaryDirectoryPrefix)) {
          continue;
        }
        try {
          await entity.delete(recursive: true);
          removed += 1;
        } on FileSystemException {
          // A concurrent platform copy may still hold the directory open.
        }
      }
    } on FileSystemException {
      // The app remains usable if the platform's temporary directory is gone.
    }
    return removed;
  }

  static Future<NativeFileResult?> pickFiles({
    NativeFileType type = NativeFileType.custom,
    List<String> allowedExtensions = const [],
    bool allowMultiple = false,
    String? dialogTitle,
    int maximumBytes = maximumNativePickedFileBytes,
  }) async {
    final List<Object?>? response;
    try {
      response = await _channel
          .invokeListMethod<Object?>('pickFiles', <String, Object?>{
            'type': type.name,
            'allowedExtensions': allowedExtensions,
            'allowMultiple': allowMultiple,
            'dialogTitle': dialogTitle,
            'maximumBytes': maximumBytes,
          });
    } on PlatformException catch (error) {
      if (error.code == 'pick_too_large') {
        throw const NativePickedFileTooLargeException();
      }
      if (error.code == 'pick_unsupported_type') {
        throw const NativePickedFileUnsupportedTypeException();
      }
      rethrow;
    }
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
      _exportTemporaryDirectoryPrefix,
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
      await _deleteTemporaryDirectory(temporaryDirectory);
    }
  }

  /// Makes one temporary plaintext copy available to the operating system's
  /// share sheet. The native host owns that copy and removes it after sharing
  /// (or at the next launch if the operating system interrupts the share).
  static Future<bool> shareBytes({
    required String fileName,
    required Uint8List bytes,
    String mimeType = 'application/octet-stream',
  }) async {
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      _exportTemporaryDirectoryPrefix,
    );
    final source = File('${temporaryDirectory.path}/$fileName');
    try {
      await source.writeAsBytes(bytes, flush: true);
      return await _channel.invokeMethod<bool>('shareFile', <String, Object?>{
            'sourcePath': source.path,
            'fileName': fileName,
            'mimeType': mimeType,
          }) ??
          false;
    } finally {
      await _deleteTemporaryDirectory(temporaryDirectory);
    }
  }

  static Future<void> _deleteTemporaryDirectory(Directory directory) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        await directory.delete(recursive: true);
        return;
      } on FileSystemException {
        if (attempt == 2) rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
  }
}

Future<void> _deleteStagedFile(File file) async {
  for (var attempt = 0; attempt < 3; attempt++) {
    try {
      if (await file.exists()) await file.delete();
      return;
    } on FileSystemException {
      if (attempt == 2) rethrow;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }
}
