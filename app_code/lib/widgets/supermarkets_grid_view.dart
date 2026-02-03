import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/providers/real_app_providers/supermarket/supermarkets_notifier.dart';
import 'package:app_code/providers/real_app_providers/navigation_provider.dart';
import 'package:app_code/screens/supermarket/supermarket_customization_screen.dart';

class SupermarketsGridView extends ConsumerStatefulWidget {
  final List<Supermarket> supermarkets;
  final String emptyMessage;
  final Widget? floatingActionButton;
  final void Function(bool)? onDeletionModeChanged;

  const SupermarketsGridView({
    super.key,
    required this.supermarkets,
    required this.emptyMessage,
    this.floatingActionButton,
    this.onDeletionModeChanged,
  });

  @override
  ConsumerState<SupermarketsGridView> createState() =>
      _SupermarketsGridViewState();
}

class _SupermarketsGridViewState extends ConsumerState<SupermarketsGridView> {
  final Set<String> _selectedIds = {};

  bool get _selectionActive => _selectedIds.isNotEmpty;

  void _toggleSelection(Supermarket supermarket) {
    setState(() {
      if (_selectedIds.contains(supermarket.id)) {
        _selectedIds.remove(supermarket.id);
      } else {
        _selectedIds.add(supermarket.id);
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

  void _resetSelection() {
    if (!_selectionActive) return;
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
        content: Text(
          'Want to delete $count supermarket(s)?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final notifier = ref.read(supermarketsProvider.notifier);
      // Mark all selected supermarkets as non-visible
      await notifier.deleteSupermarkets(_selectedIds.toList());
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
    // Listen for global navigation signals to clear selection and hide delete FAB
    ref.listen(appNavigationSignalProvider, (prev, next) {
      if (prev != next) {
        _resetSelection();
      }
    });

    if (widget.supermarkets.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        resizeToAvoidBottomInset: false,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.store_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                widget.emptyMessage,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Create your first supermarket to get started',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
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
                backgroundColor:
                    Theme.of(context).appBarTheme.backgroundColor ??
                    Theme.of(context).colorScheme.primary,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _cancelSelection,
                ),
                title: Text(
                  '${_selectedIds.length} selected',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              )
            : null,
        body: ListView.builder(
          padding: EdgeInsets.only(
            left: 8,
            right: 8,
            top: 8,
            bottom: 80,
          ),
          itemCount: widget.supermarkets.length,
          itemBuilder: (context, index) {
            final supermarket = widget.supermarkets[index];
            final isSelected = _selectedIds.contains(supermarket.id);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
              child: Card(
                elevation: isSelected ? 8 : 2,
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).cardColor,
                child: InkWell(
                  onTap: () {
                    if (_selectionActive) {
                      _toggleSelection(supermarket);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SupermarketCustomizationScreen(
                            supermarket: supermarket,
                          ),
                        ),
                      );
                    }
                  },
                  onLongPress: () => _toggleSelection(supermarket),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    leading: _selectionActive
                        ? Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleSelection(supermarket),
                            activeColor: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    title: Text(
                      supermarket.getName(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).textTheme.titleMedium?.color,
                      ),
                    ),
                    trailing: _selectionActive
                        ? null
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Favorite/Star button
                              IconButton(
                                icon: Icon(
                                  supermarket.isFavorite
                                      ? Icons.star
                                      : Icons.star_outline,
                                ),
                                onPressed: () async {
                                  try {
                                    if (supermarket.isFavorite) {
                                      // Try to clear favorite (will fail if it's the only one)
                                      final success = await ref
                                          .read(supermarketsProvider.notifier)
                                          .clearFavoriteSupermarket(supermarket.id);
                                      
                                      if (!success && mounted) {
                                        // Show message explaining why favorite couldn't be cleared
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text(
                                              'Cannot remove favorite: You must have at least one favorite supermarket. Select a different one first.',
                                            ),
                                            backgroundColor: Theme.of(context).colorScheme.primary,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    } else {
                                      // Set as favorite (will clear previous favorite)
                                      await ref
                                          .read(supermarketsProvider.notifier)
                                          .setFavoriteSupermarket(supermarket.id);
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error updating favorite: ${e.toString()}',
                                          ),
                                          backgroundColor:
                                              Theme.of(context).colorScheme.error,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  }
                                },
                                color: supermarket.isFavorite
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.outline,
                              ),
                              // Edit button
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          SupermarketCustomizationScreen(
                                            supermarket: supermarket,
                                          ),
                                    ),
                                  );
                                },
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            );
          },
        ),
        floatingActionButton: _selectionActive
            ? FloatingActionButton(
                heroTag: 'deleteSupermarketsFAB',
                onPressed: () => _deleteSelectedWithCallback(context),
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
                child: const Icon(Icons.delete),
              )
            : widget.floatingActionButton,
      ),
    );
  }
}
