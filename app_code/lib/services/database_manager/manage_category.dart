import 'package:app_code/models/category.dart';
import 'package:app_code/services/database/sqlite/manage_category.dart' as sqlite_manage_category;

class ManageCategory {
  static Future<void> addCategory(Category category) {
    return sqlite_manage_category.ManageCategory.addCategory(category) ;
  }

  static Future<void> deleteCategory(Category category) {
    return sqlite_manage_category.ManageCategory.deleteCategory(category.id);
  }

  static Future<void> updateCategory(Category category) {
    return sqlite_manage_category.ManageCategory.updateCategory(category);
  }

  static Future<Category?> getCategoryById(String id) {
    return sqlite_manage_category.ManageCategory.getCategoryById(id);
  }

  static Future<Category?> getCategoryByName(String name) {
    return sqlite_manage_category.ManageCategory.getCategoryByName(name);
  }

  static Future<List<Category>> getAllCategories() {
    return sqlite_manage_category.ManageCategory.getAllCategories();
  }

}