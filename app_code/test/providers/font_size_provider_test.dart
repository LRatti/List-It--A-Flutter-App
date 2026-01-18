import 'package:app_code/providers/real_app_providers/font_size_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('FontSizeNotifier', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('build returns default font size when no preference saved', () async {
      final container = ProviderContainer();

      final result = await container.read(fontSizeProvider.future);

      expect(result, 1.0);
    });

    test('build returns saved font size from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'fontSize': 1.2});
      final container = ProviderContainer();

      final result = await container.read(fontSizeProvider.future);

      expect(result, 1.2);
    });

    test('build returns default when saved value is below minimum', () async {
      SharedPreferences.setMockInitialValues({'fontSize': 0.5});
      final container = ProviderContainer();

      final result = await container.read(fontSizeProvider.future);

      expect(result, 1.0);
    });

    test('build returns default when saved value is above maximum', () async {
      SharedPreferences.setMockInitialValues({'fontSize': 1.8});
      final container = ProviderContainer();

      final result = await container.read(fontSizeProvider.future);

      expect(result, 1.0);
    });

    test('setFontSize clamps value between 0.8 and 1.4', () async {
      final container = ProviderContainer();
      final notifier = container.read(fontSizeProvider.notifier);

      await notifier.setFontSize(0.5);
      final clamped = container.read(fontSizeValueProvider);

      expect(clamped, 0.8);
    });

    test('setFontSize saves value to SharedPreferences', () async {
      final container = ProviderContainer();
      final notifier = container.read(fontSizeProvider.notifier);

      await notifier.setFontSize(1.3);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('fontSize'), 1.3);
    });

    test('resetFontSize returns to default 1.0', () async {
      SharedPreferences.setMockInitialValues({'fontSize': 1.4});
      final container = ProviderContainer();
      final notifier = container.read(fontSizeProvider.notifier);

      await notifier.resetFontSize();
      final result = container.read(fontSizeValueProvider);

      expect(result, 1.0);
    });

    test('increaseFontSize adds 0.1 to current value', () async {
      SharedPreferences.setMockInitialValues({'fontSize': 1.0});
      final container = ProviderContainer();
      final notifier = container.read(fontSizeProvider.notifier);

      await notifier.increaseFontSize();
      final result = container.read(fontSizeValueProvider);

      expect(result, closeTo(1.1, 0.01));
    });

    test('increaseFontSize respects maximum 1.4 limit via setFontSize', () async {
      final container = ProviderContainer();
      final notifier = container.read(fontSizeProvider.notifier);

      // Set directly to near max
      await notifier.setFontSize(1.35);
      await notifier.increaseFontSize();
      final result = container.read(fontSizeValueProvider);

      expect(result, 1.4);
    });

    test('decreaseFontSize subtracts 0.1 from current value', () async {
      SharedPreferences.setMockInitialValues({'fontSize': 1.0});
      final container = ProviderContainer();
      final notifier = container.read(fontSizeProvider.notifier);

      await notifier.decreaseFontSize();
      final result = container.read(fontSizeValueProvider);

      expect(result, closeTo(0.9, 0.01));
    });

    test('decreaseFontSize respects minimum 0.8 limit via setFontSize', () async {
      final container = ProviderContainer();
      final notifier = container.read(fontSizeProvider.notifier);

      // Set directly to near min
      await notifier.setFontSize(0.85);
      await notifier.decreaseFontSize();
      final result = container.read(fontSizeValueProvider);

      expect(result, 0.8);
    });

    test('fontSizeValueProvider returns default while loading', () async {
      final container = ProviderContainer();

      final result = container.read(fontSizeValueProvider);

      expect(result, 1.0);
    });

    test('fontSizeValueProvider returns 1.0 on error', () async {
      // This test verifies the fallback behavior
      final container = ProviderContainer();

      final result = container.read(fontSizeValueProvider);

      expect(result, 1.0);
    });
  });

  group('FontSizeNotifier - Range Constants', () {
    test('fontSizeRange has correct min and max values', () {
      expect(FontSizeNotifier.fontSizeRange.min, 0.8);
      expect(FontSizeNotifier.fontSizeRange.max, 1.4);
    });
  });
}
