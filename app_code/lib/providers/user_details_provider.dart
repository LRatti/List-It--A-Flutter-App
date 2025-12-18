import 'package:app_code/models/user.dart';
import 'package:app_code/services/database_manager/manage_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Since UserManager is typically a singleton that doesn't change, 
/// the watch is mostly for explicit dependency declaration rather than reactive updates.
final userManagerProvider = Provider((ref) {
  return UserManager();
});

/// Provides real-time user details from the UserManager

/// This provider watches for changes in user details (email, username, etc.)
/// and notifies all watchers of any updates. It's useful for updating UI
/// components like the profile page whenever the user edits their information.
final userDetailsProvider = FutureProvider.autoDispose<User?>((ref) async {
  final userManager = ref.watch(userManagerProvider);
  final user = await userManager.getUserData();
  return user;
});
