import 'package:flutter/foundation.dart';

/// Centralized logging utility to reduce debug print boilerplate
class AppLogger {
  static const String _tag = 'AppUsageTracker';

  /// Log info message
  static void info(String message, [String? component]) {
    _log('INFO', message, component);
  }

  /// Log error message
  static void error(String message, [String? component, Object? error]) {
    _log('ERROR', message, component);
    if (error != null) {
      debugPrint('[$_tag] ERROR Details: $error');
    }
  }

  /// Log warning message
  static void warning(String message, [String? component]) {
    _log('WARN', message, component);
  }

  /// Log debug message
  static void debug(String message, [String? component]) {
    if (kDebugMode) {
      _log('DEBUG', message, component);
    }
  }

  /// Log FCM related messages
  static void fcm(String message) {
    _log('FCM', message);
  }

  /// Log connection related messages
  static void connection(String message) {
    _log('CONN', message);
  }

  /// Log service related messages
  static void service(String message, String serviceName) {
    _log('SERVICE', message, serviceName);
  }

  static void _log(String level, String message, [String? component]) {
    final prefix = component != null ? '[$_tag:$component]' : '[$_tag]';
    debugPrint('$prefix $level: $message');
  }
}
