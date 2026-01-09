import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/widgets/shopping_list_widget.dart';
import 'package:app_code/providers/shopping_lists_notifier.dart';

class ShoppingListsGridView extends ConsumerStatefulWidget {
  final List<ShoppingList> lists;
  final String emptyMessage;
  final void Function(BuildContext, ShoppingList)? onListTap;
  final Widget? floatingActionButton;

  const ShoppingListsGridView({
    super.key,
    required this.lists,
    required this.emptyMessage,
    this.onListTap,
    this.floatingActionButton,
  });

  @override
  ConsumerState<ShoppingListsGridView> createState() =>
      _ShoppingListsGridViewState();
}

class _ShoppingListsGridViewState extends ConsumerState<ShoppingListsGridView> {
  final Set<String> _selectedIds = {};

  bool get _selectionActive => _selectedIds.isNotEmpty;

  Future<void> _deleteShoppingList(
    BuildContext context,
    ShoppingList list,
  ) async {
    final ref = this.ref;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete list'),
        content: Text("Are you sure you want to delete '${list.getName()}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(shoppingListsProvider.notifier).deleteList(list);
    }
  }

  void _toggleSelection(ShoppingList list) {
    setState(() {
      if (_selectedIds.contains(list.id)) {
        _selectedIds.remove(list.id);
      } else {
        _selectedIds.add(list.id);
      }
    });
  }

  Future<void> _deleteSelected(BuildContext context) async {
    final ref = this.ref;
    if (_selectedIds.isEmpty) return;
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete selected lists'),
        content: Text('Are you sure you want to delete $count selected list(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final notifier = ref.read(shoppingListsProvider.notifier);
      final lists = ref.read(shoppingListsProvider).value ?? [];
      final toDelete = lists.where((l) => _selectedIds.contains(l.id)).toList();
      for (final l in toDelete) {
        await notifier.deleteList(l);
      }
      setState(() => _selectedIds.clear());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lists.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text(widget.emptyMessage)),
        floatingActionButton: widget.floatingActionButton,
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double spacing = 12.0;
          final double padding = 16.0;
          final double itemWidth =
              (constraints.maxWidth - (padding * 2) - (spacing * 2)) / 3;

          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Wrap(
              spacing: spacing,
              runSpacing: 24,
              children: widget.lists.map((list) {
                final isSelected = _selectedIds.contains(list.id);
                return SizedBox(
                  width: itemWidth,
                  child: ShoppingListCard(
                    shoppingList: list,
                    onTap: () {
                      if (_selectionActive) {
                        _toggleSelection(list);
                      } else {
                        widget.onListTap?.call(context, list);
                      }
                    },
                    onLongPress: () => _toggleSelection(list),
                    onNameChanged: (name) => ref
                        .read(shoppingListsProvider.notifier)
                        .updateList(list..setName(name)),
                    onDelete: () => _deleteShoppingList(context, list),
                    isSelected: isSelected,
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
      floatingActionButton: _selectionActive
          ? FloatingActionButton(
              onPressed: () => _deleteSelected(context),
              backgroundColor: Colors.red,
              child: const Icon(Icons.delete),
            )
          : widget.floatingActionButton,
    );
  }
}
