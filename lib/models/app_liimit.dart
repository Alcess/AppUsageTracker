import 'package:flutter/foundation.dart';

@immutable
class AppLimit {
  final List<String> packageNames;
  final String notificationName;
  final int minutesTracked; 
  final int minuteLimit;
  final TimeRange limitRefresh;

  const AppLimit({
    required this.packageNames,
    required this.notificationName,
    required this.minutesTracked,
    required this.minuteLimit,
    required this.limitRefresh,
  });
}

enum TimeRange { today, week, month }
enum LimitAction { notify, block }
