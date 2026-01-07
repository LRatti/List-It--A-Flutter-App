import 'package:app_code/models/category.dart';
import 'package:app_code/services/database/sqlite/manage_category.dart' as sqlite_manage_category;

class ManageCategory {
  static void addCategory(Category category) {
    sqlite_manage_category.ManageCategory.addCategory(category) ;
  }

  static void deleteCategory(Category category) {
    sqlite_manage_category.ManageCategory.deleteCategory(category.id);
  }

  static void updateCategory(Category category) {
    sqlite_manage_category.ManageCategory.updateCategory(category);
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