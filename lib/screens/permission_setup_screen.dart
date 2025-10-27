import 'package:flutter/material.dart';
import '../services/permission_handler_service.dart';

class PermissionSetupScreen extends StatefulWidget {
  const PermissionSetupScreen({super.key});

  @override
  State<PermissionSetupScreen> createState() => _PermissionSetupScreenState();
}

class _PermissionSetupScreenState extends State<PermissionSetupScreen> {
  bool _systemAlertWindow = false;
  bool _notificationPolicy = false;
  bool _usageAccess = false;
  bool _batteryOptimization = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _checking = true);

    // Individual checks for display purposes
    final systemAlert =
        await PermissionHandlerService.requestSystemAlertWindowPermission();
    final notificationPolicy =
        await PermissionHandlerService.requestAccessNotificationPolicyPermission();
    final usageAccess =
        await PermissionHandlerService.requestUsageAccessPermission();
    final batteryOptimization =
        await PermissionHandlerService.requestBatteryOptimizationExemption();

    setState(() {
      _systemAlertWindow = systemAlert;
      _notificationPolicy = notificationPolicy;
      _usageAccess = usageAccess;
      _batteryOptimization = batteryOptimization;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permission Setup'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.security, size: 64, color: Colors.orange),
              const SizedBox(height: 16),

              const Text(
                'Child Mode Permissions Required',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'To enable parental control features, please grant the following permissions:',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),

              const SizedBox(height: 24),

              if (_checking)
                const Center(child: CircularProgressIndicator())
              else ...[
                _buildPermissionTile(
                  'System Alert Window',
                  'Required for app blocking overlays',
                  Icons.block,
                  _systemAlertWindow,
                  () =>
                      PermissionHandlerService.requestSystemAlertWindowPermission(),
                ),

                const SizedBox(height: 12),

                _buildPermissionTile(
                  'Access Notification Policy',
                  'Required for notification management',
                  Icons.notifications,
                  _notificationPolicy,
                  () =>
                      PermissionHandlerService.requestAccessNotificationPolicyPermission(),
                ),

                const SizedBox(height: 12),

                _buildPermissionTile(
                  'Usage Access',
                  'Required for app usage monitoring',
                  Icons.analytics,
                  _usageAccess,
                  () => PermissionHandlerService.requestUsageAccessPermission(),
                ),

                const SizedBox(height: 12),

                _buildPermissionTile(
                  'Battery Optimization Exemption',
                  'Critical for Chinese phones (MIUI, Huawei, etc.)',
                  Icons.battery_saver,
                  _batteryOptimization,
                  () =>
                      PermissionHandlerService.requestBatteryOptimizationExemption(),
                ),

                const SizedBox(height: 16),

                // Additional Chinese phone settings
                Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.smartphone,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Chinese Phone Settings',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'For MIUI/Xiaomi, Huawei, OnePlus phones:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        const Text('• Enable Autostart for this app'),
                        const Text('• Disable battery optimization'),
                        const Text('• Allow background activity'),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                PermissionHandlerService.openAutoStartSettings(),
                            icon: const Icon(Icons.settings),
                            label: const Text('Open Autostart Settings'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _checkPermissions,
                      child: const Text('Refresh Status'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _allPermissionsGranted()
                          ? _completeSetup
                          : _requestAllPermissions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _allPermissionsGranted()
                            ? Colors.green
                            : Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        _allPermissionsGranted()
                            ? 'Complete Setup'
                            : 'Grant All',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (!_allPermissionsGranted())
                Text(
                  'Some features may not work without all permissions.',
                  style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionTile(
    String title,
    String description,
    IconData icon,
    bool granted,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: granted ? Colors.green : Colors.orange),
        title: Text(title),
        subtitle: Text(description),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              granted ? Icons.check_circle : Icons.warning,
              color: granted ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: granted ? null : onTap,
              child: Text(granted ? 'Granted' : 'Grant'),
            ),
          ],
        ),
      ),
    );
  }

  bool _allPermissionsGranted() {
    return _systemAlertWindow &&
        _notificationPolicy &&
        _usageAccess &&
        _batteryOptimization;
  }

  Future<void> _requestAllPermissions() async {
    await PermissionHandlerService.requestChildModePermissions();
    await _checkPermissions();
  }

  void _completeSetup() {
    Navigator.pop(context, true);
  }
}
