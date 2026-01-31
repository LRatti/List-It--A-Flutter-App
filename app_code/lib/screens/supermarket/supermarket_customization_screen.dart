import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/providers/real_app_providers/supermarkets_notifier.dart';
import 'package:app_code/screens/supermarket/category_selection_screen.dart';
import 'package:app_code/screens/supermarket/category_editing_screen.dart';
import 'package:app_code/widgets/app_snackbar.dart';

class SupermarketCustomizationScreen extends ConsumerStatefulWidget {
  final Supermarket supermarket;

  const SupermarketCustomizationScreen({super.key, required this.supermarket});

  @override
  ConsumerState<SupermarketCustomizationScreen> createState() =>
      _SupermarketCustomizationScreenState();
}

class _SupermarketCustomizationScreenState
    extends ConsumerState<SupermarketCustomizationScreen> {
  late TextEditingController _nameController;
  late List<Category> _categories;
  int? _draggingIndex;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.supermarket.getName());
    _categories = List.from(widget.supermarket.getCategories());
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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

    widget.supermarket.setName(name);
    widget.supermarket.setCategories(_categories);

    try {
      await ref
          .read(supermarketsProvider.notifier)
          .updateSupermarket(widget.supermarket);

      if (mounted) {
        Navigator.pop(context);
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
  void _deleteCategory(int index) {
    setState(() {
      _categories.removeAt(index);
    });
  }

  /// Reorder categories (called after drag)
  void _onReorderCategory(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final category = _categories.removeAt(oldIndex);
      _categories.insert(newIndex, category);
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

  /// Delete the supermarket (mark as non-visible)
  Future<void> _deleteSupermarket() async {
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
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Customize Supermarket'),
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
                  labelText: 'Supermarket Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.store),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Delete button
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _deleteSupermarket,
                    color: Theme.of(context).colorScheme.error,
                    iconSize: 28,
                    tooltip: 'Delete supermarket',
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
                ],
              ),
            ),
            // Categories list section
            Expanded(
              child: _categories.isEmpty
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
                        for (int i = 0; i < _categories.length; i++)
                          _buildCategoryTile(i, _categories[i]),
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
          onPressed: () => _deleteCategory(index),
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
