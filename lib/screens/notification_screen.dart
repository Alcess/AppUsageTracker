import 'package:flutter/material.dart';
import '../services/app_limit_service.dart';
import '../models/app_limit.dart';
import 'view_limits_screen.dart';
import 'add_limit_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final AppLimitService _limitService = AppLimitService();
  List<AppLimitStatus> _limitStatuses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLimitStatuses();
  }

  Future<void> _loadLimitStatuses() async {
    try {
      final statuses = await _limitService.getAppLimitStatuses();

      // Also check for notifications when loading
      await _limitService.checkLimitsAndNotify();

      if (mounted) {
        setState(() {
          _limitStatuses = statuses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToViewLimits() async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ViewLimitsScreen()));

    // Refresh if returning from view limits screen
    if (result == true) {
      _loadLimitStatuses();
    }
  }

  void _navigateToAddLimit() async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AddLimitScreen()));

    // Refresh if new limit was added
    if (result == true) {
      _loadLimitStatuses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        automaticallyImplyLeading: false,
        actions: [
          // Test Notifications Button
          Tooltip(
            message: 'Check Limits Now',
            child: IconButton(
              onPressed: () async {
                await _limitService.triggerNotificationCheck();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Checked for limit violations')),
                );
              },
              icon: const Icon(Icons.notification_add, size: 18),
            ),
          ),
          // View Limits Button
          Tooltip(
            message: 'View App Limits',
            child: TextButton.icon(
              onPressed: _navigateToViewLimits,
              icon: const Icon(Icons.list_alt, size: 18),
              label: const Text('View'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Add Limit Button
          Tooltip(
            message: 'Add App Limit',
            child: TextButton.icon(
              onPressed: _navigateToAddLimit,
              icon: const Icon(Icons.add_alarm, size: 18),
              label: const Text('Add'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_limitStatuses.isEmpty) {
      return _buildEmptyState();
    }

    final exceededLimits = _limitStatuses.where((s) => s.isOverLimit).toList();
    final approachingLimits = _limitStatuses
        .where((s) => !s.isOverLimit && s.usagePercentage >= 0.8)
        .toList();

    return RefreshIndicator(
      onRefresh: _loadLimitStatuses,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (exceededLimits.isNotEmpty) ...[
            _buildSectionHeader(
              'Limits Exceeded',
              Icons.warning,
              Colors.red,
              exceededLimits.length,
            ),
            const SizedBox(height: 8),
            ...exceededLimits.map((status) => _buildLimitCard(status, true)),
            const SizedBox(height: 24),
          ],

          if (approachingLimits.isNotEmpty) ...[
            _buildSectionHeader(
              'Approaching Limits',
              Icons.timer,
              Colors.orange,
              approachingLimits.length,
            ),
            const SizedBox(height: 8),
            ...approachingLimits.map(
              (status) => _buildLimitCard(status, false),
            ),
            const SizedBox(height: 24),
          ],

          if (exceededLimits.isEmpty && approachingLimits.isEmpty) ...[
            _buildNoAlertsCard(),
          ],

          // Summary card
          _buildSummaryCard(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No App Limits Set',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add time limits for apps to receive notifications\nwhen you exceed your usage goals.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToAddLimit,
            icon: const Icon(Icons.add_alarm),
            label: const Text('Add Your First Limit'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    Color color,
    int count,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLimitCard(AppLimitStatus status, bool isExceeded) {
    final color = isExceeded ? Colors.red : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(
            isExceeded ? Icons.warning : Icons.timer,
            color: color,
            size: 20,
          ),
        ),
        title: Text(status.limit.appName),
        subtitle: Text(
          isExceeded
              ? 'Exceeded by ${AppLimitService.formatMinutes(status.currentUsageMinutes - status.limit.limitMinutes)}'
              : '${AppLimitService.formatMinutes(status.remainingMinutes)} remaining',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${AppLimitService.formatMinutes(status.currentUsageMinutes)} / ${AppLimitService.formatMinutes(status.limit.limitMinutes)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 60,
              child: LinearProgressIndicator(
                value: status.usagePercentage,
                backgroundColor: Colors.grey.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAlertsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 12),
            Text(
              'All Good!',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'re within all your app usage limits.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalLimits = _limitStatuses.length;
    final exceededCount = _limitStatuses.where((s) => s.isOverLimit).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('Total Limits:'), Text(totalLimits.toString())],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Exceeded:'),
                Text(
                  exceededCount.toString(),
                  style: TextStyle(
                    color: exceededCount > 0 ? Colors.red : null,
                    fontWeight: exceededCount > 0 ? FontWeight.bold : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Within Limits:'),
                Text(
                  (totalLimits - exceededCount).toString(),
                  style: TextStyle(
                    color: (totalLimits - exceededCount) > 0
                        ? Colors.green
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
