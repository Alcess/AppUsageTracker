import 'package:flutter/material.dart';
import '../services/app_limit_service.dart';
import '../models/app_limit.dart';

class ViewLimitsScreen extends StatefulWidget {
  const ViewLimitsScreen({super.key});

  @override
  State<ViewLimitsScreen> createState() => _ViewLimitsScreenState();
}

class _ViewLimitsScreenState extends State<ViewLimitsScreen> {
  final AppLimitService _limitService = AppLimitService();
  List<AppLimitStatus> _limitStatuses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLimitStatuses();
  }

  Future<void> _loadLimitStatuses() async {
    setState(() => _isLoading = true);

    try {
      final statuses = await _limitService.getAppLimitStatuses();
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
        _showError('Failed to load app limits: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _removeLimit(String packageName, String appName) async {
    final confirmed = await _showDeleteConfirmation(appName);
    if (!confirmed) return;

    try {
      await _limitService.removeAppLimit(packageName);
      await _loadLimitStatuses();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Removed limit for $appName')));
      }
    } catch (e) {
      _showError('Failed to remove limit: $e');
    }
  }

  Future<bool> _showDeleteConfirmation(String appName) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Limit'),
        content: Text('Remove the usage limit for $appName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _editLimit(AppLimitStatus status) async {
    final controller = TextEditingController(
      text: status.limit.limitMinutes.toString(),
    );

    final newLimit = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${status.limit.appName} Limit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current usage today: ${AppLimitService.formatMinutes(status.currentUsageMinutes)}',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Limit (minutes)',
                suffixText: 'min',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final minutes = int.tryParse(controller.text);
              if (minutes != null && minutes > 0) {
                Navigator.of(context).pop(minutes);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newLimit != null) {
      try {
        final updatedLimit = status.limit.copyWith(limitMinutes: newLimit);
        await _limitService.updateAppLimit(updatedLimit);
        await _loadLimitStatuses();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Updated ${status.limit.appName} limit')),
          );
        }
      } catch (e) {
        _showError('Failed to update limit: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Limits'),
        actions: [
          IconButton(
            onPressed: _loadLimitStatuses,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_limitStatuses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timer_off,
              size: 80,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No App Limits',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You haven\'t set any app usage limits yet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    // Sort by usage percentage (highest first)
    final sortedStatuses = List<AppLimitStatus>.from(_limitStatuses)
      ..sort((a, b) => b.usagePercentage.compareTo(a.usagePercentage));

    return RefreshIndicator(
      onRefresh: _loadLimitStatuses,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedStatuses.length,
        itemBuilder: (context, index) {
          final status = sortedStatuses[index];
          return _buildLimitCard(status);
        },
      ),
    );
  }

  Widget _buildLimitCard(AppLimitStatus status) {
    final isExceeded = status.isOverLimit;
    final isNearLimit = status.usagePercentage >= 0.8;

    Color statusColor = Colors.green;
    if (isExceeded) {
      statusColor = Colors.red;
    } else if (isNearLimit) {
      statusColor = Colors.orange;
    }

    IconData statusIcon = Icons.check_circle;
    if (isExceeded) {
      statusIcon = Icons.warning;
    } else if (isNearLimit) {
      statusIcon = Icons.timer;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.2),
                  radius: 20,
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.limit.appName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Limit: ${AppLimitService.formatMinutes(status.limit.limitMinutes)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editLimit(status);
                    } else if (value == 'delete') {
                      _removeLimit(
                        status.limit.packageName,
                        status.limit.appName,
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit Limit'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Remove Limit'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Usage info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today: ${AppLimitService.formatMinutes(status.currentUsageMinutes)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  isExceeded
                      ? 'Over by ${AppLimitService.formatMinutes(status.currentUsageMinutes - status.limit.limitMinutes)}'
                      : '${AppLimitService.formatMinutes(status.remainingMinutes)} left',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Progress bar
            LinearProgressIndicator(
              value: status.usagePercentage.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),

            const SizedBox(height: 4),

            // Percentage
            Text(
              '${(status.usagePercentage * 100).round()}% of limit used',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
