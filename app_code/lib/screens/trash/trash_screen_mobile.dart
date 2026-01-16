import 'package:flutter/material.dart';
import 'package:app_code/widgets/app_snackbar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/providers/real_app_providers/shopping_lists_notifier.dart';

class TrashScreenMobile extends ConsumerWidget {
  const TrashScreenMobile({super.key});

  Future<void> _confirmRestoreAll(
    BuildContext context,
    WidgetRef ref,
    List<ShoppingList> trashedLists,
  ) async {
    if (trashedLists.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restore all'),
        content: const Text(
          'Are you sure you want to restore all lists from trash?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final notifier = ref.read(shoppingListsProvider.notifier);
      for (final l in trashedLists) {
        await notifier.updateList(l..setIsInTheTrash(false));
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(buildAppSnackBar(message: 'All lists restored'));
    }
  }

  Future<void> _confirmEmptyTrash(
    BuildContext context,
    WidgetRef ref,
    List<ShoppingList> trashedLists,
  ) async {
    if (trashedLists.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Empty trash'),
        content: const Text(
          'This will permanently delete all lists in trash. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete all'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final notifier = ref.read(shoppingListsProvider.notifier);
      for (final l in trashedLists) {
        await notifier.deleteList(l);
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(buildAppSnackBar(message: 'Trash emptied'));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoppingListsAsync = ref.watch(shoppingListsProvider);

    return shoppingListsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('Error: $error'))),
      data: (lists) {
        final trashedLists = lists.where((l) => l.getIsInTheTrash()).toList()
          ..sort((a, b) {
            final ad =
                a.getCreatedAt() ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bd =
                b.getCreatedAt() ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bd.compareTo(ad); // newest first
          });

        return Scaffold(
          appBar: AppBar(
            title: const Text('Trash'),
            centerTitle: false,
            actions: [
              TextButton(
                onPressed: () => _confirmRestoreAll(context, ref, trashedLists),
                child: const Text('Restore all'),
              ),
              TextButton(
                onPressed: () => _confirmEmptyTrash(context, ref, trashedLists),
                child: Text(
                  'Empty trash',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: trashedLists.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Trash is empty'),
                    ),
                  )
                : ListView.builder(
                    itemCount: trashedLists.length,
                    itemBuilder: (context, index) {
                      final list = trashedLists[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    list.getName(),
                                    softWrap: true,
                                    maxLines: 4,
                                    overflow: TextOverflow.visible,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    list.getDeletionMessage(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Theme.of(context).hintColor),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              fit: FlexFit.loose,
                              child: Align(
                                alignment: Alignment.topRight,
                                child: Wrap(
                                  alignment: WrapAlignment.end,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.restore),
                                      tooltip: 'Restore',
                                      onPressed: () async {
                                        await ref
                                            .read(
                                              shoppingListsProvider.notifier,
                                            )
                                            .updateList(
                                              list..setIsInTheTrash(false),
                                            );
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: Theme.of(context).colorScheme.error,
                                      ),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text(
                                              'Delete permanently',
                                            ),
                                            content: Text(
                                              "Are you sure you want to permanently delete '${list.getName()}'?",
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  await ref
                                                      .read(
                                                        shoppingListsProvider
                                                            .notifier,
                                                      )
                                                      .deleteList(list);
                                                  if (context.mounted)
                                                    Navigator.pop(context);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Theme.of(context).colorScheme.error,
                                                ),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}
