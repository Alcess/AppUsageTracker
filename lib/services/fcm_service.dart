import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../utils/app_name_mapper.dart';
import '../utils/shared_prefs_helper.dart';
import '../utils/app_logger.dart';
import 'overlay_service.dart';
import 'simple_screen_lock_service.dart';
import 'simple_overlay_service.dart';
import 'dart:async';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static StreamSubscription<QuerySnapshot>? _commandSubscription;

  /// Initialize Firebase Messaging and get FCM token
  static Future<String?> initialize() async {
    try {
      // Skip FCM initialization on web
      if (kIsWeb) {
        AppLogger.fcm('FCM not supported on web platform');
        return null;
      }

      // Request permission for notifications
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get FCM token with retry mechanism
        String? fcmToken = await _getFCMTokenWithRetry();

        // Store token locally if obtained
        if (fcmToken != null) {
          await SharedPrefsHelper.setString('fcmToken', fcmToken);
          AppLogger.fcm('Token obtained and stored successfully');
        } else {
          AppLogger.error('Failed to obtain FCM token after retries', 'FCM');
        }

        return fcmToken;
      } else {
        AppLogger.warning('FCM notification permission denied', 'FCM');
      }

      return null;
    } catch (e) {
      AppLogger.error('FCM initialization error', 'FCM', e);
      // Continue without FCM if Google Play Services has issues
      return null;
    }
  }

  /// Get FCM token with retry mechanism to handle Google Play Services issues
  static Future<String?> _getFCMTokenWithRetry() async {
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        AppLogger.debug(
          'Attempting to get FCM token (attempt $attempt/3)',
          'FCM',
        );
        final token = await _messaging.getToken();
        if (token != null) {
          AppLogger.fcm('Token obtained successfully on attempt $attempt');
          return token;
        }
      } catch (e) {
        AppLogger.warning('FCM token attempt $attempt failed: $e', 'FCM');
        if (attempt < 3) {
          // Wait before retrying
          await Future.delayed(Duration(seconds: attempt));
        }
      }
    }

    AppLogger.warning(
      'All FCM token attempts failed - continuing without FCM',
      'FCM',
    );
    return null;
  }

  /// Get stored FCM token
  static Future<String?> getFCMToken() async {
    try {
      if (kIsWeb) {
        AppLogger.fcm('FCM not supported on web platform');
        return null;
      }

      String? storedToken = await SharedPrefsHelper.getString('fcmToken');

      // If no stored token, try to get a fresh one
      if (storedToken == null) {
        AppLogger.debug(
          'No stored FCM token found, requesting new one...',
          'FCM',
        );
        storedToken = await _messaging.getToken();

        if (storedToken != null) {
          await SharedPrefsHelper.setString('fcmToken', storedToken);
          AppLogger.fcm('New FCM token obtained and stored');
        } else {
          AppLogger.error('Failed to obtain FCM token', 'FCM');
        }
      }

      return storedToken;
    } catch (e) {
      AppLogger.error('Error getting FCM token', 'FCM', e);
      return null;
    }
  }

  /// Force refresh FCM token
  static Future<String?> refreshFCMToken() async {
    try {
      if (kIsWeb) {
        AppLogger.fcm('FCM not supported on web platform');
        return null;
      }

      AppLogger.debug('Refreshing FCM token...', 'FCM');
      final newToken = await _messaging.getToken();

      if (newToken != null) {
        await SharedPrefsHelper.setString('fcmToken', newToken);
        AppLogger.fcm('Token refreshed successfully');
      } else {
        AppLogger.error('Failed to refresh FCM token', 'FCM');
      }

      return newToken;
    } catch (e) {
      AppLogger.error('Error refreshing FCM token', 'FCM', e);
      return null;
    }
  }

  /// Start listening for commands (Child device)
  static Future<void> startListeningForCommands() async {
    final fcmToken = await getFCMToken();
    if (fcmToken == null) return;

    _commandSubscription = _firestore
        .collection('commands')
        .where('to', isEqualTo: fcmToken)
        .snapshots()
        .listen((snapshot) async {
          for (var doc in snapshot.docs) {
            await handleCommand(doc.data());
            // Delete the command after processing
            doc.reference.delete();
          }
        });
  }

  /// Stop listening for commands
  static void stopListeningForCommands() {
    _commandSubscription?.cancel();
    _commandSubscription = null;
  }

  /// Send command from parent to child
  static Future<bool> sendCommand({
    required String childToken,
    required String action,
    String? appPackage,
  }) async {
    try {
      await _firestore.collection('commands').add({
        'to': childToken,
        'action': action,
        'appPackage': appPackage,
        'timestamp': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      AppLogger.error('Error sending command', 'FCM', e);
      return false;
    }
  }

  /// Handle incoming commands (Child device)
  static Future<void> handleCommand(Map<String, dynamic> data) async {
    final action = data['action'] as String?;
    final appPackage = data['appPackage'] as String?;

    switch (action) {
      case 'lock_device':
        // Lock the entire device
        await showDeviceLockOverlay();
        break;
      case 'unlock_device':
        // Unlock the device - hide all overlays
        await SimpleOverlayService.hideSystemOverlay();
        OverlayService.hideOverlay();
        AppLogger.service(
          'Device unlock command executed - all overlays hidden',
          'FCM',
        );
        break;
      case 'lock':
        if (appPackage != null) {
          // Legacy app-specific lock (deprecated)
          final appName = AppNameMapper.getAppNameSync(appPackage);
          await showLockOverlay(appPackage, appName);
        }
        break;
      case 'unlock':
        // Legacy unlock command (deprecated)
        await SimpleOverlayService.hideSystemOverlay();
        OverlayService.hideOverlay();
        AppLogger.service(
          'Unlock command executed - all overlays hidden',
          'FCM',
        );
        break;
      case 'emergency_unlock':
      case 'unlock_all':
        // Handle emergency unlock or unlock all command - force hide all overlays
        await SimpleOverlayService.hideSystemOverlay();
        OverlayService.hideOverlay();
        AppLogger.service(
          'Emergency/unlock all command executed - all overlays force hidden',
          'FCM',
        );
        break;
      case 'time_limit':
        // Handle time limit command
        break;
      default:
        AppLogger.warning('Unknown command: $action', 'FCM');
    }
  }

  /// Show device-wide lock overlay
  static Future<void> showDeviceLockOverlay() async {
    // Use the system overlay that works over other apps
    final success = await SimpleOverlayService.showSystemOverlay(
      'Device Locked',
    );

    if (!success) {
      // Fallback to notification if system overlay fails
      await SimpleScreenLockService.showBlockingNotification('Device Locked');
    }

    AppLogger.service(
      'Device lock command executed - System overlay: $success',
      'FCM',
    );
  }

  /// Show lock overlay for specific app
  static Future<void> showLockOverlay(String appPackage, String appName) async {
    // Use the system overlay that works over other apps
    final success = await SimpleOverlayService.showSystemOverlay(appName);

    if (!success) {
      // Fallback to notification if system overlay fails
      await SimpleScreenLockService.showBlockingNotification(appName);
    }

    AppLogger.service(
      'Lock command executed for $appName - System overlay: $success',
      'FCM',
    );
  }
}
