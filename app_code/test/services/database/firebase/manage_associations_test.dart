import 'package:app_code/services/database/firebase/manage_associations.dart';
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

  group('FirebaseManageAssociations', () {
    test('sets and deletes association', () async {
      final manager = FirebaseManageAssociations(
        firestore: firestore,
        firebaseAuth: auth,
      );

      await manager.setAssociation('prod1', 'sup1', 'cat1');
      var doc = await firestore
          .collection('Users')
          .doc(uid)
          .collection('Associations')
          .doc('prod1_sup1')
          .get();
      expect(doc.exists, true);

      final category = await manager.getCategoryForProduct('prod1', 'sup1');
      expect(category, 'cat1');

      await manager.deleteAssociation('prod1', 'sup1');
      doc = await firestore
          .collection('Users')
          .doc(uid)
          .collection('Associations')
          .doc('prod1_sup1')
          .get();
      expect(doc.exists, false);
    });

    test('deletes all product associations', () async {
      final manager = FirebaseManageAssociations(
        firestore: firestore,
        firebaseAuth: auth,
      );
      await manager.setAssociation('prod1', 'sup1', 'cat1');
      await manager.setAssociation('prod1', 'sup2', 'cat2');

      await manager.deleteProductAssociations('prod1');

      final remaining = await firestore
          .collection('Users')
          .doc(uid)
          .collection('Associations')
          .get();
      expect(remaining.docs, isEmpty);
    });

    test('queries associations: product map, by supermarket, by category', () async {
      final manager = FirebaseManageAssociations(
        firestore: firestore,
        firebaseAuth: auth,
      );

      await manager.setAssociation('prod1', 'sup1', 'cat1');
      await manager.setAssociation('prod2', 'sup1', 'cat2');
      await manager.setAssociation('prod3', 'sup2', 'cat1');

      final map = await manager.getProductAssociations('prod1');
      expect(map, {'sup1': 'cat1'});

      final sup1Products = await manager.getProductsBySupermarket('sup1');
      expect(sup1Products.toSet(), {'prod1', 'prod2'});

      final byCat = await manager.getProductsByCategory('sup1', 'cat2');
      expect(byCat, ['prod2']);
    });

    test('queries categories by product returns unique list', () async {
      final manager = FirebaseManageAssociations(
        firestore: firestore,
        firebaseAuth: auth,
      );
      await manager.setAssociation('p', 's1', 'c1');
      await manager.setAssociation('p', 's2', 'c1');
      await manager.setAssociation('p', 's3', 'c2');

      final cats = await manager.getCategoriesByProduct('p');
      expect(cats.toSet(), {'c1', 'c2'});
    });

    test('unauthenticated query methods return empty results, not throw', () async {
      final unauth = MockFirebaseAuth(signedIn: false);
      final manager = FirebaseManageAssociations(
        firestore: firestore,
        firebaseAuth: unauth,
      );

      // These methods catch errors and return empty structures
      expect(await manager.getProductAssociations('x'), isEmpty);
      expect(await manager.getProductsBySupermarket('s'), isEmpty);
      expect(await manager.getProductsByCategory('s', 'c'), isEmpty);
      expect(await manager.getCategoriesByProduct('p'), isEmpty);
    });

    test('unauthenticated set/delete behaviors', () async {
      final unauth = MockFirebaseAuth(signedIn: false);
      final manager = FirebaseManageAssociations(
        firestore: firestore,
        firebaseAuth: unauth,
      );

      await expectLater(
        manager.setAssociation('p', 's', 'c'),
        throwsA(isA<Exception>()),
      );

      await expectLater(
        manager.deleteAssociation('p', 's'),
        throwsA(isA<Exception>()),
      );

      // deleteProductAssociations wraps in try/catch and should not throw
      await manager.deleteProductAssociations('p');
    });
  });
}
