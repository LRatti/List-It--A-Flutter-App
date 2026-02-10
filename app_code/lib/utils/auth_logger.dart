import 'package:app_code/utils/app_logger.dart';

/// A specialized logger for authentication-related events, providing a consistent
/// interface and additional functionality for masking sensitive information
class AuthLogger {
  static const String _name = 'auth';

  static void debug(String message, {Map<String, Object?>? data}) {
    AppLogger.debug(message, name: _name, data: data);
  }

  static void info(String message, {Map<String, Object?>? data}) {
    AppLogger.info(message, name: _name, data: data);
  }

  static void warning(String message, {Map<String, Object?>? data}) {
    AppLogger.warning(message, name: _name, data: data);
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? data,
  }) {
    AppLogger.error(
      message,
      name: _name,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  static String maskEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'unknown';
    }

    final parts = email.split('@');
    if (parts.length != 2) {
      return 'invalid';
    }

    final name = parts[0];
    final domain = parts[1];
    if (name.isEmpty) {
      return 'unknown@$domain';
    }

    final maskedName = name.length <= 2
        ? '${name[0]}*'
        : '${name[0]}***${name[name.length - 1]}';

    return '$maskedName@$domain';
  }
}
