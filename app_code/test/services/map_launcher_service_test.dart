import 'package:app_code/services/map_launcher_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';

/// Fake URL launcher platform for testing
class FakeUrlLauncherPlatform extends UrlLauncherPlatform with MockPlatformInterfaceMixin {
  bool shouldCanLaunchSucceed = true;
  bool shouldLaunchSucceed = true;
  Exception? exceptionToThrow;
  int canLaunchCallCount = 0;
  int launchCallCount = 0;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async {
    canLaunchCallCount++;
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return shouldCanLaunchSucceed;
  }

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async {
    launchCallCount++;
    return shouldLaunchSucceed;
  }

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launchCallCount++;
    return shouldLaunchSucceed;
  }

  void reset() {
    shouldCanLaunchSucceed = true;
    shouldLaunchSucceed = true;
    exceptionToThrow = null;
    canLaunchCallCount = 0;
    launchCallCount = 0;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeUrlLauncherPlatform fakeUrlLauncher;
  late MapLauncherService service;

  setUp(() {
    fakeUrlLauncher = FakeUrlLauncherPlatform();
    UrlLauncherPlatform.instance = fakeUrlLauncher;
    service = MapLauncherService();
  });

  group('MapLauncherService.openMap()', () {
    test('successfully opens map with valid coordinates', () async {
      // Arrange
      const latitude = 45.464664;
      const longitude = 9.188540;
      const label = 'Test Supermarket';

      fakeUrlLauncher.shouldCanLaunchSucceed = true;
      fakeUrlLauncher.shouldLaunchSucceed = true;

      // Act
      final result = await service.openMap(
        latitude: latitude,
        longitude: longitude,
        label: label,
      );

      // Assert
      expect(result, true);
      expect(fakeUrlLauncher.canLaunchCallCount, greaterThan(0));
    });

    test('successfully opens map without label', () async {
      // Arrange
      const latitude = 45.464664;
      const longitude = 9.188540;

      fakeUrlLauncher.shouldCanLaunchSucceed = true;
      fakeUrlLauncher.shouldLaunchSucceed = true;

      // Act
      final result = await service.openMap(
        latitude: latitude,
        longitude: longitude,
      );

      // Assert
      expect(result, true);
    });

    test('falls back to web map when platform-specific URL fails', () async {
      // Arrange
      const latitude = 45.464664;
      const longitude = 9.188540;

      fakeUrlLauncher.shouldCanLaunchSucceed = false;
      fakeUrlLauncher.shouldLaunchSucceed = true;

      // Act
      final result = await service.openMap(
        latitude: latitude,
        longitude: longitude,
      );

      // Assert - canLaunch fails for platform-specific, service tries fallback
      // Fallback succeeds because shouldLaunchSucceed is true
      expect(result, isTrue);
    });

    test('returns false when both platform-specific and web URLs fail', () async {
      // Arrange
      const latitude = 45.464664;
      const longitude = 9.188540;

      fakeUrlLauncher.shouldCanLaunchSucceed = false;
      fakeUrlLauncher.shouldLaunchSucceed = false;

      // Act
      final result = await service.openMap(
        latitude: latitude,
        longitude: longitude,
      );

      // Assert
      expect(result, false);
    });

    test('returns false when canLaunchUrl succeeds but launchUrl fails', () async {
      // Arrange
      const latitude = 45.464664;
      const longitude = 9.188540;

      fakeUrlLauncher.shouldCanLaunchSucceed = true;
      fakeUrlLauncher.shouldLaunchSucceed = false;

      // Act
      final result = await service.openMap(
        latitude: latitude,
        longitude: longitude,
      );

      // Assert
      expect(result, false);
    });

    test('handles exception gracefully and returns false', () async {
      // Arrange
      const latitude = 45.464664;
      const longitude = 9.188540;

      fakeUrlLauncher.exceptionToThrow = Exception('Network error');

      // Act
      final result = await service.openMap(
        latitude: latitude,
        longitude: longitude,
      );

      // Assert
      expect(result, false);
    });

    test('handles invalid coordinates gracefully', () async {
      // Arrange - coordinates at edge values
      const latitude = 90.0; // Max valid latitude
      const longitude = 180.0; // Max valid longitude

      fakeUrlLauncher.shouldCanLaunchSucceed = true;
      fakeUrlLauncher.shouldLaunchSucceed = true;

      // Act
      final result = await service.openMap(
        latitude: latitude,
        longitude: longitude,
      );

      // Assert
      expect(result, true);
    });

    test('handles negative coordinates correctly', () async {
      // Arrange - southern and western hemispheres
      const latitude = -45.464664;
      const longitude = -9.188540;

      fakeUrlLauncher.shouldCanLaunchSucceed = true;
      fakeUrlLauncher.shouldLaunchSucceed = true;

      // Act
      final result = await service.openMap(
        latitude: latitude,
        longitude: longitude,
      );

      // Assert
      expect(result, true);
    });

    test('handles label with special characters', () async {
      // Arrange
      const latitude = 45.464664;
      const longitude = 9.188540;
      const label = 'Supermarket & Café (Main St.)';

      fakeUrlLauncher.shouldCanLaunchSucceed = true;
      fakeUrlLauncher.shouldLaunchSucceed = true;

      // Act
      final result = await service.openMap(
        latitude: latitude,
        longitude: longitude,
        label: label,
      );

      // Assert
      expect(result, true);
    });
  });

  group('MapLauncherService.openDirections()', () {
    test('successfully opens directions with valid destination', () async {
      // Arrange
      const destinationLat = 45.464664;
      const destinationLon = 9.188540;
      const label = 'Target Location';

      fakeUrlLauncher.shouldCanLaunchSucceed = true;
      fakeUrlLauncher.shouldLaunchSucceed = true;

      // Act
      final result = await service.openDirections(
        destinationLat: destinationLat,
        destinationLon: destinationLon,
        destinationLabel: label,
      );

      // Assert
      expect(result, true);
    });

    test('successfully opens directions without label', () async {
      // Arrange
      const destinationLat = 45.464664;
      const destinationLon = 9.188540;

      fakeUrlLauncher.shouldCanLaunchSucceed = true;
      fakeUrlLauncher.shouldLaunchSucceed = true;

      // Act
      final result = await service.openDirections(
        destinationLat: destinationLat,
        destinationLon: destinationLon,
      );

      // Assert
      expect(result, true);
    });

    test('falls back to web directions when platform-specific fails', () async {
      // Arrange
      const destinationLat = 45.464664;
      const destinationLon = 9.188540;

      fakeUrlLauncher.shouldCanLaunchSucceed = false;
      fakeUrlLauncher.shouldLaunchSucceed = true;

      // Act
      final result = await service.openDirections(
        destinationLat: destinationLat,
        destinationLon: destinationLon,
      );

      // Assert - Fallback succeeds
      expect(result, isTrue);
    });

    test('returns false when all direction URLs fail', () async {
      // Arrange
      const destinationLat = 45.464664;
      const destinationLon = 9.188540;

      fakeUrlLauncher.shouldCanLaunchSucceed = false;
      fakeUrlLauncher.shouldLaunchSucceed = false;

      // Act
      final result = await service.openDirections(
        destinationLat: destinationLat,
        destinationLon: destinationLon,
      );

      // Assert
      expect(result, false);
    });

    test('handles exception gracefully and returns false', () async {
      // Arrange
      const destinationLat = 45.464664;
      const destinationLon = 9.188540;

      fakeUrlLauncher.exceptionToThrow = Exception('Platform error');

      // Act
      final result = await service.openDirections(
        destinationLat: destinationLat,
        destinationLon: destinationLon,
      );

      // Assert
      expect(result, false);
    });

    test('handles extreme coordinate values', () async {
      // Arrange
      const destinationLat = -90.0; // South Pole
      const destinationLon = -180.0; // International Date Line

      fakeUrlLauncher.shouldCanLaunchSucceed = true;
      fakeUrlLauncher.shouldLaunchSucceed = true;

      // Act
      final result = await service.openDirections(
        destinationLat: destinationLat,
        destinationLon: destinationLon,
      );

      // Assert
      expect(result, true);
    });

    test('handles zero coordinates (Null Island)', () async {
      // Arrange
      const destinationLat = 0.0;
      const destinationLon = 0.0;

      fakeUrlLauncher.shouldCanLaunchSucceed = true;
      fakeUrlLauncher.shouldLaunchSucceed = true;

      // Act
      final result = await service.openDirections(
        destinationLat: destinationLat,
        destinationLon: destinationLon,
      );

      // Assert
      expect(result, true);
    });
  });
}
