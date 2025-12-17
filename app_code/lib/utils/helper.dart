import 'package:uuid/uuid.dart';

class Helper {
  static String generateId() {
    return const Uuid().v4();
  }
}