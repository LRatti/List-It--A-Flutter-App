import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage password reset email cooldown.
/// Prevents spam by enforcing a 30-second cooldown between reset emails.
/// Uses SharedPreferences to persist state across sign-outs and app restarts.
class PasswordResetCooldownService {
  static const String _cooldownKey = 'password_reset_last_sent_timestamp';
  static const int _cooldownDurationSeconds = 30;

  /// Check if a password reset email can be sent (cooldown expired).
  /// Returns true if enough time has passed since the last reset email.
  Future<bool> canSendResetEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSentTimestamp = prefs.getInt(_cooldownKey);
    
    if (lastSentTimestamp == null) {
      // Never sent before, allow sending
      return true;
    }
    
    final lastSentTime = DateTime.fromMillisecondsSinceEpoch(lastSentTimestamp);
    final now = DateTime.now();
    final difference = now.difference(lastSentTime);
    
    return difference.inSeconds >= _cooldownDurationSeconds;
  }

  /// Get the remaining cooldown time in seconds.
  /// Returns 0 if cooldown has expired.
  Future<int> getRemainingCooldownSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSentTimestamp = prefs.getInt(_cooldownKey);
    
    if (lastSentTimestamp == null) {
      return 0;
    }
    
    final lastSentTime = DateTime.fromMillisecondsSinceEpoch(lastSentTimestamp);
    final now = DateTime.now();
    final difference = now.difference(lastSentTime);
    final remaining = _cooldownDurationSeconds - difference.inSeconds;
    
    return remaining > 0 ? remaining : 0;
  }

  /// Record that a password reset email was sent.
  /// Stores the current timestamp to enforce the cooldown.
  Future<void> recordResetEmailSent() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(_cooldownKey, now);
  }

  /// Clear the cooldown (for testing or admin purposes).
  Future<void> clearCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cooldownKey);
  }

  /// Get the cooldown duration in seconds (for UI display).
  int get cooldownDurationSeconds => _cooldownDurationSeconds;
}
