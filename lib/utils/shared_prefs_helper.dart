import 'package:shared_preferences/shared_preferences.dart';

/// Utility class to reduce SharedPreferences boilerplate
class SharedPrefsHelper {
  static SharedPreferences? _instance;

  /// Get SharedPreferences instance (cached)
  static Future<SharedPreferences> get instance async {
    _instance ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  /// Get string value
  static Future<String?> getString(String key) async {
    final prefs = await instance;
    return prefs.getString(key);
  }

  /// Set string value
  static Future<void> setString(String key, String value) async {
    final prefs = await instance;
    await prefs.setString(key, value);
  }

  /// Get bool value
  static Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final prefs = await instance;
    return prefs.getBool(key) ?? defaultValue;
  }

  /// Set bool value
  static Future<void> setBool(String key, bool value) async {
    final prefs = await instance;
    await prefs.setBool(key, value);
  }

  /// Get int value
  static Future<int> getInt(String key, {int defaultValue = 0}) async {
    final prefs = await instance;
    return prefs.getInt(key) ?? defaultValue;
  }

  /// Set int value
  static Future<void> setInt(String key, int value) async {
    final prefs = await instance;
    await prefs.setInt(key, value);
  }

  /// Remove key
  static Future<void> remove(String key) async {
    final prefs = await instance;
    await prefs.remove(key);
  }

  /// Clear all preferences
  static Future<void> clear() async {
    final prefs = await instance;
    await prefs.clear();
  }
}
