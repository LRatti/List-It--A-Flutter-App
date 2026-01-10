import 'package:app_code/models/nearby_supermarket.dart';

/// Abstract repository for fetching nearby supermarkets
abstract class SupermarketLocationRepository {
  /// Fetch nearby supermarkets given latitude and longitude
  /// Returns list of supermarkets or empty list if none found or error occurs
  Future<List<NearbySupermarket>> fetchNearbySupermarkets({
    required double latitude,
    required double longitude,
    double radiusInMeters = 5000, // 5km default search radius
  });
}
