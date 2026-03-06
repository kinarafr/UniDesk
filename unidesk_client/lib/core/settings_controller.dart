import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController with ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _highContrastKey = 'high_contrast';
  static const String _reduceMotionKey = 'reduce_motion';

  ThemeMode _themeMode = ThemeMode.light;
  bool _isHighContrast = false;
  bool _isReduceMotion = false;

  ThemeMode get themeMode => _themeMode;
  bool get isHighContrast => _isHighContrast;
  bool get isReduceMotion => _isReduceMotion;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final savedTheme = prefs.getString(_themeModeKey);
    if (savedTheme != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.toString() == savedTheme,
        orElse: () => ThemeMode.system,
      );
    }

    _isHighContrast = prefs.getBool(_highContrastKey) ?? false;
    _isReduceMotion = prefs.getBool(_reduceMotionKey) ?? false;

    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode? newThemeMode) async {
    if (newThemeMode == null || newThemeMode == _themeMode) return;

    _themeMode = newThemeMode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, newThemeMode.toString());
  }

  Future<void> updateHighContrast(bool newValue) async {
    if (newValue == _isHighContrast) return;

    _isHighContrast = newValue;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_highContrastKey, newValue);
  }

  Future<void> updateReduceMotion(bool newValue) async {
    if (newValue == _isReduceMotion) return;

    _isReduceMotion = newValue;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reduceMotionKey, newValue);
  }
}
