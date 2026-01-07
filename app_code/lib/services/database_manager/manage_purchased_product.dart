import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/services/database/sqlite/manage_purchased_product.dart' as sqlite_manage_purchased_product;

class ManagePurchasedProduct {
  static Future<void> addPurchasedProduct(PurchasedProduct purchasedProduct) {
    return sqlite_manage_purchased_product.ManagePurchasedProduct.addPurchasedProduct(purchasedProduct) ;
  }

  static Future<void> deletePurchasedProduct(PurchasedProduct purchasedProduct) {
    return sqlite_manage_purchased_product.ManagePurchasedProduct.deletePurchasedProduct(purchasedProduct.id);
  }

  static Future<void> updatePurchasedProduct(PurchasedProduct purchasedProduct) {
    return sqlite_manage_purchased_product.ManagePurchasedProduct.updatePurchasedProduct(purchasedProduct);
  }

  static Future<List<PurchasedProduct>> getPurchasedProductsByList(String listId) {
    return sqlite_manage_purchased_product.ManagePurchasedProduct.getPurchasedProductsByList(listId);
  }

  static Future<PurchasedProduct?> getPurchasedProductById(String id) {
    return sqlite_manage_purchased_product.ManagePurchasedProduct.getPurchasedProductById(id);
  }

  static Future<PurchasedProduct?> getPurchasedProductByName(String listId, String productName) {
    return sqlite_manage_purchased_product.ManagePurchasedProduct.getPurchasedProductByName(listId, productName);
  }
}