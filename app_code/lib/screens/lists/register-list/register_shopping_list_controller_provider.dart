import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/screens/lists/register-list/register_shopping_list_controller.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Provider for the register shopping list controller
final registerShoppingListControllerProvider =
    ChangeNotifierProvider.family<RegisterShoppingListController, ShoppingList>((
      ref,
      shoppingList,
    ) {
      return RegisterShoppingListController(shoppingList: shoppingList, ref: ref);
    });
