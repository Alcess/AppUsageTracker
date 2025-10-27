import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';

class OverlayService {
  static bool _isOverlayActive = false;

  /// Show lock overlay for a specific app
  static Future<void> showLockOverlay(String appPackage) async {
    if (_isOverlayActive || kIsWeb) {
      if (kIsWeb) {
        debugPrint(
          'Overlay not supported on web - App $appPackage would be locked',
        );
      }
      return;
    }

    try {
      // Check if overlay permission is granted
      final hasPermission = await FlutterOverlayWindow.isPermissionGranted();
      if (!hasPermission) {
        await requestOverlayPermission();
        return;
      }

      _isOverlayActive = true;

      // Show blocking overlay as specified in the attachment
      await FlutterOverlayWindow.showOverlay(
        alignment: OverlayAlignment.center,
        height: 400,
        width: 300,
        enableDrag: false,
        flag: OverlayFlag.focusPointer,
        overlayTitle: "Locked App",
        overlayContent: "This app is locked by your parent.",
      );

      // Auto-hide overlay after a few seconds
      Future.delayed(const Duration(seconds: 3), () {
        hideOverlay();
      });
    } catch (e) {
      debugPrint('Error showing overlay: $e');
      _isOverlayActive = false;
    }
  }

  /// Show lock overlay for a specific app with custom UI
  static Future<void> showCustomLockOverlay(
    String appPackage,
    String appName,
  ) async {
    if (_isOverlayActive || kIsWeb) {
      if (kIsWeb) {
        debugPrint(
          'Custom overlay not supported on web - App $appName ($appPackage) would be locked',
        );
      }
      return;
    }

    try {
      // Check if overlay permission is granted
      final hasPermission = await FlutterOverlayWindow.isPermissionGranted();
      if (!hasPermission) {
        await requestOverlayPermission();
        return;
      }

      _isOverlayActive = true;

      // Show custom blocking overlay with full screen coverage
      await FlutterOverlayWindow.showOverlay(
        alignment: OverlayAlignment.center,
        height: 600,
        width: 400,
        enableDrag: false,
        flag: OverlayFlag.focusPointer,
        overlayTitle: "🔒 $appName Locked",
        overlayContent:
            "This app is currently blocked by parental controls. Please use other apps or contact your parent for permission.",
      );

      // Keep overlay active until manually dismissed
      // Don't auto-hide for blocking functionality
    } catch (e) {
      debugPrint('Error showing custom overlay: $e');
      _isOverlayActive = false;
    }
  }

  /// Hide the overlay
  static Future<void> hideOverlay() async {
    if (kIsWeb) {
      _isOverlayActive = false;
      return;
    }

    try {
      await FlutterOverlayWindow.closeOverlay();
      _isOverlayActive = false;
    } catch (e) {
      debugPrint('Error hiding overlay: $e');
    }
  }

  /// Request overlay permission
  static Future<void> requestOverlayPermission() async {
    if (kIsWeb) {
      debugPrint('Overlay permission not needed on web');
      return;
    }

    try {
      await FlutterOverlayWindow.requestPermission();
    } catch (e) {
      debugPrint('Error requesting overlay permission: $e');
    }
  }

  /// Check if overlay permission is granted
  static Future<bool> hasOverlayPermission() async {
    if (kIsWeb) {
      return true; // Web doesn't need overlay permission
    }

    try {
      return await FlutterOverlayWindow.isPermissionGranted();
    } catch (e) {
      debugPrint('Error checking overlay permission: $e');
      return false;
    }
  }

  /// Open app settings for overlay permission
  static Future<void> openOverlaySettings() async {
    if (kIsWeb) {
      debugPrint('Overlay settings not available on web');
      return;
    }

    try {
      const intent = AndroidIntent(
        action: 'android.settings.action.MANAGE_OVERLAY_PERMISSION',
      );
      await intent.launch();
    } catch (e) {
      debugPrint('Error opening overlay settings: $e');
    }
  }
}
