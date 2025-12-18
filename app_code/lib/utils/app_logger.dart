import 'package:logger/logger.dart';

class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 6,
      lineLength: 100,
      printEmojis: true,
      printTime: true,
    ),
  );

  static void info(String message, {Map<String, Object?>? data}) {
    _logger.i(_format(message, data));
  }

  static void warning(String message, {Map<String, Object?>? data}) {
    _logger.w(_format(message, data));
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? data,
  }) {
    _logger.e(_format(message, data), error: error, stackTrace: stackTrace);
  }

  static String _format(String message, Map<String, Object?>? data) {
    if (data == null || data.isEmpty) return message;
    return '$message | data=$data';
  }
}
