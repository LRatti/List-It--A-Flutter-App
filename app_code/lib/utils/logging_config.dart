import 'package:logger/logger.dart';

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
