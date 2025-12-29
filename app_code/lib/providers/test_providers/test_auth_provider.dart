import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/user.dart';
import 'package:app_code/providers/real_app_providers/auth_provider.dart';
import 'package:app_code/repositories/test_repo/in_memory_auth_repository.dart';

/// Test-only AuthNotifier that uses the in-memory auth repository to avoid Firebase in widget tests.
class TestAuthNotifier extends AuthNotifier {
  TestAuthNotifier(this.repository);

  final InMemoryAuthRepository repository;

  @override
  Future<User?> build() async {
    return repository.getCurrentUser();
  }

  @override
  Future<void> signInAnonymously() async {
    final user = await repository.signInAnonymously();
    state = AsyncData(user);
  }

  @override
  Future<void> signUp(String email, String password) async {
    final user = await repository.signUp(email, password);
    state = AsyncData(user);
  }

  @override
  Future<void> signOut() async {
    await repository.signOut();
    state = AsyncData(repository.getCurrentUser());
  }
}
