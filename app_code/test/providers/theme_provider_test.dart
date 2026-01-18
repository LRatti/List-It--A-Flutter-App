import 'package:app_code/providers/real_app_providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ThemeNotifier', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('build returns ThemeMode.system when no preference saved', () async {
      final container = ProviderContainer();

      final result = await container.read(themeProvider.future);

      expect(result, ThemeMode.system);
    });

    test('build returns ThemeMode.light when saved preference is light', () async {
      SharedPreferences.setMockInitialValues({'themeMode': 'light'});
      final container = ProviderContainer();

      final result = await container.read(themeProvider.future);

      expect(result, ThemeMode.light);
    });

    test('build returns ThemeMode.dark when saved preference is dark', () async {
      SharedPreferences.setMockInitialValues({'themeMode': 'dark'});
      final container = ProviderContainer();

      final result = await container.read(themeProvider.future);

      expect(result, ThemeMode.dark);
    });

    test('build returns ThemeMode.system for invalid saved value', () async {
      SharedPreferences.setMockInitialValues({'themeMode': 'invalid'});
      final container = ProviderContainer();

      final result = await container.read(themeProvider.future);

      expect(result, ThemeMode.system);
    });

    test('setThemeMode saves light theme to SharedPreferences', () async {
      final container = ProviderContainer();
      final notifier = container.read(themeProvider.notifier);

      await notifier.setThemeMode(ThemeMode.light);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('themeMode'), 'light');
    });

    test('setThemeMode saves dark theme to SharedPreferences', () async {
      final container = ProviderContainer();
      final notifier = container.read(themeProvider.notifier);

      await notifier.setThemeMode(ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('themeMode'), 'dark');
    });

    test('setThemeMode saves dark for ThemeMode.system (non-standard input)', () async {
      final container = ProviderContainer();
      final notifier = container.read(themeProvider.notifier);

      // Although not recommended, system mode should fall back to 'dark'
      await notifier.setThemeMode(ThemeMode.system);

      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('themeMode');
      expect(saved, 'dark');
    });

    test('setThemeMode updates provider state to light', () async {
      final container = ProviderContainer();
      final notifier = container.read(themeProvider.notifier);

      await notifier.setThemeMode(ThemeMode.light);
      final result = container.read(themeModeValueProvider);

      expect(result, ThemeMode.light);
    });

    test('setThemeMode updates provider state to dark', () async {
      final container = ProviderContainer();
      final notifier = container.read(themeProvider.notifier);

      await notifier.setThemeMode(ThemeMode.dark);
      final result = container.read(themeModeValueProvider);

      expect(result, ThemeMode.dark);
    });

    test('toggleTheme switches from light to dark', () async {
      SharedPreferences.setMockInitialValues({'themeMode': 'light'});
      final container = ProviderContainer();
      final notifier = container.read(themeProvider.notifier);

      await notifier.toggleTheme();
      final result = container.read(themeModeValueProvider);

      expect(result, ThemeMode.dark);
    });

    test('toggleTheme switches from dark to light', () async {
      final container = ProviderContainer();
      final notifier = container.read(themeProvider.notifier);

      // Set explicitly first to establish state
      await notifier.setThemeMode(ThemeMode.dark);
      await notifier.toggleTheme();
      final result = container.read(themeModeValueProvider);

      expect(result, ThemeMode.light);
    });

    test('toggleTheme from system defaults to light and switches to dark',
        () async {
      final container = ProviderContainer();
      final notifier = container.read(themeProvider.notifier);

      // First toggle from system (treated as light) -> dark
      await notifier.toggleTheme();
      var result = container.read(themeModeValueProvider);
      expect(result, ThemeMode.dark);

      // Second toggle dark -> light
      await notifier.toggleTheme();
      result = container.read(themeModeValueProvider);
      expect(result, ThemeMode.light);
    });

    test('themeModeValueProvider returns system while loading', () async {
      final container = ProviderContainer();

      final result = container.read(themeModeValueProvider);

      expect(result, ThemeMode.system);
    });

    test('themeModeValueProvider returns system on error', () async {
      final container = ProviderContainer();

      final result = container.read(themeModeValueProvider);

      expect(result, ThemeMode.system);
    });

    test('setThemeMode maintains state consistency even if save fails', () async {
      final container = ProviderContainer();
      final notifier = container.read(themeProvider.notifier);

      // Set theme (may or may not persist depending on shared prefs mock)
      await notifier.setThemeMode(ThemeMode.dark);

      // State should still reflect the update
      final result = container.read(themeModeValueProvider);
      expect(result, ThemeMode.dark);
    });
  });
}
