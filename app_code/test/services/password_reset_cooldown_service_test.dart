import 'package:app_code/services/password_reset_cooldown_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('PasswordResetCooldownService', () {
    late PasswordResetCooldownService service;

    setUp(() async {
      // Clear any existing preferences
      SharedPreferences.setMockInitialValues({});
      service = PasswordResetCooldownService();
    });

    tearDown(() async {
      // Clean up after each test
      await service.clearCooldown();
    });

    test('canSendResetEmail returns true when no email was sent before', () async {
      final canSend = await service.canSendResetEmail();
      expect(canSend, true);
    });

    test('canSendResetEmail returns false immediately after recording email sent', () async {
      await service.recordResetEmailSent();
      final canSend = await service.canSendResetEmail();
      expect(canSend, false);
    });

    test('getRemainingCooldownSeconds returns 0 when no email was sent', () async {
      final remaining = await service.getRemainingCooldownSeconds();
      expect(remaining, 0);
    });

    test('getRemainingCooldownSeconds returns correct value after recording email', () async {
      await service.recordResetEmailSent();
      final remaining = await service.getRemainingCooldownSeconds();
      
      // Should be approximately 30 seconds (allowing for small execution time)
      expect(remaining, greaterThanOrEqualTo(29));
      expect(remaining, lessThanOrEqualTo(30));
    });

    test('cooldown expires after waiting', () async {
      await service.recordResetEmailSent();
      
      // Wait 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      
      final remaining = await service.getRemainingCooldownSeconds();
      
      // Should be approximately 28 seconds remaining
      expect(remaining, greaterThanOrEqualTo(27));
      expect(remaining, lessThanOrEqualTo(29));
    });

    test('canSendResetEmail returns true after cooldown expires (simulated)', () async {
      // Record an email sent 31 seconds ago
      final prefs = await SharedPreferences.getInstance();
      final oldTimestamp = DateTime.now()
          .subtract(const Duration(seconds: 31))
          .millisecondsSinceEpoch;
      await prefs.setInt('password_reset_last_sent_timestamp', oldTimestamp);
      
      final canSend = await service.canSendResetEmail();
      expect(canSend, true);
    });

    test('getRemainingCooldownSeconds returns 0 after cooldown expires', () async {
      // Record an email sent 31 seconds ago
      final prefs = await SharedPreferences.getInstance();
      final oldTimestamp = DateTime.now()
          .subtract(const Duration(seconds: 31))
          .millisecondsSinceEpoch;
      await prefs.setInt('password_reset_last_sent_timestamp', oldTimestamp);
      
      final remaining = await service.getRemainingCooldownSeconds();
      expect(remaining, 0);
    });

    test('clearCooldown allows sending email immediately', () async {
      await service.recordResetEmailSent();
      expect(await service.canSendResetEmail(), false);
      
      await service.clearCooldown();
      expect(await service.canSendResetEmail(), true);
    });

    test('cooldownDurationSeconds returns correct duration', () {
      expect(service.cooldownDurationSeconds, 30);
    });

    test('cooldown persists across service instances', () async {
      // Record email with first instance
      final service1 = PasswordResetCooldownService();
      await service1.recordResetEmailSent();
      
      // Check with second instance
      final service2 = PasswordResetCooldownService();
      final canSend = await service2.canSendResetEmail();
      
      expect(canSend, false);
    });

    test('recordResetEmailSent updates timestamp correctly', () async {
      final before = DateTime.now().millisecondsSinceEpoch;
      await service.recordResetEmailSent();
      final after = DateTime.now().millisecondsSinceEpoch;
      
      final prefs = await SharedPreferences.getInstance();
      final storedTimestamp = prefs.getInt('password_reset_last_sent_timestamp');
      
      expect(storedTimestamp, isNotNull);
      expect(storedTimestamp!, greaterThanOrEqualTo(before));
      expect(storedTimestamp, lessThanOrEqualTo(after));
    });
  });
}
