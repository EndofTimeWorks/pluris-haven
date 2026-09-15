import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:libcompress/libcompress.dart';

void main() {
  test('zstd stream segments round trip with a bounded decoder', () async {
    final input = List<Uint8List>.generate(
      4,
      (index) => Uint8List.fromList(List<int>.filled(64 * 1024, index)),
    );
    final compressed = await ZstdStreamCodec(
      checksum: true,
      strict: true,
    ).compress(Stream<Uint8List>.fromIterable(input)).toList();
    final restored = await ZstdStreamCodec(
      maxSize: 4 * 64 * 1024,
      maxBufferSize: 256 * 1024,
      verified: true,
    ).decompress(Stream<Uint8List>.fromIterable(compressed)).toList();

    expect(
      restored.expand((chunk) => chunk),
      orderedEquals(input.expand((chunk) => chunk)),
    );
  });

  test('zstd stream decoder rejects output above its declared limit', () async {
    final input = Uint8List.fromList(List<int>.filled(64 * 1024, 0x41));
    final compressed = await ZstdStreamCodec(
      checksum: true,
      strict: true,
    ).compress(Stream.value(input)).toList();

    await expectLater(
      ZstdStreamCodec(
        maxSize: 1024,
        verified: true,
      ).decompress(Stream<Uint8List>.fromIterable(compressed)).drain(),
      throwsA(anything),
    );
  });
}
