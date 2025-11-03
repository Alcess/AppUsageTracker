import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/shared_prefs_helper.dart';
import '../utils/app_logger.dart';
import 'fcm_service.dart';
import 'role_service.dart';

class FamilyLinkService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate a random 6-digit code for child mode
  static String generateChildCode() {
    final random = Random();
    return random.nextInt(999999).toString().padLeft(6, '0');
  }

  /// Child: Create a link document and return the code
  static Future<String> createChildLink() async {
    final code = generateChildCode();
    final childToken = _generateToken();

    // Force refresh FCM token to ensure we have a valid one
    String? fcmToken = await FCMService.refreshFCMToken();

    // If refresh fails, try getting existing token
    fcmToken ??= await FCMService.getFCMToken();

    AppLogger.connection(
      'Creating child link with FCM token: ${fcmToken?.substring(0, 20) ?? 'null'}',
    );

    try {
      // Try Firestore first
      await _firestore.collection('links').doc(code).set({
        'childToken': childToken,
        'childFCMToken': fcmToken,
        'linked': false,
        'created': FieldValue.serverTimestamp(),
      });
      AppLogger.info(
        'Child link created successfully in Firestore',
        'FamilyLink',
      );
    } catch (e) {
      AppLogger.error('Firestore not available', 'FamilyLink', e);
      AppLogger.info(
        'Using local storage mode - limited functionality',
        'FamilyLink',
      );
      // Store locally as fallback
      await SharedPrefsHelper.setBool('firestore_available', false);
    }

    // Always store locally as well
    await SharedPrefsHelper.setString('childToken', childToken);
    await SharedPrefsHelper.setString('linkCode', code);

    return code;
  }

  /// Parent: Link to child using the code
  static Future<bool> linkToChild(String code) async {
    try {
      final parentToken = _generateToken();
      final fcmToken = await FCMService.getFCMToken();

      await _firestore.collection('links').doc(code).update({
        'parentToken': parentToken,
        'parentFCMToken': fcmToken,
        'linked': true,
      });

      // Store the parent token and link code locally
      await SharedPrefsHelper.setString('parentToken', parentToken);
      await SharedPrefsHelper.setString('linkCode', code);

      return true;
    } catch (e) {
      AppLogger.error('Error linking to child', 'FamilyLink', e);
      return false;
    }
  }

  /// Check if devices are linked
  static Future<bool> isLinked() async {
    try {
      final code = await SharedPrefsHelper.getString('linkCode');

      if (code == null) return false;

      final doc = await _firestore.collection('links').doc(code).get();
      return doc.exists && doc.data()?['linked'] == true;
    } catch (e) {
      AppLogger.error('Error checking link status', 'FamilyLink', e);
      // On web without Firebase, return false
      return false;
    }
  }

  /// Check if alternative connection method is available
  static Future<bool> hasAlternativeConnection() async {
    try {
      final code = await SharedPrefsHelper.getString('linkCode');

      if (code == null) return false;

      final doc = await _firestore.collection('links').doc(code).get();
      if (doc.exists) {
        final data = doc.data()!;
        final alternativeConnection =
            data['alternativeConnection'] as bool? ?? false;
        final forcedConnection = data['forcedConnection'] as bool? ?? false;

        return alternativeConnection || forcedConnection;
      }
      return false;
    } catch (e) {
      AppLogger.error('Error checking alternative connection', 'FamilyLink', e);
      return false;
    }
  }

  /// Get the stored link code
  static Future<String?> getLinkCode() async {
    return await SharedPrefsHelper.getString('linkCode');
  }

  /// Get child's FCM token (for parent to send commands)
  static Future<String?> getChildFCMToken() async {
    try {
      final code = await SharedPrefsHelper.getString('linkCode');

      if (code == null) return null;

      final doc = await _firestore.collection('links').doc(code).get();
      if (doc.exists) {
        return doc.data()?['childFCMToken'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Clear linking data (for unlinking)
  static Future<void> unlink() async {
    final code = await SharedPrefsHelper.getString('linkCode');

    // Remove from Firestore
    if (code != null) {
      try {
        await _firestore.collection('links').doc(code).delete();
      } catch (e) {
        // Handle error silently
      }
    }

    // Clear local storage
    await SharedPrefsHelper.remove('childToken');
    await SharedPrefsHelper.remove('parentToken');
    await SharedPrefsHelper.remove('linkCode');
  }

  /// Update child FCM token (call when FCM token changes)
  static Future<bool> updateChildFCMToken() async {
    try {
      final code = await SharedPrefsHelper.getString('linkCode');
      final childToken = await SharedPrefsHelper.getString('childToken');

      if (code == null) {
        AppLogger.warning(
          'No link code found - cannot update child FCM token',
          'FamilyLink',
        );
        return false;
      }

      if (childToken == null) {
        AppLogger.warning(
          'No child token found - this device may not be a child',
          'FamilyLink',
        );
        return false;
      }

      // Force refresh FCM token
      String? newFCMToken = await FCMService.refreshFCMToken();

      // If refresh fails, try getting existing token
      newFCMToken ??= await FCMService.getFCMToken();

      if (newFCMToken == null) {
        AppLogger.error(
          'Failed to get FCM token - FCM may not be initialized',
          'FamilyLink',
        );
        return false;
      }

      AppLogger.connection(
        'Updating child FCM token: ${newFCMToken.substring(0, 20)}...',
      );

      // Update in Firestore
      await _firestore.collection('links').doc(code).update({
        'childFCMToken': newFCMToken,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      AppLogger.info('Child FCM token updated successfully', 'FamilyLink');
      return true;
    } catch (e) {
      AppLogger.error('Error updating child FCM token', 'FamilyLink', e);
      return false;
    }
  }

  /// Update parent FCM token (call when FCM token changes)
  static Future<bool> updateParentFCMToken() async {
    try {
      final code = await SharedPrefsHelper.getString('linkCode');
      final parentToken = await SharedPrefsHelper.getString('parentToken');

      if (code == null || parentToken == null) {
        AppLogger.warning('No link code or parent token found', 'FamilyLink');
        return false;
      }

      final newFCMToken = await FCMService.getFCMToken();
      if (newFCMToken == null) {
        AppLogger.error('Failed to get new FCM token', 'FamilyLink');
        return false;
      }

      // Update in Firestore
      await _firestore.collection('links').doc(code).update({
        'parentFCMToken': newFCMToken,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      AppLogger.info('Parent FCM token updated successfully', 'FamilyLink');
      return true;
    } catch (e) {
      AppLogger.error('Error updating parent FCM token', 'FamilyLink', e);
      return false;
    }
  }

  /// Force fix FCM token issues - comprehensive repair method
  static Future<bool> fixFCMTokenIssues() async {
    try {
      AppLogger.info('Starting FCM token fix process...', 'FamilyLink');

      final code = await SharedPrefsHelper.getString('linkCode');

      if (code == null) {
        AppLogger.error(
          'No link code found - cannot fix FCM token',
          'FamilyLink',
        );
        return false;
      }

      // Step 1: Force refresh FCM token
      AppLogger.debug('Step 1: Refreshing FCM token...', 'FamilyLink');
      String? newFCMToken = await FCMService.refreshFCMToken();

      if (newFCMToken == null) {
        AppLogger.error('Step 1 failed: Could not get FCM token', 'FamilyLink');
        return false;
      }

      // Step 2: Update in Firestore based on role
      final role = await RoleService.getRole();
      AppLogger.debug('Step 2: Updating token for role: $role', 'FamilyLink');

      bool success = false;
      if (role == AppRole.child) {
        success = await updateChildFCMToken();
      } else if (role == AppRole.parent) {
        success = await updateParentFCMToken();
      }

      if (success) {
        AppLogger.info('FCM token fix completed successfully', 'FamilyLink');
      } else {
        AppLogger.error('FCM token fix failed during update', 'FamilyLink');
      }

      return success;
    } catch (e) {
      AppLogger.error('Error during FCM token fix', 'FamilyLink', e);
      return false;
    }
  }

  /// Generate a random token for authentication
  static String _generateToken() {
    final random = Random();
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(
      32,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }
}
