import 'package:flutter/foundation.dart';
import 'app_usage.dart';

@immutable
class DailyUsage {
  final DateTime day; // start of day
  final int minutesUsed;
  final int launchCount;

  const DailyUsage({
    required this.day,
    required this.minutesUsed,
    required this.launchCount,
  });
}

@immutable
class AppUsageDetail {
  final String packageName;
  final String appName;
  final TimeRange range;
  final int totalMinutes;
  final int totalLaunches;
  final List<DailyUsage> daily;

  const AppUsageDetail({
    required this.packageName,
    required this.appName,
    required this.range,
    required this.totalMinutes,
    required this.totalLaunches,
    required this.daily,
  });
}
