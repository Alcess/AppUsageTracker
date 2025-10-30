import 'package:flutter/foundation.dart';

/// Represents a usage limit set for a specific app with notification settings
@immutable
class AppLimit {
  final String packageName;
  final String appName;
  final int limitMinutes; // Usage limit in minutes
  final bool isEnabled; // Whether the limit is active
  final DateTime createdAt;
  final DateTime? lastNotified; // When the user was last notified

  const AppLimit({
    required this.packageName,
    required this.appName,
    required this.limitMinutes,
    this.isEnabled = true,
    required this.createdAt,
    this.lastNotified,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'packageName': packageName,
    'appName': appName,
    'limitMinutes': limitMinutes,
    'isEnabled': isEnabled,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'lastNotified': lastNotified?.millisecondsSinceEpoch,
  };

  /// Create from JSON
  factory AppLimit.fromJson(Map<String, dynamic> json) => AppLimit(
    packageName: json['packageName'] as String,
    appName: json['appName'] as String,
    limitMinutes: json['limitMinutes'] as int,
    isEnabled: json['isEnabled'] as bool? ?? true,
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
    lastNotified: json['lastNotified'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['lastNotified'] as int)
        : null,
  );

  /// Create a copy with updated values
  AppLimit copyWith({
    String? packageName,
    String? appName,
    int? limitMinutes,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? lastNotified,
  }) => AppLimit(
    packageName: packageName ?? this.packageName,
    appName: appName ?? this.appName,
    limitMinutes: limitMinutes ?? this.limitMinutes,
    isEnabled: isEnabled ?? this.isEnabled,
    createdAt: createdAt ?? this.createdAt,
    lastNotified: lastNotified ?? this.lastNotified,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppLimit &&
          runtimeType == other.runtimeType &&
          packageName == other.packageName;

  @override
  int get hashCode => packageName.hashCode;

  @override
  String toString() => 'AppLimit($appName: ${limitMinutes}min)';
}

/// Status of an app regarding its usage limit
class AppLimitStatus {
  final AppLimit limit;
  final int currentUsageMinutes;
  final bool isOverLimit;
  final int remainingMinutes;
  final double usagePercentage;

  const AppLimitStatus({
    required this.limit,
    required this.currentUsageMinutes,
    required this.isOverLimit,
    required this.remainingMinutes,
    required this.usagePercentage,
  });

  factory AppLimitStatus.fromUsage(AppLimit limit, int usageMinutes) {
    final isOver = usageMinutes >= limit.limitMinutes;
    final remaining = (limit.limitMinutes - usageMinutes).clamp(
      0,
      limit.limitMinutes,
    );
    final percentage = (usageMinutes / limit.limitMinutes).clamp(0.0, 1.0);

    return AppLimitStatus(
      limit: limit,
      currentUsageMinutes: usageMinutes,
      isOverLimit: isOver,
      remainingMinutes: remaining,
      usagePercentage: percentage,
    );
  }
}
