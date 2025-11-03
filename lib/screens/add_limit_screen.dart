import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import '../services/app_limit_service.dart';
import '../services/app_usage_service.dart';
import '../models/app_limit.dart';
import '../models/app_usage.dart';

class AddLimitScreen extends StatefulWidget {
  const AddLimitScreen({super.key});

  @override
  State<AddLimitScreen> createState() => _AddLimitScreenState();
}

class _AddLimitScreenState extends State<AddLimitScreen> {
  final AppLimitService _limitService = AppLimitService();
  final AppUsageService _usageService = AppUsageService();
  final TextEditingController _limitController = TextEditingController();

  List<AppUsage> _availableApps = [];
  List<String> _existingLimitPackages = [];
  AppUsage? _selectedApp;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableApps();
  }

  Future<void> _loadAvailableApps() async {
    setState(() => _isLoading = true);

    try {
      // Load today's usage as primary source
      final todayUsage = await _usageService.fetchUsage(TimeRange.today);

      // Load existing limits to filter them out
      final existingLimits = await _limitService.getAppLimits();
      final existingPackages = existingLimits.map((l) => l.packageName).toSet();

      // Start with today's usage and try to get additional apps
      final availableApps = <AppUsage>[];
      final usedPackages = <String>{};

      // Add apps from today's usage that don't have limits
      for (final app in todayUsage) {
        if (!existingPackages.contains(app.packageName)) {
          availableApps.add(app);
          usedPackages.add(app.packageName);
        }
      }

      // Try to get additional installed apps (with timeout)
      try {
        final installedApps = await InstalledApps.getInstalledApps(
          true,
          true,
        ).timeout(const Duration(seconds: 10));

        // Add apps that weren't in today's usage
        for (final app in installedApps) {
          if (!existingPackages.contains(app.packageName) &&
              !usedPackages.contains(app.packageName)) {
            final appName = app.name.isNotEmpty ? app.name : app.packageName;

            availableApps.add(
              AppUsage(
                packageName: app.packageName,
                appName: appName,
                minutesUsed: 0, // Not used today
                launchCount: 0,
              ),
            );
          }
        }
      } catch (e) {
        // If getting installed apps fails, continue with just today's usage
        debugPrint('Failed to get installed apps: $e');
      }

      // Sort by name for better user experience
      availableApps.sort((a, b) => a.appName.compareTo(b.appName));

      if (mounted) {
        setState(() {
          _availableApps = availableApps;
          _existingLimitPackages = existingPackages.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to load apps: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveLimit() async {
    if (_selectedApp == null) {
      _showError('Please select an app');
      return;
    }

    final limitText = _limitController.text.trim();
    if (limitText.isEmpty) {
      _showError('Please enter a time limit');
      return;
    }

    final limitMinutes = int.tryParse(limitText);
    if (limitMinutes == null || limitMinutes <= 0) {
      _showError('Please enter a valid number of minutes');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final appLimit = AppLimit(
        packageName: _selectedApp!.packageName,
        appName: _selectedApp!.appName,
        limitMinutes: limitMinutes,
        createdAt: DateTime.now(),
      );

      await _limitService.addAppLimit(appLimit);

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added ${limitMinutes}min limit for ${_selectedApp!.appName}',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showError('Failed to save limit: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add App Limit'),
        actions: [
          if (_selectedApp != null && _limitController.text.isNotEmpty)
            TextButton(
              onPressed: _isSaving ? null : _saveLimit,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_availableApps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.apps,
              size: 80,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No Apps Available',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _existingLimitPackages.isNotEmpty
                  ? 'All your apps already have limits set.'
                  : 'No apps available. Try using some apps first.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // App selection
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select App',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose an app to set a daily usage limit:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ),

        // App list
        Expanded(
          child: ListView.builder(
            itemCount: _availableApps.length,
            itemBuilder: (context, index) {
              final app = _availableApps[index];
              final isSelected = _selectedApp?.packageName == app.packageName;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    app.appName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(app.appName),
                subtitle: Text(
                  app.minutesUsed > 0
                      ? 'Used ${app.minutesUsed}min today'
                      : 'Not used today',
                ),
                trailing: isSelected
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                selected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedApp = app;
                  });
                },
              );
            },
          ),
        ),

        // Limit input section
        if (_selectedApp != null) ...[
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      radius: 16,
                      child: Text(
                        _selectedApp!.appName.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Set limit for ${_selectedApp!.appName}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _limitController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Daily limit (minutes)',
                    suffixText: 'min',
                    border: const OutlineInputBorder(),
                    helperText:
                        'You\'ll get notified when this limit is reached',
                  ),
                  onChanged: (value) {
                    setState(() {}); // Rebuild to show/hide save button
                  },
                ),

                const SizedBox(height: 16),

                // Quick suggestions
                Text(
                  'Quick suggestions:',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [30, 60, 120, 180, 300].map((minutes) {
                    return FilterChip(
                      label: Text('${minutes}min'),
                      selected: _limitController.text == minutes.toString(),
                      onSelected: (selected) {
                        if (selected) {
                          _limitController.text = minutes.toString();
                          setState(() {});
                        }
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Current usage info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedApp!.minutesUsed > 0
                            ? 'Current usage today: ${_selectedApp!.minutesUsed} minutes'
                            : 'Not used today - set a limit for future tracking',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }
}
