import 'package:app_code/models/category.dart';

/// Abstract interface for category repositories
abstract class CategoryRepository {
  Future<List<Category>> getAll();
  Future<void> add(Category category);
  Future<void> update(Category category);
  Future<void> deleteById(String id);
  Future<Category?> getById(String id);
}
