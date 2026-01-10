import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/repositories/abstract/location_repository.dart';
import 'package:app_code/repositories/real_app_repo/geolocator_location_repository.dart';

/// Provider for location repository
final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return GeolocatorLocationRepository();
});
