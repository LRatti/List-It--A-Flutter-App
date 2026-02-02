import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:collection/collection.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/providers/real_app_providers/supermarkets_notifier.dart';
import 'package:app_code/screens/lists/controllers/list_detail_controller.dart';
import 'package:app_code/screens/lists/add_recipe_screen_mobile.dart';
import 'package:app_code/screens/supermarket/supermarket_customization_screen.dart';
import 'package:app_code/services/product_search_service.dart';
import 'package:app_code/widgets/app_snackbar.dart';
import 'package:app_code/widgets/draggable_product_list.dart';
import 'package:app_code/utils/uncategorized_category_initializer.dart';
import 'package:riverpod/src/framework.dart';

/// Provider for the list detail controller
final listDetailControllerProvider = ChangeNotifierProvider.family<
    ListDetailController, ShoppingList>((ref, shoppingList) {
  return ListDetailController(shoppingList: shoppingList);
});

class ListDetailScreenMobile extends ConsumerStatefulWidget {
  final ShoppingList shoppingList;
  final bool isNewList;

  const ListDetailScreenMobile({
    super.key,
    required this.shoppingList,
    this.isNewList = false,
  });

  @override
  ConsumerState<ListDetailScreenMobile> createState() =>
      _ListDetailScreenMobileState();
}

