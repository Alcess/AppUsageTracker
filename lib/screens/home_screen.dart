import 'package:flutter/material.dart';
import '../services/app_usage_service.dart';
import '../models/app_usage.dart';
import 'app_detail_screen.dart';
import '../services/usage_access_permission.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AppUsageService _service = AppUsageService();

  late Future<List<AppUsage>> _futureUsage;
  TimeRange _selectedRange = TimeRange.today;

  @override
  void initState() {
    super.initState();
    // On Android, prompt user to grant Usage Access if missing (non-blocking)
    UsageAccessPermission.ensurePermission();
    _futureUsage = _service.fetchUsage(_selectedRange);
  }

  void _reload(TimeRange range) {
    setState(() {
      _selectedRange = range;
      _futureUsage = _service.fetchUsage(range);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Usage Tracker'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => _reload(_selectedRange),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _RangeSelector(
            selected: _selectedRange,
            onChanged: _reload,
          ),
          Expanded(
            child: FutureBuilder<List<AppUsage>>(
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
                if (data.isEmpty) {
                  return const Center(child: Text('No usage data'));
                }
                final totalMinutes = data.fold<int>(0, (sum, e) => sum + e.minutesUsed);
                return Column(
                  children: [
                    _SummaryCard(totalMinutes: totalMinutes),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.separated(
                        itemCount: data.length,
                        separatorBuilder: (context, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = data[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              child: Text(item.appName.substring(0, 1).toUpperCase()),
                            ),
                            title: Text(item.appName),
                            subtitle: Text('${item.minutesUsed} min • ${item.launchCount} launches'),
                            trailing: Text(_formatDuration(item.minutesUsed)),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AppDetailScreen(
                                    packageName: item.packageName,
                                    appName: item.appName,
                                    initialRange: _selectedRange,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _reload(_selectedRange),
        icon: const Icon(Icons.sync),
        label: const Text('Sync'),
      ),
    );
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final rem = minutes % 60;
    if (hours == 0) return '${rem}m';
    return '${hours}h ${rem}m';
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.totalMinutes});
  final int totalMinutes;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.timer, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              'Total: ${_format(totalMinutes)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  String _format(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({required this.selected, required this.onChanged});
  final TimeRange selected;
  final ValueChanged<TimeRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: SegmentedButton<TimeRange>(
        segments: const [
          ButtonSegment(value: TimeRange.today, label: Text('Today')),
          ButtonSegment(value: TimeRange.week, label: Text('Week')),
          ButtonSegment(value: TimeRange.month, label: Text('Month')),
        ],
        selected: {selected},
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
  }
}
