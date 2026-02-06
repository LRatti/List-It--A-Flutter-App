import 'package:app_code/providers/real_app_providers/navigation_provider.dart';
import 'package:app_code/providers/real_app_providers/shopping_list/shopping_lists_notifier.dart';
import 'package:app_code/utils/screen_size_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/providers/real_app_providers/supermarket/supermarkets_notifier.dart';
import 'package:app_code/screens/lists/controllers/list_detail_controller.dart';
import 'package:app_code/screens/lists/add_recipe_screen_mobile.dart';
import 'package:app_code/screens/lists/register-list/register_shopping_list_screen_mobile.dart';
import 'package:app_code/screens/supermarket/supermarket_customization_screen.dart';
import 'package:app_code/services/product_search_service.dart';
import 'package:app_code/widgets/app_snackbar.dart';
import 'package:app_code/widgets/draggable_product_list.dart';
import 'package:app_code/utils/uncategorized_category_initializer.dart';
import 'package:riverpod/src/framework.dart';
import 'package:app_code/providers/real_app_providers/register_shopping_list_navigation_provider.dart';

/// Provider for the list detail controller
final listDetailControllerProvider =
    ChangeNotifierProvider.family<ListDetailController, ShoppingList>((
      ref,
      shoppingList,
    ) {
      return ListDetailController(shoppingList: shoppingList, ref: ref);
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
  final FocusNode _productSearchFocusNode = FocusNode();
  final ScrollController _listScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.shoppingList.getName(),
    );
    _productSearchController = TextEditingController();

    // Initialize controller with favorite supermarket if new list
    if (widget.isNewList) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadFavoriteSupermarket();
      });
    } else if (widget.shoppingList.getSupermarket() == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _clearSupermarketSelection();
      });
    }
  }

  Future<void> _loadFavoriteSupermarket() async {
    final controller = ref.read(
      listDetailControllerProvider(widget.shoppingList),
    );
    final favorite = await ref
        .read(supermarketsProvider.notifier)
        .getFavoriteSupermarket();

    if (favorite != null) {
      controller.updateSupermarket(favorite);
    }
  }

  Future<void> _clearSupermarketSelection() async {
    final controller = ref.read(
      listDetailControllerProvider(widget.shoppingList),
    );
    final uncategorized =
        await UncategorizedCategoryInitializer.getUncategorized();
    await controller.clearSupermarket(uncategorized: uncategorized);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _productSearchController.dispose();
    _nameFieldFocusNode.dispose();
    _productSearchFocusNode.dispose();
    _listScrollController.dispose();
    super.dispose();
  }

  /// Handle back button - save changes before exiting
  Future<bool> _handleBack() async {
    final controller = ref.read(
      listDetailControllerProvider(widget.shoppingList),
    );

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
      return;
    }

    final controller = ref.read(
      listDetailControllerProvider(widget.shoppingList),
    );
    final supermarket = controller.selectedSupermarket;

    if (supermarket == null) {
      // No supermarket selected: place product in uncategorized
      _productSearchController.clear();
      final uncategorized =
          await UncategorizedCategoryInitializer.getUncategorized();
      final existing = await controller.searchExistingProduct(productName);
      final product = existing ?? Product(name: productName);
      controller.addProduct(product, uncategorized);
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
        content: Text("Delete '${widget.shoppingList.getName()}'?"),
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
      final controller = ref.read(
        listDetailControllerProvider(widget.shoppingList),
      );
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

  /// Handle cart button - navigate to register shopping list screen
  /// This decouples the screens by using push instead of awaiting the result.
  /// The register screen handles its own navigation back based on the source.
  /// Passes the shopping list ID to ensure the register screen fetches fresh data
  /// with all changes (including toggled products) from the database.
  Future<void> _handleCartButton() async {
    final controller = ref.read(
      listDetailControllerProvider(widget.shoppingList),
    );

    // Update list name from text field before saving
    controller.updateListName(_nameController.text.trim());

    try {
      // Save all current changes before navigating to register screen
      await controller.save();
      
      if (mounted) {
        // Set the navigation source to indicate this came from list_detail
        ref.read(registerShoppingListSourceProvider.notifier).state =
            RegisterShoppingListSource.listDetail;
        
        // Navigate to register shopping list screen without awaiting
        // This decouples the navigation - register screen handles its own navigation
        // Pass only the ID - the register screen will fetch fresh data from the database
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RegisterShoppingListScreenMobile(
              shoppingListId: widget.shoppingList.id,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        buildAppSnackBar(
          message: 'Error: ${e.toString()}',
          isError: true,
          context: context,
        ),
      );
    }
  }

  /// Show supermarket selection popup menu
  Future<void> _showSupermarketSelectionMenu(
    List<Supermarket> visibleSupermarkets,
    ListDetailController controller,
    ColorScheme colorScheme,
  ) async {
    final selectedId = controller.selectedSupermarket?.id;
    final hasSelected =
        selectedId != null &&
        visibleSupermarkets.any((s) => s.id == selectedId);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: colorScheme.surface,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select Supermarket',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: colorScheme.onSurface,
                            ),
                            onPressed: () => Navigator.pop(context),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        visibleSupermarkets.isEmpty
                            ? 'No supermarkets yet. Create one to get started.'
                            : '${visibleSupermarkets.length} supermarket${visibleSupermarkets.length != 1 ? 's' : ''} available',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Scrollable list
                Expanded(
                  child: visibleSupermarkets.isEmpty
                      ? _buildEmptyState(colorScheme)
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          itemCount: visibleSupermarkets.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            indent: 24,
                            endIndent: 24,
                            color: colorScheme.outlineVariant.withOpacity(0.3),
                          ),
                          itemBuilder: (context, index) {
                            final supermarket = visibleSupermarkets[index];
                            final isSelected = selectedId == supermarket.id;
                            return _buildSupermarketTile(
                              supermarket,
                              isSelected,
                              controller,
                              colorScheme,
                            );
                          },
                        ),
                ),
                // Footer with create button
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.outlineVariant.withOpacity(0.2),
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _navigateToSupermarketCustomization(
                                null,
                                isNew: true,
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Create New'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                              ),
                            ),
                          ),
                        ),
                        if (hasSelected) ...[
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _clearSupermarketSelection();
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.clear),
                              label: const Text('Clear'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colorScheme.primary,
                                side: BorderSide(color: colorScheme.primary),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Build supermarket tile for the selection menu
  Widget _buildSupermarketTile(
    Supermarket supermarket,
    bool isSelected,
    ListDetailController controller,
    ColorScheme colorScheme,
  ) {
    return Container(
      color: isSelected ? colorScheme.primaryContainer.withOpacity(0.4) : null,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24.0,
          vertical: 4.0,
        ),
        leading: isSelected
            ? Icon(Icons.check_circle, color: colorScheme.primary, size: 24)
            : Icon(
                Icons.circle_outlined,
                color: colorScheme.outlineVariant,
                size: 24,
              ),
        title: Text(
          supermarket.getName(),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? colorScheme.primary : colorScheme.onSurface,
          ),
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  color: colorScheme.primary,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  Navigator.pop(context);
                  _navigateToSupermarketCustomization(supermarket);
                },
                tooltip: 'Edit supermarket',
              ),
            ),
          ],
        ),
        onTap: () {
          controller.updateSupermarket(supermarket);
          Navigator.pop(context);
        },
      ),
    );
  }

  /// Build empty state widget for supermarket selection menu
  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store_outlined,
            size: 48,
            color: colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No Supermarkets Yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a supermarket to organize\nyour shopping categories',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Navigate to supermarket customization
  Future<void> _navigateToSupermarketCustomization(
    Supermarket? supermarket, {
    bool isNew = false,
  }) async {
    final uncategorized =
        await UncategorizedCategoryInitializer.getUncategorized();

    final targetSupermarket =
        supermarket ?? Supermarket(name: '', categories: [uncategorized]);

    final updatedSupermarket = await Navigator.push<Supermarket?>(
      context,
      MaterialPageRoute(
        builder: (_) => SupermarketCustomizationScreen(
          supermarket: targetSupermarket,
          isCreationMode: isNew,
        ),
      ),
    );

    if (mounted) {
      FocusScope.of(context).unfocus();
    }

    // Refresh supermarkets list to reflect any changes
    ref.invalidate(supermarketsProvider);

    // Only update the selected supermarket if changes were saved
    // If user cancelled (updatedSupermarket == null), keep the current selection
    if (updatedSupermarket != null) {
      // CRITICAL: Wait for supermarketsProvider to finish refreshing
      // This ensures the newly created/edited supermarket is loaded
      // before we try to select it in the controller
      await ref.read(supermarketsProvider.future);

      if (mounted) {
        final controller = ref.read(
          listDetailControllerProvider(widget.shoppingList),
        );
        controller.updateSupermarket(updatedSupermarket);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(
      listDetailControllerProvider(widget.shoppingList),
    );
    final supermarketsAsync = ref.watch(supermarketsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isMobile = ScreenSize.isMobile(context);

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
                if (mounted) {
                    // Fallback for mobile: navigate to home
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/home',
                      (route) => false, // Keep the home/root route
                      arguments: HomeTab.lists,
                    );
                }
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.shopping_cart),
              tooltip: 'Register list',
              onPressed: _handleCartButton,
            ),
          ],
          elevation: 0,
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Supermarket dropdown
              _buildSupermarketDropdown(
                supermarketsAsync,
                controller,
                colorScheme,
              ),

              // Product list with categories
              Expanded(
                child: _buildProductList(controller, colorScheme, textTheme),
              ),

              // Product search and action buttons (like WhatsApp)
              _buildSearchAndActions(colorScheme, controller, isMobile),
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
      loading: () => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: const LinearProgressIndicator(),
      ),
      error: (error, _) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.error),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: colorScheme.error, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Error loading supermarkets',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
      data: (supermarkets) {
        final visibleSupermarkets = supermarkets
            .where((s) => s.isVisible)
            .fold<Map<String, Supermarket>>({}, (map, s) {
              map[s.id] = s;
              return map;
            })
            .values
            .toList();
        final selectedId = controller.selectedSupermarket?.id;
        final hasSelected =
            selectedId != null &&
            visibleSupermarkets.any((s) => s.id == selectedId);
        final selectedSupermarket = hasSelected
            ? visibleSupermarkets.firstWhere((s) => s.id == selectedId)
            : null;

        if (selectedId != null && !hasSelected) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;
            await _clearSupermarketSelection();
          });
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              width: hasSelected ? 2 : 1,
            ),
            boxShadow: hasSelected
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _showSupermarketSelectionMenu(
                  visibleSupermarkets,
                  controller,
                  colorScheme,
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 12.0,
                ),
                child: Row(
                  children: [
                    // Leading store icon
                    Icon(
                      Icons.store,
                      color: hasSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    // Supermarket name (expanded)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            selectedSupermarket?.getName() ??
                                (visibleSupermarkets.isEmpty
                                    ? 'Create a supermarket'
                                    : 'Select supermarket'),
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: hasSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: hasSelected
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurfaceVariant,
                                ),
                          ),
                          if (selectedSupermarket != null &&
                              selectedSupermarket.getCategories().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Text(
                                '${selectedSupermarket.getCategories().length} categories',
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Dropdown arrow indicator
                    Icon(
                      Icons.unfold_more,
                      color: hasSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build bottom action bar with search and action buttons
  Widget _buildSearchAndActions(
    ColorScheme colorScheme,
    ListDetailController controller,
    bool isMobile,
  ) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
        child: Row(
          children: [
            // Add Recipe button
            IconButton(
              icon: const Icon(Icons.restaurant_menu),
              tooltip: 'Add Recipe',
              color: colorScheme.primary,
              onPressed: () async {
                if (await _handleBack()) {
                  if (isMobile) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddRecipeScreen(
                          shoppingList: widget.shoppingList,
                          availableCategories:
                              controller.selectedSupermarket?.getCategories() ??
                              [],
                        ),
                      ),
                    );
                  } else {
                    _showAddRecipeSidePanel(controller, colorScheme);
                  }
                }
              },
            ),
            // Search input
            Expanded(
              child: TextField(
                controller: _productSearchController,
                focusNode: _productSearchFocusNode,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: 'Add product...',
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
                onSubmitted: (_) => _addProduct(),
              ),
            ),
            const SizedBox(width: 4),
            // Send/Add button
            IconButton(
              icon: const Icon(Icons.send),
              tooltip: 'Add product',
              color: colorScheme.primary,
              onPressed: _addProduct,
            ),
            // Delete list button
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete list',
              color: colorScheme.error,
              onPressed: _deleteList,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddRecipeSidePanel(
    ListDetailController controller,
    ColorScheme colorScheme,
  ) async {
    final width = MediaQuery.of(context).size.width;

    return showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Add Recipe',
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.25),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: width * 0.5,
            child: Material(
              color: colorScheme.surface,
              elevation: 8,
              child: AddRecipeScreen(
                shoppingList: widget.shoppingList,
                availableCategories:
                    controller.selectedSupermarket?.getCategories() ?? [],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
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
      controller: _listScrollController,
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
                    Icon(
                      Icons.error_outline,
                      color: colorScheme.error,
                      size: 20,
                    )
                  else
                    Icon(
                      Icons.check_circle,
                      color: colorScheme.primary,
                      size: 20,
                    ),
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
          scrollController: _listScrollController,
          onProductMoved: (product, newCategory) {
            controller.moveProductToCategory(product, newCategory);
          },
          onProductRemoved: (product) {
            controller.removeProduct(product);
          },
          onProductRenamed: (product, newName) async {
            // Use the controller's method to properly handle product name updates
            // This ensures that renaming a product in one list does not affect
            // purchased products in other lists, even if they originally had the same name
            await controller.updatePurchasedProductName(product, newName);
          },
          onProductBoughtToggled: (product, isBought) {
            // Update the bought status of the product
            controller.toggleProductBought(product, isBought);
          },
        ),
      ],
    );
  }
}
