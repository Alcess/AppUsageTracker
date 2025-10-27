import 'package:flutter/material.dart';

/// Custom overlay widget for app locking
class AppLockOverlay extends StatelessWidget {
  final String appName;
  final String appPackage;

  const AppLockOverlay({
    super.key,
    required this.appName,
    required this.appPackage,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black87,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.red.shade800, Colors.red.shade900],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lock Icon
            const Icon(Icons.lock, size: 80, color: Colors.white),
            const SizedBox(height: 32),

            // App Locked Title
            const Text(
              'App Locked',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // App Name
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                appName,
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Message
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'This app is locked by your parent.\nPlease use other apps or ask for permission.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Close Button
            ElevatedButton.icon(
              onPressed: () {
                // This would close the overlay and return to home screen
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.home),
              label: const Text('Go to Home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red.shade800,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Package name for debugging
            if (appPackage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Package: $appPackage',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
