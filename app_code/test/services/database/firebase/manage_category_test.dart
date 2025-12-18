import 'package:app_code/models/category.dart';
import 'package:app_code/services/database/firebase/manage_category.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const uid = 'test-user';
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth auth;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    auth = MockFirebaseAuth(
      mockUser: MockUser(uid: uid, email: 'user@example.com'),
      signedIn: true,
    );
  });

  group('FirebaseCategoryManager', () {
    test('stores and reads categories', () async {
      final manager = FirebaseCategoryManager(
        firestore: firestore,
        firebaseAuth: auth,
      );
      final categories = [
        Category(id: 'c1', name: 'Fruit'),
        Category(id: 'c2', name: 'Veg'),
      ];

      await manager.setAllCategories(categories);
      final fetched = await manager.getAllCategories();

      expect(fetched.length, 2);
      expect(fetched.map((c) => c.id), containsAll(['c1', 'c2']));
    });

    test('setCategory and getCategoryById', () async {
      final manager = FirebaseCategoryManager(
        firestore: firestore,
        firebaseAuth: auth,
      );

      final cat = Category(id: 'c9', name: 'Bakery');
      await manager.setCategory(cat);
      // Since setCategory uses auto-id when adding, ensure setAllCategories path too
      await manager.setAllCategories([cat]);

      final fetched = await manager.getCategoryById('c9');
      expect(fetched, isNotNull);
      expect(fetched!.id, 'c9');
      expect(fetched.getName(), 'Bakery');
    });

    test('getCategoryById returns null when missing', () async {
      final manager = FirebaseCategoryManager(
        firestore: firestore,
        firebaseAuth: auth,
      );
      expect(await manager.getCategoryById('missing'), isNull);
    });

    test('unauthenticated setCategory and setAllCategories throw', () async {
      final unauth = MockFirebaseAuth(signedIn: false);
      final manager = FirebaseCategoryManager(
        firestore: firestore,
        firebaseAuth: unauth,
      );

      await expectLater(
        manager.setCategory(Category(name: 'X')),
        throwsA(isA<Exception>()),
      );

      await expectLater(
        manager.setAllCategories([Category(name: 'A')]),
        throwsA(isA<Exception>()),
      );
    });

    test('unauthenticated getters return safe defaults', () async {
      final unauth = MockFirebaseAuth(signedIn: false);
      final manager = FirebaseCategoryManager(
        firestore: firestore,
        firebaseAuth: unauth,
      );
      expect(await manager.getCategoryById('any'), isNull);
      expect(await manager.getAllCategories(), isEmpty);
    });
  });
}
