import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import '../models/app_usage.dart';
import '../models/app_usage_detail.dart';
import '../utils/app_name_mapper.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A mock service that returns fake app usage data.
/// Replace with a platform-specific implementation later.
class AppUsageService {
  static const _channel = MethodChannel('app_usage_tracker/usage_access');

  Future<List<AppUsage>> fetchUsage(TimeRange range) async {
    if (Platform.isAndroid) {
      try {
        final now = DateTime.now();
        final end = now.millisecondsSinceEpoch;
        final start = _startForRange(now, range).millisecondsSinceEpoch;
        final includeSystemApps = await _getIncludeSystemApps();

        // Prefer the generic getUsage call; fallback to getTodayUsage if not implemented and range==today
        List<dynamic>? raw;
        try {
          raw = await _channel.invokeMethod<List<dynamic>>('getUsage', {
            'start': start,
            'end': end,
            'includeSystemApps': includeSystemApps,
          });
        } on PlatformException catch (_) {
          if (range == TimeRange.today) {
            raw = await _channel.invokeMethod<List<dynamic>>('getTodayUsage');
          } else {
            rethrow;
          }
        }

        final items = <AppUsage>[];
        for (final m in (raw ?? const <dynamic>[]).whereType<Map>()) {
          final packageName = (m['packageName'] ?? '') as String;
          final rawAppName = (m['appName'] ?? '') as String;

          // Use hybrid app name mapping
          String appName;
          if (rawAppName.isNotEmpty && rawAppName != packageName) {
            // If we have a good raw name, check if we have a better hard-coded one
            appName = AppNameMapper.getAppNameSync(packageName) != packageName
                ? AppNameMapper.getAppNameSync(packageName)
                : rawAppName;
          } else {
            // Try to get app name from our hybrid system
            appName = await AppNameMapper.getAppName(packageName);
          }

          items.add(
            AppUsage(
              packageName: packageName,
              appName: appName,
              minutesUsed: ((m['minutesUsed'] ?? 0) as num).toInt(),
              launchCount: ((m['launchCount'] ?? 0) as num).toInt(),
            ),
          );
        }
        return items;
      } on PlatformException catch (_) {
        // fall back to mock
      }
    }

    // Fallback: mock data for non-Android or other ranges
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final multiplier = switch (range) {
      TimeRange.today => 1,
      TimeRange.week => 5,
      TimeRange.month => 20,
    };
    return [
      AppUsage(
        packageName: 'com.social.app',
        appName: 'SocialX',
        minutesUsed: 35 * multiplier,
        launchCount: 6 * multiplier,
      ),
      AppUsage(
        packageName: 'com.video.app',
        appName: 'Streamly',
        minutesUsed: 82 * multiplier,
        launchCount: 3 * multiplier,
      ),
      AppUsage(
        packageName: 'com.productivity.app',
        appName: 'NotesPro',
        minutesUsed: 24 * multiplier,
        launchCount: 9 * multiplier,
      ),
    ];
  }

  Future<AppUsageDetail> fetchUsageDetail({
    required String packageName,
    required String appName,
    required TimeRange range,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    // Create fake daily data based on range
    final days = switch (range) {
      TimeRange.today => 1,
      TimeRange.week => 7,
      TimeRange.month => 30,
    };

    final now = DateTime.now();
    final List<DailyUsage> daily = List.generate(days, (i) {
      final d = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      final minutes = 10 + (i * 3) % 60;
      final launches = 1 + (i % 5);
      return DailyUsage(day: d, minutesUsed: minutes, launchCount: launches);
    }).reversed.toList();

    final totalMinutes = daily.fold<int>(0, (s, e) => s + e.minutesUsed);
    final totalLaunches = daily.fold<int>(0, (s, e) => s + e.launchCount);

    return AppUsageDetail(
      packageName: packageName,
      appName: appName,
      range: range,
      totalMinutes: totalMinutes,
      totalLaunches: totalLaunches,
      daily: daily,
    );
  }

  DateTime _startForRange(DateTime now, TimeRange range) {
    final todayStart = DateTime(now.year, now.month, now.day);
    return switch (range) {
      TimeRange.today => todayStart,
      TimeRange.week => todayStart.subtract(
        const Duration(days: 6),
      ), // last 7 days incl today
      TimeRange.month => todayStart.subtract(
        const Duration(days: 29),
      ), // last 30 days incl today
    };
  }

  Future<bool> _getIncludeSystemApps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('includeSystemApps') ?? false;
    } catch (_) {
      return false;
    }
  }
}
