import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_usage.dart';
import '../services/usage_access_permission.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _includeSystemApps = false;
  bool _enableNotifications = true;
  TimeRange _defaultRange = TimeRange.today;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('darkMode') ?? false;
      _includeSystemApps = prefs.getBool('includeSystemApps') ?? false;
      _enableNotifications = prefs.getBool('enableNotifications') ?? true;
      final r = prefs.getString('defaultRange');
      _defaultRange = switch (r) {
        'week' => TimeRange.week,
        'month' => TimeRange.month,
        _ => TimeRange.today,
      };
      _loading = false;
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _darkMode);
    await prefs.setBool('includeSystemApps', _includeSystemApps);
    await prefs.setBool('enableNotifications', _enableNotifications);
    final r = switch (_defaultRange) {
      TimeRange.today => 'today',
      TimeRange.week => 'week',
      TimeRange.month => 'month',
    };
    await prefs.setString('defaultRange', r);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            onPressed: () async {
              await _savePrefs();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings saved')),
              );
            },
            tooltip: 'Save',
            icon: const Icon(Icons.save_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: const Text('Dark mode'),
                  subtitle: const Text('Use dark theme (applies on next launch)'),
                  value: _darkMode,
                  onChanged: (v) => setState(() => _darkMode = v),
                ),
                ListTile(
                  title: const Text('Default time range'),
                  subtitle: const Text('Used when opening the app'),
                  trailing: DropdownButton<TimeRange>(
                    value: _defaultRange,
                    onChanged: (v) => setState(() => _defaultRange = v ?? TimeRange.today),
                    items: const [
                      DropdownMenuItem(value: TimeRange.today, child: Text('Today')),
                      DropdownMenuItem(value: TimeRange.week, child: Text('Week')),
                      DropdownMenuItem(value: TimeRange.month, child: Text('Month')),
                    ],
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Include system apps'),
                  subtitle: const Text('Show system packages in usage list'),
                  value: _includeSystemApps,
                  onChanged: (v) => setState(() => _includeSystemApps = v),
                ),
                SwitchListTile(
                  title: const Text('Enable notifications'),
                  subtitle: const Text('Daily summary at the end of day'),
                  value: _enableNotifications,
                  onChanged: (v) => setState(() => _enableNotifications = v),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Manage Usage Access'),
                  subtitle: const Text('Open system settings to grant usage access'),
                  onTap: () {
                    UsageAccessPermission.requestPermission();
                  },
                  trailing: const Icon(Icons.open_in_new),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  subtitle: const Text('App Usage Tracker • v1.0.0'),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}
