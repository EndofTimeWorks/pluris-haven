import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Copies text to the system clipboard, marked sensitive on Android so the
/// OS clipboard preview (Android 13+) does not show the copied content.
///
/// iOS has no equivalent clipboard-sensitivity flag, so it falls back to a
/// plain copy there and on every other platform.
class SensitiveClipboard {
  SensitiveClipboard._();

  static const _channel = MethodChannel('works.endoftime.plurishaven/clipboard');

  static Future<void> copy(String text) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      await Clipboard.setData(ClipboardData(text: text));
      return;
    }
    try {
      await _channel.invokeMethod<void>('copySensitive', {'text': text});
    } on MissingPluginException {
      await Clipboard.setData(ClipboardData(text: text));
    }
  }
}
