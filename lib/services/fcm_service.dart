import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
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
        debugPrint('FCM not supported on web platform');
        return null;
      }

      // Request permission for notifications
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get FCM token
        String? fcmToken = await _messaging.getToken();

        // Store token locally
        if (fcmToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('fcmToken', fcmToken);
        }

        return fcmToken;
      }

      return null;
    } catch (e) {
      debugPrint('FCM initialization error: $e');
      return null;
    }
  }

  /// Get stored FCM token
  static Future<String?> getFCMToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcmToken');
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
      debugPrint('Error sending command: $e');
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
        debugPrint('Device unlock command executed - all overlays hidden');
        break;
      case 'lock':
        if (appPackage != null) {
          // Legacy app-specific lock (deprecated)
          final appName = _getAppNameFromPackage(appPackage);
          await showLockOverlay(appPackage, appName);
        }
        break;
      case 'unlock':
        // Legacy unlock command (deprecated)
        await SimpleOverlayService.hideSystemOverlay();
        OverlayService.hideOverlay();
        debugPrint('Unlock command executed - all overlays hidden');
        break;
      case 'emergency_unlock':
      case 'unlock_all':
        // Handle emergency unlock or unlock all command - force hide all overlays
        await SimpleOverlayService.hideSystemOverlay();
        OverlayService.hideOverlay();
        debugPrint('Emergency/unlock all command executed - all overlays force hidden');
        break;
      case 'time_limit':
        // Handle time limit command
        break;
      default:
        debugPrint('Unknown command: $action');
    }
  }

  /// Show device-wide lock overlay
  static Future<void> showDeviceLockOverlay() async {
    // Use the system overlay that works over other apps
    final success = await SimpleOverlayService.showSystemOverlay('Device Locked');
    
    if (!success) {
      // Fallback to notification if system overlay fails
      await SimpleScreenLockService.showBlockingNotification('Device Locked');
    }
    
    debugPrint('Device lock command executed - System overlay: $success');
  }

  /// Show lock overlay for specific app
  static Future<void> showLockOverlay(String appPackage, String appName) async {
    // Use the system overlay that works over other apps
    final success = await SimpleOverlayService.showSystemOverlay(appName);
    
    if (!success) {
      // Fallback to notification if system overlay fails
      await SimpleScreenLockService.showBlockingNotification(appName);
    }
    
    debugPrint('Lock command executed for $appName - System overlay: $success');
  }

  /// Get user-friendly app name from package name
  static String _getAppNameFromPackage(String packageName) {
    // Map common package names to user-friendly names
    const packageToNameMap = {
      'com.tiktok.android': 'TikTok',
      'com.instagram.android': 'Instagram',
      'com.google.android.youtube': 'YouTube',
      'com.snapchat.android': 'Snapchat',
      'com.whatsapp': 'WhatsApp',
      'com.facebook.katana': 'Facebook',
      'com.twitter.android': 'Twitter',
      'com.spotify.music': 'Spotify',
      'com.netflix.mediaclient': 'Netflix',
      'com.roblox.client': 'Roblox',
    };

    return packageToNameMap[packageName] ?? packageName;
  }
}
