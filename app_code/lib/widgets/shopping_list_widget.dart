import 'package:flutter/material.dart';
import 'package:app_code/models/shopping_list.dart';

/// Card widget for a shopping list: fixed-size yellow rectangle, name + delete below.
/// Updated to handle long text with ellipses and dynamic text scaling.
class ShoppingListCard extends StatefulWidget {
  final ShoppingList shoppingList;
  final VoidCallback onTap;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onDelete;

  const ShoppingListCard({
    super.key,
    required this.shoppingList,
    required this.onTap,
    required this.onNameChanged,
    required this.onDelete,
  });

  @override
  State<ShoppingListCard> createState() => _ShoppingListCardState();
}

class _ShoppingListCardState extends State<ShoppingListCard> {
  bool _editingName = false;
  late TextEditingController _nameController;

  // Constants for layout
  static const double _sideElementSize = 40.0;
  static const double _fontSize = 12.0;
  static const double _lineHeightMultiplier = 1.2;

  // Define consistent text style
  final TextStyle _productTextStyle = const TextStyle(
    fontSize: _fontSize,
    height: _lineHeightMultiplier,
    color: Colors.black87,
  );

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.shoppingList.getName(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveName() {
    final newName = _nameController.text.trim();
    if (newName.isNotEmpty) {
      widget.onNameChanged(newName);
    } else {
      _nameController.text = widget.shoppingList.getName();
    }
    setState(() {
      _editingName = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. The main yellow square with the product list
        _buildProductPreviewCard(),

        const SizedBox(height: 8),

        // 2. The footer row with Name and Delete button
        _buildFooterRow(),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Helper Methods
  // ---------------------------------------------------------------------------

  Widget _buildProductPreviewCard() {
    return AspectRatio(
      aspectRatio: 1,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.yellow[100],
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return _buildProductListContent(context, constraints);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProductListContent(BuildContext context, BoxConstraints constraints) {
    final products = widget.shoppingList.getProducts();

    // Use TextPainter to accurately calculate line height including system text scaling
    final textPainter = TextPainter(
      text: TextSpan(text: "A", style: _productTextStyle),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.of(context).textScaler,
    )..layout();

    final singleLineHeight = textPainter.height;

    // Avoid division by zero
    if (singleLineHeight == 0) return const SizedBox();

    // Calculate how many lines fit
    int maxLines = (constraints.maxHeight / singleLineHeight).floor();
    if (maxLines < 1) maxLines = 1;

    final needsMoreLine = products.length > maxLines;
    final productLines = needsMoreLine ? maxLines - 1 : maxLines;

    final visibleProducts = products
        .take(productLines.clamp(0, products.length))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        if (products.isEmpty)
          _buildEmptyState()
        else ...[
          for (var p in visibleProducts)
            Text(
              "• ${p.product.getName()}",
              style: _productTextStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (needsMoreLine)
            Text(
              "+${products.length - visibleProducts.length} more",
              style: _productTextStyle.copyWith(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ]
      ],
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Text(
          "Empty",
          style: _productTextStyle.copyWith(color: Colors.black38),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildFooterRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Small padding on the left so text doesn't touch the screen edge
        const SizedBox(width: 8.0),

        // Middle: Editable Name OR Name and Date Column
        // Expanded allows it to take all available space to the left of the delete button.
        Expanded(
          child: _editingName
              ? _buildEditingField()
              : _buildNameAndDate(),
        ),

        // Right: Delete Button
        _buildDeleteButton(),
      ],
    );
  }

  // Combines the list name and creation date in a column
  Widget _buildNameAndDate() {
    return GestureDetector(
      onTap: () => setState(() => _editingName = true),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildDisplayTitle(),
          _buildCreationDate(),
        ],
      ),
    );
  }

  Widget _buildEditingField() {
    return TextField(
      controller: _nameController,
      autofocus: true,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
      onSubmitted: (_) => _saveName(),
      onTapOutside: (_) {
        FocusManager.instance.primaryFocus?.unfocus();
        _saveName();
      },
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 4),
        border: UnderlineInputBorder(),
      ),
    );
  }

  Widget _buildDisplayTitle() {
    return Text(
      widget.shoppingList.getName(),
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  // Displays the list creation date with a lighter font style
  Widget _buildCreationDate() {
    final date = widget.shoppingList.createdAt;
    // Simple formatting: dd/MM/yyyy HH:mm
    final formattedDate = "${date?.day.toString().padLeft(2, '0')}/${date?.month.toString().padLeft(2, '0')}/${date?.year}";

    return Text(
      formattedDate,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 11, // Slightly smaller font
        fontWeight: FontWeight.w400, // Lighter font weight
        color: Colors.black54, // Lighter color
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDeleteButton() {
    return SizedBox(
      width: _sideElementSize,
      height: _sideElementSize,
      child: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        iconSize: 20,
        onPressed: widget.onDelete,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }
}