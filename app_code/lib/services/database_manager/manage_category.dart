import 'package:app_code/models/category.dart';
import 'package:app_code/services/database/sqlite/manage_category.dart' as sqlite_manage_category;

class ManageCategory {
  void addCategory(Category category) {
    sqlite_manage_category.ManageCategory.addCategory(category) ;
  }

  void deleteCategory(Category category) {
    sqlite_manage_category.ManageCategory.deleteCategory(category.id);
  }

  void updateCategory(Category category) {
    sqlite_manage_category.ManageCategory.updateCategory(category);
  }

  Category? getCategoryById(String id) {
    return sqlite_manage_category.ManageCategory.getCategoryById(id) as Category?;
  }

  Category? getCategoryByName(String name) {
    return sqlite_manage_category.ManageCategory.getCategoryByName(name) as Category?;
  }

  List<Category> getAllCategories() {
    return sqlite_manage_category.ManageCategory.getAllCategories() as List<Category>;
  }

}