import 'dart:io' show Platform;
import 'package:flutter/services.dart';

/// Dart wrapper for Android Usage Access permission.
class UsageAccessPermission {
  static const _channel = MethodChannel('app_usage_tracker/usage_access');

  /// Returns true if the app currently has Usage Access permission (Android only).
  static Future<bool> hasPermission() async {
    if (!Platform.isAndroid) return true; // non-Android: treat as granted
    final ok = await _channel.invokeMethod<bool>('hasUsageAccess');
    return ok ?? false;
  }

  /// Opens the Usage Access settings screen (Android only).
  /// Returns immediately; user must toggle permission and navigate back.
  static Future<void> requestPermission() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod('requestUsageAccess');
  }

  /// Ensures the permission is granted. If not, opens settings and
  /// returns false. Callers can re-check after user returns.
  static Future<bool> ensurePermission() async {
    final has = await hasPermission();
    if (has) return true;
    await requestPermission();
    return false;
  }
}
