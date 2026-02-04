import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/providers/real_app_providers/shopping_list/shopping_lists_notifier.dart';
import 'package:app_code/screens/lists/register-list/register_shopping_list_screen_mobile.dart';
import 'package:app_code/widgets/searchable_shopping_lists_view.dart';
import 'package:app_code/providers/real_app_providers/register_shopping_list_navigation_provider.dart';

class HistoryScreenMobile extends ConsumerWidget {
  const HistoryScreenMobile({super.key});

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
        final registeredLists = lists
            .where((l) => l.getIsRegistered() && !l.getIsInTheTrash())
            .toList()
          ..sort((a, b) {
            final ad = a.getCreatedAt() ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bd = b.getCreatedAt() ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bd.compareTo(ad); // newest first
          });
        return SearchableShoppingListsView(
          lists: registeredLists,
          emptyMessage: 'No registered lists yet.',
          showRegistered: true,
          onListTap: (context, shoppingList) {
            // Set navigation source to indicate this came from history
            ref.read(registerShoppingListSourceProvider.notifier).state =
                RegisterShoppingListSource.history;
            
            // Navigate to register shopping list screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RegisterShoppingListScreenMobile(
                  shoppingList: shoppingList,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

