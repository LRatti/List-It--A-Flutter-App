import 'package:app_code/models/supermarket.dart';
import 'package:app_code/services/database/sqlite/manage_supermarket.dart' as sqlite_manage_supermarket;

/// This class provides methods to manage supermarkets in the database. 
/// It acts as a bridge between the application and the SQLite database,
/// allowing for adding, deleting, updating, and retrieving supermarkets.
class ManageSupermarket {
  static Future<void> addSupermarket(Supermarket supermarket) {
    return sqlite_manage_supermarket.ManageSupermarket.addSupermarket(supermarket);
  }

  static Future<void> deleteSupermarket(String id) {
      return sqlite_manage_supermarket.ManageSupermarket.deleteSupermarket(id);
  }

  static Future<void> updateSupermarket(Supermarket supermarket) {
    return sqlite_manage_supermarket.ManageSupermarket.updateSupermarket(supermarket);
  }

  static Future<List<Supermarket>> getAllSupermarkets() {
    return sqlite_manage_supermarket.ManageSupermarket.getAllSupermarkets();
  }

  static Future<Supermarket?> getSupermarketByName(String name) {
    return sqlite_manage_supermarket.ManageSupermarket.getSupermarketByName(name);
  }

  static Future<Supermarket?> getSupermarketById(String id) {
    return sqlite_manage_supermarket.ManageSupermarket.getSupermarketById(id);
  }

}