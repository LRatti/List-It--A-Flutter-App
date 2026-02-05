import 'package:app_code/providers/real_app_providers/navigation_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/models/receipt_match.dart';
import 'package:app_code/screens/lists/register-list/register_shopping_list_controller.dart';
import 'package:app_code/screens/lists/register-list/register_shopping_list_controller_provider.dart';
import 'package:app_code/screens/lists/list_detail_screen_mobile.dart';
import 'package:app_code/screens/lists/lists_screen_mobile.dart';
import 'package:app_code/screens/history/history_screen_mobile.dart';
import 'package:app_code/widgets/app_snackbar.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:app_code/providers/real_app_providers/register_shopping_list_navigation_provider.dart';
import 'package:app_code/screens/camera/receipt_camera_screen.dart';
import 'package:app_code/providers/real_app_providers/shopping_list/shopping_lists_notifier.dart';

class RegisterShoppingListScreenMobile extends ConsumerStatefulWidget {
  final String shoppingListId;

  const RegisterShoppingListScreenMobile({
    super.key,
    required this.shoppingListId,
  });

  @override
  ConsumerState<RegisterShoppingListScreenMobile> createState() =>
      _RegisterShoppingListScreenMobileState();
}

class _RegisterShoppingListScreenMobileState
    extends ConsumerState<RegisterShoppingListScreenMobile> {
  final Map<String, TextEditingController> _quantityControllers = {};
  final Map<String, TextEditingController> _priceControllers = {};

  @override
  void initState() {
    super.initState();
    // Text controllers will be initialized in build() once we have the shopping list
  }

  @override
  void dispose() {
    // Clean up all text controllers
    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }
    for (var controller in _priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Handle back button - navigate back to the source screen (history or list_detail)
  /// Saves any quantity/price changes before navigating back
  Future<void> _handleBack(ShoppingList shoppingList) async {
    final controller = ref.read(
      registerShoppingListControllerProvider(shoppingList),
    );
    final source = ref.read(registerShoppingListSourceProvider);

    try {
      // Persist any quantity/price changes
      await controller.persistChanges();
      
      if (mounted) {
        // Clear the navigation source
        ref.read(registerShoppingListSourceProvider.notifier).state = null;
        
        // Navigate back to the previous screen
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        buildAppSnackBar(
          message: 'Error saving changes: ${e.toString()}',
          isError: true,
          context: context,
        ),
      );
    }
  }

  /// Handle check button - register the list and navigate to history
  Future<void> _handleRegister(ShoppingList shoppingList) async {
    final controller = ref.read(
      registerShoppingListControllerProvider(shoppingList),
    );

    try {
      // Register the list (sets is_registered=true, auto-fills quantities)
      await controller.registerList();
      
      if (mounted) {
        // Clear the navigation source
        ref.read(registerShoppingListSourceProvider.notifier).state = null;
        
        // Pop to get back to the source screen, then navigate to history
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (route) => false, // Keep the home/root route
          arguments: HomeTab.history,
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        buildAppSnackBar(
          message: 'Error registering list: ${e.toString()}',
          isError: true,
          context: context,
        ),
      );
    }
  }

  /// Handle pencil button - navigate to lists_screen for further editing
  /// This allows the user to:
  /// - Go back to lists_screen
  /// - Edit or navigate to other screens from there
  Future<void> _handleOpenForEditing(ShoppingList shoppingList) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Continue Editing?'),
        content: const Text(
          'You can add more products or check additional items.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Continue'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final controller = ref.read(
      registerShoppingListControllerProvider(shoppingList),
    );

    try {
      // Unregister the list and persist changes
      await controller.unregisterList();
      
      if (mounted) {
        // Clear the navigation source
        ref.read(registerShoppingListSourceProvider.notifier).state = null;
        
        // Navigate to lists_screen (replaces the navigation stack to avoid stacking)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => ListDetailScreenMobile(shoppingList: shoppingList),
          ),
          (route) => route.isFirst, // Keep the home/root route
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        buildAppSnackBar(
          message: 'Error opening for editing: ${e.toString()}',
          isError: true,
          context: context,
        ),
      );
    }
  }

  /// Handle camera button - persist changes and navigate to camera screen
  Future<void> _handleCamera(ShoppingList shoppingList) async {
    final controller = ref.read(
      registerShoppingListControllerProvider(shoppingList),
    );

    try {
      // Persist any quantity/price changes before navigating to camera
      await controller.persistChanges();
      
      if (mounted) {
        // Navigate to camera screen
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReceiptCameraScreen(shoppingList: shoppingList),
          ),
        );

        if (result is List) {
          _applyReceiptUpdates(result, shoppingList);
        }
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        buildAppSnackBar(
          message: 'Error saving changes: ${e.toString()}',
          isError: true,
          context: context,
        ),
      );
    }
  }

  void _applyReceiptUpdates(List<dynamic> result, ShoppingList shoppingList) {
    final controller = ref.read(
      registerShoppingListControllerProvider(shoppingList),
    );

    final boughtProducts = controller.getBoughtProducts();
    final nameToId = {
      for (final product in boughtProducts)
        product.product.getName().toLowerCase().trim(): product.id,
    };

    for (final item in result) {
      if (item is! ReceiptMatch) continue;

      final productId = item.productId ??
          nameToId[item.productName?.toLowerCase().trim() ?? ''];
      if (productId == null) continue;

      final quantityController = _quantityControllers[productId];
      if (quantityController != null) {
        quantityController.text = item.quantity.toString();
      }

      final priceController = _priceControllers[productId];
      if (priceController != null) {
        priceController.text = item.price.toStringAsFixed(2);
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Fetch fresh shopping list data from the database
    final shoppingListAsync = ref.watch(shoppingListProvider(widget.shoppingListId));
    
    return shoppingListAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Text('Error loading shopping list: $error'),
        ),
      ),
      data: (shoppingList) {
        // Initialize text controllers only once when we have the shopping list
        if (_quantityControllers.isEmpty && _priceControllers.isEmpty) {
          final controller = ref.read(
            registerShoppingListControllerProvider(shoppingList),
          );
          final boughtProducts = controller.getBoughtProducts();
          
          for (final product in boughtProducts) {
            _quantityControllers[product.id] = TextEditingController(
              text: controller.getQuantity(product.id).toString(),
            );
            _priceControllers[product.id] = TextEditingController(
              text: controller.getPrice(product.id).toStringAsFixed(2),
            );
          }
        }

        final controller = ref.watch(
          registerShoppingListControllerProvider(shoppingList),
        );
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        final boughtProducts = controller.getBoughtProducts();

        return WillPopScope(
          onWillPop: () async {
            await _handleBack(shoppingList);
            return false;
          },
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              title: Text(
                controller.listName,
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _handleBack(shoppingList),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.check),
                  tooltip: 'Register list',
                  onPressed: () => _handleRegister(shoppingList),
                ),
              ],
              elevation: 0,
            ),
            body: SafeArea(
              child: Column(
                children: [
              // Supermarket display (fixed, non-interactive)
              _buildSupermarketDisplay(shoppingList, controller, colorScheme, textTheme),

              // Bought products list
              Expanded(
                child: _buildBoughtProductsList(
                  controller,
                  boughtProducts,
                  colorScheme,
                  textTheme,
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Camera button
            FloatingActionButton(
              heroTag: 'camera_btn',
              mini: true,
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              onPressed: () => _handleCamera(shoppingList),
              tooltip: 'Scan receipt',
              child: const Icon(Icons.camera_alt),
            ),
            const SizedBox(height: 12),
            // Pencil button (open for editing)
            FloatingActionButton(
              heroTag: 'pencil_btn',
              mini: true,
              backgroundColor: colorScheme.secondaryContainer,
              foregroundColor: colorScheme.onSecondaryContainer,
              onPressed: () => _handleOpenForEditing(shoppingList),
              tooltip: 'Continue editing',
              child: const Icon(Icons.edit),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          ),
        );
      },
    );
  }

  /// Build the supermarket display (fixed, non-interactive)
  Widget _buildSupermarketDisplay(
    ShoppingList shoppingList,
    RegisterShoppingListController controller,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final supermarket = shoppingList.getSupermarket();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.store,
            color: colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Supermarket',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  supermarket?.getName() ?? 'Not selected',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build the list of bought products with quantity and price fields
  Widget _buildBoughtProductsList(
    RegisterShoppingListController controller,
    List<dynamic> boughtProducts,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    if (boughtProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 48,
              color: colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No checked items',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check items in the shopping list\nto register them here',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // Group products by category
    final productsByCategory = <String, List<dynamic>>{};
    for (final product in boughtProducts) {
      final categoryId = product.category.id;
      productsByCategory.putIfAbsent(categoryId, () => []);
      productsByCategory[categoryId]!.add(product);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      children: [
        ...productsByCategory.entries.expand((entry) {
          final products = entry.value;
          return [
            // Category header
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
              child: Text(
                products.first.category.getName(),
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Products in this category
            ...products.map((product) => _buildProductTile(
              product,
              controller,
              colorScheme,
              textTheme,
            )),
          ];
        }).toList(),
        const SizedBox(height: 24), // Bottom spacing for floating action buttons
      ],
    );
  }

  /// Build a single product tile with quantity and price fields
  Widget _buildProductTile(
    dynamic product,
    RegisterShoppingListController controller,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final quantityController = _quantityControllers[product.id]!;
    final priceController = _priceControllers[product.id];

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product name
          Text(
            product.product.getName(),
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          // Quantity and Price fields
          Row(
            children: [
              // Quantity field
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quantity',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8.0,
                        ),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        final quantity = int.tryParse(value) ?? 0;
                        controller.updateQuantity(product.id, quantity);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Price field
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8.0,
                        ),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        final price = double.tryParse(value) ?? 0.0;
                        controller.updatePrice(product.id, price);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
