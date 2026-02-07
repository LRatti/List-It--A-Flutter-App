import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/providers/real_app_providers/supermarket/supermarkets_notifier.dart';
import 'package:app_code/screens/supermarket/supermarket_customization_screen.dart';
import 'package:app_code/widgets/searchable_supermarkets_view.dart';
import 'package:app_code/utils/uncategorized_category_initializer.dart';
import 'package:app_code/utils/responsive_layout.dart';
import 'package:app_code/l10n/app_localizations.dart';

/// Mobile supermarkets screen: searchable list view.
class SupermarketsScreenMobile extends ConsumerWidget {
  const SupermarketsScreenMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        final visibleSupermarkets = _getVisibleSupermarkets(supermarkets);

        return SearchableSupermarketsView(
          supermarkets: visibleSupermarkets,
          emptyMessage: l10n.noSupermarketsYet,
          onDeletionModeChanged: _handleDeletionModeChanged,
          floatingActionButton: FloatingActionButton(
            heroTag: 'addSupermarketFAB',
            onPressed: () => _navigateToCreateSupermarket(
              context: context,
              ref: ref,
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

/// Tablet supermarkets screen: responsive grid view.
class SupermarketsScreenTablet extends ConsumerWidget {
  const SupermarketsScreenTablet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        final visibleSupermarkets = _getVisibleSupermarkets(supermarkets);

        return ResponsiveGridView(
          children: visibleSupermarkets
              .map((supermarket) => _SupermarketCard(
                    supermarket: supermarket,
                  ))
              .toList(),
          mobileColumns: 1,
          tabletColumns: 2,
          desktopColumns: 3,
        );
      },
    );
  }
}

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

void _handleDeletionModeChanged(bool isDeletionMode) {
  // Deletion mode is handled by SearchableSupermarketsView
}

Future<void> _navigateToCreateSupermarket({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final lastSupermarket = await ref
      .read(supermarketsProvider.notifier)
      .getLastEditedSupermarket();
  final uncategorized = await UncategorizedCategoryInitializer.getUncategorized();

  final templateCategories = lastSupermarket?.getCategories() ?? [];
  final hasUncategorized =
      templateCategories.any((cat) => cat.id == uncategorized.id);

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

/// Supermarket card widget for grid display
class _SupermarketCard extends ConsumerWidget {
  final Supermarket supermarket;

  const _SupermarketCard({
    required this.supermarket,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SupermarketCustomizationScreen(
                supermarket: supermarket,
                isCreationMode: false,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name and favorite indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      supermarket.getName(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (supermarket.isFavorite)
                    Icon(
                      Icons.favorite,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Category count
              Row(
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.categoriesCountLabel(supermarket.getCategories().length),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Location if available
              // if (supermarket.latitude != null && supermarket.longitude != null)
              //   Row(
              //     children: [
              //       Icon(
              //         Icons.location_on_outlined,
              //         size: 16,
              //         color: colorScheme.onSurfaceVariant,
              //       ),
              //       const SizedBox(width: 4),
              //       Text(
              //         '${supermarket.latitude!.toStringAsFixed(2)}, ${supermarket.longitude!.toStringAsFixed(2)}',
              //         style: Theme.of(context).textTheme.bodySmall?.copyWith(
              //           color: colorScheme.onSurfaceVariant,
              //         ),
              //         maxLines: 1,
              //         overflow: TextOverflow.ellipsis,
              //       ),
              //     ],
              //   ),

              const Spacer(),

              // Edit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SupermarketCustomizationScreen(
                          supermarket: supermarket,
                          isCreationMode: false,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: Text(l10n.editLabel),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
