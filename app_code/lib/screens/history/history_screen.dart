import 'package:app_code/widgets/detail_pane_navigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/providers/real_app_providers/shopping_list/shopping_lists_notifier.dart';
import 'package:app_code/screens/lists/register-list/register_shopping_list_screen_mobile.dart';
import 'package:app_code/widgets/searchable_shopping_lists_view.dart';
import 'package:app_code/providers/real_app_providers/register_shopping_list_navigation_provider.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/l10n/app_localizations.dart';

/// Mobile history screen: single column list with modal registration view.
class HistoryScreenMobile extends ConsumerWidget {
  const HistoryScreenMobile({super.key});

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
          emptyMessage: l10n.noRegisteredListsYet,
          showRegistered: true,
          onListTap: (context, shoppingList) {
            ref.read(registerShoppingListSourceProvider.notifier).state =
                RegisterShoppingListSource.history;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RegisterShoppingListScreenMobile(
                  shoppingListId: shoppingList.id,
                  initialShoppingList: shoppingList,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Tablet history screen: master-detail split view.
class HistoryScreenTablet extends ConsumerStatefulWidget {
  const HistoryScreenTablet({super.key});

  @override
  ConsumerState<HistoryScreenTablet> createState() =>
      _HistoryScreenTabletViewState();
}

class _HistoryScreenTabletViewState extends ConsumerState<HistoryScreenTablet> {
  ShoppingList? _selectedList;

  @override
  Widget build(BuildContext context) {
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
        final registeredLists = lists
            .where((l) => l.getIsRegistered() && !l.getIsInTheTrash())
            .toList()
          ..sort((a, b) {
            final ad = a.getCreatedAt() ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bd = b.getCreatedAt() ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bd.compareTo(ad); // newest first
          });

        if (_selectedList != null &&
            !registeredLists.any((l) => l.id == _selectedList!.id)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _selectedList = null);
            }
          });
        }

        return Scaffold(
          body: Row(
            children: [
              Flexible(
                flex: 40,
                child: SearchableShoppingListsView(
                  lists: registeredLists,
                  emptyMessage: l10n.noRegisteredListsYet,
                  showRegistered: true,
                  onListTap: (context, shoppingList) {
                    setState(() => _selectedList = shoppingList);
                    ref.read(registerShoppingListSourceProvider.notifier).state =
                        RegisterShoppingListSource.history;
                  },
                ),
              ),
              Flexible(
                flex: 60,
                child: _selectedList != null
                    ? DetailPaneNavigator(
                        key: ValueKey(_selectedList!.id),
                        initialChild: RegisterShoppingListScreenMobile(
                          shoppingListId: _selectedList!.id,
                          initialShoppingList: _selectedList,
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
  }
}

Widget _buildEmptyDetailPane(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  final l10n = AppLocalizations.of(context)!;

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
            l10n.selectCompletedListToReview,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}
