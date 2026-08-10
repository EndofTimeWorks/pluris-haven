import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('English localisation catalogues expose the same messages', () {
    final english = _messagesIn('lib/l10n/app_en.arb');
    final usEnglish = _messagesIn('lib/l10n/app_en_US.arb');

    expect(usEnglish.keys, unorderedEquals(english.keys));
    expect(english.values, everyElement(isNotEmpty));
    expect(usEnglish.values, everyElement(isNotEmpty));
  });
}

Map<String, String> _messagesIn(String path) {
  final json =
      jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
  return {
    for (final entry in json.entries)
      if (!entry.key.startsWith('@')) entry.key: entry.value! as String,
  };
}
