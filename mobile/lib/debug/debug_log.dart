import 'package:flutter/foundation.dart';

void appDebugLog(String message, {Object? error, StackTrace? stackTrace}) {
  if (!kDebugMode) {
    return;
  }

  final buffer = StringBuffer('[PlurisHaven] $message');
  if (error != null) {
    buffer.write(' | error=$error');
  }
  if (stackTrace != null) {
    final stackLines = stackTrace.toString().trim().split('\n').take(12);
    buffer.write('\n${stackLines.join('\n')}');
  }

  final text = buffer.toString();
  const chunkSize = 900;
  for (var start = 0; start < text.length; start += chunkSize) {
    final end = (start + chunkSize).clamp(0, text.length);
    debugPrint(text.substring(start, end));
  }
}
