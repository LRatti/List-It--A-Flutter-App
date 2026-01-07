import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/services/database/sqlite/manage_shopping_list.dart' as sqlite_manage_shopping_list;

class ManageShoppingList {
  static Future<void> addShoppingList(ShoppingList shoppingList) {
    return sqlite_manage_shopping_list.ManageShoppingList.addShoppingList(shoppingList);
  }

  static Future<void> deleteShoppingList(ShoppingList shoppingList) {
    return sqlite_manage_shopping_list.ManageShoppingList.deleteShoppingList(shoppingList);
  }

  static Future<void> updateShoppingList(ShoppingList shoppingList) {
    return sqlite_manage_shopping_list.ManageShoppingList.updateShoppingList(shoppingList);
  }

  static Future<List<ShoppingList>> getAllShoppingLists() {
    return sqlite_manage_shopping_list.ManageShoppingList.getAllShoppingLists();
  }
}