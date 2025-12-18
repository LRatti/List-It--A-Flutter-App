import 'package:app_code/models/user.dart' as app_user;
import 'package:app_code/services/database/firebase/manage_user.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const uid = 'test-user';
  late FakeFirebaseFirestore firestore;

  setUp(() {
    firestore = FakeFirebaseFirestore();
  });

  group('FirebaseUserManager', () {
    test('writes and reads a user', () async {
      final manager = FirebaseUserManager(firestore: firestore);
      final user = app_user.User(
        uid: uid,
        email: 'user@example.com',
        userName: 'Test',
      );

      await manager.setUser(user);
      final fetched = await manager.getUserById(uid);

      expect(fetched?.email, 'user@example.com');
      expect(fetched?.getUserName(), 'Test');
    });

    test('returns null for non-existent user', () async {
      final manager = FirebaseUserManager(firestore: firestore);
      final fetched = await manager.getUserById('nope');
      expect(fetched, isNull);
    });
  });
}
