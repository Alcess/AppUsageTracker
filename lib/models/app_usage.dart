import 'package:flutter/foundation.dart';

/// Represents usage of a single app within a time range.
@immutable
class AppUsage {
  final String packageName;
  final String appName;
  final int minutesUsed; // total foreground minutes
  final int launchCount; // number of times app launched

  const AppUsage({
    required this.packageName,
    required this.appName,
    required this.minutesUsed,
    required this.launchCount,
  });
}

/// Time ranges supported by the UI.
enum TimeRange { today, week, month }
