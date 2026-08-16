import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/notifications/local_time_zone.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  test(
    'configures the scheduling timezone from the device identifier',
    () async {
      await configureLocalTimeZone(
        readIdentifier: () async => 'America/Phoenix',
      );

      expect(tz.local.name, 'America/Phoenix');
      expect(tz.TZDateTime(tz.local, 2026, 8, 16, 9).hour, 9);
    },
  );
}
