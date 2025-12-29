import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/widgets/shopping_list_widget.dart';
import 'package:app_code/providers/real_app_providers/shopping_lists_notifier.dart';

class ListsScreenMobile extends ConsumerWidget {
  const ListsScreenMobile({super.key});

  Future<void> _showAddShoppingListDialog(BuildContext context, WidgetRef ref,) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add new list"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "List name"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final newList = ShoppingList(
                  name: name,
                  createdAt: DateTime.now(),
                );
                await ref
                    .read(shoppingListsProvider.notifier)
                    .addList(newList);
              }
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteShoppingList(BuildContext context, WidgetRef ref, ShoppingList list,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete list"),
        content: Text("Are you sure you want to delete '${list.getName()}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(shoppingListsProvider.notifier).deleteList(list);
    }
  }

  Future<void> _updateListName(WidgetRef ref, ShoppingList list, String newName,
  ) async {
    list.setName(newName);
    await ref.read(shoppingListsProvider.notifier).updateList(list);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoppingListsAsync = ref.watch(shoppingListsProvider);

    return shoppingListsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (lists) {
        if (lists.isEmpty) {
          return const Center(
            child: Text(
              "No lists yet.\nTap + to create one.",
              textAlign: TextAlign.center,
            ),
          );
        }

        return Scaffold(
          body: LayoutBuilder(
            builder: (context, constraints) {
              const crossAxisCount = 3;
              const spacing = 12.0;
              final totalWidth = constraints.maxWidth;
              final itemWidth =
                  (totalWidth - (crossAxisCount + 1) * spacing) / crossAxisCount;
              const nameRowHeight = 48.0;
              const verticalGap = 8.0;
              const safeBuffer = 2.0;
              final itemHeight = itemWidth + nameRowHeight + verticalGap + safeBuffer;

              return GridView.builder(
                padding: const EdgeInsets.all(spacing),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: itemWidth / itemHeight,
                ),
                itemCount: lists.length,
                itemBuilder: (context, index) {
                  final shoppingList = lists[index];
                  return ShoppingListCard(
                    shoppingList: shoppingList,
                    onTap: () {},
                    onNameChanged: (newName) =>
                        _updateListName(ref, shoppingList, newName),
                    onDelete: () =>
                        _deleteShoppingList(context, ref, shoppingList),
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
      },
    );
  }
}
