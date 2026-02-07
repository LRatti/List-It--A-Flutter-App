import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/providers/real_app_providers/supermarket/supermarkets_notifier.dart';
import 'package:app_code/screens/supermarket/supermarket_customization_screen.dart';
import 'package:app_code/widgets/searchable_supermarkets_view.dart';
import 'package:app_code/utils/uncategorized_category_initializer.dart';
import 'package:app_code/l10n/app_localizations.dart';

class SupermarketsScreenMobile extends ConsumerStatefulWidget {
  const SupermarketsScreenMobile({super.key});

  @override
  ConsumerState<SupermarketsScreenMobile> createState() =>
      _SupermarketsScreenMobileState();
}

class _SupermarketsScreenMobileState
    extends ConsumerState<SupermarketsScreenMobile> {
  void _handleDeletionModeChanged(bool isDeletionMode) {
    // No-op: deletion mode is now handled by SearchableSupermarketsView
  }

  /// Navigate to supermarket customization screen to create a new supermarket
  void _navigateToCreateSupermarket(BuildContext context) async {
    // Create an empty supermarket for creation mode
    // Get the last edited supermarket to use as template
    final lastSupermarket = await ref
      .read(supermarketsProvider.notifier)
      .getLastEditedSupermarket();
    final uncategorized =
        await UncategorizedCategoryInitializer.getUncategorized();

    final templateCategories = lastSupermarket?.getCategories() ?? [];
    final hasUncategorized = templateCategories
        .any((cat) => cat.id == uncategorized.id);

    final newSupermarket = Supermarket(
      name: '',
      categories: hasUncategorized
          ? templateCategories
          : [uncategorized, ...templateCategories],
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SupermarketCustomizationScreen(
          supermarket: newSupermarket,
          isCreationMode: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final supermarketsAsync = ref.watch(supermarketsProvider);
    final l10n = AppLocalizations.of(context)!;

    return supermarketsAsync.when(
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: Text(l10n.errorWithDetails(error.toString()))),
      ),
      data: (supermarkets) {
        // Filter only visible supermarkets
        final visibleSupermarkets = supermarkets
            .where((s) => s.isVisible)
            .toList();

        // Show favorite supermarket first
        visibleSupermarkets.sort((a, b) {
          if (a.isFavorite == b.isFavorite) {
            return a.getName().compareTo(b.getName());
          }
          return b.isFavorite ? 1 : -1;
        });

        return SearchableSupermarketsView(
          supermarkets: visibleSupermarkets,
          emptyMessage: l10n.noSupermarketsYet,
          onDeletionModeChanged: _handleDeletionModeChanged,
          floatingActionButton: FloatingActionButton(
            heroTag: 'addSupermarketFAB_mobile',
            onPressed: () => _navigateToCreateSupermarket(context),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
