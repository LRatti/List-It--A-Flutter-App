import 'package:flutter_test/flutter_test.dart';
import 'package:app_code/models/nearby_supermarket.dart';

void main() {
  group('NearbySupermarket Tests', () {
    test('creates instance with correct values', () {
      final supermarket = NearbySupermarket(
        name: 'Tesco',
        latitude: 51.5074,
        longitude: -0.1278,
        distanceInMeters: 250.0,
      );

      expect(supermarket.name, 'Tesco');
      expect(supermarket.latitude, 51.5074);
      expect(supermarket.longitude, -0.1278);
      expect(supermarket.distanceInMeters, 250.0);
    });

    test('formats distance in meters correctly', () {
      final supermarket = NearbySupermarket(
        name: 'Tesco',
        latitude: 51.5074,
        longitude: -0.1278,
        distanceInMeters: 250.0,
      );

      expect(supermarket.formattedDistance, '250m');
    });

    test('formats distance in kilometers correctly', () {
      final supermarket = NearbySupermarket(
        name: 'Tesco',
        latitude: 51.5074,
        longitude: -0.1278,
        distanceInMeters: 2500.0,
      );

      expect(supermarket.formattedDistance, '2.5km');
    });

    test('formats distance correctly at boundary (999m)', () {
      final supermarket = NearbySupermarket(
        name: 'Tesco',
        latitude: 51.5074,
        longitude: -0.1278,
        distanceInMeters: 999.0,
      );

      expect(supermarket.formattedDistance, '999m');
    });

    test('formats distance correctly at boundary (1000m)', () {
      final supermarket = NearbySupermarket(
        name: 'Tesco',
        latitude: 51.5074,
        longitude: -0.1278,
        distanceInMeters: 1000.0,
      );

      expect(supermarket.formattedDistance, '1.0km');
    });

    test('rounds distance correctly', () {
      final supermarket = NearbySupermarket(
        name: 'Tesco',
        latitude: 51.5074,
        longitude: -0.1278,
        distanceInMeters: 123.7,
      );

      expect(supermarket.formattedDistance, '124m');
    });

    test('toString returns formatted string', () {
      final supermarket = NearbySupermarket(
        name: 'Tesco Extra',
        latitude: 51.5074,
        longitude: -0.1278,
        distanceInMeters: 250.0,
      );

      expect(supermarket.toString(), 'Tesco Extra (250m)');
    });

    test('creates from Overpass API response with tags', () {
      final element = {
        'lat': 51.5074,
        'lon': -0.1278,
        'tags': {
          'name': 'Tesco Metro',
          'brand': 'Tesco',
        },
      };

      final supermarket = NearbySupermarket.fromOverpassElement(
        element,
        51.5074,
        -0.1278,
      );

      expect(supermarket.name, 'Tesco Metro');
      expect(supermarket.latitude, 51.5074);
      expect(supermarket.longitude, -0.1278);
      expect(supermarket.distanceInMeters, greaterThanOrEqualTo(0));
    });

    test('creates from Overpass API response with brand fallback', () {
      final element = {
        'lat': 51.5074,
        'lon': -0.1278,
        'tags': {
          'brand': 'Sainsbury\'s',
        },
      };

      final supermarket = NearbySupermarket.fromOverpassElement(
        element,
        51.5074,
        -0.1278,
      );

      expect(supermarket.name, 'Sainsbury\'s');
    });

    test('creates from Overpass API response with default name', () {
      final element = {
        'lat': 51.5074,
        'lon': -0.1278,
        'tags': <String, dynamic>{},
      };

      final supermarket = NearbySupermarket.fromOverpassElement(
        element,
        51.5074,
        -0.1278,
      );

      expect(supermarket.name, 'Supermarket');
    });

    test('calculates distance correctly between close locations', () {
      // Two locations 111 meters apart (roughly 0.001 degrees at equator)
      final element = {
        'lat': 51.5084,
        'lon': -0.1268,
        'tags': {'name': 'Test Supermarket'},
      };

      final supermarket = NearbySupermarket.fromOverpassElement(
        element,
        51.5074,
        -0.1278,
      );

      // Distance should be roughly 150-200 meters (diagonal)
      expect(supermarket.distanceInMeters, greaterThan(100));
      expect(supermarket.distanceInMeters, lessThan(500));
    });

    test('calculates distance correctly between different locations', () {
      // London to Paris is roughly 340km
      final element = {
        'lat': 48.8566,
        'lon': 2.3522,
        'tags': {'name': 'Supermarche'},
      };

      final supermarket = NearbySupermarket.fromOverpassElement(
        element,
        51.5074,
        -0.1278,
      );

      // Should be roughly 340km
      final distanceKm = supermarket.distanceInMeters / 1000;
      expect(distanceKm, greaterThan(300));
      expect(distanceKm, lessThan(400));
    });

    test('handles zero distance (same location)', () {
      final element = {
        'lat': 51.5074,
        'lon': -0.1278,
        'tags': {'name': 'Test Supermarket'},
      };

      final supermarket = NearbySupermarket.fromOverpassElement(
        element,
        51.5074,
        -0.1278,
      );

      expect(supermarket.distanceInMeters, lessThan(1));
    });

    test('handles edge case: supermarket at North Pole', () {
      final element = {
        'lat': 90.0,
        'lon': 0.0,
        'tags': {'name': 'Arctic Supermarket'},
      };

      final supermarket = NearbySupermarket.fromOverpassElement(
        element,
        51.5074,
        -0.1278,
      );

      expect(supermarket.distanceInMeters, greaterThan(4000000)); // ~4000km
    });

    test('handles edge case: supermarket at South Pole', () {
      final element = {
        'lat': -90.0,
        'lon': 0.0,
        'tags': {'name': 'Antarctic Supermarket'},
      };

      final supermarket = NearbySupermarket.fromOverpassElement(
        element,
        51.5074,
        -0.1278,
      );

      expect(supermarket.distanceInMeters, greaterThan(12000000)); // ~12000km
    });

    test('handles negative coordinates (Southern hemisphere)', () {
      final element = {
        'lat': -33.8688,
        'lon': 151.2093,
        'tags': {'name': 'Sydney Supermarket'},
      };

      final supermarket = NearbySupermarket.fromOverpassElement(
        element,
        51.5074,
        -0.1278,
      );

      expect(supermarket.latitude, -33.8688);
      expect(supermarket.longitude, 151.2093);
      expect(supermarket.distanceInMeters, greaterThan(16000000)); // ~17000km
    });
  });
}
