import 'package:app_code/models/product.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/services/database/sqlite/manage_product.dart';

/// Helper class for managing purchased product updates
/// 
/// This class handles the logic of updating a purchased product's name,
/// ensuring that product references are properly managed and that renaming
/// one purchased product does not affect others.
/// 
/// Key Responsibility:
/// - When a purchased product's name changes, determine whether to create a new
///   product, reuse an existing product, or update an existing one
/// - Prevent shared product reference issues where modifying one purchased
///   product's product inadvertently affects others
class PurchasedProductUpdateHandler {
  
  /// Update a purchased product's name with proper product reference handling
  /// 
  /// This method implements the following logic:
  /// 
  /// 1. Check if a product with [newName] already exists in the database
  /// 2. If it exists:
  ///    - Update the purchased product to reference the existing product
  ///    - Preserve all associations and metadata
  /// 3. If it doesn't exist:
  ///    - Create a new product with [newName]
  ///    - Copy relevant associations from the old product if applicable
  ///    - Update the purchased product to reference the new product
  /// 
  /// This ensures that renaming a purchased product in one list does not
  /// affect purchased products in other lists, even if they originally had
  /// the same name.
  /// 
  /// Parameters:
  /// - [purchasedProduct]: The purchased product to update
  /// - [newName]: The new name for the product
  /// 
  /// Returns: The updated [PurchasedProduct] with the new product reference
  static Future<PurchasedProduct> updateProductName(
    PurchasedProduct purchasedProduct,
    String newName,
  ) async {
    // Validation: Skip update if name hasn't changed
    if (purchasedProduct.product.getName() == newName) {
      return purchasedProduct;
    }

    // 1. Look up existing product with the new name
    final existingProduct = await ManageProduct.getProductByName(newName);

    if (existingProduct != null) {
      // Case 1: Product with new name exists - reuse it
      // This handles the scenario where the user renames to match an existing product
      purchasedProduct.product = existingProduct;
    } else {
      // Case 2: Product with new name doesn't exist - create new product
      // This is the common case where we're creating a truly new product
      final newProduct = Product(
        name: newName,
        // Copy associations from the old product if they exist
        // This preserves category mappings in the supermarket
        associations: Map<String, String>.from(
          purchasedProduct.product.associations,
        ),
      );

      purchasedProduct.product = newProduct;
    }

    // Update the timestamp to reflect the modification
    purchasedProduct.lastModified = DateTime.now();

    return purchasedProduct;
  }

  /// Check if a product update would create a duplicate reference
  /// 
  /// In some cases, renaming a product might result in it having the same
  /// name as another product. This method helps detect such scenarios.
  /// 
  /// Returns: true if the new name matches an existing product
  static Future<bool> wouldCreateDuplicate(
    String newName,
    String currentProductId,
  ) async {
    final existingProduct = await ManageProduct.getProductByName(newName);
    return existingProduct != null && existingProduct.id != currentProductId;
  }
}
