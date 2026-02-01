import 'package:flutter/material.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/models/purchased_product.dart';

/// Widget that allows dragging products across categories
class DraggableProductList extends StatefulWidget {
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
  State<DraggableProductList> createState() => _DraggableProductListState();
}

class _DraggableProductListState extends State<DraggableProductList> {
  final Map<String, FocusNode> _focusNodes = {};
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    // Clean up focus nodes and controllers
    for (var node in _focusNodes.values) {
      node.dispose();
    }
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  FocusNode _getFocusNode(String productId) {
    if (!_focusNodes.containsKey(productId)) {
      _focusNodes[productId] = FocusNode();
    }
    return _focusNodes[productId]!;
  }

  TextEditingController _getController(String productId, String initialName) {
    if (!_controllers.containsKey(productId)) {
      _controllers[productId] = TextEditingController(text: initialName);
    }
    return _controllers[productId]!;
  }

  void _unfocusAll() {
    // Unfocus all text fields
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: _unfocusAll,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal:0),
        child: Column(
          children: widget.productsByCategory.entries.map((entry) {
        final category = entry.key;
        final products = entry.value;

        // NEW BEHAVIOR: Always show category headers, even if empty
        // This allows users to see all available categories upfront
        // and drag products to any category
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
                      Expanded(
                        child: Text(
                          category.getName(),
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      // Show count badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: products.isEmpty 
                              ? colorScheme.surfaceContainerHighest
                              : colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${products.length}',
                          style: textTheme.labelSmall?.copyWith(
                            color: products.isEmpty
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.onPrimaryContainer,
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
                  widget.onProductMoved(product, category);
                }
              },
            ),
            // Products in this category (if any)
            if (products.isNotEmpty)
              ...products.map((product) {
                return _buildDraggableProductTile(
                  product,
                  colorScheme,
                  textTheme,
                  context,
                );
              }).toList()
          ],
        );
          }).toList(),
        ),
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
    final controller = _getController(product.id, product.product.getName());
    final focusNode = _getFocusNode(product.id);

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
          focusNode,
          colorScheme,
          textTheme,
          context,
        ),
      ),
      child: _buildProductTileContent(
        product,
        controller,
        focusNode,
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
    FocusNode focusNode,
    ColorScheme colorScheme,
    TextTheme textTheme,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () {
        // Prevent tap from propagating to parent GestureDetector
        // This keeps the text field focused when tapping on the tile
      },
      child: Container(
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
              widget.onProductRemoved(product);
            },
            tooltip: 'Remove product',
          ),
          // Product name (editable)
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              ),
              style: textTheme.bodyLarge,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty && value.trim() != product.product.getName()) {
                  widget.onProductRenamed(product, value.trim());
                }
                focusNode.unfocus();
              },
              onTapOutside: (event) {
                focusNode.unfocus();
              },
            ),
          ),
        ],
      ),
      ),
    );
  }
}
