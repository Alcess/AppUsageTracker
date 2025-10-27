import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:usage_stats/usage_stats.dart';

/// Comprehensive permission handler for all app permissions
class PermissionHandlerService {
  static const _channel = MethodChannel('app_usage_tracker/permissions');

  /// Request all necessary permissions for child mode
  static Future<void> requestChildModePermissions() async {
    if (!Platform.isAndroid || kIsWeb) return;

    debugPrint('Requesting child mode permissions...');

    // 1. System Alert Window Permission (for overlays)
    await requestSystemAlertWindowPermission();

    // 2. Access Notification Policy (for DND and notification management)
    await requestAccessNotificationPolicyPermission();

    // 3. Usage Access Permission (for app usage stats)
    await requestUsageAccessPermission();

    // 4. Battery Optimization Exemption (critical for Chinese phones)
    await requestBatteryOptimizationExemption();

    debugPrint('Child mode permission requests completed');
  }

  /// Request System Alert Window permission for overlays
  static Future<bool> requestSystemAlertWindowPermission() async {
    if (!Platform.isAndroid || kIsWeb) return true;

    try {
      // Check if already granted
      final hasPermission =
          await _channel.invokeMethod<bool>('hasSystemAlertWindowPermission') ??
          false;

      if (hasPermission) {
        debugPrint('System Alert Window permission already granted');
        return true;
      }

      debugPrint('Requesting System Alert Window permission...');
      await _channel.invokeMethod('requestSystemAlertWindowPermission');
      return false; // User needs to grant manually
    } catch (e) {
      debugPrint('Error requesting System Alert Window permission: $e');
      return false;
    }
  }

  /// Request Access Notification Policy permission
  static Future<bool> requestAccessNotificationPolicyPermission() async {
    if (!Platform.isAndroid || kIsWeb) return true;

    try {
      // Check if already granted
      final hasPermission =
          await _channel.invokeMethod<bool>(
            'hasAccessNotificationPolicyPermission',
          ) ??
          false;

      if (hasPermission) {
        debugPrint('Access Notification Policy permission already granted');
        return true;
      }

      debugPrint('Requesting Access Notification Policy permission...');
      await _channel.invokeMethod('requestAccessNotificationPolicyPermission');
      return false; // User needs to grant manually
    } catch (e) {
      debugPrint('Error requesting Access Notification Policy permission: $e');
      return false;
    }
  }

  /// Request Usage Access permission using existing usage_stats package
  static Future<bool> requestUsageAccessPermission() async {
    if (!Platform.isAndroid || kIsWeb) return true;

    try {
      final hasPermission = await UsageStats.checkUsagePermission();

      if (hasPermission == true) {
        debugPrint('Usage Access permission already granted');
        return true;
      }

      debugPrint('Requesting Usage Access permission...');
      UsageStats.grantUsagePermission();
      return false; // User needs to grant manually
    } catch (e) {
      debugPrint('Error requesting Usage Access permission: $e');
      return false;
    }
  }

  /// Request Battery Optimization Exemption (critical for Chinese phones)
  static Future<bool> requestBatteryOptimizationExemption() async {
    if (!Platform.isAndroid || kIsWeb) return true;

    try {
      // Check if already exempted
      final hasExemption =
          await _channel.invokeMethod<bool>(
            'hasBatteryOptimizationExemption',
          ) ??
          false;

      if (hasExemption) {
        debugPrint('Battery optimization exemption already granted');
        return true;
      }

      debugPrint('Requesting battery optimization exemption...');
      await _channel.invokeMethod('requestBatteryOptimizationExemption');
      return false; // User needs to grant manually
    } catch (e) {
      debugPrint('Error requesting battery optimization exemption: $e');
      return false;
    }
  }

  /// Request ignore battery optimizations permission (direct approach)
  static Future<bool> requestIgnoreBatteryOptimizations() async {
    if (!Platform.isAndroid || kIsWeb) return true;

    try {
      debugPrint('Requesting ignore battery optimizations...');
      await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
      return false; // User needs to grant manually
    } catch (e) {
      debugPrint('Error requesting ignore battery optimizations: $e');
      return false;
    }
  }

  /// Open autostart settings (manufacturer-specific for Chinese phones)
  static Future<void> openAutoStartSettings() async {
    if (!Platform.isAndroid || kIsWeb) return;

    try {
      debugPrint('Opening autostart settings...');
      await _channel.invokeMethod('openAutoStartSettings');
    } catch (e) {
      debugPrint('Error opening autostart settings: $e');
    }
  }

  /// Check if all child mode permissions are granted
  static Future<bool> hasAllChildModePermissions() async {
    if (!Platform.isAndroid || kIsWeb) return true;

    try {
      final systemAlert =
          await _channel.invokeMethod<bool>('hasSystemAlertWindowPermission') ??
          false;
      final notificationPolicy =
          await _channel.invokeMethod<bool>(
            'hasAccessNotificationPolicyPermission',
          ) ??
          false;
      final usageAccess = await UsageStats.checkUsagePermission() ?? false;
      final batteryOptimization =
          await _channel.invokeMethod<bool>(
            'hasBatteryOptimizationExemption',
          ) ??
          false;

      debugPrint(
        'Permission status - SystemAlert: $systemAlert, NotificationPolicy: $notificationPolicy, UsageAccess: $usageAccess, BatteryOptimization: $batteryOptimization',
      );

      return systemAlert &&
          notificationPolicy &&
          usageAccess &&
          batteryOptimization;
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      return false;
    }
  }

  /// Show permission explanation dialog
  static Future<void> showPermissionExplanation() async {
    // This would typically show a dialog explaining why permissions are needed
    debugPrint('Showing permission explanation...');
  }

  /// Open app settings for manual permission granting
  static Future<void> openAppSettings() async {
    if (!Platform.isAndroid || kIsWeb) return;

    try {
      await _channel.invokeMethod('openAppSettings');
    } catch (e) {
      debugPrint('Error opening app settings: $e');
    }
  }
}
