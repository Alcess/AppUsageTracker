import 'package:flutter/foundation.dart';

/// Represents usage of a single app within a time range.
@immutable
class AppLimit {
  final List<String> packageNames;
  final String notificationName;
  final int minutesTracked; // total foreground minutes
  final int minuteLimit; // default limit for notifications
  final TimeRange limitRefresh;

  const AppLimit({
    required this.packageNames,
    required this.notificationName,
    required this.minutesTracked,
    required this.minuteLimit,
    required this.limitRefresh,
  });
}

/// Time ranges supported by the UI.
enum TimeRange { today, week, month }
enum LimitAction { notify, block }
