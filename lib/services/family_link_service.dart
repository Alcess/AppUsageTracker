import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'fcm_service.dart';

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
    final fcmToken = await FCMService.getFCMToken();

    try {
      // Try Firestore first
      await _firestore.collection('links').doc(code).set({
        'childToken': childToken,
        'childFCMToken': fcmToken,
        'linked': false,
      });
      debugPrint('Child link created successfully in Firestore');
    } catch (e) {
      debugPrint('Firestore not available: $e');
      debugPrint('Using local storage mode - limited functionality');
      // Store locally as fallback
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('firestore_available', false);
    }

    // Always store locally as well
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('childToken', childToken);
    await prefs.setString('linkCode', code);

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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('parentToken', parentToken);
      await prefs.setString('linkCode', code);

      return true;
    } catch (e) {
      debugPrint('Error linking to child: $e');
      return false;
    }
  }

  /// Check if devices are linked
  static Future<bool> isLinked() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString('linkCode');

      if (code == null) return false;

      final doc = await _firestore.collection('links').doc(code).get();
      return doc.exists && doc.data()?['linked'] == true;
    } catch (e) {
      debugPrint('Error checking link status: $e');
      // On web without Firebase, return false
      return false;
    }
  }

  /// Get the stored link code
  static Future<String?> getLinkCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('linkCode');
  }

  /// Get child's FCM token (for parent to send commands)
  static Future<String?> getChildFCMToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString('linkCode');

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
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('linkCode');

    // Remove from Firestore
    if (code != null) {
      try {
        await _firestore.collection('links').doc(code).delete();
      } catch (e) {
        // Handle error silently
      }
    }

    // Clear local storage
    await prefs.remove('childToken');
    await prefs.remove('parentToken');
    await prefs.remove('linkCode');
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
