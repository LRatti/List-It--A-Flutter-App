import 'package:flutter/material.dart';
import 'package:app_code/models/shopping_list.dart';

class ShoppingListCard extends StatefulWidget {
  final ShoppingList shoppingList;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onDelete;
  final bool isSelected;

  const ShoppingListCard({
    super.key,
    required this.shoppingList,
    required this.onTap,
    this.onLongPress,
    required this.onNameChanged,
    required this.onDelete,
    this.isSelected = false,
  });

  @override
  State<ShoppingListCard> createState() => _ShoppingListCardState();
}

class _ShoppingListCardState extends State<ShoppingListCard> {
  bool _editingName = false;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.shoppingList.getName());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getAccentColor() {
    final colors = [Colors.redAccent, Colors.orangeAccent, Colors.greenAccent, Colors.teal];
    return colors[widget.shoppingList.getName().length % colors.length];
  }

  void _saveName() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) widget.onNameChanged(text);
    setState(() => _editingName = false);
  }

  @override
  Widget build(BuildContext context) {
    final products = widget.shoppingList.getProducts();

    return GestureDetector(
      onLongPress: widget.onLongPress,
      child: Column(
      mainAxisSize: MainAxisSize.min, // Allows the column to grow vertically
      children: [
        // Note Box: Fixed height ensures horizontal alignment of the "boxes"
        Stack(
          children: [
            Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(12),
              color: widget.isSelected ? Colors.blue[50] : Colors.white,
              child: InkWell(
                onTap: widget.onTap,
                onLongPress: widget.onLongPress,
                borderRadius: BorderRadius.circular(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    children: [
                      Container(height: 6, width: double.infinity, color: _getAccentColor()),
                      Container(
                        height: 100,
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        child: products.isEmpty
                            ? const Center(
                                child: Text(
                                  'No items',
                                  style: TextStyle(fontSize: 12, color: Colors.black87),
                                ),
                              )
                            : ListView(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                children: products
                                    .map((p) => _buildBulletItem(p.product.getName()))
                                    .toList(),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (widget.isSelected)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.check, size: 14, color: Colors.white),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Footer: No fixed height here = No overflow
        _editingName ? _buildEditor() : _buildFooter(),
      ],
    ));
  }

  Widget _buildBulletItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(fontSize: 12, color: Colors.black87)),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildEditor() {
    return TextField(
      controller: _controller,
      autofocus: true,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      onSubmitted: (_) => _saveName(),
      onTapOutside: (_) => _saveName(),
      decoration: const InputDecoration(isDense: true, border: InputBorder.none),
    );
  }

  Widget _buildFooter() {
    final date = widget.shoppingList.createdAt;
    final formatted = date != null
        ? '${date.day} ${monthAbbreviation(date.month)} ${date.year}'
        : '--/--/----';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start, // Align icon to top of text
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _editingName = true),
                child: Text(
                  widget.shoppingList.getName(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1, // Truncate to one line as requested
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 2),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          formatted,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
      ],
    );
  }

  String monthAbbreviation(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}