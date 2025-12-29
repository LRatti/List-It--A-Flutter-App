import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/services/password_reset_cooldown_service.dart';

/// Provider for the PasswordResetCooldownService singleton
final passwordResetCooldownServiceProvider = Provider<PasswordResetCooldownService>((ref) {
  return PasswordResetCooldownService();
});

/// Provider that checks if a password reset email can be sent
/// This is an autoDispose provider that updates when read
final canSendPasswordResetProvider = FutureProvider.autoDispose<bool>((ref) async {
  final cooldownService = ref.watch(passwordResetCooldownServiceProvider);
  return await cooldownService.canSendResetEmail();
});

/// Provider that returns the remaining cooldown time in seconds
/// This is an autoDispose provider that updates when read
final passwordResetCooldownRemainingProvider = FutureProvider.autoDispose<int>((ref) async {
  final cooldownService = ref.watch(passwordResetCooldownServiceProvider);
  return await cooldownService.getRemainingCooldownSeconds();
});

/// Notifier to manage cooldown timer updates in real-time
/// This allows the UI to show a countdown timer
class PasswordResetCooldownNotifier extends Notifier<int> {
  PasswordResetCooldownService? _cooldownService;
  Timer? _countdownTimer;

  @override
  int build() {
    _cooldownService = ref.watch(passwordResetCooldownServiceProvider);
    
    // Register cleanup callback when provider is disposed
    ref.onDispose(() {
      _countdownTimer?.cancel();
      _countdownTimer = null;
    });
    
    // Don't start timer in build - just initialize state
    // Timer will be started when needed in recordEmailSent()
    return 0;
  }

  /// Start periodic updates of the countdown
  /// This uses a Timer to update the UI every second
  void _startPeriodicUpdates() {
    if (_countdownTimer != null) return; // Already running
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_cooldownService != null) {
        final remaining = await _cooldownService!.getRemainingCooldownSeconds();
        state = remaining;
        
        // Stop timer when cooldown expires
        if (remaining == 0) {
          _countdownTimer?.cancel();
          _countdownTimer = null;
        }
      }
    });
  }

  /// Check cooldown without starting periodic updates
  Future<void> checkCooldown() async {
    if (_cooldownService != null) {
      final remaining = await _cooldownService!.getRemainingCooldownSeconds();
      state = remaining;
    }
  }

  /// Record that an email was sent and start the cooldown display
  Future<void> recordEmailSent() async {
    if (_cooldownService != null) {
      await _cooldownService!.recordResetEmailSent();
      state = _cooldownService!.cooldownDurationSeconds;
      // Start periodic updates
      _startPeriodicUpdates();
    }
  }
}

/// Provider for the cooldown notifier
/// This manages real-time countdown updates
final passwordResetCooldownNotifierProvider = 
    NotifierProvider<PasswordResetCooldownNotifier, int>(
  PasswordResetCooldownNotifier.new,
);

