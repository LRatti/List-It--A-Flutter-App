import 'package:flutter/material.dart';
import 'package:app_code/models/shopping_list.dart';

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

  static const double _sideElementSize = 40.0;
  static const double _fontSize = 12.0;
  static const double _lineHeightMultiplier = 1.2;

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
        _buildProductPreviewCard(),
        const SizedBox(height: 8),
        _buildFooterRow(),
      ],
    );
  }

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

  Widget _buildProductListContent(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final products = widget.shoppingList.getProducts();

    if (products.isEmpty) {
      return _buildEmptyState();
    }

    // Show only the items that fit without scrolling.
    // Estimate line height using font size and height multiplier.
    final lineHeightPx = _fontSize * _lineHeightMultiplier;
    final maxLinesFit = (constraints.maxHeight / lineHeightPx).floor();

    // If there are more products than lines available, reserve one line
    // for a "+N more" indicator.
    final hasOverflow = products.length > maxLinesFit && maxLinesFit > 0;
    final visibleCount = hasOverflow
        ? (maxLinesFit - 1).clamp(0, products.length)
        : products.length.clamp(0, products.length);
    final remainingCount = products.length - visibleCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        for (var p in products.take(visibleCount))
          Text(
            "• ${p.product.getName()}",
            style: _productTextStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        if (hasOverflow && remainingCount > 0)
          Text(
            "+$remainingCount more",
            style: _productTextStyle.copyWith(color: Colors.black45),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    // Avoid using Expanded outside of Flex parents
    return Center(
      child: Text(
        "Empty",
        style: _productTextStyle.copyWith(color: Colors.black38),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildFooterRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: 8.0),
        Expanded(
          child: _editingName ? _buildEditingField() : _buildNameAndDate(),
        ),
        _buildDeleteButton(),
      ],
    );
  }

  Widget _buildNameAndDate() {
    return GestureDetector(
      onTap: () => setState(() => _editingName = true),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [_buildDisplayTitle(), _buildCreationDate()],
      ),
    );
  }

  Widget _buildEditingField() {
    return TextField(
      controller: _nameController,
      autofocus: true,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildCreationDate() {
    final date = widget.shoppingList.createdAt;
    final formattedDate =
        "${date?.day.toString().padLeft(2, '0')}/${date?.month.toString().padLeft(2, '0')}/${date?.year}";

    return Text(
      formattedDate,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: Colors.black54,
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
