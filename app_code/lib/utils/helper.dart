import 'package:uuid/uuid.dart';

class Helper{
  static String generateId() {
    final uuid = Uuid();
    return uuid.v4();
  }
}