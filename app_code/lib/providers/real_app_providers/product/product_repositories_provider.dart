import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/repositories/abstract/product_repository.dart';
import 'package:app_code/repositories/abstract/association_repository.dart';
import 'package:app_code/repositories/sync/product_repository_sync.dart';
import 'package:app_code/repositories/sync/purchased_product_repository_sync.dart';
import 'package:app_code/repositories/sync/association_repository_sync.dart';

/// Provides the product repository implementation.
final productRepositoryProvider =
    Provider<ProductRepository>((ref) {
  return ProductRepositoryWithSync();
});

/// Provides the purchased product repository implementation.
final purchasedProductRepositoryProvider =
    Provider<PurchasedProductRepositoryWithSync>((ref) {
  return PurchasedProductRepositoryWithSync();
});

/// Provides the association repository implementation.
final associationRepositoryProvider =
    Provider<AssociationRepository>((ref) {
  return AssociationRepositoryWithSync();
});
