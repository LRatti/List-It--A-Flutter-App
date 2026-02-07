import 'package:flutter/material.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

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
    final colors = [
      Colors.redAccent,
      Colors.orangeAccent,
      Colors.greenAccent,
      Colors.teal
    ];
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
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onLongPress: widget.onLongPress,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(12),
                color: widget.isSelected
                ? colorScheme.primaryContainer
                : (Theme.of(context).brightness == Brightness.dark
                    ? colorScheme.surfaceContainerHigh
                    : colorScheme.surface),
                child: InkWell(
                  onTap: widget.onTap,
                  onLongPress: widget.onLongPress,
                  borderRadius: BorderRadius.circular(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      children: [
                        Container(
                          height: 6,
                          width: double.infinity,
                          color: _getAccentColor(),
                        ),
                        Container(
                          height: 100,
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          child: products.isEmpty
                              ? Center(
                                  child: Text(
                                    l10n.noItemsLabel,
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                )
                              : ListView(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: products
                                      .map((p) =>
                                          _buildBulletItem(p.product.getName(), colorScheme))
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
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.check, size: 14, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _editingName ? _buildEditor(colorScheme) : _buildFooter(colorScheme),
        ],
      ),
    );
  }

  Widget _buildBulletItem(String text, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('• ', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildEditor(ColorScheme colorScheme) {
    return TextField(
      controller: _controller,
      autofocus: true,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
      ),
      onSubmitted: (_) => _saveName(),
      onTapOutside: (_) => _saveName(),
      decoration: const InputDecoration(
        isDense: true,
        border: InputBorder.none,
      ),
    );
  }

  Widget _buildFooter(ColorScheme colorScheme) {
    final date = widget.shoppingList.createdAt;
    final l10n = AppLocalizations.of(context)!;
    final formatted = date != null
      ? DateFormat('d MMM yyyy', Localizations.localeOf(context).toString())
        .format(date)
      : l10n.dateNotAvailable;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _editingName = true),
                child: Text(
                  widget.shoppingList.getName(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
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
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

}
