import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/providers/shopping_lists_notifier.dart';
import 'package:app_code/widgets/shopping_lists_grid_view.dart';

class HistoryScreenMobile extends ConsumerWidget {
  const HistoryScreenMobile({super.key});

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
        final registeredLists = lists.where((l) => l.getIsRegistered()).toList();
        return ShoppingListsGridView(
          lists: registeredLists,
          emptyMessage: 'No registered lists yet.',
        );
      },
    );
  }
}
