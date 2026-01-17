import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notifier to manage theme mode state
class ThemeNotifier extends Notifier<ThemeMode> {
  static const String _themeModeKey = 'themeMode';

  @override
  ThemeMode build() {
    _loadThemeMode();
    return ThemeMode.light; // Default to light mode on first launch
  }

  /// Load theme mode from SharedPreferences
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_themeModeKey);
      
      if (savedMode != null) {
        final newMode = savedMode == 'light' ? ThemeMode.light : ThemeMode.dark;
        state = newMode;
      }
    } catch (e) {
      // If loading fails, keep default light
      state = ThemeMode.light;
    }
  }

  /// Set theme mode and save to SharedPreferences
  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeString = mode == ThemeMode.light ? 'light' : 'dark';
      await prefs.setString(_themeModeKey, modeString);
      state = mode;
    } catch (e) {
      // If saving fails, still update state
      state = mode;
    }
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }
}

/// Provider for theme mode management
final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});
