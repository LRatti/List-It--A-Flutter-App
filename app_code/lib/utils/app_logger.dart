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

  static void debug(
    String message, {
    String name = 'app',
    Map<String, Object?>? data,
  }) {
    _logger.d(_format(name, message, data));
  }

  static void info(
    String message, {
    String name = 'app',
    Map<String, Object?>? data,
  }) {
    _logger.i(_format(name, message, data));
  }

  static void warning(
    String message, {
    String name = 'app',
    Map<String, Object?>? data,
  }) {
    _logger.w(_format(name, message, data));
  }

  static void error(
    String message,
    {
    String name = 'app',
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? data,
  }) {
    _logger.e(
      _format(name, message, data),
      error: error,
      stackTrace: stackTrace,
    );
  }

  static String _format(
    String name,
    String message,
    Map<String, Object?>? data,
  ) {
    final base = '[$name] $message';
    if (data == null || data.isEmpty) return base;
    return '$base | data=$data';
  }
}
