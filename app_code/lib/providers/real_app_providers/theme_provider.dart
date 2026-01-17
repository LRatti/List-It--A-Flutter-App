import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AsyncNotifier to manage and persist theme mode.
/// Default: ThemeMode.system (segue il sistema finché l'utente non sceglie).
class ThemeNotifier extends AsyncNotifier<ThemeMode> {
  static const String _themeModeKey = 'themeMode';

  @override
  Future<ThemeMode> build() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_themeModeKey);

      if (saved == 'light') return ThemeMode.light;
      if (saved == 'dark') return ThemeMode.dark;

      // Nessuna scelta salvata: segui il sistema
      return ThemeMode.system;
    } catch (_) {
      // In caso di errore, segui comunque il sistema
      return ThemeMode.system;
    }
  }

  /// Salva e applica il tema scelto (solo light/dark; niente opzione system da UI).
  Future<void> setThemeMode(ThemeMode mode) async {
    final value = mode == ThemeMode.light ? 'light' : 'dark';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, value);
      state = AsyncValue.data(mode);
    } catch (_) {
      // Anche se il salvataggio fallisce, aggiorniamo lo stato per coerenza UI
      state = AsyncValue.data(mode);
    }
  }

  /// Toggle rapido tra light e dark (non reintroduce system).
  Future<void> toggleTheme() async {
    final current = state.value ?? ThemeMode.light;
    final next = current == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(next);
  }
}

/// Provider principale (Async)
final themeProvider = AsyncNotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});

/// Provider sincrono di comodo per MaterialApp e widget (fallback: system).
final themeModeValueProvider = Provider<ThemeMode>((ref) {
  final async = ref.watch(themeProvider);
  return async.when(
    data: (value) => value,
    loading: () => ThemeMode.system,
    error: (_, __) => ThemeMode.system,
  );
});
