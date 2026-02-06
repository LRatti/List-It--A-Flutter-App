import 'package:app_code/widgets/detail_pane_navigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/providers/real_app_providers/shopping_list/shopping_lists_notifier.dart';
import 'package:app_code/screens/lists/register-list/register_shopping_list_screen_mobile.dart';
import 'package:app_code/widgets/searchable_shopping_lists_view.dart';
import 'package:app_code/providers/real_app_providers/register_shopping_list_navigation_provider.dart';
import 'package:app_code/utils/screen_size_helper.dart';
import 'package:app_code/models/shopping_list.dart';

/// Responsive history screen showing completed shopping lists.
/// 
/// Mobile: Single column list with modal registration view
/// Tablet+: Master-detail split view
class HistoryScreenResponsive extends StatefulWidget {
  const HistoryScreenResponsive({super.key});

  @override
  State<HistoryScreenResponsive> createState() => _HistoryScreenResponsiveState();
}

class _HistoryScreenResponsiveState extends State<HistoryScreenResponsive> {
  ShoppingList? _selectedList;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final shoppingListsAsync = ref.watch(shoppingListsProvider);
        final isMobile = ScreenSize.isMobile(context);

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

        if (isMobile) {
          // Mobile: Simple list view
          return SearchableShoppingListsView(
            lists: registeredLists,
            emptyMessage: 'No registered lists yet.',
            showRegistered: true,
            onListTap: (context, shoppingList) {
              ref.read(registerShoppingListSourceProvider.notifier).state =
                  RegisterShoppingListSource.history;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RegisterShoppingListScreenMobile(
                    shoppingListId: shoppingList.id,
                  ),
                ),
              );
            },
          );
        }

        // Clear selected list if it's no longer in active lists (e.g., registered or deleted)
        if (_selectedList != null && !registeredLists.any((l) => l.id == _selectedList!.id)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _selectedList = null);
            }
          });
        }

        // Tablet/Desktop: Master-detail split view
        return Scaffold(
          body: Row(
            children: [
              // Master pane: History list
              Flexible(
                flex: 40,
                child: SearchableShoppingListsView(
                  lists: registeredLists,
                  emptyMessage: 'No registered lists yet.',
                  showRegistered: true,
                  onListTap: (context, shoppingList) {
                    setState(() => _selectedList = shoppingList);
                    ref.read(registerShoppingListSourceProvider.notifier).state =
                        RegisterShoppingListSource.history;
                  },
                ),
              ),
              // Detail pane: Registration view or empty state
              Flexible(
                flex: 60,
                child: _selectedList != null
                    ? DetailPaneNavigator(
                        key: ValueKey(_selectedList!.id),
                        initialChild: RegisterShoppingListScreenMobile(
                          shoppingListId: _selectedList!.id,
                        ),
                        emptyBuilder: _buildEmptyDetailPane,
                      )
                    : _buildEmptyDetailPane(context),
              ),
            ],
          ),
        );
      },
        );
      },
    );
  }

  Widget _buildEmptyDetailPane(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Select a completed list to review',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
