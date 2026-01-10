import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/providers/real_app_providers/email_verification_provider.dart';

void main() {
  test('emailVerificationSessionProvider stores and updates session', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Initial state is null
    expect(container.read(emailVerificationSessionProvider), isNull);

    // Set a new signup session
    final session = EmailVerificationSession(isNewSignup: true, email: 'new@example.com');
    container.read(emailVerificationSessionProvider.notifier).state = session;

    final readSession = container.read(emailVerificationSessionProvider);
    expect(readSession, isNotNull);
    expect(readSession!.isNewSignup, isTrue);
    expect(readSession.email, 'new@example.com');

    // Update to email change flow
    final updated = session.copyWith(isNewSignup: false, email: 'updated@example.com');
    container.read(emailVerificationSessionProvider.notifier).state = updated;

    final readUpdated = container.read(emailVerificationSessionProvider);
    expect(readUpdated, isNotNull);
    expect(readUpdated!.isNewSignup, isFalse);
    expect(readUpdated.email, 'updated@example.com');
  });
}
