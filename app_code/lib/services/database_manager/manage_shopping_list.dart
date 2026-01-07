import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/services/database/sqlite/manage_shopping_list.dart' as sqlite_manage_shopping_list;

class ManageShoppingList {
  void addShoppingList(ShoppingList shoppingList) {
    sqlite_manage_shopping_list.ManageShoppingList.addShoppingList(shoppingList);
  }

  void deleteShoppingList(ShoppingList shoppingList) {
    sqlite_manage_shopping_list.ManageShoppingList.deleteShoppingList(shoppingList);
  }

  void updateShoppingList(ShoppingList shoppingList) {
    sqlite_manage_shopping_list.ManageShoppingList.updateShoppingList(shoppingList);
  }

  List<ShoppingList> getAllShoppingLists() {
    return sqlite_manage_shopping_list.ManageShoppingList.getAllShoppingLists() as List<ShoppingList>;
  }
}