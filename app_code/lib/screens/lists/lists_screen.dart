import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/providers/real_app_providers/shopping_list/shopping_lists_notifier.dart';
import 'package:app_code/screens/lists/list_detail_screen_mobile.dart';
import 'package:app_code/widgets/searchable_shopping_lists_view.dart';
import 'package:app_code/widgets/detail_pane_navigator.dart';
import 'package:app_code/utils/screen_size_helper.dart';
import 'package:app_code/providers/real_app_providers/screen_size_provider.dart';

/// Responsive lists screen that adapts layout based on screen size.
/// 
/// Mobile (< 600 dp): Single column list with modal detail view
/// Tablet+ (≥ 600 dp): Master-detail split view with list on left, detail on right
class ListsScreenResponsive extends ConsumerStatefulWidget {
  const ListsScreenResponsive({super.key});

  @override
  ConsumerState<ListsScreenResponsive> createState() => _ListsScreenResponsiveState();
}

class _ListsScreenResponsiveState extends ConsumerState<ListsScreenResponsive> {
  ShoppingList? _selectedList;

  Future<void> _showAddShoppingListDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

        return MediaQuery(
          data: MediaQuery.of(context).copyWith(viewInsets: EdgeInsets.zero),
          child: AlertDialog(
            title: const Text("Add new list"),
            content: Container(
              width: double.maxFinite,
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
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
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
                    await ref.read(shoppingListsProvider.notifier).addList(newList);

                    if (context.mounted) {
                      Navigator.pop(context);
                      
                        final isPhone = ScreenSize.isPhoneAtLaunch ??
                          ScreenSize.isMobile(context);
                        if (isPhone) {
                        // Mobile: Navigate to detail screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ListDetailScreenMobile(
                              shoppingList: newList,
                              isNewList: true,
                            ),
                          ),
                        );
                      } else {
                        // Tablet+: Select in master view
                        setState(() => _selectedList = newList);
                      }
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
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final shoppingListsAsync = ref.watch(shoppingListsProvider);
        final isMobile = ScreenSize.isPhoneAtLaunch ??
          ScreenSize.isMobile(context);

        // Watch screen size provider to rebuild on size/orientation changes
        ref.watch(screenSizeProvider);

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
            return bd.compareTo(ad);
          });

        if (isMobile) {
          // Mobile: Simple list with modal detail
          return SearchableShoppingListsView(
            lists: activeLists,
            emptyMessage: 'No lists yet.',
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
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              child: const Icon(Icons.add),
            ),
          );
        }

        // Clear selected list if it's no longer in active lists (e.g., registered or deleted)
        if (_selectedList != null && !activeLists.any((l) => l.id == _selectedList!.id)) {
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
              // Master pane: List of shopping lists
              Flexible(
                flex: 40,
                child: SearchableShoppingListsView(
                  lists: activeLists,
                  emptyMessage: 'No lists yet.',
                  showRegistered: false,
                  onListTap: (context, list) {
                    setState(() => _selectedList = list);
                  },
                  floatingActionButton: FloatingActionButton(
                    heroTag: 'addShoppingListFAB',
                    onPressed: () => _showAddShoppingListDialog(context, ref),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    child: const Icon(Icons.add),
                  ),
                ),
              ),
              // Detail pane: List editor or empty state (with nested navigator)
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
              Icons.shopping_cart_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Select a list to view details',
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
