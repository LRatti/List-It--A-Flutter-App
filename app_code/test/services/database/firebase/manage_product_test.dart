import 'package:app_code/models/product.dart';
import 'package:app_code/services/database/firebase/manage_product.dart';
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

  group('FirebaseProductManager', () {
    test('stores product data and associations', () async {
      final manager = FirebaseProductManager(
        firestore: firestore,
        firebaseAuth: auth,
      );
      final product = Product(
        id: 'p1',
        name: 'Apple',
        associations: {'s1': 'c1'},
        isVisible: true,
      );

      await manager.setProduct(product);

      final productDoc = await firestore
          .collection('Users')
          .doc(uid)
          .collection('Products')
          .doc('p1')
          .get();
      expect(productDoc.exists, true);
      expect(productDoc.data()?['name'], 'Apple');
      expect(productDoc.data()?['is_visible'], 1);

      final assocDoc = await firestore
          .collection('Users')
          .doc(uid)
          .collection('Associations')
          .doc('p1_s1')
          .get();
      expect(assocDoc.exists, true);
      expect(assocDoc.data()?['categoryId'], 'c1');
    });

    test('retrieves product with associations', () async {
      final manager = FirebaseProductManager(
        firestore: firestore,
        firebaseAuth: auth,
      );
      final product = Product(
        id: 'p1',
        name: 'Apple',
        associations: {'s1': 'c1'},
      );

      await manager.setProduct(product);
      final fetched = await manager.getProductById('p1');

      expect(fetched?.id, 'p1');
      expect(fetched?.associations, {'s1': 'c1'});
    });

    test('filters visible products', () async {
      final manager = FirebaseProductManager(
        firestore: firestore,
        firebaseAuth: auth,
      );
      await manager.setProduct(Product(id: 'p1', name: 'Apple'));
      await manager.setProduct(
        Product(id: 'p2', name: 'Hidden', isVisible: false),
      );

      final visible = await manager.getVisibleProducts();
      expect(visible.map((p) => p.id), ['p1']);
    });

    test('setAllProducts and getAllProducts', () async {
      final manager = FirebaseProductManager(
        firestore: firestore,
        firebaseAuth: auth,
      );
      final p1 = Product(id: 'pA', name: 'Pasta', associations: {'s1': 'c1'});
      final p2 = Product(id: 'pB', name: 'Beans', associations: {'s2': 'c2'});

      await manager.setAllProducts([p1, p2]);
      final all = await manager.getAllProducts();
      expect(all.map((e) => e.id).toSet(), {'pA', 'pB'});
      final a = all.firstWhere((e) => e.id == 'pA');
      expect(a.associations, {'s1': 'c1'});
    });

    test('getProductByName', () async {
      final manager = FirebaseProductManager(
        firestore: firestore,
        firebaseAuth: auth,
      );
      final p = Product(id: 'px', name: 'Tomato');
      await manager.setProduct(p);
      final fetched = await manager.getProductByName('Tomato');
      expect(fetched, isNotNull);
      expect(fetched!.id, 'px');
    });

    test('setProduct throws when not authenticated', () async {
      final unauth = MockFirebaseAuth(signedIn: false);
      final manager = FirebaseProductManager(
        firestore: firestore,
        firebaseAuth: unauth,
      );
      final p = Product(id: 'pNA', name: 'NA');
      await expectLater(manager.setProduct(p), throwsA(isA<Exception>()));
    });

    test('unauthenticated getters return safe defaults', () async {
      final unauth = MockFirebaseAuth(signedIn: false);
      final manager = FirebaseProductManager(
        firestore: firestore,
        firebaseAuth: unauth,
      );
      expect(await manager.getProductById('x'), isNull);
      expect(await manager.getProductByName('n'), isNull);
      expect(await manager.getAllProducts(), isEmpty);
      expect(await manager.getVisibleProducts(), isEmpty);
    });

    test('setAllProducts throws when not authenticated', () async {
      final unauth = MockFirebaseAuth(signedIn: false);
      final manager = FirebaseProductManager(
        firestore: firestore,
        firebaseAuth: unauth,
      );
      await expectLater(
        manager.setAllProducts([Product(id: 'a', name: 'A')]),
        throwsA(isA<Exception>()),
      );
    });
  });
}
