import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/widgets/shopping_list_widget.dart';
import 'package:app_code/providers/real_app_providers/shopping_lists_notifier.dart';

class ShoppingListsGridView extends ConsumerStatefulWidget {
  final List<ShoppingList> lists;
  final String emptyMessage;
  final void Function(BuildContext, ShoppingList)? onListTap;
  final Widget? floatingActionButton;
  final void Function(bool)? onDeletionModeChanged;

  const ShoppingListsGridView({
    super.key,
    required this.lists,
    required this.emptyMessage,
    this.onListTap,
    this.floatingActionButton,
    this.onDeletionModeChanged,
  });

  @override
  ConsumerState<ShoppingListsGridView> createState() =>
      _ShoppingListsGridViewState();
}

class _ShoppingListsGridViewState extends ConsumerState<ShoppingListsGridView> {
  final Set<String> _selectedIds = {};

  bool get _selectionActive => _selectedIds.isNotEmpty;

  Future<void> _deleteShoppingList(
    BuildContext context,
    ShoppingList list,
  ) async {
    final ref = this.ref;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete list'),
        content: Text("Are you sure you want to delete '${list.getName()}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Move to trash instead of permanent deletion
      await ref.read(shoppingListsProvider.notifier).updateList(
            list..setIsInTheTrash(true),
          );
    }
  }

  void _toggleSelection(ShoppingList list) {
    setState(() {
      if (_selectedIds.contains(list.id)) {
        _selectedIds.remove(list.id);
      } else {
        _selectedIds.add(list.id);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onDeletionModeChanged?.call(_selectionActive);
    });
  }

  void _cancelSelection() {
    setState(() {
      _selectedIds.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onDeletionModeChanged?.call(false);
    });
  }

  @override
  void deactivate() {
    // Clear selection when widget is deactivated (e.g., when switching screens/tabs)
    if (_selectionActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedIds.clear();
          });
          widget.onDeletionModeChanged?.call(false);
        }
      });
    }
    super.deactivate();
  }

  Future<void> _deleteSelected(BuildContext context) async {
    final ref = this.ref;
    if (_selectedIds.isEmpty) return;
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete selected lists'),
        content: Text('Are you sure you want to delete $count selected list(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final notifier = ref.read(shoppingListsProvider.notifier);
      final lists = ref.read(shoppingListsProvider).value ?? [];
      final toDelete = lists.where((l) => _selectedIds.contains(l.id)).toList();
      for (final l in toDelete) {
        // Move to trash instead of permanent deletion
        await notifier.updateList(l..setIsInTheTrash(true));
      }
      setState(() => _selectedIds.clear());
    }
  }

  void _deleteSelectedWithCallback(BuildContext context) async {
    await _deleteSelected(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onDeletionModeChanged?.call(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lists.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        resizeToAvoidBottomInset: false,
        body: Center(child: Text(widget.emptyMessage)),
        floatingActionButton: widget.floatingActionButton,
      );
    }

    return PopScope(
      canPop: !_selectionActive,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectionActive) {
          _cancelSelection();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        resizeToAvoidBottomInset: false,
        appBar: _selectionActive
            ? AppBar(
                backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).primaryColor,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _cancelSelection,
                ),
                title: Text(
                  '${_selectedIds.length} selected',
                  style: const TextStyle(fontSize: 16),
                ),
              )
            : null,
        body: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final double spacing = 12.0;
                final double padding = 16.0;
                final double itemWidth =
                    (constraints.maxWidth - (padding * 2) - (spacing * 2)) / 3;

                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: padding,
                    right: padding,
                    top: padding,
                    bottom: _selectionActive ? 80 : padding,
                  ),
                  child: Wrap(
                    spacing: spacing,
                    runSpacing: 24,
                    children: widget.lists.map((list) {
                      final isSelected = _selectedIds.contains(list.id);
                      return SizedBox(
                        width: itemWidth,
                        child: Stack(
                          children: [
                            ShoppingListCard(
                              shoppingList: list,
                              onTap: () {
                                if (_selectionActive) {
                                  _toggleSelection(list);
                                } else {
                                  widget.onListTap?.call(context, list);
                                }
                              },
                              onLongPress: () => _toggleSelection(list),
                              onNameChanged: (name) => ref
                                  .read(shoppingListsProvider.notifier)
                                  .updateList(list..setName(name)),
                              onDelete: () => _deleteShoppingList(context, list),
                              isSelected: isSelected,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
        floatingActionButton: _selectionActive
            ? FloatingActionButton(
                onPressed: () => _deleteSelectedWithCallback(context),
                backgroundColor: Theme.of(context).colorScheme.error,
                child: const Icon(Icons.delete),
              )
            : widget.floatingActionButton,
      ),
    );
  }
}
