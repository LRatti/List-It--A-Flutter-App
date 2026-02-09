import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// This is a "Global Provider" that anyone can listen to
final localeProvider = NotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});

class LocaleNotifier extends Notifier<Locale> {
  static const String _prefsKey = 'selected_locale';
  static const List<Locale> supportedLocales = [Locale('en'), Locale('it')];

  @override
  Locale build() {
    _loadLocale();
    return const Locale('en');
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    
    if (code != null && code.isNotEmpty) {
      final resolved = supportedLocales.firstWhere(
        (l) => l.languageCode == code,
        orElse: () => const Locale('en'),
      );
      // In Riverpod, we update the state property directly
      state = resolved;
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    if (!supportedLocales.any((item) => item.languageCode == newLocale.languageCode)) return;
    if (newLocale.languageCode == state.languageCode) return;

    state = newLocale;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, newLocale.languageCode);
  }
}