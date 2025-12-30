import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/repositories/abstract/location_repository.dart';
import 'package:app_code/repositories/abstract/supermarket_location_repository.dart';
import 'package:app_code/repositories/test_repo/mock_location_repository.dart';
import 'package:app_code/repositories/test_repo/mock_supermarket_location_repository.dart';

/// Test-only providers that override the real implementations with mocks
/// for creating a controlled testing environment

late MockLocationRepository _mockLocationRepository;
late MockSupermarketLocationRepository _mockSupermarketRepository;

/// Initialize mock repositories for tests
void initializeTestRepositories() {
  _mockLocationRepository = MockLocationRepository();
  _mockSupermarketRepository = MockSupermarketLocationRepository();
}

/// Reset mock repositories after each test
void resetTestRepositories() {
  _mockLocationRepository.reset();
  _mockSupermarketRepository.reset();
}

/// Get the mock location repository
MockLocationRepository getMockLocationRepository() {
  return _mockLocationRepository;
}

/// Get the mock supermarket repository
MockSupermarketLocationRepository getMockSupermarketRepository() {
  return _mockSupermarketRepository;
}

/// Override provider that returns mock location repository
final testLocationRepositoryProvider = Provider<LocationRepository>((ref) {
  return _mockLocationRepository;
});

/// Override provider that returns mock supermarket repository
final testSupermarketLocationRepositoryProvider =
    Provider<SupermarketLocationRepository>((ref) {
  return _mockSupermarketRepository;
});
