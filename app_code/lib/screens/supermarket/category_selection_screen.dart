import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/providers/real_app_providers/categories_notifier.dart';
import 'package:app_code/screens/supermarket/category_editing_screen.dart';
import 'package:app_code/widgets/app_snackbar.dart';

class CategorySelectionScreen extends ConsumerStatefulWidget {
  final String supermarketId;
  final List<Category> currentCategories;
  final Function(List<Category>) onCategoriesSelected;

  const CategorySelectionScreen({
    super.key,
    required this.supermarketId,
    required this.currentCategories,
    required this.onCategoriesSelected,
  });

  @override
  ConsumerState<CategorySelectionScreen> createState() =>
      _CategorySelectionScreenState();
}

class _CategorySelectionScreenState
    extends ConsumerState<CategorySelectionScreen> {
  late Set<String> _selectedCategoryIds;
  late List<Category> _availableCategories;

  @override
  void initState() {
    super.initState();
    _selectedCategoryIds = {};
    _availableCategories = [];
  }

  /// Load available categories (not in current supermarket)
  Future<void> _loadAvailableCategories() async {
    // Invalidate the provider to force a fresh fetch of categories
    ref.invalidate(visibleCategoriesProvider);
    
    final allCategories =
        await ref.read(visibleCategoriesProvider.future);
    
    // Filter out categories already in this supermarket
    final currentIds =
        widget.currentCategories.map((c) => c.id).toSet();
    
    setState(() {
      _availableCategories = allCategories
          .where((cat) => !currentIds.contains(cat.id))
          .toList()
        ..sort((a, b) => a.getName().compareTo(b.getName())); // Sort alphabetically
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAvailableCategories();
  }

  /// Add selected categories to the supermarket
  void _addSelectedCategories() {
    final selected = _availableCategories
        .where((cat) => _selectedCategoryIds.contains(cat.id))
        .toList();

    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        buildAppSnackBar(
          message: 'Please select at least one category',
          isError: true,
          context: context,
        ),
      );
      return;
    }

    // Add new categories at the top of the list
    final updatedCategories = [
      ...selected,
      ...widget.currentCategories,
    ];

    widget.onCategoriesSelected(updatedCategories);
    Navigator.pop(context);
  }

  /// Navigate to category editing screen to create a new category
  void _navigateToCategoryEditing() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryEditingScreen(
          onCategoryCreated: (newCategory) async {
            // Reload categories and select the new one
            await _loadAvailableCategories();
            setState(() {
              _selectedCategoryIds.add(newCategory.id);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Add Categories'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToCategoryEditing,
            tooltip: 'Create new category',
          ),
        ],
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: _availableCategories.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.done_all,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'All categories added',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a new category to continue',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _availableCategories.length,
              itemBuilder: (context, index) {
                final category = _availableCategories[index];
                final isSelected =
                    _selectedCategoryIds.contains(category.id);

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Card(
                    child: CheckboxListTile(
                      title: Text(
                        category.getName(),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedCategoryIds.add(category.id);
                          } else {
                            _selectedCategoryIds.remove(category.id);
                          }
                        });
                      },
                      activeColor:
                          Theme.of(context).colorScheme.primary,
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _addSelectedCategories,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: const Text('Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
