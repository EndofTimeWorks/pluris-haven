import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

Future<void> configureLocalTimeZone({
  Future<String> Function()? readIdentifier,
}) async {
  tz_data.initializeTimeZones();
  final identifier = readIdentifier == null
      ? (await FlutterTimezone.getLocalTimezone()).identifier
      : await readIdentifier();
  tz.setLocalLocation(tz.getLocation(identifier));
}
