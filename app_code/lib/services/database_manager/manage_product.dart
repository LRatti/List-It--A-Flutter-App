import 'package:app_code/models/product.dart';
import 'package:app_code/services/database/sqlite/manage_product.dart' as sqlite_manage_product;

class ManageProduct {
  void addProduct(Product product) {
    sqlite_manage_product.ManageProduct.addProduct(product) ;
  }

  void deleteProduct(Product product) {
    sqlite_manage_product.ManageProduct.deleteProduct(product.id);
  }

  void updateProduct(Product product) {
    sqlite_manage_product.ManageProduct.updateProduct(product);
  }

  Product? getProductById(String id) {
    return sqlite_manage_product.ManageProduct.getProductById(id) as Product?;
  }

  Product? getProductByName(String name) {
    return sqlite_manage_product.ManageProduct.getProductByName(name) as Product?;
  }

  List<Product> getAllProducts() {
    return sqlite_manage_product.ManageProduct.getAllProducts() as List<Product>;
  }

}