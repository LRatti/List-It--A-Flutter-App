import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/providers/real_app_providers/shopping_list/shopping_lists_notifier.dart';
import 'package:app_code/screens/lists/list_detail_screen_mobile.dart';
import 'package:app_code/widgets/searchable_shopping_lists_view.dart';
import 'package:app_code/l10n/app_localizations.dart';

class ListsScreenMobile extends ConsumerWidget {
  const ListsScreenMobile({super.key});

  Future<void> _showAddShoppingListDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context)!;

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
            title: Text(l10n.addNewListTitle),
            content: Container(
              width: double.maxFinite,
              // Only this scrollable area will shift to accommodate the keyboard
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: keyboardHeight),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.enterListNamePrompt),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: l10n.listNameHint,
                        border: const OutlineInputBorder(),
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
                child: Text(l10n.cancelLabel),
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
                    
                    // Navigate to detail screen
                    if (context.mounted) {
                      Navigator.pop(context); // Close dialog
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ListDetailScreenMobile(
                            shoppingList: newList,
                            isNewList: true,
                          ),
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: Text(l10n.addLabel),
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
    final l10n = AppLocalizations.of(context)!;

    return shoppingListsAsync.when(
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: Text(l10n.errorWithDetails(error.toString()))),
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
          emptyMessage: l10n.noListsYet,
          showRegistered: false,
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