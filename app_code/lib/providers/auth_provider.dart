import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/user.dart';

final authProvider = StreamProvider.autoDispose<User?>((ref) async* {
    
  // Use userChanges() instead of authStateChanges() to detect credential linking
  // userChanges() emits when user properties change (like isAnonymous, email, etc.)
  // authStateChanges() only emits on sign-in/sign-out events
  final Stream<User?> userStream = firebase_auth.FirebaseAuth.instance.userChanges().map((user) {
    if (user != null) {
      return User(
        uid: user.uid,
        isAnonymous: user.isAnonymous,
        email: user.email,
      );
    }
    return null;
  });

  // YIELD that value whenever it changes
  await for (final user in userStream) {
    yield user;
  }   

});