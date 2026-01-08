import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/providers/recipe_provider.dart';
import 'package:app_code/providers/shopping_lists_notifier.dart';
import 'package:app_code/models/product.dart';

class AddRecipeScreen extends ConsumerStatefulWidget {
  final ShoppingList shoppingList;
  final List<Category> availableCategories;

  const AddRecipeScreen({
    super.key,
    required this.shoppingList,
    required this.availableCategories,
  });

  @override
  ConsumerState<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends ConsumerState<AddRecipeScreen> {
  final TextEditingController _recipeNameController = TextEditingController();
  bool _isLoading = false;
  late Set<int> _deletedIndices;
  late Map<int, String> _editedNames;

  @override
  void initState() {
    super.initState();
    _deletedIndices = {};
    _editedNames = {};
  }

  @override
  void dispose() {
    _recipeNameController.dispose();
    super.dispose();
  }

  void _queryRecipe() async {
    final recipeName = _recipeNameController.text.trim();
    
    if (recipeName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a recipe name')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Query the recipe
    await ref.read(recipeProvider.notifier).queryRecipe(
      recipeName: recipeName,
      categories: widget.availableCategories,
    );

    setState(() {
      _isLoading = false;
    });
  }

  void _showEditIngredientDialog(int index, String currentName) {
    final editController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Ingredient'),
        content: TextField(
          controller: editController,
          decoration: InputDecoration(
            hintText: 'Enter ingredient name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = editController.text.trim();
              if (newName.isNotEmpty && newName != currentName) {
                setState(() {
                  _editedNames[index] = newName;
                });
              }
              editController.dispose();
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addProductsToList() async {
    final recipeState = ref.read(recipeProvider);
    
    recipeState.whenData((recipe) {
      if (!recipe.hasError) {
        // Add only non-deleted products to the shopping list
        for (int i = 0; i < recipe.products.length; i++) {
          if (_deletedIndices.contains(i)) {
            continue; // Skip deleted ingredients
          }

          final product = recipe.products[i];
          final categoryName = recipe.productCategories[i];
          
          // Use edited name if available, otherwise use original name
          final productName = _editedNames[i] ?? product.getName();
          final editedProduct = Product(name: productName);
          
          // Find matching category
          Category? matchingCategory;
          try {
            matchingCategory = widget.availableCategories.firstWhere(
              (cat) => cat.getName().toLowerCase() == categoryName.toLowerCase(),
            );
          } catch (_) {
            // If category not found, use the first available category
            if (widget.availableCategories.isNotEmpty) {
              matchingCategory = widget.availableCategories.first;
            } else {
              matchingCategory = Category(name: categoryName);
            }
          }

          // Create purchased product with the product from recipe
          final purchasedProduct = PurchasedProduct(
            listId: widget.shoppingList.id,
            product: editedProduct,
            category: matchingCategory,
            quantity: 1,
          );

          widget.shoppingList.products ??= [];
          widget.shoppingList.products!.add(purchasedProduct);
        }

        // Update the shopping list
        ref.read(shoppingListsProvider.notifier).updateList(widget.shoppingList);

        final addedCount = recipe.products.length - _deletedIndices.length;
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$addedCount products added to "${widget.shoppingList.getName()}"',
            ),
          ),
        );

        // Pop the screen
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final recipeState = ref.watch(recipeProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add Recipe'),
      ),
      body: Column(
        children: [
          // Input section
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[100],
            child: Column(
              spacing: 12.0,
              children: [
                TextField(
                  controller: _recipeNameController,
                  decoration: InputDecoration(
                    hintText: 'Enter recipe name...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  enabled: !_isLoading,
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _queryRecipe,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Search Recipe'),
                  ),
                ),
              ],
            ),
          ),
          // Results section
          Expanded(
            child: recipeState.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error: $error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
              data: (recipe) {
                // No recipe loaded yet
                if (recipe.recipeName.isEmpty && recipe.error.isEmpty) {
                  return Center(
                    child: Text(
                      'Enter a recipe name and press "Search Recipe"',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }

                // Error from Gemini
                if (recipe.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            recipe.error,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Success - show recipe details
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 16.0,
                    children: [
                      // Recipe name
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Recipe',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              recipe.recipeName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Products
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ingredients (${recipe.products.length - _deletedIndices.length}/${recipe.products.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: recipe.products.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, index) {
                              final product = recipe.products[index];
                              final quantity = recipe.quantities[index];
                              final categoryName = recipe.productCategories[index];
                              final isDeleted = _deletedIndices.contains(index);
                              final displayName = _editedNames[index] ?? product.getName();
                              
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12.0,
                                  horizontal: 8.0,
                                ),
                                decoration: isDeleted
                                    ? BoxDecoration(
                                        color: Colors.grey[100],
                                      )
                                    : null,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        spacing: 4.0,
                                        children: [
                                          GestureDetector(
                                            onTap: isDeleted
                                                ? null
                                                : () => _showEditIngredientDialog(
                                                      index,
                                                      displayName,
                                                    ),
                                            child: Text(
                                              displayName,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                decoration: isDeleted
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                                color: isDeleted
                                                    ? Colors.grey[500]
                                                    : Colors.blue,
                                                fontStyle: !isDeleted
                                                    ? FontStyle.italic
                                                    : null,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            quantity,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDeleted
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600],
                                              decoration: isDeleted
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      spacing: 8.0,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12.0,
                                            vertical: 6.0,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius:
                                                BorderRadius.circular(16.0),
                                          ),
                                          child: Text(
                                            categoryName,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            isDeleted
                                                ? Icons.restore
                                                : Icons.delete_outline,
                                            color: isDeleted
                                                ? Colors.blue
                                                : Colors.red,
                                            size: 20,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () {
                                            setState(() {
                                              if (isDeleted) {
                                                _deletedIndices.remove(index);
                                              } else {
                                                _deletedIndices.add(index);
                                              }
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Add to list button
          if (!_isLoading)
            recipeState.maybeWhen(
              data: (recipe) {
                if (!recipe.hasError && recipe.recipeName.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addProductsToList,
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Add to List'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              orElse: () => const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}
