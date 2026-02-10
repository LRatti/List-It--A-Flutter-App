import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:app_code/utils/uncategorized_category_utils.dart';

/// A utility class to localize category names based on a JSON file 
/// containing localized labels.
class CategoryLocalizer {
  static const String _defaultCategoriesPath =
      'assets/data/default_categories.json';
  static final Map<String, Map<String, String>> _labelsByLocale = {};
  static bool _isLoaded = false;

  static Future<void> preload() async {
    if (_isLoaded) return;

    try {
      final jsonString = await rootBundle.loadString(_defaultCategoriesPath);
      final jsonData = jsonDecode(jsonString);

      if (jsonData is! Map || jsonData['categories'] is! List) {
        _isLoaded = true;
        return;
      }

      for (final categoryJson in jsonData['categories'] as List) {
        if (categoryJson is! Map) continue;
        final name = categoryJson['name'];
        if (name is! String) continue;

        final labels = categoryJson['labels'];
        if (labels is Map) {
          for (final entry in labels.entries) {
            if (entry.key is! String || entry.value is! String) continue;
            final locale = entry.key as String;
            final label = entry.value as String;
            _labelsByLocale.putIfAbsent(locale, () => {})[name] = label;
          }
        }
      }
    } catch (_) {
      // If loading fails, fall back to the raw name.
    } finally {
      _isLoaded = true;
    }
  }

  static String localize(BuildContext context, String name) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final localized = _labelsByLocale[languageCode]?[name] ??
        _labelsByLocale['en']?[name];

    if (localized != null) return localized;

    if (name == UncategorizedCategoryUtils.name) {
      return _labelsByLocale[languageCode]?[UncategorizedCategoryUtils.name] ??
          _labelsByLocale['en']?[UncategorizedCategoryUtils.name] ??
          name;
    }

    return name;
  }
}
