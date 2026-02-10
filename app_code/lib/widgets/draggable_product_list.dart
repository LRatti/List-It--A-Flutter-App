import 'package:flutter/material.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/utils/category_localizer.dart';

/// Widget that allows dragging products across categories
class DraggableProductList extends StatefulWidget {
  final Map<Category, List<PurchasedProduct>> productsByCategory;
  final Future<void> Function(PurchasedProduct product, Category newCategory)
  onProductMoved;
  final Future<void> Function(PurchasedProduct product) onProductRemoved;
  final Future<void> Function(PurchasedProduct product, String newName)
  onProductRenamed;
  final Future<void> Function(PurchasedProduct product, bool isBought)?
  onProductBoughtToggled;
  final ScrollController? scrollController;

  const DraggableProductList({
    super.key,
    required this.productsByCategory,
    required this.onProductMoved,
    required this.onProductRemoved,
    required this.onProductRenamed,
    this.onProductBoughtToggled,
    this.scrollController,
  });

  @override
  State<DraggableProductList> createState() => _DraggableProductListState();
}

class _DraggableProductListState extends State<DraggableProductList> {
  final Map<String, FocusNode> _focusNodes = {};
  final Map<String, TextEditingController> _controllers = {};

  // Auto-scroll support
  bool _isDragging = false;
  double _lastDragPosition = 0.0;

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

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    _lastDragPosition = details.globalPosition.dy;
    _performAutoScroll();
  }

  void _performAutoScroll() {
    final scrollController = widget.scrollController;
    if (scrollController == null || !scrollController.hasClients) return;

    final scrollThresholdTop = 400.0; // Pixels from edge to start scroll
    final scrollThresholdBottom = 300.0; // Pixels from edge to start scroll
    final maxScrollSpeed = 1.5; // Maximum pixels to scroll per frame

    // Get screen height to determine scroll zones
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate scroll speed based on distance from edge (gradual acceleration)
    double scrollSpeed = 0.0;

    // Scroll down when near bottom
    if (_lastDragPosition > screenHeight - scrollThresholdBottom) {
      final distanceFromBottom = screenHeight - _lastDragPosition;
      final normalizedDistance = (distanceFromBottom / scrollThresholdBottom)
          .clamp(0.0, 1.0);
      // Use quadratic curve for smoother, more gradual acceleration
      scrollSpeed =
          maxScrollSpeed *
          (1 - normalizedDistance) *
          (1 - normalizedDistance * 0.5);

      final maxScroll = scrollController.position.maxScrollExtent;
      final currentScroll = scrollController.offset;
      if (currentScroll < maxScroll) {
        scrollController.jumpTo(
          (currentScroll + scrollSpeed).clamp(0.0, maxScroll),
        );
        // Continue scrolling if still dragging
        if (_isDragging) {
          Future.delayed(const Duration(milliseconds: 16), _performAutoScroll);
        }
      }
    }
    // Scroll up when near top
    else if (_lastDragPosition < scrollThresholdTop) {
      final normalizedDistance = (_lastDragPosition / scrollThresholdTop).clamp(
        0.0,
        1.0,
      );
      // Use quadratic curve for smoother, more gradual acceleration
      scrollSpeed =
          maxScrollSpeed *
          (1 - normalizedDistance) *
          (1 - normalizedDistance * 0.5);

      final currentScroll = scrollController.offset;
      if (currentScroll > 0) {
        scrollController.jumpTo(
          (currentScroll - scrollSpeed).clamp(
            0.0,
            scrollController.position.maxScrollExtent,
          ),
        );
        // Continue scrolling if still dragging
        if (_isDragging) {
          Future.delayed(const Duration(milliseconds: 16), _performAutoScroll);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: _unfocusAll,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: Column(
          children: widget.productsByCategory.entries.map((entry) {
            final category = entry.key;
            final products = entry.value;

            // Always show category headers, even if empty
            // This allows users to see all available categories upfront
            // and drag products to any category
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category header - Drag target for entire category
                DragTarget<PurchasedProduct>(
                  builder: (context, candidateData, rejectedData) {
                    final isDropTarget = candidateData.isNotEmpty;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12.0,
                        horizontal: 12.0,
                      ),
                      margin: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                      decoration: BoxDecoration(
                        color: isDropTarget
                            ? colorScheme.primaryContainer.withOpacity(0.2)
                            : Colors.transparent,
                        border: Border(
                          bottom: BorderSide(
                            color: isDropTarget
                                ? colorScheme.primary
                                : colorScheme.outline.withOpacity(0.3),
                            width: isDropTarget ? 2.5 : 1.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Category icon indicator
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  CategoryLocalizer.localize(
                                    context,
                                    category.getName(),
                                  ),
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Show count badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: products.isEmpty
                                  ? colorScheme.surfaceContainerHighest
                                  : colorScheme.primary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${products.length}',
                              style: textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: products.isEmpty
                                    ? colorScheme.onSurfaceVariant
                                    : colorScheme.onPrimary,
                              ),
                            ),
                          ),
                          if (isDropTarget) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.add_circle,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                  onWillAccept: (data) => data != null,
                  onAccept: (product) async {
                    // Only move if different category
                    if (product.category.id != category.id) {
                      await widget.onProductMoved(product, category);
                    }
                  },
                ),
                // Products in this category (if any)
                if (products.isNotEmpty)
                  ...products.map((product) {
                    return DragTarget<PurchasedProduct>(
                      builder: (context, candidateData, rejectedData) {
                        return Container(
                          child: _buildDraggableProductTile(
                            product,
                            colorScheme,
                            textTheme,
                            context,
                            product.isBought,
                          ),
                        );
                      },
                      onWillAccept: (draggedProduct) =>
                          draggedProduct != null &&
                          draggedProduct.id != product.id,
                      onAccept: (draggedProduct) async {
                        // Move the dragged product to this product's category
                        if (draggedProduct.category.id != product.category.id) {
                          await widget.onProductMoved(
                            draggedProduct,
                            product.category,
                          );
                        }
                      },
                    );
                  }).toList(),
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
    bool isChecked,
  ) {
    final controller = _getController(product.id, product.product.getName());
    final focusNode = _getFocusNode(product.id);

    return LongPressDraggable<PurchasedProduct>(
      data: product,
      onDragStarted: () {
        setState(() {
          _isDragging = true;
        });
      },
      onDragUpdate: _handleDragUpdate,
      onDragEnd: (_) {
        setState(() {
          _isDragging = false;
        });
      },
      onDraggableCanceled: (_, __) {
        setState(() {
          _isDragging = false;
        });
      },
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(8),
        child: Transform.scale(
          scale: 1.05,
          child: Card(
            margin: EdgeInsets.zero,
            child: SizedBox(
              width: 300,
              child: ListTile(
                leading: Checkbox(value: false, onChanged: null),
                title: Text(
                  product.product.getName(),
                  style: textTheme.bodyLarge,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Icon(Icons.drag_handle, color: colorScheme.outline),
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildProductTileContent(
          product,
          controller,
          focusNode,
          colorScheme,
          textTheme,
          context,
          isChecked,
        ),
      ),
      child: _buildProductTileContent(
        product,
        controller,
        focusNode,
        colorScheme,
        textTheme,
        context,
        isChecked,
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
    bool isChecked,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        // Checkbox on the left to mark products as bought
        leading: Checkbox(
          value: isChecked,
          onChanged: (value) async {
            if (widget.onProductBoughtToggled != null) {
              await widget.onProductBoughtToggled!(product, value ?? false);
            }
          },
        ),
        // Product name in the center (editable)
        title: TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          style: textTheme.bodyLarge,
          onSubmitted: (value) async {
            if (value.trim().isEmpty) {
              // Remove product if name is cleared
              await widget.onProductRemoved(product);
            } else if (value.trim() != product.product.getName()) {
              // Rename product if name changed
              await widget.onProductRenamed(product, value.trim());
            }
            focusNode.unfocus();
          },
          onTapOutside: (event) async {
            final value = controller.text.trim();
            if (value.isEmpty) {
              // Remove product if name is cleared
              await widget.onProductRemoved(product);
            }
            focusNode.unfocus();
          },
        ),
        // Actions on the right: remove + drag handle
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Remove button
            IconButton(
              icon: Icon(
                Icons.remove_circle_outline,
                size: 20,
                color: colorScheme.error,
              ),
              onPressed: () async {
                await widget.onProductRemoved(product);
              },
              tooltip: 'Remove product',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(width: 6),
            ReorderableDragStartListener(
              index: 0,
              child: Icon(Icons.drag_handle, color: colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}
