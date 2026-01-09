import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/widgets/shopping_list_widget.dart';
import 'package:app_code/providers/shopping_lists_notifier.dart';

class HistoryScreenMobile extends ConsumerStatefulWidget {
  const HistoryScreenMobile({super.key});

  @override
  ConsumerState<HistoryScreenMobile> createState() =>
      _HistoryScreenMobileState();
}

class _HistoryScreenMobileState extends ConsumerState<HistoryScreenMobile> {
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

  @override
  Widget build(BuildContext context) {
    final shoppingListsAsync = ref.watch(shoppingListsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: shoppingListsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (lists) {
          final registeredLists = lists
              .where((l) => l.getIsRegistered())
              .toList();
          if (registeredLists.isEmpty)
            return const Center(child: Text('No registered lists yet.'));

          return LayoutBuilder(
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
                  children: registeredLists.map((list) {
                    final isSelected = _selectedIds.contains(list.id);
                    return SizedBox(
                      width: itemWidth,
                      child: ShoppingListCard(
                        shoppingList: list,
                        onTap: () {
                          if (_selectionActive) {
                            _toggleSelection(list);
                          } else {
                            // Could navigate to details here
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
          );
        },
      ),
    );
  }
}
