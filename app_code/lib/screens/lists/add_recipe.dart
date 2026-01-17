import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/providers/real_app_providers/recipe_provider.dart';
import 'package:app_code/providers/real_app_providers/shopping_lists_notifier.dart';
import 'package:app_code/widgets/app_snackbar.dart';
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
  bool _isSearching = false;
  late Set<int> _deletedIndices;
  late Map<int, String> _editedNames;

  @override
  void initState() {
    super.initState();
    _deletedIndices = {};
    _editedNames = {};

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(backgroundRecipeProvider.notifier).loadCachedSearch(widget.shoppingList.id);
    });
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

    if (!mounted) return;
    setState(() => _isSearching = true);

    await ref.read(backgroundRecipeProvider.notifier).startBackgroundSearch(
      listId: widget.shoppingList.id,
      recipeName: recipeName,
      categories: widget.availableCategories,
      shoppingList: widget.shoppingList,
    );

    if (!mounted) return;
    setState(() => _isSearching = false);
  }

  void _showEditIngredientDialog(int index, String currentName) {
    final editController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Ingredient'),
        content: SingleChildScrollView(
          child: TextField(
            controller: editController,
            decoration: InputDecoration(
              hintText: 'Enter ingredient name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newName = editController.text.trim();
              if (newName.isNotEmpty && newName != currentName) {
                setState(() => _editedNames[index] = newName);
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
    final backgroundSearches = ref.read(backgroundRecipeProvider);
    final currentSearch = backgroundSearches[widget.shoppingList.id];
    if (currentSearch == null) return;

    currentSearch.result.whenData((recipe) {
      if (!recipe.hasError) {
        for (int i = 0; i < recipe.products.length; i++) {
          if (_deletedIndices.contains(i)) continue;

          final product = recipe.products[i];
          final categoryName = recipe.productCategories[i];
          final productName = _editedNames[i] ?? product.getName();
          final editedProduct = Product(name: productName);

          Category? matchingCategory;
          try {
            matchingCategory = widget.availableCategories.firstWhere(
              (cat) => cat.getName().toLowerCase() == categoryName.toLowerCase(),
            );
          } catch (_) {
            matchingCategory = widget.availableCategories.isNotEmpty
                ? widget.availableCategories.first
                : Category(name: categoryName);
          }

          final purchasedProduct = PurchasedProduct(
            listId: widget.shoppingList.id,
            product: editedProduct,
            category: matchingCategory,
            quantity: 1,
          );

          widget.shoppingList.products ??= [];
          widget.shoppingList.products!.add(purchasedProduct);
        }

        ref.read(shoppingListsProvider.notifier).updateList(widget.shoppingList);
        ref.read(backgroundRecipeProvider.notifier).clearSearchForList(widget.shoppingList.id);

        final addedCount = recipe.products.length - _deletedIndices.length;
        ScaffoldMessenger.of(context).showSnackBar(
          buildAppSnackBar(
            message: '$addedCount products added to "${widget.shoppingList.getName()}"',
            isError: false,
            context: context,
          ),
        );
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundSearches = ref.watch(backgroundRecipeProvider);
    final currentSearch = backgroundSearches[widget.shoppingList.id];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: const Text('Add Recipe'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Input Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: colorScheme.primary.withAlpha(31),
                      child: Column(
                        children: [
                          TextField(
                            controller: _recipeNameController,
                            decoration: InputDecoration(
                              hintText: 'Enter recipe name...',
                              filled: true,
                              fillColor: colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            enabled: !_isSearching,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSearching ? null : _queryRecipe,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                              ),
                              child: _isSearching
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Search Recipe'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Results Section
                    if (currentSearch == null)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'Enter a recipe name and press "Search Recipe"',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                        ),
                      )
                    else
                      currentSearch.result.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (error, _) => Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              'Error: $error',
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        data: (recipe) {
                          if (recipe.hasError) {
                            return Padding(
                              padding: const EdgeInsets.all(32),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                                    const SizedBox(height: 16),
                                    Text(
                                      recipe.error,
                                      style: const TextStyle(color: Colors.red, fontSize: 16),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Recipe name
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withAlpha(38),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: colorScheme.outline),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Recipe',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(recipe.recipeName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Ingredients
                                Text(
                                  'Ingredients (${recipe.products.length - _deletedIndices.length}/${recipe.products.length})',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                      color: isDeleted ? colorScheme.surfaceContainerHighest : null,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                GestureDetector(
                                                  onTap: isDeleted ? null : () => _showEditIngredientDialog(index, displayName),
                                                  child: Text(
                                                    displayName,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                      decoration: isDeleted ? TextDecoration.lineThrough : null,
                                                      color: isDeleted ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                                                      fontStyle: !isDeleted ? FontStyle.italic : null,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  quantity,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: colorScheme.onSurfaceVariant,
                                                    decoration: isDeleted ? TextDecoration.lineThrough : null,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: colorScheme.surfaceVariant, // automatic contrast
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                child: Text(
                                                  categoryName,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                    color: colorScheme.onSurfaceVariant, // matches light/dark
                                                  ),
                                                ),
                                              ),

                                              IconButton(
                                                icon: Icon(
                                                  isDeleted ? Icons.restore : Icons.delete_outline,
                                                  size: 20,
                                                  color: isDeleted ? colorScheme.primary : colorScheme.error,
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
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            // Add to List Button
            if (currentSearch != null && !_isSearching)
              currentSearch.result.maybeWhen(
                data: (recipe) {
                  if (!recipe.hasError && recipe.recipeName.isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _addProductsToList,
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('Add to List'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
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
      ),
    );
  }
}
