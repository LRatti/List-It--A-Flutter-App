import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/repositories/abstract/shopping_list_repository.dart';

/// In-memory implementation used only for widget tests.
/// It behaves like a real repository but without persistence.
class MockShoppingListRepository implements ShoppingListRepository {
  final List<ShoppingList> _lists = [];

  @override
  Future<List<ShoppingList>> getAll() async {
    return List.from(_lists);
  }

  @override
  Future<void> add(ShoppingList list) async {
    _lists.add(list);
  }

  @override
  Future<void> update(ShoppingList list) async {}

  @override
  Future<void> delete(ShoppingList list) async {
    _lists.remove(list);
  }
}