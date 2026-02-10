import 'package:app_code/l10n/app_localizations.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/providers/real_app_providers/supermarket/supermarkets_notifier.dart';
import 'package:app_code/screens/supermarket/supermarket_customization_screen.dart';
import 'package:app_code/utils/uncategorized_category_initializer.dart';
import 'package:app_code/widgets/detail_pane_navigator.dart';
import 'package:app_code/widgets/searchable_supermarkets_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================================================
// Common Helper Functions
// ============================================================================

/// Filters and sorts supermarkets: visible only, favorites first, then alphabetically.
List<Supermarket> _getVisibleSupermarkets(List<Supermarket> supermarkets) {
  final visibleSupermarkets = supermarkets.where((s) => s.isVisible).toList();

  visibleSupermarkets.sort((a, b) {
    if (a.isFavorite == b.isFavorite) {
      return a.getName().compareTo(b.getName());
    }
    return b.isFavorite ? 1 : -1;
  });

  return visibleSupermarkets;
}

/// Creates a new supermarket with template categories from the last edited supermarket.
Future<Supermarket> _createNewSupermarket(WidgetRef ref) async {
  final lastSupermarket = await ref
      .read(supermarketsProvider.notifier)
      .getLastEditedSupermarket();
  final uncategorized =
      await UncategorizedCategoryInitializer.getUncategorized();

  final templateCategories = List<Category>.from(
    lastSupermarket?.getCategories() ?? [],
  );
  final hasUncategorized = templateCategories.any(
    (cat) => cat.id == uncategorized.id,
  );

  if (hasUncategorized) {
    templateCategories.removeWhere((cat) => cat.id == uncategorized.id);
    templateCategories.insert(0, uncategorized);
  }

  return Supermarket(
    name: '',
    categories: hasUncategorized
        ? templateCategories
        : [uncategorized, ...templateCategories],
  );
}

/// Builds a loading scaffold.
Widget _buildLoadingScaffold(BuildContext context) {
  return Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    body: const Center(child: CircularProgressIndicator()),
  );
}

/// Builds an error scaffold with localized message.
Widget _buildErrorScaffold(BuildContext context, Object error) {
  final l10n = AppLocalizations.of(context)!;
  return Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    body: Center(child: Text(l10n.errorWithDetails(error.toString()))),
  );
}

// ============================================================================
// Mobile Screen
// ============================================================================

/// Mobile supermarkets screen: searchable list view.
class SupermarketsScreenMobile extends ConsumerWidget {
  const SupermarketsScreenMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supermarketsAsync = ref.watch(supermarketsProvider);
    final l10n = AppLocalizations.of(context)!;

    return supermarketsAsync.when(
      loading: () => _buildLoadingScaffold(context),
      error: (error, _) => _buildErrorScaffold(context, error),
      data: (supermarkets) {
        final visibleSupermarkets = _getVisibleSupermarkets(supermarkets);

        return SearchableSupermarketsView(
          supermarkets: visibleSupermarkets,
          emptyMessage: l10n.noSupermarketsYet,
          floatingActionButton: FloatingActionButton(
            heroTag: 'addSupermarketFAB_mobile_view',
            onPressed: () => _navigateToCreateSupermarketMobile(context, ref),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Future<void> _navigateToCreateSupermarketMobile(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final newSupermarket = await _createNewSupermarket(ref);

    if (context.mounted) {
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
  }
}

// ============================================================================
// Tablet Screen
// ============================================================================

/// Tablet supermarkets screen: master-detail split view.
class SupermarketsScreenTablet extends ConsumerStatefulWidget {
  const SupermarketsScreenTablet({super.key});

  @override
  ConsumerState<SupermarketsScreenTablet> createState() =>
      _SupermarketsScreenTabletState();
}

class _SupermarketsScreenTabletState
    extends ConsumerState<SupermarketsScreenTablet> {
  Supermarket? _selectedSupermarket;

  @override
  Widget build(BuildContext context) {
    final supermarketsAsync = ref.watch(supermarketsProvider);
    final l10n = AppLocalizations.of(context)!;

    return supermarketsAsync.when(
      loading: () => _buildLoadingScaffold(context),
      error: (error, _) => _buildErrorScaffold(context, error),
      data: (supermarkets) {
        final visibleSupermarkets = _getVisibleSupermarkets(supermarkets);

        _clearSelectedIfNotVisible(visibleSupermarkets);

        return Scaffold(
          body: Row(
            children: [
              _buildMasterPane(context, visibleSupermarkets, l10n),
              _buildDetailPane(context),
              
            ],
          ),
        );
      },
    );
  }

  /// Clears selected supermarket if it's no longer visible.
  void _clearSelectedIfNotVisible(List<Supermarket> visibleSupermarkets) {
    if (_selectedSupermarket != null &&
        !visibleSupermarkets.any((s) => s.id == _selectedSupermarket!.id)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _selectedSupermarket = null);
        }
      });
    }
  }

  /// Builds the master pane with the list of supermarkets.
  Widget _buildMasterPane(
    BuildContext context,
    List<Supermarket> visibleSupermarkets,
    AppLocalizations l10n,
  ) {
    return Flexible(
      flex: 40,
      child: SearchableSupermarketsView(
        supermarkets: visibleSupermarkets,
        emptyMessage: l10n.noSupermarketsYet,
        onSupermarketTap: (context, supermarket) {
          setState(() => _selectedSupermarket = supermarket);
        },
        floatingActionButton: FloatingActionButton(
          heroTag: 'addSupermarketFAB_tablet_master',
          onPressed: _navigateToCreateSupermarketTablet,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  /// Builds the detail pane with supermarket customization or empty state.
  Widget _buildDetailPane(BuildContext context) {
    final selection = _selectedSupermarket;
    _selectedSupermarket = null;
    return Flexible(
      flex: 60,
      child: selection != null
          ? DetailPaneNavigator(
              key: ValueKey(selection.id),
              selectionKey: selection.id,
              initialChild: SupermarketCustomizationScreen(
                supermarket: selection,
                isCreationMode: selection.getName().isEmpty ),
              emptyBuilder: _buildEmptyDetailPane,
            )
          : _buildEmptyDetailPane(context),
    );
  }

  /// Builds an empty detail pane when no supermarket is selected.
  Widget _buildEmptyDetailPane(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.selectSupermarketToViewDetails,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Navigates to create a new supermarket by selecting it in the master view.
  Future<void> _navigateToCreateSupermarketTablet() async {
    final newSupermarket = await _createNewSupermarket(ref);

    if (mounted) {
      setState(() => _selectedSupermarket = newSupermarket);
    }
  }
}
