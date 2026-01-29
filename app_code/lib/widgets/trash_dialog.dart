import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/providers/real_app_providers/shopping_lists_notifier.dart';

class TrashDialog extends ConsumerWidget {
  const TrashDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoppingListsAsync = ref.watch(shoppingListsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return shoppingListsAsync.when(
      loading: () => AlertDialog(
        title: const Text('Trash'),
        content: const SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
      error: (error, _) => AlertDialog(
        title: const Text('Trash'),
        content: Text('Error: $error'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
      data: (lists) {
        final trashedLists = lists.where((l) => l.getIsInTheTrash()).toList();

        return AlertDialog(
          title: const Text('Trash'),
          content: SizedBox(
            width: double.maxFinite,
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
                      return ListTile(
                        title: Text(list.getName()),
                        subtitle: Text(
                          list.getDeletionMessage(),
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                        trailing: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            TextButton(
                              onPressed: () async {
                                await ref
                                    .read(shoppingListsProvider.notifier)
                                    .updateList(list..setIsInTheTrash(false));
                              },
                              child: const Text('Restore'),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: colorScheme.error,
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Delete permanently'),
                                    content: Text(
                                      "Are you sure you want to permanently delete '${list.getName()}'?",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          await ref
                                              .read(shoppingListsProvider
                                                  .notifier)
                                              .deleteList(list);
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: colorScheme.error,
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
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
