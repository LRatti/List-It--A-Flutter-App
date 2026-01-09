import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/widgets/shopping_list_widget.dart';
import 'package:app_code/providers/shopping_lists_notifier.dart';

class ListsScreenMobile extends ConsumerWidget {
  const ListsScreenMobile({super.key});

  /// Opens a dialog to create a new shopping list
  Future<void> _showAddShoppingListDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add new list'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'List name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await ref.read(shoppingListsProvider.notifier).addList(
                      ShoppingList(
                        name: name,
                        createdAt: DateTime.now(),
                      ),
                    );
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  /// Opens a confirmation dialog to delete a list
  Future<void> _deleteShoppingList(
    BuildContext context,
    WidgetRef ref,
    ShoppingList list,
  ) async {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoppingListsAsync = ref.watch(shoppingListsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: shoppingListsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (lists) {
          final activeLists = lists.where((l) => !l.getIsRegistered()).toList();
          if (activeLists.isEmpty) return const Center(child: Text('No lists yet.'));

          return LayoutBuilder(
            builder: (context, constraints) {
              // Calculate width for 3 columns minus padding and spacing
              final double spacing = 12.0;
              final double padding = 16.0;
              final double itemWidth = (constraints.maxWidth - (padding * 2) - (spacing * 2)) / 3;

              return SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: Wrap(
                  spacing: spacing, // Horizontal space between cards
                  runSpacing: 24,   // Vertical space between rows
                  children: activeLists.map((list) {
                    return SizedBox(
                      width: itemWidth,
                      child: ShoppingListCard(
                        shoppingList: list,
                        onTap: () {},
                        onNameChanged: (name) => ref.read(shoppingListsProvider.notifier).updateList(
                          list..setName(name),
                        ),
                        onDelete: () => _deleteShoppingList(context, ref, list),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddShoppingListDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}