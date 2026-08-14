import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/avatar/avatar_file_policy.dart';

void main() {
  test('accepts supported raster image signatures', () {
    expect(
      validateRasterAvatarBytes(
        Uint8List.fromList([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
      ),
      'image/png',
    );
    expect(
      validateRasterAvatarBytes(Uint8List.fromList([0xff, 0xd8, 0xff])),
      'image/jpeg',
    );
    expect(
      validateRasterAvatarBytes(Uint8List.fromList('GIF89a'.codeUnits)),
      'image/gif',
    );
    expect(
      validateRasterAvatarBytes(
        Uint8List.fromList([
          ...'RIFF'.codeUnits,
          0,
          0,
          0,
          0,
          ...'WEBP'.codeUnits,
        ]),
      ),
      'image/webp',
    );
  });

  test('rejects empty, oversized, unknown, and SVG avatar data', () {
    expect(
      () => validateRasterAvatarBytes(Uint8List(0)),
      throwsAvatarIssue(AvatarFileIssue.empty),
    );
    expect(
      () => validateRasterAvatarBytes(Uint8List(maximumAvatarBytes + 1)),
      throwsAvatarIssue(AvatarFileIssue.tooLarge),
    );
    expect(
      () =>
          validateRasterAvatarBytes(Uint8List.fromList('not a png'.codeUnits)),
      throwsAvatarIssue(AvatarFileIssue.unsupportedType),
    );
    expect(
      () => validateRasterAvatarBytes(
        Uint8List.fromList(
          '<svg xmlns="http://www.w3.org/2000/svg"/>'.codeUnits,
        ),
      ),
      throwsAvatarIssue(AvatarFileIssue.unsupportedType),
    );
  });
}

Matcher throwsAvatarIssue(AvatarFileIssue issue) => throwsA(
  isA<AvatarFileException>().having((error) => error.issue, 'issue', issue),
);
