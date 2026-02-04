import 'package:app_code/models/category.dart';

class UncategorizedCategoryUtils {
  static const String name = 'Uncategorized';

  static bool isUncategorized(Category category) {
    return category.getName().trim().toLowerCase() == name.toLowerCase();
  }

  static Category? findIn(List<Category> categories) {
    for (final category in categories) {
      if (isUncategorized(category)) return category;
    }
    return null;
  }

  /// Returns the uncategorized category if present, otherwise a safe fallback
  /// (first available category, or a hidden uncategorized placeholder).
  static Category fallbackFrom(List<Category> categories) {
    final uncategorized = findIn(categories);
    if (uncategorized != null) return uncategorized;
    if (categories.isNotEmpty) return categories.first;
    return Category(name: name, isVisible: false);
  }
}
