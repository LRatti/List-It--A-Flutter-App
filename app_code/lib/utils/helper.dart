import 'package:uuid/uuid.dart';

/// A helper class providing utility functions.
class Helper {
  /// Generates a unique identifier.
  static String generateId() {
    return const Uuid().v4();
  }
}