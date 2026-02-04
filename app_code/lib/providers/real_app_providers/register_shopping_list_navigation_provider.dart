import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Enum to track the source from which register_shopping_list_screen was accessed
enum RegisterShoppingListSource {
  listDetail,    // Accessed from list_detail_screen via cart button
  history,       // Accessed from history_screen_mobile
}

/// Provider to track the source of navigation to register_shopping_list_screen
/// This allows the register screen to know where it came from and navigate
/// back appropriately when the back button is pressed.
///
/// The source is set when navigating to register_shopping_list and cleared
/// when the register screen is closed.
final registerShoppingListSourceProvider =
    StateProvider<RegisterShoppingListSource?>((ref) => null);
