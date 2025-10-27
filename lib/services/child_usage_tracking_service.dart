import 'dart:async';
import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/role_service.dart';
import '../services/family_link_service.dart';
import '../services/permission_handler_service.dart';
import 'package:usage_stats/usage_stats.dart';

/// Enhanced app usage tracking service with child mode syncing
class ChildUsageTrackingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static Timer? _syncTimer;

  /// Start automatic usage tracking and syncing for child mode
  static Future<void> startChildModeTracking() async {
    // Only start if in child mode and on mobile platform
    if (kIsWeb) return;

    final role = await RoleService.getRole();
    if (role != AppRole.child) return;

    // Request all necessary permissions for child mode
    debugPrint('Requesting child mode permissions...');
    await PermissionHandlerService.requestChildModePermissions();

    // Check if all permissions are granted
    final hasAllPermissions =
        await PermissionHandlerService.hasAllChildModePermissions();
    if (!hasAllPermissions) {
      debugPrint('Not all permissions granted - some features may not work');
      // Continue anyway, but functionality will be limited
    }

    debugPrint('Starting child mode usage tracking...');

    // Start periodic syncing every hour
    _syncTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _syncUsageToFirestore();
    });

    // Initial sync
    await _syncUsageToFirestore();
  }

  /// Stop usage tracking
  static void stopChildModeTracking() {
    _syncTimer?.cancel();
    _syncTimer = null;
    debugPrint('Stopped child mode usage tracking');
  }

  /// Sync current usage data to Firestore
  static Future<void> _syncUsageToFirestore() async {
    try {
      if (kIsWeb) return;

      // Get child's link code for Firestore document
      final linkCode = await FamilyLinkService.getLinkCode();
      if (linkCode == null) {
        debugPrint('No link code found, skipping usage sync');
        return;
      }

      // Get usage events for the last hour
      final events = await _getRecentUsageEvents();

      if (events.isEmpty) {
        debugPrint('No usage events to sync');
        return;
      }

      // Prepare data for Firestore
      final usageData = {
        'timestamp': FieldValue.serverTimestamp(),
        'childToken': await _getChildToken(),
        'events': events.map((event) => event.toJson()).toList(),
        'syncedAt': DateTime.now().toIso8601String(),
      };

      // Save to Firestore under the link document
      await _firestore
          .collection('links')
          .doc(linkCode)
          .collection('usage_data')
          .add(usageData);

      debugPrint('Synced ${events.length} usage events to Firestore');
    } catch (e) {
      debugPrint('Error syncing usage data: $e');
    }
  }

  /// Get recent usage events from the device
  static Future<List<UsageEvent>> _getRecentUsageEvents() async {
    try {
      if (Platform.isAndroid) {
        final now = DateTime.now();
        final oneHourAgo = now.subtract(const Duration(hours: 1));

        // Get usage events from the last hour
        final events = await UsageStats.queryEvents(oneHourAgo, now);

        return events
            .map(
              (event) => UsageEvent(
                packageName: event.packageName ?? '',
                appName: event.packageName ?? '', // Will be mapped later
                timestamp: (event.timeStamp as int?) ?? 0,
                eventType: (event.eventType as int?) ?? 0,
                duration: _calculateDuration(event),
              ),
            )
            .toList();
      }
    } catch (e) {
      debugPrint('Error getting usage events: $e');
    }

    return [];
  }

  /// Calculate duration for usage event
  static int _calculateDuration(dynamic event) {
    // This would calculate actual usage duration
    // For now, return a placeholder
    return 0;
  }

  /// Get child token from local storage
  static Future<String?> _getChildToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('childToken');
  }

  /// Manual sync for immediate data transfer
  static Future<void> forceSyncUsage() async {
    debugPrint('Force syncing usage data...');
    await _syncUsageToFirestore();
  }
}

/// Usage event model for Firestore
class UsageEvent {
  final String packageName;
  final String appName;
  final int timestamp;
  final int eventType;
  final int duration;

  UsageEvent({
    required this.packageName,
    required this.appName,
    required this.timestamp,
    required this.eventType,
    required this.duration,
  });

  Map<String, dynamic> toJson() => {
    'packageName': packageName,
    'appName': appName,
    'timestamp': timestamp,
    'eventType': eventType,
    'duration': duration,
  };
}
