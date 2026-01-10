import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/repositories/abstract/supermarket_location_repository.dart';
import 'package:app_code/repositories/real_app_repo/overpass_supermarket_location_repository.dart';

/// Provider for supermarket location repository
final supermarketLocationRepositoryProvider =
    Provider<SupermarketLocationRepository>((ref) {
  return OverpassSupermarketLocationRepository();
});
