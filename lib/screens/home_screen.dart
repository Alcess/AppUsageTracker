import 'package:flutter/material.dart';
// settings screen removed from HomeScreen (no appbar actions required)
// import 'settings_screen.dart';
import '../services/app_usage_service.dart';
import '../models/app_usage.dart';
import '../utils/time_format.dart';
import '../services/usage_access_permission.dart';
import 'dart:math';

// Custom rounded circular progress painter used for the total ring
class _RingPainter extends CustomPainter {
  final double progress; // 0.0 - 1.0
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;

  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final fgPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -pi / 2; // start at top
    final sweepBg = 2 * pi;
    final sweepFg = (2 * pi) * progress.clamp(0.0, 1.0);

    canvas.drawArc(rect, startAngle, sweepBg, false, bgPaint);
    if (sweepFg > 0) canvas.drawArc(rect, startAngle, sweepFg, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

class _RoundedCircularProgress extends StatelessWidget {
  final double percent; // 0.0 - 1.0
  final double size;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;

  const _RoundedCircularProgress({
    Key? key,
    required this.percent,
    required this.size,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: percent,
          strokeWidth: strokeWidth,
          backgroundColor: backgroundColor,
          progressColor: progressColor,
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AppUsageService _service = AppUsageService();
  late Future<List<AppUsage>> _futureUsage;

  @override
  void initState() {
    super.initState();
    UsageAccessPermission.ensurePermission();
    _futureUsage = _service.fetchUsage(TimeRange.today);
  }

  void _reload() {
    setState(() {
      _futureUsage = _service.fetchUsage(TimeRange.today);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<AppUsage>>(
        future: _futureUsage,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: ${snapshot.error}'),
              ),
            );
          }
          final data = snapshot.data ?? const <AppUsage>[];

          final totalMinutes = data.fold<int>(
            0,
            (sum, e) => sum + e.minutesUsed,
          );

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24.0,
                      horizontal: 16.0,
                    ),
                    child: Column(
                      children: [
                        // Circular split showing used vs remaining of suggested daily limit
                        SizedBox(
                          height: 200,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // rounded ring (background + used portion)
                                    Builder(
                                      builder: (ctx) {
                                        const suggestedLimitHours = 8;
                                        final limitMinutes =
                                            suggestedLimitHours * 60;
                                        final percent = limitMinutes > 0
                                            ? totalMinutes / limitMinutes
                                            : 0.0;
                                        final pct = percent.clamp(0.0, 1.0);
                                        return _RoundedCircularProgress(
                                          percent: pct,
                                          size: 160,
                                          strokeWidth: 14,
                                          backgroundColor: Theme.of(
                                            ctx,
                                          ).colorScheme.surfaceVariant,
                                          progressColor: Theme.of(
                                            ctx,
                                          ).colorScheme.primary,
                                        );
                                      },
                                    ),
                                    // center content
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Today',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          formatTime(totalMinutes),
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 6),
                                        // small rounded divider (a "fractikon") between total and limit
                                        Container(
                                          width: 44,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.85),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        // suggested limit inside the circle
                                        Text(
                                          '8h',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                data.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: Text('No usage data for today')),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final item = data[index];
                          final percent = totalMinutes > 0
                              ? item.minutesUsed / totalMinutes
                              : 0.0;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              child: Text(
                                item.appName.substring(0, 1).toUpperCase(),
                              ),
                            ),
                            title: Text(item.appName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    height: 8,
                                    child: LinearProgressIndicator(
                                      value: percent,
                                      minHeight: 8,
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.surfaceVariant,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${(percent * 100).toStringAsFixed(1)}%',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    Text(
                                      formatTime(item.minutesUsed),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }, childCount: data.length),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}
