import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AsyncNotifier that manages and persists theme mode.
/// Default is `ThemeMode.system` until the user makes an explicit choice.
class ThemeNotifier extends AsyncNotifier<ThemeMode> {
  static const String _themeModeKey = 'themeMode';

  @override
  Future<ThemeMode> build() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_themeModeKey);

      if (saved == 'light') return ThemeMode.light;
      if (saved == 'dark') return ThemeMode.dark;

      // No saved preference: follow the system setting.
      return ThemeMode.system;
    } catch (_) {
      // If persistence fails, fall back to system mode to avoid blocking UI.
      return ThemeMode.system;
    }
  }

  /// Save and apply the selected theme (UI offers only light/dark).
  Future<void> setThemeMode(ThemeMode mode) async {
    final value = mode == ThemeMode.light ? 'light' : 'dark';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, value);
      state = AsyncValue.data(mode);
    } catch (_) {
      // Even if saving fails, update state so the UI reflects the user's choice.
      state = AsyncValue.data(mode);
    }
  }

  /// Quick toggle between light and dark (does not re-enable system mode).
  Future<void> toggleTheme() async {
    final current = state.value ?? ThemeMode.light;
    final next = current == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(next);
  }
}

/// Primary async provider that persists the theme preference.
final themeProvider = AsyncNotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});

/// Synchronous provider for widgets; falls back to `ThemeMode.system`.
final themeModeValueProvider = Provider<ThemeMode>((ref) {
  final async = ref.watch(themeProvider);
  return async.when(
    data: (value) => value,
    loading: () => ThemeMode.system,
    error: (_, __) => ThemeMode.system,
  );
});
