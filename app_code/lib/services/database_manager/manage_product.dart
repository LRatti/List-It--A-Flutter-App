import 'package:app_code/models/product.dart';
import 'package:app_code/services/database/sqlite/manage_product.dart' as sqlite_manage_product;

class ManageProduct {
  static Future<void> addProduct(Product product) {
    return sqlite_manage_product.ManageProduct.addProduct(product) ;
  }

  static Future<void> deleteProduct(Product product) {
    return sqlite_manage_product.ManageProduct.deleteProduct(product.id);
  }

  static Future<void> updateProduct(Product product) {
    return sqlite_manage_product.ManageProduct.updateProduct(product);
  }

  static Future<Product?> getProductById(String id) {
    return sqlite_manage_product.ManageProduct.getProductById(id);
  }

  static Future<Product?> getProductByName(String name) {
    return sqlite_manage_product.ManageProduct.getProductByName(name);
  }

  List<Product> getAllProducts() {
    return sqlite_manage_product.ManageProduct.getAllProducts() as List<Product>;
  }

}