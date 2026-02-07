import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/l10n/app_localizations.dart';
import 'package:app_code/providers/real_app_providers/shopping_list/shopping_lists_notifier.dart';

class TrashDialog extends ConsumerWidget {
  const TrashDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoppingListsAsync = ref.watch(shoppingListsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return shoppingListsAsync.when(
      loading: () => AlertDialog(
        title: Text(l10n.trashLabel),
        content: const SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.closeLabel),
          ),
        ],
      ),
      error: (error, _) => AlertDialog(
        title: Text(l10n.trashLabel),
        content: Text(l10n.errorWithDetails(error.toString())),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.closeLabel),
          ),
        ],
      ),
      data: (lists) {
        final trashedLists = lists.where((l) => l.getIsInTheTrash()).toList();

        return AlertDialog(
          title: Text(l10n.trashLabel),
          content: SizedBox(
            width: double.maxFinite,
            child: trashedLists.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(l10n.trashEmptyMessage),
                    ),
                  )
                : ListView.builder(
                    itemCount: trashedLists.length,
                    itemBuilder: (context, index) {
                      final list = trashedLists[index];
                      return ListTile(
                        title: Text(list.getName()),
                        subtitle: Text(
                          list.getDeletionMessage(l10n),
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
                              child: Text(l10n.restoreLabel),
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
                                    title: Text(l10n.deletePermanentlyTitle),
                                    content: Text(
                                      l10n.deleteListPermanentlyConfirm(list.getName()),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(l10n.cancelLabel),
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
                                        child: Text(l10n.deleteLabel),
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
              child: Text(l10n.closeLabel),
            ),
          ],
        );
      },
    );
  }
}
