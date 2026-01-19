import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/repositories/abstract/shopping_list_repository.dart';
import 'package:app_code/repositories/real_app_repo/database_manager_repository/manage_shopping_list.dart';

class ShoppingListRepositoryDb implements ShoppingListRepository {
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
