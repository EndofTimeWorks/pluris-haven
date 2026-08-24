import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/local/local_id.dart';

void main() {
  test('local IDs are opaque and unique', () {
    final ids = <String>{
      for (var index = 0; index < 1_000; index++) newLocalId('member'),
    };

    expect(ids, hasLength(1_000));
    expect(ids.first, matches(RegExp(r'^member-[0-9a-f]{32}$')));
  });
}
