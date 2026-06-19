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

  final text = _truncateDebugText(buffer.toString());
  const chunkSize = 900;
  for (var start = 0; start < text.length; start += chunkSize) {
    final end = (start + chunkSize).clamp(0, text.length);
    debugPrint(text.substring(start, end));
  }
}

String _truncateDebugText(String text) {
  const maxLength = 12000;
  if (text.length <= maxLength) {
    return text;
  }
  return '${text.substring(0, maxLength)}\n'
      '[PlurisHaven] debug log truncated ${text.length - maxLength} chars';
}
