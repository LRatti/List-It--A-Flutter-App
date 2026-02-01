import 'package:flutter/material.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/models/purchased_product.dart';

/// Widget that allows dragging products across categories
class DraggableProductList extends StatelessWidget {
  final Map<Category, List<PurchasedProduct>> productsByCategory;
  final Function(PurchasedProduct product, Category newCategory) onProductMoved;
  final Function(PurchasedProduct product) onProductRemoved;
  final Function(PurchasedProduct product, String newName) onProductRenamed;

  const DraggableProductList({
    super.key,
    required this.productsByCategory,
    required this.onProductMoved,
    required this.onProductRemoved,
    required this.onProductRenamed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: productsByCategory.entries.map((entry) {
        final category = entry.key;
        final products = entry.value;

        // Skip empty categories
        if (products.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header - Drag target for entire category
            DragTarget<PurchasedProduct>(
              builder: (context, candidateData, rejectedData) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  decoration: BoxDecoration(
                    color: candidateData.isNotEmpty
                        ? colorScheme.primaryContainer.withOpacity(0.3)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.folder,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          category.getName(),
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      if (candidateData.isNotEmpty)
                        Icon(
                          Icons.add_circle_outline,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                    ],
                  ),
                );
              },
              onWillAccept: (data) => data != null,
              onAccept: (product) {
                // Only move if different category
                if (product.category.id != category.id) {
                  onProductMoved(product, category);
                }
              },
            ),
            // Products in this category
            ...products.map((product) {
              return _buildDraggableProductTile(
                product,
                colorScheme,
                textTheme,
                context,
              );
            }).toList(),
            const SizedBox(height: 16),
          ],
        );
        }).toList(),
      ),
    );
  }

  /// Build a draggable product tile
  Widget _buildDraggableProductTile(
    PurchasedProduct product,
    ColorScheme colorScheme,
    TextTheme textTheme,
    BuildContext context,
  ) {
    final controller = TextEditingController(text: product.product.getName());

    return LongPressDraggable<PurchasedProduct>(
      data: product,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.primary, width: 2),
          ),
          child: Row(
            children: [
              Icon(Icons.drag_indicator, color: colorScheme.onPrimaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  product.product.getName(),
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _buildProductTileContent(
          product,
          controller,
          colorScheme,
          textTheme,
          context,
        ),
      ),
      child: _buildProductTileContent(
        product,
        controller,
        colorScheme,
        textTheme,
        context,
      ),
    );
  }

  /// Build the content of the product tile
  Widget _buildProductTileContent(
    PurchasedProduct product,
    TextEditingController controller,
    ColorScheme colorScheme,
    TextTheme textTheme,
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Row(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              Icons.drag_indicator,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          // Remove button
          IconButton(
            icon: Icon(Icons.remove_circle_outline, size: 20, color: colorScheme.error),
            onPressed: () {
              onProductRemoved(product);
            },
            tooltip: 'Remove product',
          ),
          // Product name (editable)
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              ),
              style: textTheme.bodyLarge,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty && value.trim() != product.product.getName()) {
                  onProductRenamed(product, value.trim());
                }
              },
            ),
          ),
          // Edit button
          IconButton(
            icon: Icon(Icons.edit, size: 20, color: colorScheme.primary),
            onPressed: () {
              // Show dialog to edit product name
              _showEditProductDialog(context, product, controller);
            },
            tooltip: 'Edit product',
          ),
        ],
      ),
    );
  }

  /// Show dialog to edit product name
  void _showEditProductDialog(
    BuildContext context,
    PurchasedProduct product,
    TextEditingController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Product'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Product name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  onProductRenamed(product, controller.text.trim());
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
