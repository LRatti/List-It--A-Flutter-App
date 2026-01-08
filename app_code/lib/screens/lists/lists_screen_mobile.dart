import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/widgets/shopping_list_widget.dart';
import 'package:app_code/providers/shopping_lists_notifier.dart';

class ListsScreenMobile extends ConsumerWidget {
  const ListsScreenMobile({super.key});

  Future<void> _showAddShoppingListDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        // Calculate the actual space the keyboard takes up
        final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

        return MediaQuery(
          // Reset viewInsets to zero for the Dialog positioning logic
          // This keeps the Dialog frame fixed in the center of the screen
          data: MediaQuery.of(context).copyWith(viewInsets: EdgeInsets.zero),
          child: AlertDialog(
            title: const Text("Add new list"),
            content: Container(
              width: double.maxFinite,
              // Only this scrollable area will shift to accommodate the keyboard
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: keyboardHeight),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Please enter the name of your list:"),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: "List name",
                        border: OutlineInputBorder(),
                      ),
                      autofocus: true,
                    ),
                  ],
                ),
              ),
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
                    await ref.read(shoppingListsProvider.notifier).addList(newList);
                  }
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text("Add"),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteShoppingList(
    BuildContext context,
    WidgetRef ref,
    ShoppingList list,
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

  Future<void> _updateListName(WidgetRef ref, ShoppingList list, String newName) async {
    list.setName(newName);
    await ref.read(shoppingListsProvider.notifier).updateList(list);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoppingListsAsync = ref.watch(shoppingListsProvider);

    return shoppingListsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (lists) {
        final activeLists = lists.where((list) => !list.getIsRegistered()).toList();

        return Scaffold(
          // Prevents the background grid from resizing when keyboard opens
          resizeToAvoidBottomInset: false,
          body: activeLists.isEmpty
              ? const Center(
                  child: Text(
                    "No lists yet.\nTap + to create one.",
                    textAlign: TextAlign.center,
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    // Responsive sizing tuned to avoid small overflows on compact screens
                    final scale = MediaQuery.textScaleFactorOf(context);
                    const minTileWidth = 120.0;
                    final spacing = 12.0; // keep spacing constant to maintain columns
                    final nameRowHeight = (56.0 * scale).clamp(52.0, 72.0);
                    final verticalGap = (10.0 * scale).clamp(8.0, 14.0);
                    final safeBuffer = (10.0 * scale).clamp(6.0, 16.0);

                    final totalWidth = constraints.maxWidth;
                    int crossAxisCount = (totalWidth / (minTileWidth + spacing)).floor();
                    if (crossAxisCount < 1) crossAxisCount = 1;

                    final tileWidth = (totalWidth - (crossAxisCount + 1) * spacing) / crossAxisCount;
                    final itemHeight = tileWidth + nameRowHeight + verticalGap + safeBuffer;

                    return GridView.builder(
                      padding: EdgeInsets.all(spacing),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        childAspectRatio: tileWidth / itemHeight,
                      ),
                      itemCount: activeLists.length,
                      itemBuilder: (context, index) {
                        final shoppingList = activeLists[index];
                        return ShoppingListCard(
                          shoppingList: shoppingList,
                          onTap: () {},
                          onNameChanged: (newName) => _updateListName(ref, shoppingList, newName),
                          onDelete: () => _deleteShoppingList(context, ref, shoppingList),
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