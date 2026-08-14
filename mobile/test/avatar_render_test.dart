import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/features/home/home_page.dart';

void main() {
  testWidgets('avatar decoding is bounded in physical pixels', (tester) async {
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: SpAvatar(
          size: 40,
          color: Colors.black,
          image: MemoryImage(_transparentPng),
        ),
      ),
    );

    final image = _avatarDecoration(tester).image as ResizeImage;
    expect(image.width, 120);
    expect(image.height, 120);
    expect(image.policy, ResizeImagePolicy.fit);
    expect(image.allowUpscaling, isFalse);
  });

  testWidgets('avatar decoding has an absolute dimension ceiling', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 4;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: SpAvatar(
          size: 200,
          color: Colors.black,
          image: MemoryImage(_transparentPng),
        ),
      ),
    );

    final image = _avatarDecoration(tester).image as ResizeImage;
    expect(image.width, 512);
    expect(image.height, 512);
  });
}

DecorationImage _avatarDecoration(WidgetTester tester) {
  final container = tester.widget<Container>(
    find.descendant(
      of: find.byType(SpAvatar),
      matching: find.byType(Container),
    ),
  );
  return (container.decoration! as BoxDecoration).image!;
}

final Uint8List _transparentPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);
