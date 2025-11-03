import 'package:flutter/material.dart';
import '../services/command_service.dart';
import '../services/role_service.dart';
import '../services/family_link_service.dart';

class CommandScreen extends StatefulWidget {
  const CommandScreen({super.key});

  @override
  State<CommandScreen> createState() => _CommandScreenState();
}

class _CommandScreenState extends State<CommandScreen> {
  bool _canSendCommands = false;
  bool _loading = true;
  bool _isDeviceLocked = false;

  @override
  void initState() {
    super.initState();
    _checkCommandCapability();
  }

  Future<void> _checkCommandCapability() async {
    final role = await RoleService.getRole();
    final isLinked = await FamilyLinkService.isLinked();
    final childToken = await FamilyLinkService.getChildFCMToken();

    // Debug info
    debugPrint('Role: $role');
    debugPrint('Is linked: $isLinked');
    debugPrint('Child FCM token available: ${childToken != null}');
    if (childToken != null) {
      debugPrint('Child FCM token: ${childToken.substring(0, 20)}...');
    }

    setState(() {
      _canSendCommands =
          role == AppRole.parent && isLinked && childToken != null;
      _loading = false;
    });
  }

  Future<String> _getDiagnosticMessage() async {
    final role = await RoleService.getRole();
    final isLinked = await FamilyLinkService.isLinked();
    final childToken = await FamilyLinkService.getChildFCMToken();
    final linkCode = await FamilyLinkService.getLinkCode();

    if (role != AppRole.parent) {
      return 'Switch to Parent mode in Settings to control child devices.';
    }

    if (linkCode == null) {
      return 'No link code found. Link to a child device in Settings first.';
    }

    if (!isLinked) {
      return 'Link code exists but not connected. Make sure the child device completed the linking process.';
    }

    if (childToken == null) {
      return 'Connected to child device but FCM token is missing. Child device may need to restart the app or refresh its connection.\n\n🔧 Go to Settings → Repair Connection to fix connection issues automatically.';
    }

    return 'Unknown connection issue. Try relinking in Settings.';
  }

  Future<void> _refreshConnection() async {
    setState(() {
      _loading = true;
    });

    // Try to update FCM tokens
    await FamilyLinkService.updateParentFCMToken();

    // Recheck capabilities
    await _checkCommandCapability();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_canSendCommands) {
      return Scaffold(
        appBar: AppBar(title: const Text('Device Control')),
        body: FutureBuilder<String>(
          future: _getDiagnosticMessage(),
          builder: (context, snapshot) {
            final message = snapshot.data ?? 'Checking connection...';
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.link_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Not connected to child device',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/settings'),
                        child: Text('Go to Settings'),
                      ),
                      SizedBox(width: 16),
                      OutlinedButton(
                        onPressed: _refreshConnection,
                        child: Text('Refresh'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Control'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Device Lock Control',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Device lock/unlock card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.security, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Device Control',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Device lock/unlock button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _toggleDeviceLock,
                        icon: Icon(
                          _isDeviceLocked ? Icons.lock_open : Icons.lock,
                          color: Colors.white,
                        ),
                        label: Text(
                          _isDeviceLocked ? 'Unlock Device' : 'Lock Device',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isDeviceLocked
                              ? Colors.green
                              : Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),

                    if (_isDeviceLocked) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Child device is currently locked',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    const Text(
                      'When locked, the child device will show a black screen with the message "This device is locked by your parent" over all apps and activities.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleDeviceLock() async {
    try {
      bool success;
      if (_isDeviceLocked) {
        // Unlock the device
        success = await CommandService.unlockDevice();
        if (success) {
          setState(() {
            _isDeviceLocked = false;
          });
          _showMessage('Device unlocked');
        } else {
          _showMessage('Failed to unlock device');
        }
      } else {
        // Lock the device
        success = await CommandService.lockDevice();
        if (success) {
          setState(() {
            _isDeviceLocked = true;
          });
          _showMessage('Device locked');
        } else {
          _showMessage('Failed to lock device');
        }
      }
    } catch (e) {
      _showMessage(
        'Failed to ${_isDeviceLocked ? 'unlock' : 'lock'} device: $e',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
