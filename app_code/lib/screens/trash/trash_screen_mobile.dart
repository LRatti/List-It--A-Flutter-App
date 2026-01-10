import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/providers/shopping_lists_notifier.dart';

class TrashScreenMobile extends ConsumerWidget {
  const TrashScreenMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoppingListsAsync = ref.watch(shoppingListsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash'),
        centerTitle: true,
      ),
      body: shoppingListsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (lists) {
          final trashedLists = lists.where((l) => l.getIsRegistered()).toList();

          if (trashedLists.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Trash is empty'),
              ),
            );
          }

          return ListView.builder(
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
                              .updateList(list..setIsRegistered(false));
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
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    await ref
                                        .read(
                                            shoppingListsProvider.notifier)
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
          );
        },
      ),
    );
  }
}
