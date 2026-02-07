import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/providers/real_app_providers/shopping_list/shopping_lists_notifier.dart';
import 'package:app_code/screens/lists/list_detail_screen_mobile.dart';
import 'package:app_code/widgets/searchable_shopping_lists_view.dart';
import 'package:app_code/widgets/detail_pane_navigator.dart';
import 'package:app_code/l10n/app_localizations.dart';

/// Mobile lists screen: single column list with modal detail view.
class ListsScreenMobile extends ConsumerWidget {
  const ListsScreenMobile({super.key});

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
            return bd.compareTo(ad);
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
            heroTag: 'addShoppingListFAB_mobile_view',
            onPressed: () => _showAddShoppingListDialog(
              context: context,
              ref: ref,
              onListCreated: (newList) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ListDetailScreenMobile(
                      shoppingList: newList,
                      isNewList: true,
                    ),
                  ),
                );
              },
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

/// Tablet lists screen: master-detail split view.
class ListsScreenTablet extends ConsumerStatefulWidget {
  const ListsScreenTablet({super.key});

  @override
  ConsumerState<ListsScreenTablet> createState() =>
      _ListsScreenTabletViewState();
}

class _ListsScreenTabletViewState extends ConsumerState<ListsScreenTablet> {
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
        final activeLists = lists
            .where((l) => !l.getIsInTheTrash() && !l.getIsRegistered())
            .toList()
          ..sort((a, b) {
            final ad = a.getLastModified() ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bd = b.getLastModified() ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bd.compareTo(ad);
          });

        if (_selectedList != null &&
            !activeLists.any((l) => l.id == _selectedList!.id)) {
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
                  lists: activeLists,
                  emptyMessage: l10n.noListsYet,
                  showRegistered: false,
                  onListTap: (context, list) {
                    setState(() => _selectedList = list);
                  },
                  floatingActionButton: FloatingActionButton(
                    heroTag: 'addShoppingListFAB_tablet_master',
                    onPressed: () => _showAddShoppingListDialog(
                      context: context,
                      ref: ref,
                      onListCreated: (newList) {
                        setState(() => _selectedList = newList);
                      },
                    ),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    child: const Icon(Icons.add),
                  ),
                ),
              ),
              Flexible(
                flex: 60,
                child: _selectedList != null
                    ? DetailPaneNavigator(
                        key: ValueKey(_selectedList!.id),
                        initialChild: ListDetailScreenMobile(
                          shoppingList: _selectedList!,
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

Future<void> _showAddShoppingListDialog({
  required BuildContext context,
  required WidgetRef ref,
  required void Function(ShoppingList newList) onListCreated,
}) async {
  final controller = TextEditingController();
  final l10n = AppLocalizations.of(context)!;

  await showDialog(
    context: context,
    builder: (context) {
      final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

      return MediaQuery(
        data: MediaQuery.of(context).copyWith(viewInsets: EdgeInsets.zero),
        child: AlertDialog(
          title: Text(l10n.addNewListTitle),
          content: Container(
            width: double.maxFinite,
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
                foregroundColor: Theme.of(context).colorScheme.onSurface,
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
                  await ref.read(shoppingListsProvider.notifier).addList(newList);

                  if (!context.mounted) {
                    return;
                  }

                  Navigator.pop(context);
                  onListCreated(newList);
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
            Icons.shopping_cart_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.selectListToViewDetails,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}
