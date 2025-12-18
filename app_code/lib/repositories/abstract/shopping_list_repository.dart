import 'package:app_code/models/shopping_list.dart';

abstract class ShoppingListRepository {
  Future<List<ShoppingList>> getAll();
  Future<void> add(ShoppingList list);
  Future<void> update(ShoppingList list);
  Future<void> delete(ShoppingList list);
}
