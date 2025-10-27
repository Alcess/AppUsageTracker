import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_usage.dart';
import '../services/usage_access_permission.dart';
import '../services/role_service.dart';
import '../services/family_link_service.dart';
import '../services/overlay_service.dart';
import '../services/fcm_service.dart';
import '../services/child_usage_tracking_service.dart';
import '../services/theme_service.dart';
import 'child_usage_view_screen.dart';
import 'permission_setup_screen.dart';
import 'debug_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _includeSystemApps = false;
  bool _enableNotifications = true;
  bool _isChildMode = false;
  bool _isLinked = false;
  String? _linkCode;
  TimeRange _defaultRange = TimeRange.today;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loading) {
      _loadPrefs(); // Refresh data when screen comes into focus
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final currentRole = await RoleService.getRole();
    final isLinked = await FamilyLinkService.isLinked();
    final linkCode = await FamilyLinkService.getLinkCode();
    setState(() {
      _darkMode = ThemeService().isDarkMode; // Load from theme service
      _includeSystemApps = prefs.getBool('includeSystemApps') ?? false;
      _enableNotifications = prefs.getBool('enableNotifications') ?? true;
      _isChildMode = currentRole == AppRole.child;
      _isLinked = isLinked;
      _linkCode = linkCode;
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
    // Dark mode is now handled by ThemeService, no need to save it here
    await prefs.setBool('includeSystemApps', _includeSystemApps);
    await prefs.setBool('enableNotifications', _enableNotifications);
    final r = switch (_defaultRange) {
      TimeRange.today => 'today',
      TimeRange.week => 'week',
      TimeRange.month => 'month',
    };
    await prefs.setString('defaultRange', r);
  }

  Future<void> _generateChildCode() async {
    try {
      final code = await FamilyLinkService.createChildLink();
      setState(() {
        _linkCode = code;
      });
      if (!mounted) return;
      _showCodeDialog(code);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating code: $e')));
    }
  }

  Future<void> _showParentLinkDialog() async {
    final codeController = TextEditingController();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Link to Child'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter the 6-digit code from the child device:'),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Code',
                  border: OutlineInputBorder(),
                ),
                maxLength: 6,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final code = codeController.text.trim();
                if (code.length == 6) {
                  Navigator.of(context).pop();
                  await _linkToChild(code);
                }
              },
              child: const Text('Link'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _linkToChild(String code) async {
    try {
      final success = await FamilyLinkService.linkToChild(code);
      if (success) {
        setState(() {
          _isLinked = true;
          _linkCode = code;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully linked to child device!')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to link. Please check the code.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error linking: $e')));
    }
  }

  void _showCodeDialog(String code) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Child Code Generated'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Share this code with the parent:'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  code,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _unlink() async {
    try {
      await FamilyLinkService.unlink();
      setState(() {
        _isLinked = false;
        _linkCode = null;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Devices unlinked successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error unlinking: $e')));
    }
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
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Settings saved')));
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
                  subtitle: const Text(
                    'Use dark theme (changes immediately)',
                  ),
                  value: _darkMode,
                  onChanged: (v) async {
                    setState(() => _darkMode = v);
                    await ThemeService().setDarkMode(v);
                  },
                ),
                SwitchListTile(
                  title: const Text('Child Mode'),
                  value: _isChildMode,
                  onChanged: (value) async {
                    if (value) {
                      // Show permission setup screen when enabling child mode
                      final permissionGranted = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PermissionSetupScreen(),
                        ),
                      );

                      if (permissionGranted != true) {
                        // User didn't complete permission setup, don't enable child mode
                        return;
                      }
                    }

                    setState(() => _isChildMode = value);
                    await RoleService.setRole(
                      value ? AppRole.child : AppRole.parent,
                    );

                    // Start/stop FCM command listening and usage tracking based on role
                    if (value) {
                      await FCMService.startListeningForCommands();
                      await ChildUsageTrackingService.startChildModeTracking();
                    } else {
                      FCMService.stopListeningForCommands();
                      ChildUsageTrackingService.stopChildModeTracking();
                    }
                  },
                ),
                const Divider(height: 1),
                if (_isChildMode) ...[
                  ListTile(
                    leading: const Icon(Icons.link),
                    title: Text(
                      _isLinked ? 'Linked to Parent' : 'Generate Link Code',
                    ),
                    subtitle: _isLinked
                        ? Text('Code: ${_linkCode ?? 'Unknown'}')
                        : const Text('Create a code for parent to enter'),
                    trailing: _isLinked
                        ? IconButton(
                            icon: const Icon(Icons.link_off),
                            onPressed: _unlink,
                            tooltip: 'Unlink',
                          )
                        : const Icon(Icons.arrow_forward_ios),
                    onTap: _isLinked ? null : _generateChildCode,
                  ),
                  // Manual sync button for child mode
                  if (_isLinked)
                    ListTile(
                      leading: const Icon(
                        Icons.cloud_upload,
                        color: Colors.blue,
                      ),
                      title: const Text('Sync Usage Data'),
                      subtitle: const Text('Send latest app usage to parent'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: _syncUsageData,
                    ),
                ] else ...[
                  ListTile(
                    leading: const Icon(Icons.family_restroom),
                    title: Text(
                      _isLinked ? 'Linked to Child' : 'Link to Child',
                    ),
                    subtitle: _isLinked
                        ? Text('Code: ${_linkCode ?? 'Unknown'}')
                        : const Text('Enter child code to connect'),
                    trailing: _isLinked
                        ? IconButton(
                            icon: const Icon(Icons.link_off),
                            onPressed: _unlink,
                            tooltip: 'Unlink',
                          )
                        : const Icon(Icons.arrow_forward_ios),
                    onTap: _isLinked ? null : _showParentLinkDialog,
                  ),
                  // View child usage button for linked parents
                  if (_isLinked)
                    ListTile(
                      leading: const Icon(Icons.analytics, color: Colors.green),
                      title: const Text('View Child Usage'),
                      subtitle: const Text('See your child\'s app usage data'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: _openChildUsageView,
                    ),
                ],
                ListTile(
                  title: const Text('Default time range'),
                  subtitle: const Text('Used when opening the app'),
                  trailing: DropdownButton<TimeRange>(
                    value: _defaultRange,
                    onChanged: (v) =>
                        setState(() => _defaultRange = v ?? TimeRange.today),
                    items: const [
                      DropdownMenuItem(
                        value: TimeRange.today,
                        child: Text('Today'),
                      ),
                      DropdownMenuItem(
                        value: TimeRange.week,
                        child: Text('Week'),
                      ),
                      DropdownMenuItem(
                        value: TimeRange.month,
                        child: Text('Month'),
                      ),
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
                  subtitle: const Text(
                    'Open system settings to grant usage access',
                  ),
                  onTap: () {
                    UsageAccessPermission.requestPermission();
                  },
                  trailing: const Icon(Icons.open_in_new),
                ),
                if (_isChildMode) ...[
                  ListTile(
                    leading: const Icon(Icons.security),
                    title: const Text('Overlay Permission'),
                    subtitle: const Text(
                      'Required for app locking functionality',
                    ),
                    onTap: () async {
                      final hasPermission =
                          await OverlayService.hasOverlayPermission();
                      if (!hasPermission) {
                        await OverlayService.requestOverlayPermission();
                      } else {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Overlay permission already granted'),
                          ),
                        );
                      }
                    },
                    trailing: const Icon(Icons.open_in_new),
                  ),
                ],
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  subtitle: const Text('App Usage Tracker • v1.0.0'),
                ),
                ListTile(
                  leading: const Icon(Icons.bug_report, color: Colors.orange),
                  title: const Text('Debug Lock Command'),
                  subtitle: const Text('Troubleshoot lock command issues'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DebugScreen(),
                      ),
                    );
                  },
                  trailing: const Icon(Icons.arrow_forward_ios),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  void _openChildUsageView() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChildUsageViewScreen()),
    );
  }

  Future<void> _syncUsageData() async {
    try {
      await ChildUsageTrackingService.forceSyncUsage();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usage data synced successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to sync usage data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
