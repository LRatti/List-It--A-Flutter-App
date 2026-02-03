import 'package:app_code/providers/real_app_providers/supermarket/supermarkets_notifier.dart';
import 'package:app_code/utils/uncategorized_category_initializer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/repositories/sync/supermarket_repository_sync.dart';
import 'package:app_code/services/database/sqlite/manage_supermarket.dart'
		as sqlite_supermarket;

/// AsyncNotifier that manages the currently selected supermarket.
///
/// - Loads an initial selection from the favorite supermarket if available.
/// - Falls back to the first visible supermarket when no favorite exists.
/// - Exposes simple APIs to select, clear, and refresh the selection.
class SelectedSupermarketNotifier extends AsyncNotifier<Supermarket?> {
	late final SupermarketRepositoryWithSync _repo =
			SupermarketRepositoryWithSync();

	@override
	Future<Supermarket?> build() async {
		return _loadInitialSelection();
	}

	/// Select a specific supermarket instance (in-memory only).
	Future<void> setSelectedSupermarket(Supermarket? supermarket) async {
		state = AsyncValue.data(supermarket);
	}

	/// Select a supermarket by its ID (loads fresh data from storage).
	Future<void> selectById(String id) async {
		state = await AsyncValue.guard(() async {
			return _repo.getById(id);
		});
	}

	/// Clear the current selection.
	Future<void> clearSelection() async {
		state = const AsyncValue.data(null);
	}

	/// Refresh the current selection from storage.
	/// If it no longer exists or is invisible, fall back to the initial selection.
	Future<void> refreshSelection() async {
		final current = state.value;
		if (current == null) {
			state = AsyncValue.data(await _loadInitialSelection());
			return;
		}

		state = await AsyncValue.guard(() async {
			final refreshed = await _repo.getById(current.id);
			if (refreshed == null || !refreshed.isVisible) {
				return _loadInitialSelection();
			}
			return refreshed;
		});
	}

	Future<Supermarket?> _loadInitialSelection() async {
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
    return newSupermarket;
  } 
}

/// Provider for the selected supermarket state.
final selectedSupermarketProvider =
		AsyncNotifierProvider<SelectedSupermarketNotifier, Supermarket?>(
			SelectedSupermarketNotifier.new,
		);

/// Convenience provider to get the current value synchronously.
/// Returns null while loading or on error.
final selectedSupermarketValueProvider = Provider<Supermarket?>((ref) {
	final async = ref.watch(selectedSupermarketProvider);
	return async.when(
		data: (value) => value,
		loading: () => null,
		error: (_, __) => null,
	);
});
