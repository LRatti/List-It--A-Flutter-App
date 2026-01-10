import 'package:app_code/models/user.dart';
import 'package:app_code/repositories/real_app_repo/database_manager_repository/manage_user.dart';
import 'package:app_code/providers/real_app_providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Repository provider to keep the data layer injectable/testable.
final userManagerProvider = Provider<UserDatabaseManager>((ref) {
  return UserDatabaseManager();
});

/// Riverpod notifier that exposes the current user details and handles updates.
final userDetailsProvider =
    AsyncNotifierProvider<UserDetailsNotifier, User?>(UserDetailsNotifier.new);

class UserDetailsNotifier extends AsyncNotifier<User?> {
  UserDatabaseManager get _userManager => ref.read(userManagerProvider);

  @override
  Future<User?> build() async {
    // Watch auth state so this provider rebuilds when user signs in/out
    // This ensures user details refresh after email updates or re-authentication
    final authUser = ref.watch(authProvider);
    
    // If no auth user or user is loading, return null
    if (!authUser.hasValue || authUser.value == null) {
      return null;
    }
    
    return _userManager.getUserData();
  }

  /// Reloads user details from the repository.
  Future<User?> refreshUser() async {
    try {
      final user = await _userManager.getUserData();
      state = AsyncData(user);
      return user;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Persists the updated user and refreshes Riverpod state.
  Future<User?> updateUser(User updatedUser) async {
    try {
      await _userManager.setUserData(updatedUser);
      final refreshedUser = await _userManager.getUserData();
      state = AsyncData(refreshedUser);
      return refreshedUser;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
