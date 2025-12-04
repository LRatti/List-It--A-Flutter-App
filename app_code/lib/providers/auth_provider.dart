import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/user.dart';

final authProvider = StreamProvider.autoDispose<User?>((ref) async* {
  
  // create a stream provides continues values (user/null)
  final Stream<User?> userStream = firebase_auth.FirebaseAuth.instance.authStateChanges().map((user) {
    if (user != null) {
      if (user.email == null) {
        return User(uid: user.uid);
      }
      return User(uid: user.uid, email: user.email!);
    }
    return null;
  });
  
  // YIELD that value whenever it changes
  await for (final user in userStream) {
    yield user;
  }   

});