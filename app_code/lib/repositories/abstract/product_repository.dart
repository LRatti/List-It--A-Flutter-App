import 'package:app_code/models/product.dart';

/// Abstract interface for product repositories
abstract class ProductRepository {
  Future<List<Product>> getAll();
  Future<void> add(Product product);
  Future<void> update(Product product);
  Future<void> deleteById(String id);
  Future<Product?> getById(String id);
}
