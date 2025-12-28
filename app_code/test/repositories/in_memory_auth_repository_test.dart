import 'package:flutter_test/flutter_test.dart';
import 'package:app_code/repositories/test_repo/in_memory_auth_repository.dart';

void main() {
  late InMemoryAuthRepository repo;

  setUp(() {
    repo = InMemoryAuthRepository();
  });

  tearDown(() {
    repo.reset();
  });

  test('updateEmail changes email after verifying current password', () async {
    await repo.signUp('old@example.com', 'password123');

    await repo.updateEmail(newEmail: 'new@example.com', currentPassword: 'password123');

    final user = repo.getCurrentUser();
    expect(user, isNotNull);
    expect(user!.email, 'new@example.com');
  });

  test('updateEmail throws on wrong password', () async {
    await repo.signUp('old@example.com', 'password123');

    expect(
      () => repo.updateEmail(newEmail: 'new@example.com', currentPassword: 'wrong'),
      throwsA(isA<Exception>()),
    );
  });

  test('updatePassword updates password and signs out', () async {
    await repo.signUp('user@example.com', 'password123');

    await repo.updatePassword(newPassword: 'newpass456', currentPassword: 'password123');

    final current = repo.getCurrentUser();
    expect(current, isNotNull);
    expect(current!.isAnonymous, isTrue); // Signed out to anonymous

    // Signing in with new password works
    await repo.signIn('user@example.com', 'newpass456');
    final signedIn = repo.getCurrentUser();
    expect(signedIn, isNotNull);
    expect(signedIn!.isAnonymous, isFalse);
  });

  test('abortEmailVerification new signup resets to anonymous', () async {
    await repo.signUp('user@example.com', 'password123');
    await repo.abortEmailVerification(isNewSignup: true);
    final current = repo.getCurrentUser();
    expect(current, isNotNull);
    expect(current!.isAnonymous, isTrue);
  });

  test('abortEmailVerification email update keeps signed in', () async {
    await repo.signUp('user@example.com', 'password123');
    await repo.abortEmailVerification(isNewSignup: false);
    final current = repo.getCurrentUser();
    expect(current, isNotNull);
    expect(current!.isAnonymous, isFalse);
  });
}