class _ListDetailScreenMobileState
    extends ConsumerState<ListDetailScreenMobile> {
  late TextEditingController _nameController;
  late TextEditingController _productSearchController;
  final FocusNode _nameFieldFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.shoppingList.getName());
    _productSearchController = TextEditingController();
    
    // Initialize controller with favorite supermarket if new list
    if (widget.isNewList) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadFavoriteSupermarket();
      });
    }
  }

  Future<void> _loadFavoriteSupermarket() async {
    final controller = ref.read(listDetailControllerProvider(widget.shoppingList));
    final favorite = await ref.read(supermarketsProvider.notifier).getFavoriteSupermarket();
    
    if (favorite != null) {
      controller.updateSupermarket(favorite);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _productSearchController.dispose();
    _nameFieldFocusNode.dispose();
    super.dispose();
  }

  /// Handle back button - save changes before exiting
  Future<bool> _handleBack() async {
    final controller = ref.read(listDetailControllerProvider(widget.shoppingList));
    
    // Update list name from text field
    controller.updateListName(_nameController.text.trim());
    
    // If no changes, just go back
    if (!controller.hasChanges) {
      return true;
    }
    
    try {
      // Save all changes
      await controller.save();
      return true;
    } catch (e) {
      if (!mounted) return false;
      
      // Show error and ask user what to do
      final shouldDiscard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error Saving'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Failed to save changes:'),
              const SizedBox(height: 8),
              Text(
                e.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
              const SizedBox(height: 16),
              const Text('What would you like to do?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Stay and retry'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Discard changes'),
            ),
          ],
        ),
      );
      
      // If user chose to discard, allow navigation
      return shouldDiscard ?? false;
    }
  }

  /// Add product to the list
  Future<void> _addProduct() async {
    final productName = _productSearchController.text.trim();
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

    final controller = ref.read(listDetailControllerProvider(widget.shoppingList));
    final supermarket = controller.selectedSupermarket;

    if (supermarket == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          buildAppSnackBar(
            message: 'Please select a supermarket',
            isError: true,
            context: context,
          ),
        );
      }
      return;
    }

    // Clear input
    _productSearchController.clear();

    // Add to buffer zone
    controller.addToBuffer(productName);

    try {
      // Search and categorize
      final searchService = ref.read(productSearchServiceProvider);
      final result = await searchService.searchAndCategorize(
        productName: productName,
        supermarketId: supermarket.id,
        availableCategories: supermarket.getCategories(),
      );

      // Remove from buffer
      controller.removeFromBuffer(productName);

      // Add to list
      controller.addProduct(result.product, result.category);
      
    } catch (e) {
      // Update buffer with error
      controller.updateBufferProduct(
        productName,
        isLoading: false,
        error: e.toString(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          buildAppSnackBar(
            message: 'Error adding product: ${e.toString()}',
            isError: true,
            context: context,
          ),
        );
      }
    }
  }

  /// Delete shopping list
  Future<void> _deleteList() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(
          "Delete '${widget.shoppingList.getName()}'?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final controller = ref.read(listDetailControllerProvider(widget.shoppingList));
      try {
        await controller.deleteList();
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            buildAppSnackBar(
              message: 'Error deleting list: ${e.toString()}',
              isError: true,
              context: context,
            ),
          );
        }
      }
    }
  }

  /// Navigate to supermarket customization
  Future<void> _navigateToSupermarketCustomization(Supermarket? supermarket,
      {bool isNew = false}) async {
    final uncategorized =
        await UncategorizedCategoryInitializer.getUncategorized();

    final targetSupermarket = supermarket ??
        Supermarket(
          name: '',
          categories: [uncategorized],
        );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SupermarketCustomizationScreen(
          supermarket: targetSupermarket,
          isCreationMode: isNew,
        ),
      ),
    );

    // Refresh supermarkets and update controller
    ref.invalidate(supermarketsProvider);
    final controller = ref.read(listDetailControllerProvider(widget.shoppingList));
    final lastEdited = await ref.read(lastEditedSupermarketProvider.future);
    if (lastEdited != null) {
        controller.updateSupermarket(lastEdited);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(listDetailControllerProvider(widget.shoppingList));
    final supermarketsAsync = ref.watch(supermarketsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return WillPopScope(
      onWillPop: _handleBack,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: TextField(
            controller: _nameController,
            focusNode: _nameFieldFocusNode,
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'List name',
            ),
            onSubmitted: (value) {
              controller.updateListName(value.trim());
              _nameFieldFocusNode.unfocus();
            },
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _handleBack()) {
                if (mounted) Navigator.pop(context);
              }
            },
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Supermarket dropdown
              _buildSupermarketDropdown(supermarketsAsync, controller, colorScheme),

              // Product search
              _buildProductSearch(colorScheme),

              // Product list with categories
              Expanded(
                child: _buildProductList(controller, colorScheme, textTheme),
              ),

              // Bottom buttons - hidden when keyboard is visible
              if (MediaQuery.of(context).viewInsets.bottom == 0)
                _buildBottomButtons(colorScheme, controller),
            ],
          ),
        ),
      ),
    );
  }

  /// Build supermarket dropdown
  Widget _buildSupermarketDropdown(
    AsyncValue<List<Supermarket>> supermarketsAsync,
    ListDetailController controller,
    ColorScheme colorScheme,
  ) {
    return supermarketsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('Error loading supermarkets: $error'),
      ),
      data: (supermarkets) {
        final visibleSupermarkets = supermarkets
            .where((s) => s.isVisible)
            .fold<Map<String, Supermarket>>({}, (map, s) {
          map[s.id] = s;
          return map;
        }).values.toList();
        final selectedId = controller.selectedSupermarket?.id;
        final hasSelected = selectedId != null &&
            visibleSupermarkets.any((s) => s.id == selectedId);
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outline),
          ),
          child: Row(
            children: [
              const Icon(Icons.store),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: hasSelected ? selectedId : null,
                    isExpanded: true,
                    hint: const Text('Select supermarket'),
                    items: [
                      ...visibleSupermarkets.map((supermarket) {
                        return DropdownMenuItem<String>(
                          value: supermarket.id,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  supermarket.getName(),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit, size: 20, color: colorScheme.primary),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  _navigateToSupermarketCustomization(supermarket);
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        final selected = visibleSupermarkets.firstWhere(
                          (s) => s.id == newValue,
                        );
                        controller.updateSupermarket(selected);
                      }
                    },
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add, color: colorScheme.primary),
                onPressed: () {
                  _navigateToSupermarketCustomization(null, isNew: true);
                },
                tooltip: 'New supermarket',
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build product search field
  Widget _buildProductSearch(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _productSearchController,
              decoration: InputDecoration(
                hintText: 'Enter product name...',
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onSubmitted: (_) => _addProduct(),
            ),
          ),
        ],
      ),
    );
  }

  /// Build product list with categories
  Widget _buildProductList(
    ListDetailController controller,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final productsByCategory = controller.getProductsByCategory();
    final bufferProducts = controller.bufferProducts;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      children: [
        // Buffer zone (products being categorized)
        if (bufferProducts.isNotEmpty) ...[
          ...bufferProducts.entries.map((entry) {
            final buffer = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  if (buffer.isLoading)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    )
                  else if (buffer.error != null)
                    Icon(Icons.error_outline, color: colorScheme.error, size: 20)
                  else
                    Icon(Icons.check_circle, color: colorScheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      buffer.name,
                      style: textTheme.bodyMedium?.copyWith(
                        color: buffer.error != null
                            ? colorScheme.error
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          const Divider(height: 24),
        ],

        // Categorized products with drag-and-drop
        DraggableProductList(
          productsByCategory: productsByCategory,
          onProductMoved: (product, newCategory) {
            controller.moveProductToCategory(product, newCategory);
          },
          onProductRemoved: (product) {
            controller.removeProduct(product);
          },
          onProductRenamed: (product, newName) {
            product.product.setName(newName);
            controller.updateProduct(product);
          },
        ),
      ],
    );
  }

  /// Build bottom action buttons
  Widget _buildBottomButtons(ColorScheme colorScheme, ListDetailController controller) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Delete button
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: _deleteList,
                color: colorScheme.error,
                iconSize: 28,
              ),
            ],
          ),
          // Add Recipe button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddRecipeScreen(
                    shoppingList: widget.shoppingList,
                    availableCategories: controller.selectedSupermarket?.getCategories() ?? [],
                  ),
                ),
              );
            },
            icon: const Icon(Icons.restaurant_menu),
            label: const Text('Add Recipe'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.secondaryContainer,
              foregroundColor: colorScheme.onSecondaryContainer,
            ),
          ),
          // Register button
          ElevatedButton(
            onPressed: () {
              // TODO: Implement register flow
              ScaffoldMessenger.of(context).showSnackBar(
                buildAppSnackBar(
                  message: 'Register feature coming soon',
                  isError: false,
                  context: context,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            child: const Text('Register'),
          ),
        ],
      ),
    );
  }
}
