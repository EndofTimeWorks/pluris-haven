import 'dart:typed_data';

const maximumAvatarBytes = 10 * 1024 * 1024;

enum AvatarFileIssue { empty, tooLarge, unsupportedType }

final class AvatarFileException implements Exception {
  const AvatarFileException(this.issue);

  final AvatarFileIssue issue;
}

String validateRasterAvatarBytes(Uint8List bytes) {
  if (bytes.isEmpty) {
    throw const AvatarFileException(AvatarFileIssue.empty);
  }
  if (bytes.length > maximumAvatarBytes) {
    throw const AvatarFileException(AvatarFileIssue.tooLarge);
  }
  final mimeType = sniffAvatarMimeType(bytes);
  if (mimeType == null || mimeType == 'image/svg+xml') {
    throw const AvatarFileException(AvatarFileIssue.unsupportedType);
  }
  return mimeType;
}

String? sniffAvatarMimeType(Uint8List bytes) {
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4e &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0d &&
      bytes[5] == 0x0a &&
      bytes[6] == 0x1a &&
      bytes[7] == 0x0a) {
    return 'image/png';
  }
  if (bytes.length >= 3 &&
      bytes[0] == 0xff &&
      bytes[1] == 0xd8 &&
      bytes[2] == 0xff) {
    return 'image/jpeg';
  }
  if (bytes.length >= 6) {
    final signature = String.fromCharCodes(bytes.take(6));
    if (signature == 'GIF87a' || signature == 'GIF89a') {
      return 'image/gif';
    }
  }
  if (bytes.length >= 12 &&
      String.fromCharCodes(bytes.take(4)) == 'RIFF' &&
      String.fromCharCodes(bytes.skip(8).take(4)) == 'WEBP') {
    return 'image/webp';
  }
  if (bytes.isNotEmpty) {
    final prefix = String.fromCharCodes(
      bytes.take(512),
    ).trimLeft().toLowerCase();
    if (prefix.startsWith('<svg') ||
        (prefix.startsWith('<?xml') && prefix.contains('<svg'))) {
      return 'image/svg+xml';
    }
  }
  return null;
}
