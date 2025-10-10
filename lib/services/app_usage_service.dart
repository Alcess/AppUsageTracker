import 'dart:async';
import '../models/app_usage.dart';
import '../models/app_usage_detail.dart';

/// A mock service that returns fake app usage data.
/// Replace with a platform-specific implementation later.
class AppUsageService {
  Future<List<AppUsage>> fetchUsage(TimeRange range) async {
    // Simulate network/compute delay
    await Future<void>.delayed(const Duration(milliseconds: 400));

    // Generate some mock data that varies by range
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
      final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
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
}
