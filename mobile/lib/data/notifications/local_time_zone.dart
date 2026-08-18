import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../platform/native_timezone.dart';

Future<void> configureLocalTimeZone({
  Future<String> Function()? readIdentifier,
}) async {
  tz_data.initializeTimeZones();
  final identifier = readIdentifier == null
      ? await NativeTimezone.getLocalTimezone()
      : await readIdentifier();
  tz.setLocalLocation(tz.getLocation(identifier));
}
