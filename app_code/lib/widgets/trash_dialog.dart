import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/providers/shopping_lists_notifier.dart';

class TrashDialog extends ConsumerWidget {
  const TrashDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoppingListsAsync = ref.watch(shoppingListsProvider);

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
                          'Delete in 30 days',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        trailing: SizedBox(
                          width: 150,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () async {
                                  // Restore the list
                                  await ref
                                      .read(shoppingListsProvider.notifier)
                                      .updateList(list..setIsInTheTrash(false));
                                },
                                child: const Text('Restore'),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
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
                                          onPressed: () =>
                                              Navigator.pop(context),
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
                                            backgroundColor: Colors.red,
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
