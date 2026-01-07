import 'package:app_code/models/product.dart';
import 'package:app_code/services/database/sqlite/manage_product.dart' as sqlite_manage_product;

class ManageProduct {
  static void addProduct(Product product) {
    sqlite_manage_product.ManageProduct.addProduct(product) ;
  }

  static void deleteProduct(Product product) {
    sqlite_manage_product.ManageProduct.deleteProduct(product.id);
  }

  static void updateProduct(Product product) {
    sqlite_manage_product.ManageProduct.updateProduct(product);
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