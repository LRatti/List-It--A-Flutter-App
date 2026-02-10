import 'package:flutter/material.dart';
import 'package:app_code/widgets/app_snackbar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/providers/real_app_providers/shopping_list/shopping_lists_notifier.dart';
import 'package:app_code/l10n/app_localizations.dart';

/// Mobile screen for managing trashed shopping lists, 
/// allowing restore or permanent deletion.
class TrashScreenMobile extends ConsumerWidget {
  const TrashScreenMobile({super.key});

  Future<void> _confirmRestoreAll(
    BuildContext context,
    WidgetRef ref,
    List<ShoppingList> trashedLists,
  ) async {
    if (trashedLists.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.restoreAllTitle),
        content: Text(l10n.restoreAllConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface, // adapt to light/dark
            ),
            child: Text(l10n.cancelLabel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: Text(l10n.restoreLabel),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final notifier = ref.read(shoppingListsProvider.notifier);
      await Future.wait(
        trashedLists.map((l) => notifier.updateList(l..setIsInTheTrash(false))),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        buildAppSnackBar(message: l10n.allListsRestoredMessage, context: context),
      );
    }
  }

  Future<void> _confirmEmptyTrash(
    BuildContext context,
    WidgetRef ref,
    List<ShoppingList> trashedLists,
  ) async {
    if (trashedLists.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.emptyTrashTitle),
        content: Text(l10n.emptyTrashConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
            child: Text(l10n.cancelLabel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.deleteAllLabel),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final notifier = ref.read(shoppingListsProvider.notifier);
      await Future.wait(trashedLists.map((l) => notifier.deleteList(l)));
      ScaffoldMessenger.of(context).showSnackBar(
        buildAppSnackBar(message: l10n.trashEmptiedMessage, context: context),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoppingListsAsync = ref.watch(shoppingListsProvider);
    final l10n = AppLocalizations.of(context)!;

    return shoppingListsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) =>
          Scaffold(body: Center(child: Text(l10n.errorWithDetails(error.toString())))),
      data: (lists) {
        final trashedLists = lists.where((l) => l.getIsInTheTrash()).toList()
          ..sort((a, b) {
            final ad =
                a.getCreatedAt();
            final bd =
                b.getCreatedAt();
            return bd.compareTo(ad); // newest first
          });

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.trashLabel),
            centerTitle: false,
            actions: [
              TextButton(
                onPressed: () => _confirmRestoreAll(context, ref, trashedLists),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                ),
                child: Text(l10n.restoreAllTitle),
              ),
              TextButton(
                onPressed: () => _confirmEmptyTrash(context, ref, trashedLists),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: Text(l10n.emptyTrashTitle),
              ),
            ],
          ),
          body: SafeArea(
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
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    list.getDeletionMessage(l10n),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
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
                                      tooltip: l10n.restoreLabel,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface, // adapt to light/dark
                                      onPressed: () async {
                                        await ref
                                            .read(shoppingListsProvider.notifier)
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
                                            title: Text(l10n.deletePermanentlyTitle),
                                            content: Text(
                                              l10n.deleteListPermanentlyConfirm(list.getName()),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                style: TextButton.styleFrom(
                                                  foregroundColor: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                                child: Text(l10n.cancelLabel),
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
                                                  backgroundColor: Theme.of(context)
                                                      .colorScheme
                                                      .error,
                                                  foregroundColor: Colors.white,
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
