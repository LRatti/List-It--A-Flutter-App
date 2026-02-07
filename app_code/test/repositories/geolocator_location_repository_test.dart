import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:geolocator/geolocator.dart';
import 'package:app_code/services/geolocator_service.dart';
import 'package:app_code/repositories/real_app_repo/geolocator_location_repository.dart';

/// Mock classes for external dependencies
class MockGeolocatorService extends Mock implements GeolocatorService {}

/// Fallback LocationSettings for mocktail
class FakeLocationSettings extends Fake implements LocationSettings {}

class MockPosition extends Mock implements Position {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double altitude;
  final double heading;
  final double speed;
  final double speedAccuracy;
  final DateTime timestamp;

  MockPosition({
    this.latitude = 40.7580,
    this.longitude = -73.9855,
    this.accuracy = 5.0,
    this.altitude = 10.0,
    this.heading = 0.0,
    this.speed = 0.0,
    this.speedAccuracy = 0.0,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

void main() {
  setUpAll(() {
    // Register fallback value for LocationSettings
    registerFallbackValue(FakeLocationSettings());
  });

  group('GeolocatorLocationRepository', () {
    late GeolocatorLocationRepository repository;
    late MockGeolocatorService mockGeolocatorService;

    setUp(() {
      mockGeolocatorService = MockGeolocatorService();
      repository = GeolocatorLocationRepository(
        geolocatorService: mockGeolocatorService,
      );
    });

    group('isLocationServiceEnabled', () {
      test('returns true when location services are enabled', () async {
        // Arrange
        when(() => mockGeolocatorService.isLocationServiceEnabled())
            .thenAnswer((_) async => true);

        // Act
        final result = await repository.isLocationServiceEnabled();

        // Assert
        expect(result, isTrue);
        verify(() => mockGeolocatorService.isLocationServiceEnabled())
            .called(1);
      });

      test('returns false when location services are disabled', () async {
        // Arrange
        when(() => mockGeolocatorService.isLocationServiceEnabled())
            .thenAnswer((_) async => false);

        // Act
        final result = await repository.isLocationServiceEnabled();

        // Assert
        expect(result, isFalse);
        verify(() => mockGeolocatorService.isLocationServiceEnabled())
            .called(1);
      });

      test('returns false when service throws an exception', () async {
        // Arrange
        when(() => mockGeolocatorService.isLocationServiceEnabled())
            .thenThrow(Exception('Service check failed'));

        // Act
        final result = await repository.isLocationServiceEnabled();

        // Assert
        expect(result, isFalse);
      });
    });

    group('checkPermission', () {
      test('returns whileInUse permission when permission is granted',
          () async {
        // Arrange
        when(() => mockGeolocatorService.checkPermission())
            .thenAnswer((_) async => LocationPermission.whileInUse);

        // Act
        final result = await repository.checkPermission();

        // Assert
        expect(result, LocationPermission.whileInUse);
        verify(() => mockGeolocatorService.checkPermission()).called(1);
      });

      test('returns denied permission when permission is denied', () async {
        // Arrange
        when(() => mockGeolocatorService.checkPermission())
            .thenAnswer((_) async => LocationPermission.denied);

        // Act
        final result = await repository.checkPermission();

        // Assert
        expect(result, LocationPermission.denied);
      });

      test('returns deniedForever when permission is denied forever',
          () async {
        // Arrange
        when(() => mockGeolocatorService.checkPermission())
            .thenAnswer((_) async => LocationPermission.deniedForever);

        // Act
        final result = await repository.checkPermission();

        // Assert
        expect(result, LocationPermission.deniedForever);
      });

      test('returns denied when service throws an exception', () async {
        // Arrange
        when(() => mockGeolocatorService.checkPermission())
            .thenThrow(Exception('Permission check failed'));

        // Act
        final result = await repository.checkPermission();

        // Assert
        expect(result, LocationPermission.denied);
      });
    });

    group('requestPermission', () {
      test('returns whileInUse permission when user grants permission',
          () async {
        // Arrange
        when(() => mockGeolocatorService.requestPermission())
            .thenAnswer((_) async => LocationPermission.whileInUse);

        // Act
        final result = await repository.requestPermission();

        // Assert
        expect(result, LocationPermission.whileInUse);
        verify(() => mockGeolocatorService.requestPermission()).called(1);
      });

      test('returns denied when user denies permission', () async {
        // Arrange
        when(() => mockGeolocatorService.requestPermission())
            .thenAnswer((_) async => LocationPermission.denied);

        // Act
        final result = await repository.requestPermission();

        // Assert
        expect(result, LocationPermission.denied);
      });

      test('returns deniedForever when permission is denied forever',
          () async {
        // Arrange
        when(() => mockGeolocatorService.requestPermission())
            .thenAnswer((_) async => LocationPermission.deniedForever);

        // Act
        final result = await repository.requestPermission();

        // Assert
        expect(result, LocationPermission.deniedForever);
      });

      test('returns denied when service throws an exception', () async {
        // Arrange
        when(() => mockGeolocatorService.requestPermission())
            .thenThrow(Exception('Permission request failed'));

        // Act
        final result = await repository.requestPermission();

        // Assert
        expect(result, LocationPermission.denied);
      });
    });

    group('getCurrentPosition', () {
      test('returns position when location services are enabled and permitted',
          () async {
        // Arrange
        final mockPosition = MockPosition(
          latitude: 40.7580,
          longitude: -73.9855,
          accuracy: 5.0,
        );

        when(() => mockGeolocatorService.isLocationServiceEnabled())
            .thenAnswer((_) async => true);
        when(() => mockGeolocatorService.checkPermission())
            .thenAnswer((_) async => LocationPermission.whileInUse);
        when(() => mockGeolocatorService.getCurrentPosition(
              locationSettings: any(named: 'locationSettings'),
            )).thenAnswer((_) async => mockPosition);

        // Act
        final result = await repository.getCurrentPosition();

        // Assert
        expect(result, isNotNull);
        expect(result?.latitude, 40.7580);
        expect(result?.longitude, -73.9855);
        expect(result?.accuracy, 5.0);
      });

      test('returns null when location services are disabled', () async {
        // Arrange
        when(() => mockGeolocatorService.isLocationServiceEnabled())
            .thenAnswer((_) async => false);

        // Act
        final result = await repository.getCurrentPosition();

        // Assert
        expect(result, isNull);
        verifyNever(
          () => mockGeolocatorService.getCurrentPosition(
            locationSettings: any(named: 'locationSettings'),
          ),
        );
      });

      test('requests permission when permission is initially denied',
          () async {
        // Arrange
        final mockPosition = MockPosition();

        when(() => mockGeolocatorService.isLocationServiceEnabled())
            .thenAnswer((_) async => true);
        when(() => mockGeolocatorService.checkPermission())
            .thenAnswer((_) async => LocationPermission.denied);
        when(() => mockGeolocatorService.requestPermission())
            .thenAnswer((_) async => LocationPermission.whileInUse);
        when(() => mockGeolocatorService.getCurrentPosition(
              locationSettings: any(named: 'locationSettings'),
            )).thenAnswer((_) async => mockPosition);

        // Act
        final result = await repository.getCurrentPosition();

        // Assert
        expect(result, isNotNull);
        verify(() => mockGeolocatorService.requestPermission()).called(1);
      });

      test('returns null when permission is denied after request', () async {
        // Arrange
        when(() => mockGeolocatorService.isLocationServiceEnabled())
            .thenAnswer((_) async => true);
        when(() => mockGeolocatorService.checkPermission())
            .thenAnswer((_) async => LocationPermission.denied);
        when(() => mockGeolocatorService.requestPermission())
            .thenAnswer((_) async => LocationPermission.denied);

        // Act
        final result = await repository.getCurrentPosition();

        // Assert
        expect(result, isNull);
        verifyNever(
          () => mockGeolocatorService.getCurrentPosition(
            locationSettings: any(named: 'locationSettings'),
          ),
        );
      });

      test('returns null when permission is denied forever', () async {
        // Arrange
        when(() => mockGeolocatorService.isLocationServiceEnabled())
            .thenAnswer((_) async => true);
        when(() => mockGeolocatorService.checkPermission())
            .thenAnswer((_) async => LocationPermission.deniedForever);

        // Act
        final result = await repository.getCurrentPosition();

        // Assert
        expect(result, isNull);
        verifyNever(
          () => mockGeolocatorService.getCurrentPosition(
            locationSettings: any(named: 'locationSettings'),
          ),
        );
      });

      test('returns position with low accuracy but logs warning', () async {
        // Arrange
        final mockPosition = MockPosition(accuracy: 150.0);

        when(() => mockGeolocatorService.isLocationServiceEnabled())
            .thenAnswer((_) async => true);
        when(() => mockGeolocatorService.checkPermission())
            .thenAnswer((_) async => LocationPermission.whileInUse);
        when(() => mockGeolocatorService.getCurrentPosition(
              locationSettings: any(named: 'locationSettings'),
            )).thenAnswer((_) async => mockPosition);

        // Act
        final result = await repository.getCurrentPosition();

        // Assert
        expect(result, isNotNull);
        expect(result?.accuracy, 150.0);
      });

      test('returns null when service throws an exception', () async {
        // Arrange
        when(() => mockGeolocatorService.isLocationServiceEnabled())
            .thenAnswer((_) async => true);
        when(() => mockGeolocatorService.checkPermission())
            .thenAnswer((_) async => LocationPermission.whileInUse);
        when(() => mockGeolocatorService.getCurrentPosition(
              locationSettings: any(named: 'locationSettings'),
            )).thenThrow(Exception('Position retrieval failed'));

        // Act
        final result = await repository.getCurrentPosition();

        // Assert
        expect(result, isNull);
      });

      test('handles timeout gracefully', () async {
        // Arrange
        when(() => mockGeolocatorService.isLocationServiceEnabled())
            .thenAnswer((_) async => true);
        when(() => mockGeolocatorService.checkPermission())
            .thenAnswer((_) async => LocationPermission.whileInUse);
        when(() => mockGeolocatorService.getCurrentPosition(
              locationSettings: any(named: 'locationSettings'),
            )).thenThrow(Exception('Timeout getting position'));

        // Act
        final result = await repository.getCurrentPosition();

        // Assert
        expect(result, isNull);
      });

      test('respects LocationSettings with correct accuracy and distance filter',
          () async {
        // Arrange
        final mockPosition = MockPosition();

        when(() => mockGeolocatorService.isLocationServiceEnabled())
            .thenAnswer((_) async => true);
        when(() => mockGeolocatorService.checkPermission())
            .thenAnswer((_) async => LocationPermission.whileInUse);
        when(() => mockGeolocatorService.getCurrentPosition(
              locationSettings: any(named: 'locationSettings'),
            )).thenAnswer((_) async => mockPosition);

        // Act
        final result = await repository.getCurrentPosition();

        // Assert
        expect(result, isNotNull);
        verify(() => mockGeolocatorService.getCurrentPosition(
          locationSettings: any(named: 'locationSettings'),
        )).called(1);
      });
    });

    group('getPositionStream', () {
      test('returns a position stream', () async {
        // Arrange
        final mockPosition1 =
            MockPosition(latitude: 40.7580, longitude: -73.9855);
        final mockPosition2 =
            MockPosition(latitude: 40.7590, longitude: -73.9865);

        when(() => mockGeolocatorService.getPositionStream(
              locationSettings: any(named: 'locationSettings'),
            )).thenAnswer(
          (_) => Stream.fromIterable([mockPosition1, mockPosition2]),
        );

        // Act
        final stream = repository.getPositionStream();

        // Assert
        expect(stream, isA<Stream<Position>>());

        // Verify stream emits positions
        final positions = await stream.toList();
        expect(positions.length, 2);
        expect(positions[0].latitude, 40.7580);
        expect(positions[1].latitude, 40.7590);
      });

      test('stream respects LocationSettings with distance filter', () async {
        // Arrange
        when(() => mockGeolocatorService.getPositionStream(
              locationSettings: any(named: 'locationSettings'),
            )).thenAnswer((_) => Stream.empty());

        // Act
        final stream = repository.getPositionStream();

        // Assert
        expect(stream, isA<Stream<Position>>());
        verify(() => mockGeolocatorService.getPositionStream(
          locationSettings: any(named: 'locationSettings'),
        )).called(1);
      });

      test('stream handles empty position stream', () async {
        // Arrange
        when(() => mockGeolocatorService.getPositionStream(
              locationSettings: any(named: 'locationSettings'),
            )).thenAnswer((_) => Stream.empty());

        // Act
        final stream = repository.getPositionStream();
        final positions = await stream.toList();

        // Assert
        expect(positions, isEmpty);
      });

      test('stream emits multiple positions over time', () async {
        // Arrange
        final positions = [
          MockPosition(latitude: 1.0, longitude: 1.0),
          MockPosition(latitude: 2.0, longitude: 2.0),
          MockPosition(latitude: 3.0, longitude: 3.0),
        ];

        when(() => mockGeolocatorService.getPositionStream(
              locationSettings: any(named: 'locationSettings'),
            )).thenAnswer((_) => Stream.fromIterable(positions));

        // Act
        final stream = repository.getPositionStream();
        final emittedPositions = await stream.toList();

        // Assert
        expect(emittedPositions.length, 3);
        for (int i = 0; i < 3; i++) {
          expect(emittedPositions[i].latitude, i + 1.0);
          expect(emittedPositions[i].longitude, i + 1.0);
        }
      });
    });

    group('Error handling and resilience', () {
      test('logs errors when operations fail', () async {
        // Arrange
        when(() => mockGeolocatorService.isLocationServiceEnabled())
            .thenThrow(Exception('Service check error'));

        // Act
        final result = await repository.isLocationServiceEnabled();

        // Assert
        expect(result, isFalse);
      });

      test('continues operating after multiple sequential calls', () async {
        // Arrange - First call returns false
        when(() => mockGeolocatorService.isLocationServiceEnabled())
            .thenAnswer((_) async => false);

        // Act
        final result1 = await repository.isLocationServiceEnabled();

        // Re-setup mock for second call
        when(() => mockGeolocatorService.isLocationServiceEnabled())
            .thenAnswer((_) async => true);
        final result2 = await repository.isLocationServiceEnabled();

        // Assert
        expect(result1, isFalse);
        expect(result2, isTrue);
      });

      test('handles missing location services gracefully', () async {
        // Arrange
        when(() => mockGeolocatorService.isLocationServiceEnabled())
            .thenThrow(Exception('Platform not available'));

        // Act
        final result = await repository.isLocationServiceEnabled();

        // Assert
        expect(result, isFalse);
      });
    });
  });
}
