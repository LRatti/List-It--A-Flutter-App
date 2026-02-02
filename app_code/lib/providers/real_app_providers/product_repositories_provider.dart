import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/repositories/sync/product_repository_sync.dart';
import 'package:app_code/repositories/sync/purchased_product_repository_sync.dart';
import 'package:app_code/repositories/sync/association_repository_sync.dart';

/// Provides the product repository implementation.
final productRepositoryProvider =
    Provider<ProductRepositoryWithSync>((ref) {
  return ProductRepositoryWithSync();
});

/// Provides the purchased product repository implementation.
final purchasedProductRepositoryProvider =
    Provider<PurchasedProductRepositoryWithSync>((ref) {
  return PurchasedProductRepositoryWithSync();
});

/// Provides the association repository implementation.
final associationRepositoryProvider =
    Provider<AssociationRepositoryWithSync>((ref) {
  return AssociationRepositoryWithSync();
});
