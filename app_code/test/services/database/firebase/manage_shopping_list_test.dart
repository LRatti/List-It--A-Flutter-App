import 'package:app_code/models/category.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/services/database/firebase/manage_purchased_product.dart';
import 'package:app_code/services/database/firebase/manage_shopping_list.dart';
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

  group('FirebaseShoppingListManager', () {
    test('persists and reads shopping list with purchased products', () async {
      final category = Category(id: 'c1', name: 'Fruit');
      final product = Product(
        id: 'p1',
        name: 'Apple',
        associations: {'s1': 'c1'},
      );
      final supermarket = Supermarket(
        id: 's1',
        name: 'Market',
        categories: [category],
      );
      await firestore
          .collection('Users')
          .doc(uid)
          .collection('Categories')
          .doc(category.id)
          .set(category.toJson());
      await firestore
          .collection('Users')
          .doc(uid)
          .collection('Products')
          .doc(product.id)
          .set(product.toDatabase());
      await firestore
          .collection('Users')
          .doc(uid)
          .collection('Supermarkets')
          .doc(supermarket.id)
          .set(supermarket.toDatabase());

      final purchased = PurchasedProduct(
        id: 'pp1',
        listId: 'l1',
        product: product,
        category: category,
        price: 2.5,
        quantity: 1,
      );
      final shoppingList = ShoppingList(
        id: 'l1',
        name: 'Groceries',
        createdAt: DateTime(2024, 1, 1),
        supermarket: supermarket,
        products: [purchased],
      );

      final purchasedManager = FirebasePurchasedProductManager(
        firestore: firestore,
        firebaseAuth: auth,
      );
      final manager = FirebaseShoppingListManager(
        firestore: firestore,
        firebaseAuth: auth,
        purchasedProductManager: purchasedManager,
      );

      await manager.setAllShoppingLists([shoppingList]);
      final fetched = await manager.getShoppingListById('l1');

      expect(fetched?.id, 'l1');
      expect(fetched?.getSupermarket()?.id, 's1');
      expect(fetched?.getProducts().length, 1);
      expect(fetched?.getProducts().first.product.id, 'p1');
    });

    test('getAllShoppingLists aggregates lists with products', () async {
      final category = Category(id: 'c2', name: 'Veg');
      final product = Product(id: 'p2', name: 'Tomato');
      final supermarket = Supermarket(id: 's2', name: 'Shop', categories: [category]);
      await firestore
          .collection('Users')
          .doc(uid)
          .collection('Categories')
          .doc(category.id)
          .set(category.toJson());
      await firestore
          .collection('Users')
          .doc(uid)
          .collection('Products')
          .doc(product.id)
          .set(product.toDatabase());
      await firestore
          .collection('Users')
          .doc(uid)
          .collection('Supermarkets')
          .doc(supermarket.id)
          .set(supermarket.toDatabase());

      final purchased = PurchasedProduct(
        listId: 'l2',
        product: product,
        category: category,
        price: 1.0,
        quantity: 3,
      );
      final list = ShoppingList(
        id: 'l2',
        name: 'List 2',
        createdAt: DateTime(2024, 2, 1),
        supermarket: supermarket,
        products: [purchased],
      );

      final purchasedManager = FirebasePurchasedProductManager(
        firestore: firestore,
        firebaseAuth: auth,
      );
      final manager = FirebaseShoppingListManager(
        firestore: firestore,
        firebaseAuth: auth,
        purchasedProductManager: purchasedManager,
      );

      await manager.setAllShoppingLists([list]);
      final all = await manager.getAllShoppingLists();
      expect(all.length, 1);
      expect(all.first.getProducts().length, 1);
    });

    test('deleteShoppingList removes list and its purchased products', () async {
      final manager = FirebaseShoppingListManager(
        firestore: firestore,
        firebaseAuth: auth,
        purchasedProductManager: FirebasePurchasedProductManager(
          firestore: firestore,
          firebaseAuth: auth,
        ),
      );

      // Minimal seed: a list with no supermarket linkage would not load via getter, but can be deleted
      await firestore
          .collection('Users')
          .doc(uid)
          .collection('Shopping Lists')
          .doc('to-del')
          .set({'id': 'to-del', 'name': 'tmp', 'created_at': DateTime(2024,1,1).millisecondsSinceEpoch, 'supermarket_id': 's-x'});
      await firestore
          .collection('Users')
          .doc(uid)
          .collection('Shopping Lists')
          .doc('to-del')
          .collection('Purchased Products')
          .doc('pp-x')
          .set({'id': 'pp-x', 'list_id': 'to-del', 'product_id': 'p-x', 'category_id': 'c-x', 'price': 1, 'quantity': 1});

      // Also seed referenced supermarket to pass the presence check if needed later
      await firestore
          .collection('Users')
          .doc(uid)
          .collection('Supermarkets')
          .doc('s-x')
          .set({'id': 's-x', 'name': 'X', 'is_visible': 1, 'categoryIds': []});

      await manager.deleteShoppingList('to-del');

      final listDoc = await firestore
          .collection('Users')
          .doc(uid)
          .collection('Shopping Lists')
          .doc('to-del')
          .get();
      expect(listDoc.exists, false);
    });

    test('returns null when supermarket_id missing', () async {
      final manager = FirebaseShoppingListManager(
        firestore: firestore,
        firebaseAuth: auth,
        purchasedProductManager: FirebasePurchasedProductManager(
          firestore: firestore,
          firebaseAuth: auth,
        ),
      );
      await firestore
          .collection('Users')
          .doc(uid)
          .collection('Shopping Lists')
          .doc('no-sup')
          .set({'id': 'no-sup', 'name': 'x'});
      expect(await manager.getShoppingListById('no-sup'), isNull);
    });

    test('unauthenticated setters throw; getters safe; delete throws', () async {
      final unauth = MockFirebaseAuth(signedIn: false);
      final manager = FirebaseShoppingListManager(
        firestore: firestore,
        firebaseAuth: unauth,
        purchasedProductManager: FirebasePurchasedProductManager(
          firestore: firestore,
          firebaseAuth: unauth,
        ),
      );

      await expectLater(
        manager.setShoppingList(ShoppingList(name: 'X', createdAt: DateTime(2024,1,1))),
        throwsA(isA<Exception>()),
      );

      await expectLater(
        manager.setAllShoppingLists([ShoppingList(name: 'Y', createdAt: DateTime(2024,1,2))]),
        throwsA(isA<Exception>()),
      );

      expect(await manager.getShoppingListById('id'), isNull);
      expect(await manager.getAllShoppingLists(), isEmpty);

      await expectLater(
        manager.deleteShoppingList('id'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
