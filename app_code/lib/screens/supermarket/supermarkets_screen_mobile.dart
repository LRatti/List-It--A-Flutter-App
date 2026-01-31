import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/providers/real_app_providers/supermarkets_notifier.dart';
import 'package:app_code/screens/supermarket/supermarket_customization_screen.dart';
import 'package:app_code/widgets/searchable_supermarkets_view.dart';

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
    final newSupermarket = Supermarket(
      name: '',
      categories: lastSupermarket?.getCategories() ?? [],
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

    return supermarketsAsync.when(
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: Text('Error: ${error.toString()}')),
      ),
      data: (supermarkets) {
        // Filter only visible supermarkets
        final visibleSupermarkets = supermarkets
            .where((s) => s.isVisible)
            .toList();

        return SearchableSupermarketsView(
          supermarkets: visibleSupermarkets,
          emptyMessage: 'No supermarkets yet',
          onDeletionModeChanged: _handleDeletionModeChanged,
          floatingActionButton: FloatingActionButton(
            heroTag: 'addSupermarketFAB',
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
