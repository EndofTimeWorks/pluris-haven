import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('US English catalogue contains intentional base-English overrides', () {
    final english = _messagesIn('lib/l10n/app_en.arb');
    final usEnglish = _messagesIn('lib/l10n/app_en_US.arb');

    expect(usEnglish.keys, everyElement(isIn(english.keys)));
    for (final entry in usEnglish.entries) {
      expect(entry.value, isNot(english[entry.key]));
    }
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
