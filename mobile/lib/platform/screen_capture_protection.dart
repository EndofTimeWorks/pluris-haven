import 'package:flutter/services.dart';

class ScreenCaptureProtection {
  static const _channel = MethodChannel(
    'works.endoftime.plurishaven/screen_capture',
  );

  static Future<void> setEnabled(bool enabled) async {
    try {
      await _channel.invokeMethod<void>('setEnabled', {'enabled': enabled});
    } on MissingPluginException {
      // Unsupported desktop and web targets intentionally have no native hook.
    }
  }
}
