import 'dart:async';

import 'package:abcdish/services/api_client.dart';
import 'package:flutter/foundation.dart';

String userFriendlyErrorMessage(
  Object error, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  if (error is TimeoutException || _looksLikeNetworkError(error)) {
    return 'The connection is taking too long. Please try again.';
  }

  if (error is ApiException) {
    if (error.statusCode == 401 || error.statusCode == 403) {
      return 'Please sign in to continue.';
    }
    if (error.statusCode == 404) {
      return 'We could not find that item.';
    }
    if (error.statusCode >= 500) {
      return 'ABCDish is warming up. Please try again in a moment.';
    }

    final message = error.message.trim();
    if (message.isNotEmpty && !_looksInternal(message)) {
      return message;
    }
  }

  final message = error.toString().trim();
  if (message.isNotEmpty && !_looksInternal(message)) {
    return message;
  }

  return fallback;
}

void logUiError(String context, Object error, [StackTrace? stackTrace]) {
  debugPrint('$context: $error');
  if (stackTrace != null) {
    debugPrintStack(stackTrace: stackTrace);
  }
}

bool _looksLikeNetworkError(Object error) {
  final message = error.toString().toLowerCase();
  return message.contains('socketexception') ||
      message.contains('failed host lookup') ||
      message.contains('connection refused') ||
      message.contains('connection closed');
}

bool _looksInternal(String message) {
  final lower = message.toLowerCase();
  if (message.length > 180) return true;

  return lower.contains('exception') ||
      lower.contains('stacktrace') ||
      lower.contains('hibernate') ||
      lower.contains('jdbc') ||
      lower.contains('sql') ||
      lower.contains('postgres') ||
      lower.contains('constraint') ||
      lower.contains('org.') ||
      lower.contains('java.') ||
      lower.contains('com.innitsocial');
}
