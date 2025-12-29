import 'package:app_code/models/category.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/services/database/firebase/manage_supermarket.dart';
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

  group('FirebaseSupermarketManager', () {
    test('fetches supermarket with categories', () async {
      final manager = FirebaseSupermarketManager(
        firestore: firestore,
        firebaseAuth: auth,
      );
      final category = Category(id: 'c1', name: 'Fruit');
      await firestore
          .collection('Users')
          .doc(uid)
          .collection('Categories')
          .doc('c1')
          .set(category.toJson());

      final supermarket = Supermarket(
        id: 's1',
        name: 'Market',
        categories: [category],
      );
      await manager.setSupermarket(supermarket);

      final fetched = await manager.getSupermarketById('s1');
      expect(fetched?.id, 's1');
      expect(fetched?.getCategories().length, 1);
      expect(fetched?.getCategories().first.id, 'c1');
    });

    test('setAllSupermarkets and getAllSupermarkets', () async {
      final manager = FirebaseSupermarketManager(
        firestore: firestore,
        firebaseAuth: auth,
      );
      final s1 = Supermarket(id: 'sA', name: 'One');
      final s2 = Supermarket(id: 'sB', name: 'Two');
      await manager.setAllSupermarkets([s1, s2]);
      final all = await manager.getAllSupermarkets();
      expect(all.map((e) => e.id).toSet(), {'sA', 'sB'});
    });

    test('getSupermarketByName', () async {
      final manager = FirebaseSupermarketManager(
        firestore: firestore,
        firebaseAuth: auth,
      );
      final sm = Supermarket(id: 'sN', name: 'Named Market');
      await manager.setSupermarket(sm);
      final fetched = await manager.getSupermarketByName('Named Market');
      expect(fetched?.id, 'sN');
    });

    test('getVisibleSupermarkets filters by isVisible', () async {
      final manager = FirebaseSupermarketManager(
        firestore: firestore,
        firebaseAuth: auth,
      );
      await manager.setAllSupermarkets([
        Supermarket(id: 'sv1', name: 'V1', isVisible: true),
        Supermarket(id: 'sv2', name: 'V2', isVisible: false),
      ]);
      final visible = await manager.getVisibleSupermarkets();
      expect(visible.map((e) => e.id), ['sv1']);
    });

    test('handles missing categories gracefully', () async {
      final manager = FirebaseSupermarketManager(
        firestore: firestore,
        firebaseAuth: auth,
      );
      // Supermarket references a category that doesn't exist
      await firestore
          .collection('Users')
          .doc(uid)
          .collection('Supermarkets')
          .doc('s-miss')
          .set({'id': 's-miss', 'name': 'Miss', 'categoryIds': ['no-cat'], 'is_visible': true});
      final fetched = await manager.getSupermarketById('s-miss');
      expect(fetched, isNotNull);
      expect(fetched!.getCategories(), isEmpty);
    });

    test('unauthenticated behaviors: set does not throw, queries safe', () async {
      final unauth = MockFirebaseAuth(signedIn: false);
      final manager = FirebaseSupermarketManager(
        firestore: firestore,
        firebaseAuth: unauth,
      );

      // setSupermarket wrapped in try/catch: should not throw
      await manager.setSupermarket(Supermarket(id: 'nope', name: 'Nope'));
      final doc = await firestore
          .collection('Users')
          .doc(uid)
          .collection('Supermarkets')
          .doc('nope')
          .get();
      expect(doc.exists, false);

      // setAllSupermarkets builds batch before try: should throw
      await expectLater(
        manager.setAllSupermarkets([Supermarket(id: 'a'), Supermarket(id: 'b')]),
        throwsA(isA<Exception>()),
      );

      expect(await manager.getSupermarketById('x'), isNull);
      expect(await manager.getSupermarketByName('x'), isNull);
      expect(await manager.getAllSupermarkets(), isEmpty);
      expect(await manager.getVisibleSupermarkets(), isEmpty);
    });
  });
}
