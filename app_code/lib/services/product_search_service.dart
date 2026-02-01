import 'package:app_code/models/category.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/providers/real_app_providers/product_categorization_provider.dart';
import 'package:app_code/services/database/sqlite/manage_product.dart';
import 'package:app_code/utils/uncategorized_category_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service for searching and categorizing products
class ProductSearchService {
  final Ref ref;

  ProductSearchService(this.ref);

  /// Search for a product and categorize it if needed
  /// Returns the found/created product and its category
  Future<({Product product, Category category})> searchAndCategorize({
    required String productName,
    required String supermarketId,
    required List<Category> availableCategories,
  }) async {
    // 1. Check if product exists by name
    final existingProduct = await ManageProduct.getProductByName(productName);

    if (existingProduct != null) {
      // Product exists - check if it has association with this supermarket
      if (existingProduct.associations.containsKey(supermarketId)) {
        // Has association - use existing category
        final category = _getCategoryForProduct(
          existingProduct,
          supermarketId,
          availableCategories,
        );
        return (product: existingProduct, category: category);
      } else {
        // No association - categorize with Gemini and add association
        final category = await _categorizeAndAddAssociation(
          existingProduct,
          productName,
          supermarketId,
          availableCategories,
        );
        return (product: existingProduct, category: category);
      }
    }

    // 2. Product doesn't exist - create new and categorize with Gemini
    final newProduct = Product(name: productName);
    final category = await _categorizeAndAddAssociation(
      newProduct,
      productName,
      supermarketId,
      availableCategories,
    );

    return (product: newProduct, category: category);
  }

  /// Get category for an existing product
  Category _getCategoryForProduct(
    Product product,
    String supermarketId,
    List<Category> availableCategories,
  ) {
    // Check if product has association with this supermarket
    if (product.associations.containsKey(supermarketId)) {
      final categoryId = product.associations[supermarketId]!;
      final category = availableCategories.firstWhere(
        (cat) => cat.id == categoryId,
        orElse: () => availableCategories.firstWhere(
          (cat) => UncategorizedCategoryUtils.isUncategorized(cat),
          orElse: () =>
              UncategorizedCategoryUtils.fallbackFrom(availableCategories),
        ),
      );
      return category;
    }

    // No association - return uncategorized
    return UncategorizedCategoryUtils.fallbackFrom(availableCategories);
  }

  /// Categorize product using Gemini and add association to supermarket
  Future<Category> _categorizeAndAddAssociation(
    Product product,
    String productName,
    String supermarketId,
    List<Category> availableCategories,
  ) async {
    final categoryName = await _categorizeWithGemini(
      productName,
      availableCategories,
    );

    final category = availableCategories.firstWhere(
      (cat) => cat.getName().toLowerCase() == categoryName.toLowerCase(),
      orElse: () => UncategorizedCategoryUtils.fallbackFrom(availableCategories),
    );

    // Add association for this supermarket
    product.addAssociation(supermarketId, category.id);

    return category;
  }

  /// Categorize product name using Gemini
  Future<String> _categorizeWithGemini(
    String productName,
    List<Category> categories,
  ) async {
    try {
      final geminiRepository = ref.read(productCategorizationRepositoryProvider);
      final result = await geminiRepository.categorizeProduct(
        productName: productName,
        categories: categories,
      );
      return result;
    } catch (e) {
      // If categorization fails, return uncategorized
      return 'uncategorized';
    }
  }
}

/// Provider for ProductSearchService
final productSearchServiceProvider = Provider((ref) {
  return ProductSearchService(ref);
});
