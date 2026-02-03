import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/screens/lists/add_recipe_screen_mobile.dart';
import 'package:app_code/providers/real_app_providers/product/product_categorization_provider.dart';
import 'package:app_code/providers/real_app_providers/shopping_list/shopping_lists_notifier.dart';
import 'package:app_code/widgets/app_snackbar.dart';

class ListDetailScreenMobile extends ConsumerStatefulWidget {
  final ShoppingList shoppingList;

  static final mockCategories = [
    Category(name: 'Fruits'),
    Category(name: 'Vegetables'),
    Category(name: 'Dairy'),
    Category(name: 'Meat'),
    Category(name: 'Bakery'),
    Category(name: 'Beverages'),
    Category(name: 'uncategorized'),
  ];

  const ListDetailScreenMobile({super.key, required this.shoppingList});

  @override
  ConsumerState<ListDetailScreenMobile> createState() =>
      _ListDetailScreenMobileState();
}

class _ListDetailScreenMobileState
    extends ConsumerState<ListDetailScreenMobile> {
  final TextEditingController _productController = TextEditingController();

  @override
  void dispose() {
    _productController.dispose();
    super.dispose();
  }

  void _addProductAndCategorize() {
    final productName = _productController.text.trim();
    if (productName.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          buildAppSnackBar(
            message: 'Please enter a product name',
            isError: true,
            context: context,
          ),
        );
      }
      return;
    }

    // Clear input immediately
    _productController.clear();

    final key = '${widget.shoppingList.id}_$productName';

    // Start background categorization (no await, completely in background)
    ref
        .read(backgroundProductCategorizationProvider.notifier)
        .startBackgroundCategorization(
          id: key,
          productName: productName,
          categories: ListDetailScreenMobile.mockCategories,
        );
  }

  void _searchProduct() async {
    final productName = _productController.text.trim();
    if (productName.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          buildAppSnackBar(
            message: 'Please enter a product name',
            isError: true,
            context: context,
          ),
        );
      }
      return;
    }

    // Start background categorization
    ref
        .read(backgroundProductCategorizationProvider.notifier)
        .startBackgroundCategorization(
          id: '${widget.shoppingList.id}_$productName',
          productName: productName,
          categories: ListDetailScreenMobile.mockCategories,
        );

    // Clear the input field for next search
    _productController.clear();
  }

  void _addProductToList(
    ShoppingList shoppingList,
    String category,
    String productName,
  ) {
    final product = Product(name: productName);

    final categoryObj = ListDetailScreenMobile.mockCategories.firstWhere(
      (cat) => cat.getName() == category,
      orElse: () => Category(name: 'uncategorized'),
    );

    final purchasedProduct = PurchasedProduct(
      listId: shoppingList.id,
      product: product,
      category: categoryObj,
      quantity: 1,
    );

    shoppingList.products ??= [];
    shoppingList.products!.add(purchasedProduct);
    ref.read(shoppingListsProvider.notifier).updateList(shoppingList);

    // Remove the product from the results list after adding it
    final key = '${widget.shoppingList.id}_$productName';
    ref.read(backgroundProductCategorizationProvider.notifier).clearCategorization(key);

    if (mounted) {
      _productController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final categorizations =
        ref.watch(backgroundProductCategorizationProvider);
    final shoppingList = ref.watch(shoppingListsProvider).maybeWhen(
          data: (lists) => lists.firstWhere(
            (list) => list.id == widget.shoppingList.id,
            orElse: () => widget.shoppingList,
          ),
          orElse: () => widget.shoppingList,
        );

    // Get all categorizations for this specific list, sorted by completion
    final listCategorizations = categorizations.entries
        .where((entry) =>
            entry.key.startsWith('${shoppingList.id}_') &&
            entry.value.isCompleted)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(shoppingList.getName()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Add Recipe Button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddRecipeScreen(
                        shoppingList: shoppingList,
                        availableCategories:
                            ListDetailScreenMobile.mockCategories,
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
              const SizedBox(height: 32),

              // Product Search Section
              Text(
                'Search Product',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              // Product Input Field
              TextField(
                controller: _productController,
                decoration: InputDecoration(
                  hintText: 'Enter product name...',
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onSubmitted: (_) => _searchProduct(),
              ),
              const SizedBox(height: 12),

              // Add to List Button - always enabled
              ElevatedButton.icon(
                onPressed: _addProductAndCategorize,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Enter product to be added'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),

              // Results Section
              if (listCategorizations.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Results',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
              ],

              // Expanded list of results
              Expanded(
                child: ListView.separated(
                  itemCount: listCategorizations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final entry = listCategorizations[index];
                    final categorization = entry.value;

                    return categorization.result.when(
                      loading: () => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colorScheme.outline),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Categorizing "${categorization.productName}"...',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      error: (error, _) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colorScheme.outline),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.error_outline,
                                    color: colorScheme.error, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    categorization.productName,
                                    style: textTheme.labelLarge?.copyWith(
                                      color: colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: () {
                                    ref
                                        .read(backgroundProductCategorizationProvider
                                            .notifier)
                                        .clearCategorization(entry.key);
                                  },
                                  tooltip: 'Remove',
                                  color: colorScheme.onErrorContainer,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Error categorizing product',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onErrorContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                      data: (category) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colorScheme.outline),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.check_circle,
                                    color: colorScheme.primary, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    categorization.productName,
                                    style: textTheme.labelLarge?.copyWith(
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: () {
                                    ref
                                        .read(backgroundProductCategorizationProvider
                                            .notifier)
                                        .clearCategorization(entry.key);
                                  },
                                  tooltip: 'Remove',
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Category: $category',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _addProductToList(
                                      shoppingList,
                                      category,
                                      categorization.productName,
                                    ),
                                icon: const Icon(Icons.add_shopping_cart, size: 18),
                                label: const Text('Add to List'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
