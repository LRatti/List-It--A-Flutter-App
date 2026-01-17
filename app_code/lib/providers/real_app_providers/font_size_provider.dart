import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AsyncNotifier to manage global font size multiplier with safe async loading
/// Values range from 0.8 to 1.4 (80% to 140% of base size)
class FontSizeNotifier extends AsyncNotifier<double> {
  static const String _fontSizeKey = 'fontSize';
  static const double _minFontSize = 0.8;
  static const double _maxFontSize = 1.4;
  static const double _defaultFontSize = 1.0;

  @override
  Future<double> build() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSize = prefs.getDouble(_fontSizeKey);
      
      if (savedSize != null && 
          savedSize >= _minFontSize && 
          savedSize <= _maxFontSize) {
        return savedSize;
      }
      return _defaultFontSize;
    } catch (e) {
      // If loading fails, return default
      return _defaultFontSize;
    }
  }

  /// Set font size multiplier and save to SharedPreferences
  Future<void> setFontSize(double multiplier) async {
    final clampedValue = multiplier.clamp(_minFontSize, _maxFontSize);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_fontSizeKey, clampedValue);
      // Update state after saving
      state = AsyncValue.data(clampedValue);
    } catch (e) {
      // Still update state even if save fails
      state = AsyncValue.data(clampedValue);
    }
  }

  /// Reset to default font size
  Future<void> resetFontSize() async {
    await setFontSize(_defaultFontSize);
  }

  /// Increase font size by 0.1
  Future<void> increaseFontSize() async {
    final current = state.value ?? _defaultFontSize;
    await setFontSize(current + 0.1);
  }

  /// Decrease font size by 0.1
  Future<void> decreaseFontSize() async {
    final current = state.value ?? _defaultFontSize;
    await setFontSize(current - 0.1);
  }

  /// Get font size range
  static const fontSizeRange = (min: _minFontSize, max: _maxFontSize);
}

/// Provider for global font size management
/// Returns AsyncValue<double> - handles loading, error, and data states
final fontSizeProvider = AsyncNotifierProvider<FontSizeNotifier, double>(() {
  return FontSizeNotifier();
});

/// Convenience provider that returns only the current value (defaults to 1.0 while loading)
/// Use this for synchronous access in theme building
final fontSizeValueProvider = Provider<double>((ref) {
  final asyncValue = ref.watch(fontSizeProvider);
  return asyncValue.when(
    data: (value) => value,
    loading: () => 1.0,
    error: (_, __) => 1.0,
  );
});

