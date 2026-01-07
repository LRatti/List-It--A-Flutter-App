import 'package:app_code/models/supermarket.dart';
import 'package:app_code/services/database/sqlite/manage_supermarket.dart' as sqlite_manage_supermarket;

class ManageSupermarket {
  static void addSupermarket(Supermarket supermarket) {
    sqlite_manage_supermarket.ManageSupermarket.addSupermarket(supermarket);
  }

  static void deleteSupermarket(String id) {
      sqlite_manage_supermarket.ManageSupermarket.deleteSupermarket(id);
  }

  static void updateSupermarket(Supermarket supermarket) {
    sqlite_manage_supermarket.ManageSupermarket.updateSupermarket(supermarket);
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