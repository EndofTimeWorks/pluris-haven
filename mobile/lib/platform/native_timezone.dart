import 'package:flutter/services.dart';

class NativeTimezone {
  NativeTimezone._();

  static const _channel = MethodChannel('works.endoftime.plurishaven/timezone');

  static Future<String> getLocalTimezone() async {
    final identifier = await _channel.invokeMethod<String>('getLocalTimezone');
    if (identifier == null || identifier.isEmpty) {
      throw PlatformException(
        code: 'timezone_unavailable',
        message: 'The platform did not return a timezone identifier.',
      );
    }
    return identifier;
  }
}
