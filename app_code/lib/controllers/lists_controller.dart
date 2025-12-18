import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/repositories/shopping_list_repository.dart';

class ListsController {
  final ShoppingListRepository repository;

  ListsController(this.repository);

  Future<List<ShoppingList>> loadLists() {
    return repository.getAll();
  }

  Future<void> addList(ShoppingList list) {
    return repository.add(list);
  }

  Future<void> updateList(ShoppingList list) {
    return repository.update(list);
  }

  Future<void> deleteList(ShoppingList list) {
    return repository.delete(list);
  }
}
