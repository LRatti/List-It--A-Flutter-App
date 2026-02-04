import 'package:app_code/providers/real_app_providers/supermarket/supermarkets_notifier.dart';
import 'package:app_code/utils/uncategorized_category_initializer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/repositories/sync/supermarket_repository_sync.dart';

/// AsyncNotifier that manages the currently selected supermarket.
///
/// - Loads an initial selection from the favorite supermarket if available.
/// - Falls back to the first visible supermarket when no favorite exists.
/// - Exposes simple APIs to select, clear, and refresh the selection.
class RefreshedSupermarketNotifier extends AsyncNotifier<Supermarket?> {
  late final SupermarketRepositoryWithSync _repo =
      SupermarketRepositoryWithSync();

  @override
  Future<Supermarket?> build() async {
    return _loadInitialSelection();
  }

  /// Select a specific supermarket instance (in-memory only).
  Future<void> setSupermarket(Supermarket? supermarket) async {
    state = AsyncValue.data(supermarket);
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
    // Default to null - callers should explicitly initialize
    return null;
  }
}

/// Provider for the selected supermarket state.
final refreshedSupermarketNotifier =
    AsyncNotifierProvider<RefreshedSupermarketNotifier, Supermarket?>(
      RefreshedSupermarketNotifier.new,
    );

/// Convenience provider to get the current value synchronously.
/// Returns null while loading or on error.
final refreshedSupermarketValueProvider = Provider<Supermarket?>((ref) {
  final async = ref.watch(refreshedSupermarketNotifier);
  return async.when(
    data: (value) => value,
    loading: () => null,
    error: (_, __) => null,
  );
});
