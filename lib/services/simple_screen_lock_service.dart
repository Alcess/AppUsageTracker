import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class SimpleScreenLockService {
  static const _channel = MethodChannel('app_usage_tracker/screen_lock');

  /// Lock the device screen (requires device admin)
  static Future<bool> lockScreen() async {
    if (kIsWeb) {
      debugPrint('Screen lock not supported on web');
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>('lockScreen');
      return result ?? false;
    } catch (e) {
      debugPrint('Error locking screen: $e');
      return false;
    }
  }

  /// Check if device admin is enabled
  static Future<bool> isDeviceAdminEnabled() async {
    if (kIsWeb) return false;

    try {
      final result = await _channel.invokeMethod<bool>('isDeviceAdminEnabled');
      return result ?? false;
    } catch (e) {
      debugPrint('Error checking device admin: $e');
      return false;
    }
  }

  /// Request device admin permissions
  static Future<void> requestDeviceAdmin() async {
    if (kIsWeb) return;

    try {
      await _channel.invokeMethod('requestDeviceAdmin');
    } catch (e) {
      debugPrint('Error requesting device admin: $e');
    }
  }

  /// Show a blocking notification instead of overlay
  static Future<void> showBlockingNotification(String appName) async {
    if (kIsWeb) {
      debugPrint('Notifications not supported on web');
      return;
    }

    try {
      await _channel.invokeMethod('showBlockingNotification', {
        'title': '$appName is Locked',
        'message': 'This app is currently blocked by parental controls.',
        'appName': appName,
      });
    } catch (e) {
      debugPrint('Error showing blocking notification: $e');
    }
  }
}
