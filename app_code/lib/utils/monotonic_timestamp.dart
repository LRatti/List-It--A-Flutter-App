/// Utility class for handling monotonic timestamps
/// Ensures that each new timestamp is strictly greater than the previous one
class MonotonicTimestamp {
  /// Generate a new monotonic timestamp based on current and previous times
  /// Returns max(DateTime.now(), previousTime + 1 millisecond)
  /// This prevents false conflict resolution when rapid updates occur
  static DateTime generateNext({DateTime? previousTime}) {
    final now = DateTime.now();

    if (previousTime == null) {
      return now;
    }

    // If now is already after previous, use now
    if (now.isAfter(previousTime)) {
      return now;
    }

    // Otherwise, return previous + 1 millisecond
    return previousTime.add(const Duration(milliseconds: 1));
  }

  /// Merge two timestamps, preferring server time but ensuring monotonicity
  /// Used during sync echo processing
  static DateTime merge(DateTime localTime, DateTime? serverTime) {
    if (serverTime == null) {
      return localTime;
    }

    // Server time takes precedence for conflict resolution
    // But ensure monotonic increase from localTime
    if (serverTime.isAfter(localTime)) {
      return serverTime;
    }

    // If server time is in the past, this shouldn't happen in normal operation
    // But handle it gracefully by returning local time
    return localTime;
  }
}
