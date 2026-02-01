import 'package:app_code/repositories/mock_repo/mock_gemini_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/repositories/abstract/gemini_repository.dart';
import 'package:app_code/repositories/real_app_repo/gemini_repository_real.dart';

/// Background product categorization search state
class BackgroundProductCategorization {
  final String id;
  final String productName;
  final AsyncValue<String> result;
  final bool isCompleted;

  BackgroundProductCategorization({
    required this.id,
    required this.productName,
    required this.result,
    required this.isCompleted,
  });

  BackgroundProductCategorization copyWith({
    String? id,
    String? productName,
    AsyncValue<String>? result,
    bool? isCompleted,
  }) {
    return BackgroundProductCategorization(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      result: result ?? this.result,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// State notifier for background product categorization
class BackgroundProductCategorizationNotifier
    extends Notifier<Map<String, BackgroundProductCategorization>> {
  @override
  Map<String, BackgroundProductCategorization> build() {
    return {};
  }

  /// Start a background product categorization
  Future<void> startBackgroundCategorization({
    required String id,
    required String productName,
    required List<Category> categories,
  }) async {
    // Get repository from ref
    final geminiRepository = ref.read(productCategorizationRepositoryProvider);

    // Initialize the search state as loading
    state = {
      ...state,
      id: BackgroundProductCategorization(
        id: id,
        productName: productName,
        result: const AsyncValue.loading(),
        isCompleted: false,
      ),
    };

    // Perform the categorization in background
    final result = await AsyncValue.guard(() async {
      return await geminiRepository.categorizeProduct(
        productName: productName,
        categories: categories,
      );
    });

    // Check if the request still exists
    if (!state.containsKey(id)) {
      return;
    }

    // Update state with result and mark as completed
    state = {
      ...state,
      id: BackgroundProductCategorization(
        id: id,
        productName: productName,
        result: result,
        isCompleted: true,
      ),
    };
  }

  /// Get the categorization result for a specific id
  BackgroundProductCategorization? getCategorization(String id) {
    return state[id];
  }

  /// Clear the categorization result for a specific id
  Future<void> clearCategorization(String id) async {
    state = {...state}..remove(id);
  }

  /// Clear all categorizations
  Future<void> clearAllCategorizations() async {
    state = {};
  }
}

/// Provides the Gemini repository for product categorization
/// TODO: switch to real repository from MockGeminiRepository() to GeminiRepositoryReal() when needed
final productCategorizationRepositoryProvider =
    Provider<GeminiRepository>((ref) {
  return MockGeminiRepository();
});

/// Provider for background product categorization
final backgroundProductCategorizationProvider =
    NotifierProvider<BackgroundProductCategorizationNotifier,
        Map<String, BackgroundProductCategorization>>(
  () => BackgroundProductCategorizationNotifier(),
);
