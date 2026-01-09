import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/providers/shopping_lists_notifier.dart';
import 'package:app_code/screens/lists/list_detail_screen_mobile.dart';
import 'package:app_code/widgets/shopping_lists_grid_view.dart';

class ListsScreenMobile extends ConsumerWidget {
  const ListsScreenMobile({super.key});

  Future<void> _showAddShoppingListDialog(BuildContext context, WidgetRef ref) async {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoppingListsAsync = ref.watch(shoppingListsProvider);

    return shoppingListsAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text(error.toString())),
      ),
      data: (lists) {
        final activeLists = lists.where((l) => !l.getIsRegistered()).toList();
        return ShoppingListsGridView(
          lists: activeLists,
          emptyMessage: 'No lists yet.',
          onListTap: (context, list) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ListDetailScreenMobile(
                  shoppingList: list,
                ),
              ),
            );
          },
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddShoppingListDialog(context, ref),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}