import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/providers/real_app_providers/supermarkets_notifier.dart';
import 'package:app_code/screens/supermarket/supermarket_customization_screen.dart';
import 'package:app_code/widgets/app_snackbar.dart';

class SupermarketsScreenMobile extends ConsumerWidget {
  const SupermarketsScreenMobile({super.key});

  /// Show dialog to add a new supermarket
  Future<void> _showAddSupermarketDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

        return MediaQuery(
          data: MediaQuery.of(context).copyWith(viewInsets: EdgeInsets.zero),
          child: AlertDialog(
            title: const Text("Add new supermarket"),
            content: Container(
              width: double.maxFinite,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: keyboardHeight),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Please enter the supermarket name:"),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: "Supermarket name",
                        border: OutlineInputBorder(),
                      ),
                      autofocus: true,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                ),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = controller.text.trim();
                  if (name.isEmpty) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        buildAppSnackBar(
                          message: 'Please enter a supermarket name',
                          isError: true,
                          context: context,
                        ),
                      );
                    }
                    return;
                  }

                  // Get the last created supermarket to use as template
                  final lastSupermarket =
                      await ref.read(supermarketsProvider.notifier)
                          .getLastCreatedSupermarket();

                  // Create new supermarket with categories from the last one
                  final newSupermarket = Supermarket(
                    name: name,
                    categories: lastSupermarket?.getCategories() ?? [],
                  );

                  await ref
                      .read(supermarketsProvider.notifier)
                      .addSupermarket(newSupermarket);

                  if (context.mounted) {
                    Navigator.pop(context);
                    // Navigate to customization screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SupermarketCustomizationScreen(supermarket: newSupermarket),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: const Text("Add"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        final visibleSupermarkets =
            supermarkets.where((s) => s.isVisible).toList();

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('Supermarkets'),
            elevation: 0,
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          ),
          body: visibleSupermarkets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.store_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No supermarkets yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your first supermarket to get started',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 0,
                  ),
                  itemCount: visibleSupermarkets.length,
                  itemBuilder: (context, index) {
                    final supermarket = visibleSupermarkets[index];

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          title: Text(
                            supermarket.getName(),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Text(
                            '${supermarket.getCategories().length} categories',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Favorite/Star button
                              IconButton(
                                icon: const Icon(Icons.star_outline),
                                onPressed: () {
                                  // TODO: Implement favorite functionality
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    buildAppSnackBar(
                                      message: 'Favorite feature coming soon',
                                      isError: false,
                                      context: context,
                                    ),
                                  );
                                },
                                color:
                                    Theme.of(context).colorScheme.primary,
                              ),
                              // Edit button
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          SupermarketCustomizationScreen(
                                        supermarket: supermarket,
                                      ),
                                    ),
                                  );
                                },
                                color:
                                    Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'addSupermarketFAB',
            onPressed: () =>
                _showAddSupermarketDialog(context, ref),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
