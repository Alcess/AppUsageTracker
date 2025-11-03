import 'package:flutter/material.dart';
import '../utils/shared_prefs_helper.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  /// Initialize theme from saved preferences
  Future<void> initializeTheme() async {
    _isDarkMode = await SharedPrefsHelper.getBool('darkMode');
    notifyListeners();
  }

  /// Toggle dark mode and save preference
  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    await SharedPrefsHelper.setBool('darkMode', _isDarkMode);
    notifyListeners();
  }

  /// Set dark mode state and save preference
  Future<void> setDarkMode(bool isDark) async {
    _isDarkMode = isDark;
    await SharedPrefsHelper.setBool('darkMode', _isDarkMode);
    notifyListeners();
  }

  /// Get light theme
  ThemeData get lightTheme => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
    brightness: Brightness.light,
  );

  /// Get dark theme
  ThemeData get darkTheme => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    brightness: Brightness.dark,
  );

  /// Get current theme based on dark mode setting
  ThemeData get currentTheme => _isDarkMode ? darkTheme : lightTheme;
}
