import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/providers/real_app_providers/supermarkets_notifier.dart';
import 'package:app_code/screens/supermarket/category_selection_screen.dart';
import 'package:app_code/screens/supermarket/category_editing_screen.dart';
import 'package:app_code/widgets/app_snackbar.dart';
import 'package:app_code/utils/uncategorized_category_utils.dart';
import 'package:app_code/utils/uncategorized_category_initializer.dart';

class SupermarketCustomizationScreen extends ConsumerStatefulWidget {
  final Supermarket supermarket;
  final bool isCreationMode;

  const SupermarketCustomizationScreen({
    super.key,
    required this.supermarket,
    this.isCreationMode = false,
  });

  @override
  ConsumerState<SupermarketCustomizationScreen> createState() =>
      _SupermarketCustomizationScreenState();
}

class _SupermarketCustomizationScreenState
    extends ConsumerState<SupermarketCustomizationScreen> {
  late TextEditingController _nameController;
  late List<Category> _categories;
  int? _draggingIndex;
  late bool _isFavorite;
  late bool _initialIsFavorite;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.supermarket.getName());
    _categories = List.from(widget.supermarket.getCategories());
    _isFavorite = widget.supermarket.isFavorite;
    _initialIsFavorite = widget.supermarket.isFavorite;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool _isHiddenCategory(Category category) {
    return !category.isVisible ||
        UncategorizedCategoryUtils.isUncategorized(category);
  }

  List<Category> _visibleCategories() {
    return _categories.where((cat) => !_isHiddenCategory(cat)).toList();
  }

  /// Save the supermarket with updated name and categories
  Future<void> _saveSupermarket() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        buildAppSnackBar(
          message: 'Supermarket name cannot be empty',
          isError: true,
          context: context,
        ),
      );
      return;
    }

    final uncategorized =
        await UncategorizedCategoryInitializer.getUncategorized();

    if (!_categories.any((cat) => cat.id == uncategorized.id)) {
      _categories.insert(0, uncategorized);
    }

    widget.supermarket.setName(name);
    widget.supermarket.setCategories(_categories);
    widget.supermarket.isFavorite = _isFavorite;

    try {
      final notifier = ref.read(supermarketsProvider.notifier);

      if (widget.isCreationMode) {
        await notifier.addSupermarket(widget.supermarket);
        if (_isFavorite) {
          await notifier.setFavoriteSupermarket(widget.supermarket.id);
        }
      } else {
        await notifier.updateSupermarket(widget.supermarket);

        if (_isFavorite) {
          await notifier.setFavoriteSupermarket(widget.supermarket.id);
        } else if (_initialIsFavorite) {
          await notifier.clearFavoriteSupermarket(widget.supermarket.id);
        }
      }

      if (mounted) {
        Navigator.pop(context, widget.supermarket);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          buildAppSnackBar(
            message: 'Error saving supermarket: ${e.toString()}',
            isError: true,
            context: context,
          ),
        );
      }
    }
  }

  /// Delete a category from the supermarket
  void _deleteCategory(Category category) {
    setState(() {
      _categories.removeWhere((cat) => cat.id == category.id);
    });
  }

  /// Reorder categories (called after drag)
  void _onReorderCategory(int oldIndex, int newIndex) {
    final visible = _visibleCategories();

    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }

      final category = visible.removeAt(oldIndex);
      visible.insert(newIndex, category);

      final hidden = _categories.where(_isHiddenCategory).toList();
      _categories = [...hidden, ...visible];
    });
  }

  /// Navigate to category selection/addition screen
  void _navigateToCategorySelection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategorySelectionScreen(
          supermarketId: widget.supermarket.id,
          currentCategories: _categories,
          onCategoriesSelected: (newCategories) {
            setState(() {
              _categories = List.from(newCategories);
            });
          },
        ),
      ),
    );
  }

  /// Navigate to category editing screen to edit an existing category
  void _navigateToCategoryEditing(Category category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryEditingScreen(categoryToEdit: category),
      ),
    );
  }

  /// Delete or cancel the supermarket
  /// In creation mode, simply cancel without saving
  /// In edit mode, mark as non-visible after confirmation
  Future<void> _deleteOrCancel() async {
    if (widget.isCreationMode) {
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(
          "Want to delete '${widget.supermarket.getName()}'?",
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
      try {
        await ref
            .read(supermarketsProvider.notifier)
            .deleteSupermarket(widget.supermarket.id);

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            buildAppSnackBar(
              message: 'Error deleting supermarket: ${e.toString()}',
              isError: true,
              context: context,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleCategories = _visibleCategories();

    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            widget.isCreationMode
                ? 'Create Supermarket'
                : 'Customize Supermarket',
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (mounted) Navigator.pop(context);
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveSupermarket,
              tooltip: 'Save supermarket',
            ),
          ],
          elevation: 0,
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        ),
        body: Column(
          children: [
            // Name editing section
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Enter Supermarket Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.store),
                ),
              ),
            ),
            // Categories list section
            Expanded(
              child: visibleCategories.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No categories yet',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add categories to this supermarket',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    )
                  : ReorderableListView(
                      onReorder: _onReorderCategory,
                      children: [
                        for (int i = 0; i < visibleCategories.length; i++)
                          _buildCategoryTile(i, visibleCategories[i]),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  // Delete button (or cancel in creation mode)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _deleteOrCancel,
                    color: Theme.of(context).colorScheme.error,
                    iconSize: 28,
                    tooltip: widget.isCreationMode
                        ? 'Cancel supermarket creation'
                        : 'Delete supermarket',
                  ),
                  const SizedBox(width: 8),
                  // Add categories button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _navigateToCategorySelection,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                      ),
                      child: const Text('Add Categories'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Favorite/Star button
                  IconButton(
                    icon: Icon(
                      _isFavorite
                          ? Icons.star
                          : Icons.star_outline,
                    ),
                    onPressed: () {
                      // Only toggle locally; persist on save
                      setState(() {
                        _isFavorite = !_isFavorite;
                      });
                    },
                    color: _isFavorite
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                    iconSize: 28,
                    tooltip: _isFavorite
                        ? 'Remove from favorites'
                        : 'Set as favorite',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build individual category tile with delete, edit, and drag handles
  Widget _buildCategoryTile(int index, Category category) {
    return Card(
      key: ValueKey(category.id),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        // Tap to edit category
        onTap: () => _navigateToCategoryEditing(category),
        // Delete button on the left
        leading: IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: () => _deleteCategory(category),
          color: Theme.of(context).colorScheme.error,
          tooltip: 'Remove category',
        ),
        // Category name in the center
        title: Text(
          category.getName(),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        // Drag handle and edit button on the right
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Edit button
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                _navigateToCategoryEditing(category);
              },
              color: Theme.of(context).colorScheme.primary,
              tooltip: 'Edit category',
            ),
            // Drag handle
            ReorderableDragStartListener(
              index: index,
              child: Icon(
                Icons.drag_handle,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
