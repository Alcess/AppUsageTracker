import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/overlay_service.dart';
import '../services/fcm_service.dart';
import '../services/family_link_service.dart';
import '../services/simple_screen_lock_service.dart';
import '../services/simple_overlay_service.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  bool _hasOverlayPermission = false;
  String? _fcmToken;
  bool _isLinked = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final hasOverlay = await OverlayService.hasOverlayPermission();
    final fcmToken = await FCMService.getFCMToken();
    final isLinked = await FamilyLinkService.isLinked();

    setState(() {
      _hasOverlayPermission = hasOverlay;
      _fcmToken = fcmToken;
      _isLinked = isLinked;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug Lock Command')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lock Command Debug',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),

            // Overlay Permission
            Card(
              child: ListTile(
                leading: Icon(
                  _hasOverlayPermission ? Icons.check_circle : Icons.error,
                  color: _hasOverlayPermission ? Colors.green : Colors.red,
                ),
                title: const Text('Overlay Permission'),
                subtitle: Text(
                  _hasOverlayPermission ? 'Granted' : 'Not granted',
                ),
                trailing: _hasOverlayPermission
                    ? null
                    : ElevatedButton(
                        onPressed: () async {
                          await OverlayService.requestOverlayPermission();
                          _checkStatus();
                        },
                        child: const Text('Grant'),
                      ),
              ),
            ),

            // FCM Token
            Card(
              child: ListTile(
                leading: Icon(
                  _fcmToken != null ? Icons.check_circle : Icons.error,
                  color: _fcmToken != null ? Colors.green : Colors.red,
                ),
                title: const Text('FCM Token'),
                subtitle: Text(_fcmToken != null ? 'Available' : 'Missing'),
              ),
            ),

            // Device Linking
            Card(
              child: ListTile(
                leading: Icon(
                  _isLinked ? Icons.check_circle : Icons.error,
                  color: _isLinked ? Colors.green : Colors.red,
                ),
                title: const Text('Device Linking'),
                subtitle: Text(_isLinked ? 'Linked' : 'Not linked'),
              ),
            ),

            const SizedBox(height: 20),

            // Test Buttons
            ElevatedButton(
              onPressed: () {
                try {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Showing simple overlay (in-app)...'),
                    ),
                  );

                  SimpleOverlayService.showSimpleOverlay(context, 'Test App');
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Simple overlay error: $e')),
                  );
                }
              },
              child: const Text('Test Simple Overlay (In-App)'),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () async {
                try {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Testing system overlay (works over other apps)...',
                      ),
                    ),
                  );

                  final success = await SimpleOverlayService.showSystemOverlay(
                    'TikTok',
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'System overlay shown! Switch to another app to test.'
                            : 'System overlay failed - check overlay permission',
                      ),
                      backgroundColor: success ? Colors.green : Colors.orange,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('System overlay error: $e')),
                  );
                }
              },
              child: const Text('Test System Overlay (Over Other Apps)'),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () async {
                try {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Testing simple screen lock...'),
                    ),
                  );

                  final success = await SimpleScreenLockService.lockScreen();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Screen lock command sent successfully!'
                            : 'Screen lock failed - may need device admin permission',
                      ),
                      backgroundColor: success ? Colors.green : Colors.orange,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Screen lock error: $e')),
                  );
                }
              },
              child: const Text('Test Screen Lock'),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () async {
                try {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Testing blocking notification...'),
                    ),
                  );

                  await SimpleScreenLockService.showBlockingNotification(
                    'Test App',
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Blocking notification sent!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Notification error: $e')),
                  );
                }
              },
              child: const Text('Test Block Notification'),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () async {
                try {
                  await SimpleScreenLockService.requestDeviceAdmin();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Device admin request sent')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Device admin error: $e')),
                  );
                }
              },
              child: const Text('Request Device Admin'),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () async {
                if (SimpleOverlayService.isShowing) {
                  SimpleOverlayService.hideOverlay();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('In-app overlay hidden')),
                  );
                } else {
                  await SimpleOverlayService.hideSystemOverlay();
                  OverlayService.hideOverlay();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All overlays hidden')),
                  );
                }
              },
              child: const Text('Hide All Overlays'),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: _checkStatus,
              child: const Text('Refresh Status'),
            ),

            const SizedBox(height: 20),

            // Debug Info
            if (_fcmToken != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FCM Token:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      SelectableText(
                        _fcmToken!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
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
}
