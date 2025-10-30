import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/app_limit.dart';
import '../models/app_usage.dart';
import 'app_usage_service.dart';

/// Service to manage app usage limits and send notifications
class AppLimitService {
  static const String _prefsKey = 'app_limits';
  static final AppLimitService _instance = AppLimitService._internal();
  factory AppLimitService() => _instance;
  AppLimitService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final AppUsageService _usageService = AppUsageService();

  bool _isInitialized = false;

  /// Initialize the service and notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(initSettings);
    _isInitialized = true;

    debugPrint('AppLimitService initialized with notifications');
  }

  /// Get all configured app limits
  Future<List<AppLimit>> getAppLimits() async {
    await initialize();
    final prefs = await SharedPreferences.getInstance();
    final limitsJson = prefs.getStringList(_prefsKey) ?? [];

    return limitsJson
        .map((json) => AppLimit.fromJson(jsonDecode(json)))
        .toList();
  }

  /// Add a new app limit
  Future<void> addAppLimit(AppLimit limit) async {
    final limits = await getAppLimits();

    // Remove existing limit for this app if any
    limits.removeWhere((l) => l.packageName == limit.packageName);

    // Add new limit
    limits.add(limit);

    await _saveAppLimits(limits);
  }

  /// Remove an app limit
  Future<void> removeAppLimit(String packageName) async {
    final limits = await getAppLimits();
    limits.removeWhere((l) => l.packageName == packageName);
    await _saveAppLimits(limits);
  }

  /// Update an existing app limit
  Future<void> updateAppLimit(AppLimit updatedLimit) async {
    final limits = await getAppLimits();
    final index = limits.indexWhere(
      (l) => l.packageName == updatedLimit.packageName,
    );

    if (index != -1) {
      limits[index] = updatedLimit;
      await _saveAppLimits(limits);
    }
  }

  /// Get app limit status with current usage
  Future<List<AppLimitStatus>> getAppLimitStatuses() async {
    final limits = await getAppLimits();
    if (limits.isEmpty) return [];

    final usage = await _usageService.fetchUsage(TimeRange.today);
    final usageMap = {for (var app in usage) app.packageName: app.minutesUsed};

    return limits.where((limit) => limit.isEnabled).map((limit) {
      final currentUsage = usageMap[limit.packageName] ?? 0;
      return AppLimitStatus.fromUsage(limit, currentUsage);
    }).toList();
  }

  /// Check for limit violations (simplified for now)
  Future<List<AppLimitStatus>> checkLimitViolations() async {
    final statuses = await getAppLimitStatuses();
    return statuses.where((status) => status.isOverLimit).toList();
  }

  /// Check for limit violations and send notifications
  Future<void> checkLimitsAndNotify() async {
    final statuses = await getAppLimitStatuses();
    final now = DateTime.now();

    for (final status in statuses) {
      if (status.isOverLimit) {
        final limit = status.limit;

        // Only notify once per day to avoid spam
        final shouldNotify =
            limit.lastNotified == null || !_isSameDay(limit.lastNotified!, now);

        if (shouldNotify) {
          await _sendLimitNotification(status);

          // Update last notified time
          final updatedLimit = limit.copyWith(lastNotified: now);
          await updateAppLimit(updatedLimit);
        }
      }
    }
  }

  /// Send a notification for limit violation
  Future<void> _sendLimitNotification(AppLimitStatus status) async {
    await initialize();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'app_limits',
          'App Usage Limits',
          channelDescription:
              'Notifications when app usage limits are exceeded',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    final title = '⚠️ Usage Limit Exceeded';
    final body =
        '${status.limit.appName} limit (${formatMinutes(status.limit.limitMinutes)}) exceeded!\n'
        'You\'ve used ${formatMinutes(status.currentUsageMinutes)} today.';

    await _notifications.show(
      status.limit.packageName.hashCode,
      title,
      body,
      notificationDetails,
    );

    debugPrint('Sent notification for ${status.limit.appName} limit exceeded');
  }

  /// Manually trigger notification check (for testing)
  Future<void> triggerNotificationCheck() async {
    await checkLimitsAndNotify();
  }

  /// Save app limits to shared preferences
  Future<void> _saveAppLimits(List<AppLimit> limits) async {
    final prefs = await SharedPreferences.getInstance();
    final limitsJson = limits
        .map((limit) => jsonEncode(limit.toJson()))
        .toList();
    await prefs.setStringList(_prefsKey, limitsJson);
  }

  /// Check if two dates are on the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Get app limit for a specific package (if exists)
  Future<AppLimit?> getAppLimit(String packageName) async {
    final limits = await getAppLimits();
    try {
      return limits.firstWhere((l) => l.packageName == packageName);
    } catch (e) {
      return null;
    }
  }

  /// Format minutes to human-readable string
  static String formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }
}
