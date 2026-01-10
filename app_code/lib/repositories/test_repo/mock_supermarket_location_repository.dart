import 'package:app_code/models/nearby_supermarket.dart';
import 'package:app_code/repositories/abstract/supermarket_location_repository.dart';

/// Mock implementation of SupermarketLocationRepository for testing
class MockSupermarketLocationRepository
    implements SupermarketLocationRepository {
  List<NearbySupermarket>? _mockSupermarkets;
  bool _shouldTimeout = false;
  bool _shouldFail = false;

  /// Set mock supermarkets to return
  void setMockSupermarkets(List<NearbySupermarket> supermarkets) {
    _mockSupermarkets = supermarkets;
  }

  /// Configure to simulate timeout
  void setShouldTimeout(bool timeout) {
    _shouldTimeout = timeout;
  }

  /// Configure to simulate network failure
  void setShouldFail(bool fail) {
    _shouldFail = fail;
  }

  /// Reset all configurations
  void reset() {
    _mockSupermarkets = null;
    _shouldTimeout = false;
    _shouldFail = false;
  }

  @override
  Future<List<NearbySupermarket>> fetchNearbySupermarkets({
    required double latitude,
    required double longitude,
    double radiusInMeters = 5000,
  }) async {
    if (_shouldTimeout) {
      await Future.delayed(const Duration(seconds: 20));
    }

    if (_shouldFail) {
      throw Exception('Network error: Unable to fetch supermarkets');
    }

    if (_mockSupermarkets != null) {
      return _mockSupermarkets!;
    }

    // Default: return some test supermarkets
    return [
      NearbySupermarket(
        name: 'Tesco Extra London',
        latitude: latitude + 0.001,
        longitude: longitude + 0.001,
        distanceInMeters: 150.0,
      ),
      NearbySupermarket(
        name: 'Sainsbury\'s London',
        latitude: latitude + 0.002,
        longitude: longitude + 0.002,
        distanceInMeters: 280.0,
      ),
      NearbySupermarket(
        name: 'Asda London',
        latitude: latitude + 0.003,
        longitude: longitude + 0.003,
        distanceInMeters: 450.0,
      ),
    ];
  }
}
