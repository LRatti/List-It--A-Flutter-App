/// Represents the type of synchronization operation to be performed.
enum SyncOperation {
  /// Insert or update operation
  upsert,

  /// Delete operation
  delete;

  /// Convert enum to string for database storage
  String toDb() => toString().split('.').last;

  /// Parse string from database to enum
  static SyncOperation fromDb(String value) {
    return SyncOperation.values.firstWhere(
      (op) => op.toDb() == value,
      orElse: () => SyncOperation.upsert,
    );
  }
}
