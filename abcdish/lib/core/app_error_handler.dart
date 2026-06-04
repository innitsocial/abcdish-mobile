import 'dart:async';
import 'package:flutter/foundation.dart';

class AppErrorHandler {
  static Future<void> initialize() async {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('Flutter Error: ${details.exception}');
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('Platform Error: $error');
      return true;
    };
  }
}
