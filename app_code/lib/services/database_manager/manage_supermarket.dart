import 'package:app_code/models/supermarket.dart';
import 'package:app_code/services/database/sqlite/manage_supermarket.dart' as sqlite_manage_supermarket;

class ManageSupermarket {
  void addSupermarket(Supermarket supermarket) {
    sqlite_manage_supermarket.ManageSupermarket.addSupermarket(supermarket);
  }

  void deleteSupermarket(String id) {
      sqlite_manage_supermarket.ManageSupermarket.deleteSupermarket(id);
  }

  void updateSupermarket(Supermarket supermarket) {
    sqlite_manage_supermarket.ManageSupermarket.updateSupermarket(supermarket);
  }

  List<Supermarket> getAllSupermarkets() {
    return sqlite_manage_supermarket.ManageSupermarket.getAllSupermarkets() as List<Supermarket>;
  }

  Supermarket? getSupermarketByName(String name) {
    return sqlite_manage_supermarket.ManageSupermarket.getSupermarketByName(name) as Supermarket?;
  }

  Supermarket? getSupermarketById(String id) {
    return sqlite_manage_supermarket.ManageSupermarket.getSupermarketById(id) as Supermarket?;
  }

}