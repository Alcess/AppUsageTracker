import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SimpleOverlayService {
  static OverlayEntry? _overlayEntry;
  static bool _isShowing = false;
  static const _systemOverlayChannel = MethodChannel(
    'app_usage_tracker/system_overlay',
  );

  /// Show a simple Flutter overlay (works within the app only)
  static void showSimpleOverlay(BuildContext context, String appName) {
    if (_isShowing) return;

    _overlayEntry = OverlayEntry(
      builder: (context) =>
          _LockOverlayWidget(appName: appName, onDismiss: hideOverlay),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _isShowing = true;

    // Make the device vibrate to indicate lock
    HapticFeedback.heavyImpact();
  }

  /// Show system-level overlay that works over other apps
  static Future<bool> showSystemOverlay(String appName) async {
    try {
      final result = await _systemOverlayChannel
          .invokeMethod<bool>('showSystemOverlay', {
            'appName': appName,
            'title': '$appName Locked',
            'message': 'This app is blocked by parental controls',
          });
      return result ?? false;
    } catch (e) {
      debugPrint('System overlay error: $e');
      return false;
    }
  }

  /// Hide system-level overlay
  static Future<void> hideSystemOverlay() async {
    try {
      await _systemOverlayChannel.invokeMethod('hideSystemOverlay');
    } catch (e) {
      debugPrint('Hide system overlay error: $e');
    }
  }

  /// Check if system overlay permission is granted
  static Future<bool> hasSystemOverlayPermission() async {
    try {
      final result = await _systemOverlayChannel.invokeMethod<bool>(
        'hasOverlayPermission',
      );
      return result ?? false;
    } catch (e) {
      debugPrint('Check overlay permission error: $e');
      return false;
    }
  }

  /// Request system overlay permission
  static Future<void> requestSystemOverlayPermission() async {
    try {
      await _systemOverlayChannel.invokeMethod('requestOverlayPermission');
    } catch (e) {
      debugPrint('Request overlay permission error: $e');
    }
  }

  /// Hide the Flutter overlay
  static void hideOverlay() {
    if (_overlayEntry != null && _isShowing) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      _isShowing = false;
    }
  }

  /// Check if Flutter overlay is currently showing
  static bool get isShowing => _isShowing;
}

class _LockOverlayWidget extends StatelessWidget {
  final String appName;
  final VoidCallback onDismiss;

  const _LockOverlayWidget({required this.appName, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black87,
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lock Icon with animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: const Icon(Icons.lock, color: Colors.white, size: 100),
                );
              },
            ),

            const SizedBox(height: 32),

            // App Locked Title
            Text(
              '$appName Locked',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Lock Message
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'This app is currently blocked by parental controls.\n\nPlease use other apps or contact your parent for permission.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 48),

            // Parent Contact Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.message, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    'Contact Parent',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Debug: Dismiss button (for testing only)
            ElevatedButton(
              onPressed: onDismiss,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.7),
                foregroundColor: Colors.white,
              ),
              child: const Text('Dismiss (Test Only)'),
            ),
          ],
        ),
      ),
    );
  }
}
