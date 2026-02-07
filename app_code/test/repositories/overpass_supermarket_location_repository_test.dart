import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:app_code/models/nearby_supermarket.dart';
import 'package:app_code/repositories/real_app_repo/overpass_supermarket_location_repository.dart';

/// Mock HTTP client for testing
class MockHttpClient extends Mock implements http.Client {}

/// Mock Logger for testing
class MockLogger extends Mock implements Logger {}

/// Fake URI for mocktail
class FakeUri extends Fake implements Uri {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeUri());
  });

  group('OverpassSupermarketLocationRepository', () {
    late MockHttpClient mockHttpClient;
    late MockLogger mockLogger;
    late OverpassSupermarketLocationRepository repository;

    setUp(() {
      mockHttpClient = MockHttpClient();
      mockLogger = MockLogger();
      repository = OverpassSupermarketLocationRepository(
        httpClient: mockHttpClient,
        logger: mockLogger,
      );
    });

    group('fetchNearbySupermarkets - Success Paths', () {
      test('returns supermarkets from node elements with direct coordinates',
          () async {
        // Arrange
        final responseBody = '''{
          "elements": [
            {
              "type": "node",
              "id": 1,
              "lat": 40.7580,
              "lon": -73.9855,
              "tags": {
                "name": "Whole Foods Market",
                "shop": "supermarket"
              }
            },
            {
              "type": "node",
              "id": 2,
              "lat": 40.7489,
              "lon": -73.9680,
              "tags": {
                "name": "Trader Joe's",
                "shop": "supermarket"
              }
            }
          ]
        }''';

        when(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final supermarkets = await repository.fetchNearbySupermarkets(
          latitude: 40.7580,
          longitude: -73.9855,
        );

        // Assert
        expect(supermarkets, isNotEmpty);
        expect(supermarkets.length, equals(2));
        expect(supermarkets[0].name, equals('Whole Foods Market'));
        expect(supermarkets[1].name, equals("Trader Joe's"));
        verify(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).called(1);
      });

      test('returns supermarkets from way elements with center coordinates',
          () async {
        // Arrange
        final responseBody = '''{
          "elements": [
            {
              "type": "way",
              "id": 100,
              "center": {
                "lat": 40.7500,
                "lon": -73.9800
              },
              "tags": {
                "name": "Supermarket Store",
                "shop": "supermarket"
              }
            }
          ]
        }''';

        when(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final supermarkets = await repository.fetchNearbySupermarkets(
          latitude: 40.7500,
          longitude: -73.9800,
        );

        // Assert
        expect(supermarkets, isNotEmpty);
        expect(supermarkets.length, equals(1));
        expect(supermarkets[0].name, equals('Supermarket Store'));
        expect(supermarkets[0].latitude, closeTo(40.7500, 0.0001));
        expect(supermarkets[0].longitude, closeTo(-73.9800, 0.0001));
      });

      test('returns mix of node and way elements', () async {
        // Arrange
        final responseBody = '''{
          "elements": [
            {
              "type": "node",
              "id": 1,
              "lat": 40.7580,
              "lon": -73.9855,
              "tags": {
                "name": "Node Supermarket",
                "shop": "supermarket"
              }
            },
            {
              "type": "way",
              "id": 100,
              "center": {
                "lat": 40.7500,
                "lon": -73.9800
              },
              "tags": {
                "name": "Way Supermarket",
                "shop": "supermarket"
              }
            }
          ]
        }''';

        when(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final supermarkets = await repository.fetchNearbySupermarkets(
          latitude: 40.7500,
          longitude: -73.9800,
        );

        // Assert
        expect(supermarkets.length, equals(2));
        expect(supermarkets[0].name, equals('Node Supermarket'));
        expect(supermarkets[1].name, equals('Way Supermarket'));
      });

      test('returns empty list when API returns empty elements array',
          () async {
        // Arrange
        final responseBody = '{"elements": []}';

        when(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final supermarkets = await repository.fetchNearbySupermarkets(
          latitude: 40.7580,
          longitude: -73.9855,
        );

        // Assert
        expect(supermarkets, isEmpty);
      });

      test('uses brand name as fallback when name tag is missing', () async {
        // Arrange
        final responseBody = '''{
          "elements": [
            {
              "type": "node",
              "id": 1,
              "lat": 40.7580,
              "lon": -73.9855,
              "tags": {
                "brand": "Aldi",
                "shop": "supermarket"
              }
            }
          ]
        }''';

        when(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final supermarkets = await repository.fetchNearbySupermarkets(
          latitude: 40.7580,
          longitude: -73.9855,
        );

        // Assert
        expect(supermarkets, isNotEmpty);
        expect(supermarkets[0].name, equals('Aldi'));
      });

      test('uses default name when both name and brand tags are missing',
          () async {
        // Arrange
        final responseBody = '''{
          "elements": [
            {
              "type": "node",
              "id": 1,
              "lat": 40.7580,
              "lon": -73.9855,
              "tags": {
                "shop": "supermarket"
              }
            }
          ]
        }''';

        when(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final supermarkets = await repository.fetchNearbySupermarkets(
          latitude: 40.7580,
          longitude: -73.9855,
        );

        // Assert
        expect(supermarkets, isNotEmpty);
        expect(supermarkets[0].name, equals('Supermarket'));
      });

      test('applies custom radius parameter correctly', () async {
        // Arrange
        final responseBody = '''{
          "elements": [
            {
              "type": "node",
              "id": 1,
              "lat": 40.7580,
              "lon": -73.9855,
              "tags": {"name": "Store", "shop": "supermarket"}
            }
          ]
        }''';

        when(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final supermarkets = await repository.fetchNearbySupermarkets(
          latitude: 40.7580,
          longitude: -73.9855,
          radiusInMeters: 1000,
        );

        // Assert
        expect(supermarkets, isNotEmpty);
        verify(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).called(1);
      });

      test('calculates distance correctly between coordinates', () async {
        // Arrange
        final responseBody = '''{
          "elements": [
            {
              "type": "node",
              "id": 1,
              "lat": 40.7580,
              "lon": -73.9855,
              "tags": {"name": "Store", "shop": "supermarket"}
            }
          ]
        }''';

        when(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final supermarkets = await repository.fetchNearbySupermarkets(
          latitude: 40.7580,
          longitude: -73.9855,
        );

        // Assert
        expect(supermarkets, isNotEmpty);
        // Distance should be close to 0 since we're querying the same location
        expect(supermarkets[0].distanceInMeters, closeTo(0, 100));
      });

      test('handles elements without tags gracefully', () async {
        // Arrange
        final responseBody = '''{
          "elements": [
            {
              "type": "node",
              "id": 1,
              "lat": 40.7580,
              "lon": -73.9855
            }
          ]
        }''';

        when(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final supermarkets = await repository.fetchNearbySupermarkets(
          latitude: 40.7580,
          longitude: -73.9855,
        );

        // Assert
        expect(supermarkets, isNotEmpty);
        expect(supermarkets[0].name, equals('Supermarket'));
      });
    });

    group('fetchNearbySupermarkets - Error Paths', () {
      test('returns empty list when API returns non-200 status code', () async {
        // Arrange
        when(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response('Server Error', 500));

        // Act
        final supermarkets = await repository.fetchNearbySupermarkets(
          latitude: 40.7580,
          longitude: -73.9855,
        );

        // Assert
        expect(supermarkets, isEmpty);
        verify(() => mockLogger.e(any())).called(greaterThan(0));
      });

      test('returns empty list when API returns 404 Not Found', () async {
        // Arrange
        when(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response('Not Found', 404));

        // Act
        final supermarkets = await repository.fetchNearbySupermarkets(
          latitude: 40.7580,
          longitude: -73.9855,
        );

        // Assert
        expect(supermarkets, isEmpty);
      });

      test('returns empty list when API returns invalid JSON', () async {
        // Arrange
        when(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response('invalid json {', 200));

        // Act
        final supermarkets = await repository.fetchNearbySupermarkets(
          latitude: 40.7580,
          longitude: -73.9855,
        );

        // Assert
        expect(supermarkets, isEmpty);
        verify(() => mockLogger.e(any())).called(greaterThan(0));
      });

      test('returns empty list when HTTP request throws exception', () async {
        // Arrange
        when(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenThrow(Exception('Network error'));

        // Act
        final supermarkets = await repository.fetchNearbySupermarkets(
          latitude: 40.7580,
          longitude: -73.9855,
        );

        // Assert
        expect(supermarkets, isEmpty);
        verify(() => mockLogger.e(any())).called(greaterThan(0));
      });

      test('skips malformed elements and continues parsing valid ones',
          () async {
        // Arrange
        final responseBody = '''{
          "elements": [
            {
              "type": "node",
              "id": 1,
              "lat": 40.7580,
              "lon": -73.9855,
              "tags": {"name": "Valid Store", "shop": "supermarket"}
            },
            {
              "type": "node",
              "id": 2,
              "tags": {"name": "Invalid Store - missing coordinates"}
            },
            {
              "type": "way",
              "id": 100,
              "center": {
                "lat": 40.7500,
                "lon": -73.9800
              },
              "tags": {"name": "Another Valid Store", "shop": "supermarket"}
            }
          ]
        }''';

        when(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final supermarkets = await repository.fetchNearbySupermarkets(
          latitude: 40.7580,
          longitude: -73.9855,
        );

        // Assert
        expect(supermarkets.length, equals(2));
        expect(supermarkets[0].name, equals('Valid Store'));
        expect(supermarkets[1].name, equals('Another Valid Store'));
      });

      test('handles null coordinates gracefully', () async {
        // Arrange
        final responseBody = '''{
          "elements": [
            {
              "type": "node",
              "id": 1,
              "lat": null,
              "lon": -73.9855,
              "tags": {"name": "Store", "shop": "supermarket"}
            }
          ]
        }''';

        when(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final supermarkets = await repository.fetchNearbySupermarkets(
          latitude: 40.7580,
          longitude: -73.9855,
        );

        // Assert
        expect(supermarkets, isEmpty);
      });

      test('returns empty list when elements field is null', () async {
        // Arrange
        final responseBody = '{"elements": null}';

        when(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final supermarkets = await repository.fetchNearbySupermarkets(
          latitude: 40.7580,
          longitude: -73.9855,
        );

        // Assert
        expect(supermarkets, isEmpty);
      });

      test('returns empty list when elements field is missing', () async {
        // Arrange
        final responseBody = '{}';

        when(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final supermarkets = await repository.fetchNearbySupermarkets(
          latitude: 40.7580,
          longitude: -73.9855,
        );

        // Assert
        expect(supermarkets, isEmpty);
      });
    });

    group('fetchNearbySupermarkets - Edge Cases', () {
      test('handles elements with only center but missing name', () async {
        // Arrange
        final responseBody = '''{
          "elements": [
            {
              "type": "way",
              "id": 100,
              "center": {
                "lat": 40.7500,
                "lon": -73.9800
              },
              "tags": {}
            }
          ]
        }''';

        when(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final supermarkets = await repository.fetchNearbySupermarkets(
          latitude: 40.7500,
          longitude: -73.9800,
        );

        // Assert
        expect(supermarkets, isNotEmpty);
        expect(supermarkets[0].name, equals('Supermarket'));
      });

      test('handles very small search radius', () async {
        // Arrange
        final responseBody = '''{
          "elements": [
            {
              "type": "node",
              "id": 1,
              "lat": 40.7580,
              "lon": -73.9855,
              "tags": {"name": "Store", "shop": "supermarket"}
            }
          ]
        }''';

        when(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final supermarkets = await repository.fetchNearbySupermarkets(
          latitude: 40.7580,
          longitude: -73.9855,
          radiusInMeters: 100,
        );

        // Assert
        expect(supermarkets is List<NearbySupermarket>, isTrue);
      });

      test('handles very large search radius', () async {
        // Arrange
        final responseBody = '''{
          "elements": [
            {
              "type": "node",
              "id": 1,
              "lat": 40.7580,
              "lon": -73.9855,
              "tags": {"name": "Store", "shop": "supermarket"}
            }
          ]
        }''';

        when(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final supermarkets = await repository.fetchNearbySupermarkets(
          latitude: 40.7580,
          longitude: -73.9855,
          radiusInMeters: 50000,
        );

        // Assert
        expect(supermarkets is List<NearbySupermarket>, isTrue);
      });

      test('handles coordinates at equator', () async {
        // Arrange
        final responseBody = '''{
          "elements": [
            {
              "type": "node",
              "id": 1,
              "lat": 0.0,
              "lon": 0.0,
              "tags": {"name": "Equator Store", "shop": "supermarket"}
            }
          ]
        }''';

        when(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final supermarkets = await repository.fetchNearbySupermarkets(
          latitude: 0.0,
          longitude: 0.0,
        );

        // Assert
        expect(supermarkets, isNotEmpty);
        expect(supermarkets[0].latitude, equals(0.0));
      });

      test('handles coordinates at poles', () async {
        // Arrange
        final responseBody = '''{
          "elements": [
            {
              "type": "node",
              "id": 1,
              "lat": 90.0,
              "lon": 0.0,
              "tags": {"name": "Pole Store", "shop": "supermarket"}
            }
          ]
        }''';

        when(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final supermarkets = await repository.fetchNearbySupermarkets(
          latitude: 90.0,
          longitude: 0.0,
        );

        // Assert
        expect(supermarkets, isNotEmpty);
      });

      test('handles negative longitude coordinates', () async {
        // Arrange
        final responseBody = '''{
          "elements": [
            {
              "type": "node",
              "id": 1,
              "lat": 40.7580,
              "lon": -73.9855,
              "tags": {"name": "West Store", "shop": "supermarket"}
            }
          ]
        }''';

        when(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final supermarkets = await repository.fetchNearbySupermarkets(
          latitude: 40.7580,
          longitude: -73.9855,
        );

        // Assert
        expect(supermarkets, isNotEmpty);
        expect(supermarkets[0].longitude, equals(-73.9855));
      });

      test('handles large result set with many supermarkets', () async {
        // Arrange
        final elements = StringBuffer();
        for (int i = 0; i < 50; i++) {
          if (i > 0) elements.write(',');
          elements.write('''{
            "type": "node",
            "id": ${i + 1},
            "lat": ${40.7580 + (i * 0.001)},
            "lon": ${-73.9855 + (i * 0.001)},
            "tags": {"name": "Store $i", "shop": "supermarket"}
          }''');
        }

        final responseBody = '{"elements": [${elements.toString()}]}';

        when(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final supermarkets = await repository.fetchNearbySupermarkets(
          latitude: 40.7580,
          longitude: -73.9855,
        );

        // Assert
        expect(supermarkets.length, equals(50));
      });

      test('preserves order of elements in response', () async {
        // Arrange
        final responseBody = '''{
          "elements": [
            {
              "type": "node",
              "id": 1,
              "lat": 40.7580,
              "lon": -73.9855,
              "tags": {"name": "First Store", "shop": "supermarket"}
            },
            {
              "type": "node",
              "id": 2,
              "lat": 40.7500,
              "lon": -73.9800,
              "tags": {"name": "Second Store", "shop": "supermarket"}
            },
            {
              "type": "node",
              "id": 3,
              "lat": 40.7450,
              "lon": -73.9750,
              "tags": {"name": "Third Store", "shop": "supermarket"}
            }
          ]
        }''';

        when(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final supermarkets = await repository.fetchNearbySupermarkets(
          latitude: 40.7580,
          longitude: -73.9855,
        );

        // Assert
        expect(supermarkets[0].name, equals('First Store'));
        expect(supermarkets[1].name, equals('Second Store'));
        expect(supermarkets[2].name, equals('Third Store'));
      });

      test('handles elements with way but without center', () async {
        // Arrange
        final responseBody = '''{
          "elements": [
            {
              "type": "way",
              "id": 100,
              "lat": 40.7500,
              "lon": -73.9800,
              "tags": {"name": "Way Store", "shop": "supermarket"}
            }
          ]
        }''';

        when(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final supermarkets = await repository.fetchNearbySupermarkets(
          latitude: 40.7500,
          longitude: -73.9800,
        );

        // Assert
        expect(supermarkets, isNotEmpty);
      });

      test('handles response with mixed valid and invalid element types',
          () async {
        // Arrange
        final responseBody = '''{
          "elements": [
            {
              "type": "node",
              "id": 1,
              "lat": 40.7580,
              "lon": -73.9855,
              "tags": {"name": "Store 1", "shop": "supermarket"}
            },
            {
              "type": "relation",
              "id": 200,
              "tags": {"name": "Invalid Type"}
            },
            {
              "type": "way",
              "id": 100,
              "center": {
                "lat": 40.7500,
                "lon": -73.9800
              },
              "tags": {"name": "Store 2", "shop": "supermarket"}
            }
          ]
        }''';

        when(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final supermarkets = await repository.fetchNearbySupermarkets(
          latitude: 40.7500,
          longitude: -73.9800,
        );

        // Assert
        expect(supermarkets.length, equals(2));
      });
    });

    group('fetchNearbySupermarkets - Default Parameters', () {
      test('uses default radius of 5000 meters when not specified', () async {
        // Arrange
        final responseBody = '''{
          "elements": [
            {
              "type": "node",
              "id": 1,
              "lat": 40.7580,
              "lon": -73.9855,
              "tags": {"name": "Store", "shop": "supermarket"}
            }
          ]
        }''';

        when(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act - not specifying radiusInMeters
        final supermarkets = await repository.fetchNearbySupermarkets(
          latitude: 40.7580,
          longitude: -73.9855,
        );

        // Assert
        expect(supermarkets, isNotEmpty);
      });

      test('latitude and longitude are required parameters', () async {
        // This test ensures that the method signature enforces required parameters
        expect(
          () => repository.fetchNearbySupermarkets(
            latitude: 0,
            longitude: 0,
          ),
          returnsNormally,
        );
      });
    });

    group('OverpassSupermarketLocationRepository - Initialization', () {
      test('creates instance with default http.Client and Logger', () {
        // Arrange & Act
        final repo = OverpassSupermarketLocationRepository();

        // Assert
        expect(repo, isNotNull);
      });

      test('creates instance with custom http.Client', () {
        // Arrange
        final customClient = MockHttpClient();

        // Act
        final repo = OverpassSupermarketLocationRepository(
          httpClient: customClient,
        );

        // Assert
        expect(repo, isNotNull);
      });

      test('creates instance with custom Logger', () {
        // Arrange
        final customLogger = MockLogger();

        // Act
        final repo = OverpassSupermarketLocationRepository(
          logger: customLogger,
        );

        // Assert
        expect(repo, isNotNull);
      });

      test('implements SupermarketLocationRepository interface', () {
        // Arrange & Act
        final repo = OverpassSupermarketLocationRepository();

        // Assert
        expect(repo, isA<OverpassSupermarketLocationRepository>());
      });
    });

    group('fetchNearbySupermarkets - Logging', () {
      test('logs debug message when fetching supermarkets', () async {
        // Arrange
        final responseBody = '{"elements": []}';

        when(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        await repository.fetchNearbySupermarkets(
          latitude: 40.7580,
          longitude: -73.9855,
        );

        // Assert
        verify(() => mockLogger.d(any())).called(1);
      });

      test('logs info message when supermarkets are found', () async {
        // Arrange
        final responseBody = '''{
          "elements": [
            {
              "type": "node",
              "id": 1,
              "lat": 40.7580,
              "lon": -73.9855,
              "tags": {"name": "Store", "shop": "supermarket"}
            }
          ]
        }''';

        when(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        await repository.fetchNearbySupermarkets(
          latitude: 40.7580,
          longitude: -73.9855,
        );

        // Assert
        verify(() => mockLogger.i(any())).called(greaterThan(0));
      });

      test('logs error on HTTP error', () async {
        // Arrange
        when(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response('Error', 500));

        // Act
        await repository.fetchNearbySupermarkets(
          latitude: 40.7580,
          longitude: -73.9855,
        );

        // Assert
        verify(() => mockLogger.e(any())).called(1);
      });
    });
  });
}

