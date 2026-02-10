import 'package:logger/logger.dart';

/// A logger for synchronization-related logs. 
/// The logging can be enabled by setting the environment variable 
/// `ENABLE_SYNC_LOGS` to `true`.
const bool enableSyncLogs = bool.fromEnvironment(
  'ENABLE_SYNC_LOGS',
  defaultValue: false,
);

Logger createSyncLogger() {
  if (!enableSyncLogs) {
    return Logger(output: _SilentLogOutput());
  }
  return Logger();
}

class _SilentLogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {}
}
