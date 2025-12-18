import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/repositories/shopping_list_repository.dart';
import 'package:app_code/services/database/sqlite/manage_shopping_list.dart';

//TODO: the class will call the methods in database_manager instead of SQlite
class ShoppingListRepositorySqlite implements ShoppingListRepository {
  @override
  Future<List<ShoppingList>> getAll() {
    return ManageShoppingList.getAllShoppingLists();
  }

  @override
  Future<void> add(ShoppingList list) {
    return ManageShoppingList.addShoppingList(list);
  }

  @override
  Future<void> update(ShoppingList list) {
    return ManageShoppingList.updateShoppingList(list);
  }

  @override
  Future<void> delete(ShoppingList list) {
    return ManageShoppingList.deleteShoppingList(list);
  }
}
