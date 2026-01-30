import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:app_code/models/category.dart';

/// Utility class to load default categories from JSON assets
class DefaultCategoriesLoader {
  static const String _defaultCategoriesPath = 'assets/data/default_categories.json';

  /// Load default categories from the JSON file
  static Future<List<Category>> loadDefaultCategories() async {
    try {
      final jsonString = await rootBundle.loadString(_defaultCategoriesPath);
      final jsonData = jsonDecode(jsonString);
      
      if (jsonData is! Map || jsonData['categories'] is! List) {
        throw FormatException('Invalid default_categories.json format');
      }

      final categoriesList = jsonData['categories'] as List;
      return categoriesList.map((categoryJson) {
        return Category(
          name: categoryJson['name'] ?? 'Unknown',
          isVisible: true,
        );
      }).toList();
    } catch (e) {
      print('Error loading default categories: $e');
      return [];
    }
  }
}
