import 'package:app_code/providers/real_app_providers/supermarket/supermarkets_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/providers/real_app_providers/shopping_list/shopping_lists_notifier.dart';
import 'package:app_code/providers/real_app_providers/shopping_list/selected_list_notifier.dart';
import 'package:app_code/screens/lists/list_detail_screen_mobile.dart';
import 'package:app_code/widgets/searchable_shopping_lists_view.dart';

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
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface, // adapts to light/dark
                ),
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
                    // Add to provider (but not fully persisted yet)
                    await ref.read(shoppingListsProvider.notifier).addList(newList);
                    
                    // Load favorite supermarket for new list
                    final favorite = await ref
                        .read(supermarketsProvider.notifier)
                        .getFavoriteSupermarket();
                    
                    if (favorite != null) {
                      await ref
                          .read(selectedListProvider.notifier)
                          .updateSelectedSupermarket(favorite);
                    }
                    
                    // Navigate to detail screen
                    if (context.mounted) {
                      // Select the list in the notifier before navigating
                      await ref.read(selectedListProvider.notifier).selectList(newList);
                      Navigator.pop(context); // Close dialog
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ListDetailScreenMobile(),
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: const Text("Add"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoppingListsAsync = ref.watch(shoppingListsProvider);

    return shoppingListsAsync.when(
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: Text(error.toString())),
      ),
      data: (lists) {
        final activeLists = lists
            .where((l) => !l.getIsInTheTrash() && !l.getIsRegistered())
            .toList()
          ..sort((a, b) {
            final ad = a.getLastModified() ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bd = b.getLastModified() ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bd.compareTo(ad); // newest first
          });
        return SearchableShoppingListsView(
          lists: activeLists,
          emptyMessage: 'No lists yet.',
          showRegistered: false,
          onListTap: (context, list) async {
            // Select the list in the notifier before navigating
            await ref.read(selectedListProvider.notifier).selectList(list);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ListDetailScreenMobile(),
              ),
            );
          },
          floatingActionButton: FloatingActionButton(
            heroTag: 'addShoppingListFAB',
            onPressed: () => _showAddShoppingListDialog(context, ref),
            backgroundColor: Theme.of(context).colorScheme.primary,      // FAB background
            foregroundColor: Theme.of(context).colorScheme.onPrimary,    // Icon color
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}