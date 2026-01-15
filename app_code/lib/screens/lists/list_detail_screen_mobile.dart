import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/screens/lists/add_recipe.dart';
import 'package:app_code/widgets/safe_bottom_padding_wrapper.dart';

class ListDetailScreenMobile extends ConsumerWidget {
  final ShoppingList shoppingList;

  // Mock categories for now
  static final mockCategories = [
    Category(name: 'Fruits'),
    Category(name: 'Vegetables'),
    Category(name: 'Dairy'),
    Category(name: 'Meat'),
    Category(name: 'Bakery'),
    Category(name: 'Beverages'),
  ];

  const ListDetailScreenMobile({
    super.key,
    required this.shoppingList,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(shoppingList.getName()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SafeBottomPaddingWrapper(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddRecipeScreen(
                    shoppingList: shoppingList,
                    availableCategories: mockCategories,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
            ),
            child: const Text('Add a Recipe'),
          ),
        ),
      ),
    );
  }
}
