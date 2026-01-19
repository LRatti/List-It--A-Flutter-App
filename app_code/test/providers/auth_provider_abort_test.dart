import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/providers/real_app_providers/auth_provider.dart';
import 'package:app_code/repositories/mock_repo/mock_auth_repository.dart';

void main() {
  test('abortEmailVerification for new signup signs in anonymously', () async {
    final repo = MockAuthRepository();
    // Simulate user signed up (non-anonymous)
    await repo.signUp('user@example.com', 'password123');

    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);

    final notifier = container.read(authProvider.notifier);

    // Abort as new signup -> user should become anonymous
    await notifier.abortEmailVerification(isNewSignup: true);

    final current = repo.getCurrentUser();
    expect(current, isNotNull);
    expect(current!.isAnonymous, isTrue);
  });

  test('abortEmailVerification for email update keeps user signed in', () async {
    final repo = MockAuthRepository();
    // Simulate user signed in
    await repo.signUp('user2@example.com', 'password123');

    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);

    final notifier = container.read(authProvider.notifier);

    // Abort as email update -> no change to auth state
    await notifier.abortEmailVerification(isNewSignup: false);

    final current = repo.getCurrentUser();
    expect(current, isNotNull);
    expect(current!.isAnonymous, isFalse);
  });
}
