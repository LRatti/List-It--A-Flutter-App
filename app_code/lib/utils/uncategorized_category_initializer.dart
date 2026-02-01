import 'package:app_code/models/category.dart';
import 'package:app_code/repositories/sync/category_repository_sync.dart';
import 'package:app_code/repositories/sync/supermarket_repository_sync.dart';
import 'package:app_code/utils/uncategorized_category_utils.dart';

/// Ensures that there is exactly one hidden "uncategorized" category
/// and that every supermarket contains it by default.
class UncategorizedCategoryInitializer {
  /// checks that the 'uncategorized' category exists and that every supermarket contains it.
  static Future<Category> ensureInitialized() async {
    final categoryRepo = CategoryRepositoryWithSync();
    final supermarketRepo = SupermarketRepositoryWithSync();

    final allCategories = await categoryRepo.getAll();
    final matches = allCategories
        .where(UncategorizedCategoryUtils.isUncategorized)
        .toList();

    Category canonical;
    if (matches.isEmpty) {
      canonical = Category(
        name: UncategorizedCategoryUtils.name,
        isVisible: false,
      );
      await categoryRepo.add(canonical);
    } else {
      canonical = matches.first;
      if (canonical.isVisible) {
        canonical.setVisibility(false);
        await categoryRepo.update(canonical);
      }

      for (final duplicate in matches.skip(1)) {
        if (duplicate.isVisible) {
          duplicate.setVisibility(false);
          await categoryRepo.update(duplicate);
        }
      }
    }

    final supermarkets = await supermarketRepo.getAll();
    for (final supermarket in supermarkets) {
      final existing = supermarket.getCategories();
      final filtered = <Category>[];
      bool hasCanonical = false;

      for (final category in existing) {
        if (UncategorizedCategoryUtils.isUncategorized(category)) {
          if (category.id == canonical.id && !hasCanonical) {
            filtered.add(category);
            hasCanonical = true;
          }
        } else {
          filtered.add(category);
        }
      }

      if (!hasCanonical) {
        filtered.insert(0, canonical);
      } else {
        final canonicalIndex =
            filtered.indexWhere((cat) => cat.id == canonical.id);
        if (canonicalIndex > 0) {
          final category = filtered.removeAt(canonicalIndex);
          filtered.insert(0, category);
        }
      }

      if (!_areCategoryListsEqual(existing, filtered)) {
        supermarket.setCategories(filtered);
        await supermarketRepo.update(supermarket);
      }
    }

    return canonical;
  }

  /// Returns the canonical uncategorized category (created if missing).
  static Future<Category> getUncategorized() async {
    final categoryRepo = CategoryRepositoryWithSync();

    final allCategories = await categoryRepo.getAll();
    final matches = allCategories
        .where(UncategorizedCategoryUtils.isUncategorized)
        .toList();

    Category canonical;
    if (matches.isEmpty) {
      canonical = Category(
        name: UncategorizedCategoryUtils.name,
        isVisible: false,
      );
      await categoryRepo.add(canonical);
    } else {
      canonical = matches.first;
      if (canonical.isVisible) {
        canonical.setVisibility(false);
        await categoryRepo.update(canonical);
      }

      for (final duplicate in matches.skip(1)) {
        if (duplicate.isVisible) {
          duplicate.setVisibility(false);
          await categoryRepo.update(duplicate);
        }
      }
    }
    return canonical;
  }

  static bool _areCategoryListsEqual(
    List<Category> current,
    List<Category> updated,
  ) {
    if (current.length != updated.length) return false;
    for (int i = 0; i < current.length; i++) {
      if (current[i].id != updated[i].id) return false;
    }
    return true;
  }
}
