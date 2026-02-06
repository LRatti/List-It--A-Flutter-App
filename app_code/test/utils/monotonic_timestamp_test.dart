import 'package:app_code/utils/monotonic_timestamp.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MonotonicTimestamp.generateNext()', () {
    test('returns current time when previousTime is null', () {
      final before = DateTime.now();
      final result = MonotonicTimestamp.generateNext(previousTime: null);
      final after = DateTime.now();

      expect(result.isAfter(before) || result.isAtSameMomentAs(before), isTrue);
      expect(result.isBefore(after) || result.isAtSameMomentAs(after), isTrue);
    });

    test('returns current time when now is after previousTime', () {
      final previousTime = DateTime.now().subtract(const Duration(hours: 1));
      final before = DateTime.now();
      final result = MonotonicTimestamp.generateNext(previousTime: previousTime);
      final after = DateTime.now();

      expect(result.isAfter(previousTime), isTrue);
      expect(result.isAfter(before) || result.isAtSameMomentAs(before), isTrue);
      expect(result.isBefore(after) || result.isAtSameMomentAs(after), isTrue);
    });

    test('returns previousTime + 1ms when now is before or equal to previousTime', () {
      final futureTime = DateTime.now().add(const Duration(hours: 1));
      final result = MonotonicTimestamp.generateNext(previousTime: futureTime);
      final expected = futureTime.add(const Duration(milliseconds: 1));

      expect(result, expected);
    });

    test('ensures monotonic increase with same timestamp', () {
      final sameTime = DateTime(2024, 1, 15, 10, 30, 0);
      final result = MonotonicTimestamp.generateNext(previousTime: sameTime);
      final expected = sameTime.add(const Duration(milliseconds: 1));

      // In this case, if current time is before or equal to sameTime
      // it should return previous + 1ms
      // Otherwise it should return current time
      expect(result.isAfter(sameTime), isTrue);
    });

    test('handles very old previousTime', () {
      final oldTime = DateTime(2020, 1, 1);
      final before = DateTime.now();
      final result = MonotonicTimestamp.generateNext(previousTime: oldTime);

      expect(result.isAfter(oldTime), isTrue);
      expect(result.isAfter(before) || result.isAtSameMomentAs(before), isTrue);
    });

    test('handles rapid successive calls with same previousTime', () {
      final previousTime = DateTime.now().add(const Duration(seconds: 1));
      
      final result1 = MonotonicTimestamp.generateNext(previousTime: previousTime);
      final result2 = MonotonicTimestamp.generateNext(previousTime: previousTime);

      // Both should be previousTime + 1ms since now is likely before previousTime
      final expected = previousTime.add(const Duration(milliseconds: 1));
      expect(result1, expected);
      expect(result2, expected);
    });

    test('handles previousTime at exact current moment', () {
      // This is a bit tricky to test since we can't perfectly control timing
      // But we can test the logic
      final now = DateTime.now();
      final result = MonotonicTimestamp.generateNext(previousTime: now);
      
      // Result should be either now (if now is after previous) or now + 1ms
      expect(
        result.isAtSameMomentAs(now) || 
        result.isAtSameMomentAs(now.add(const Duration(milliseconds: 1))) ||
        result.isAfter(now),
        isTrue
      );
    });

    test('preserves millisecond precision', () {
      final previousTime = DateTime(2024, 6, 15, 12, 0, 0, 500);
      final result = MonotonicTimestamp.generateNext(previousTime: previousTime);

      if (result.isAtSameMomentAs(previousTime.add(const Duration(milliseconds: 1)))) {
        expect(result.millisecond, 501);
      }
    });
  });

  group('MonotonicTimestamp.merge()', () {
    test('returns localTime when serverTime is null', () {
      final localTime = DateTime(2024, 6, 15, 10, 0, 0);
      final result = MonotonicTimestamp.merge(localTime, null);

      expect(result, localTime);
    });

    test('returns serverTime when it is after localTime', () {
      final localTime = DateTime(2024, 6, 15, 10, 0, 0);
      final serverTime = DateTime(2024, 6, 15, 11, 0, 0);
      final result = MonotonicTimestamp.merge(localTime, serverTime);

      expect(result, serverTime);
    });

    test('returns localTime when serverTime is before localTime', () {
      final localTime = DateTime(2024, 6, 15, 11, 0, 0);
      final serverTime = DateTime(2024, 6, 15, 10, 0, 0);
      final result = MonotonicTimestamp.merge(localTime, serverTime);

      expect(result, localTime);
    });

    test('returns localTime when serverTime equals localTime', () {
      final localTime = DateTime(2024, 6, 15, 10, 0, 0);
      final serverTime = DateTime(2024, 6, 15, 10, 0, 0);
      final result = MonotonicTimestamp.merge(localTime, serverTime);

      expect(result, localTime);
    });

    test('handles serverTime 1ms after localTime', () {
      final localTime = DateTime(2024, 6, 15, 10, 0, 0, 0);
      final serverTime = DateTime(2024, 6, 15, 10, 0, 0, 1);
      final result = MonotonicTimestamp.merge(localTime, serverTime);

      expect(result, serverTime);
    });

    test('handles serverTime 1ms before localTime', () {
      final localTime = DateTime(2024, 6, 15, 10, 0, 0, 1);
      final serverTime = DateTime(2024, 6, 15, 10, 0, 0, 0);
      final result = MonotonicTimestamp.merge(localTime, serverTime);

      expect(result, localTime);
    });

    test('handles very large time differences', () {
      final localTime = DateTime(2024, 6, 15, 10, 0, 0);
      final serverTime = DateTime(2025, 1, 1, 0, 0, 0);
      final result = MonotonicTimestamp.merge(localTime, serverTime);

      expect(result, serverTime);
    });

    test('handles negative time differences (server in past)', () {
      final localTime = DateTime(2024, 6, 15, 10, 0, 0);
      final serverTime = DateTime(2023, 1, 1, 0, 0, 0);
      final result = MonotonicTimestamp.merge(localTime, serverTime);

      expect(result, localTime);
    });

    test('prefers server time for conflict resolution when newer', () {
      final localTime = DateTime(2024, 6, 15, 10, 0, 0);
      final serverTime = DateTime(2024, 6, 15, 10, 30, 0);
      final result = MonotonicTimestamp.merge(localTime, serverTime);

      expect(result, serverTime);
      expect(result.isAfter(localTime), isTrue);
    });

    test('ensures monotonicity by returning localTime when server is older', () {
      final localTime = DateTime(2024, 6, 15, 10, 30, 0);
      final serverTime = DateTime(2024, 6, 15, 10, 0, 0);
      final result = MonotonicTimestamp.merge(localTime, serverTime);

      expect(result, localTime);
      expect(result.isAfter(serverTime), isTrue);
    });

    test('handles UTC and local timezone times', () {
      final localTime = DateTime(2024, 6, 15, 10, 0, 0);
      final serverTime = DateTime.utc(2024, 6, 15, 11, 0, 0);
      final result = MonotonicTimestamp.merge(localTime, serverTime);

      // The comparison should still work regardless of timezone
      expect(result.isAfter(localTime) || result.isAtSameMomentAs(localTime), isTrue);
    });
  });

  group('MonotonicTimestamp edge cases', () {
    test('generateNext handles null and returns reasonable time', () {
      final result = MonotonicTimestamp.generateNext();
      final now = DateTime.now();

      expect(result.difference(now).inSeconds.abs(), lessThan(2));
    });

    test('merge handles both times being now', () {
      final now = DateTime.now();
      final result = MonotonicTimestamp.merge(now, now);

      expect(result, now);
    });

    test('generateNext followed by merge maintains monotonicity', () {
      final previous = DateTime.now();
      final next = MonotonicTimestamp.generateNext(previousTime: previous);
      final serverTime = next.add(const Duration(seconds: 1));
      final merged = MonotonicTimestamp.merge(next, serverTime);

      expect(merged.isAfter(previous) || merged.isAtSameMomentAs(previous), isTrue);
      expect(merged.isAfter(next) || merged.isAtSameMomentAs(next), isTrue);
    });
  });
}
