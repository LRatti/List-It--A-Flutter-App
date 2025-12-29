import 'package:app_code/models/category.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/services/database/firebase/manage_purchased_product.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth auth;
  const uid = 'test-uid';

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    auth = MockFirebaseAuth(mockUser: MockUser(uid: uid), signedIn: true);
  });

  Future<void> seedProductAndCategory({
    required Product product,
    required Category category,
  }) async {
    await firestore
        .collection('Users')
        .doc(uid)
        .collection('Products')
        .doc(product.id)
        .set(product.toDatabase());

    await firestore
        .collection('Users')
        .doc(uid)
        .collection('Categories')
        .doc(category.id)
        .set(category.toDatabase());
  }

  test('adds and retrieves a purchased product by id', () async {
    final manager = FirebasePurchasedProductManager(
      firebaseAuth: auth,
      firestore: firestore,
    );

    final product = Product(name: 'Pasta');
    final category = Category(name: 'Pantry');
    await seedProductAndCategory(product: product, category: category);

    final purchased = PurchasedProduct(
      listId: 'list-1',
      product: product,
      category: category,
      price: 1.99,
      quantity: 2,
    );

    await manager.setPurchasedProduct(purchased);

    final fetched = await manager.getPurchasedProductById(
      'list-1',
      purchased.id,
    );
    expect(fetched, isNotNull);
    expect(fetched!.id, purchased.id);
    expect(fetched.listId, 'list-1');
    expect(fetched.product.id, product.id);
    expect(fetched.product.getName(), 'Pasta');
    expect(fetched.category.id, category.id);
    expect(fetched.quantity, 2);
    expect(fetched.price, 1.99);
  });

  test('returns null when purchased doc missing', () async {
    final manager = FirebasePurchasedProductManager(
      firebaseAuth: auth,
      firestore: firestore,
    );

    final res = await manager.getPurchasedProductById('list-X', 'missing');
    expect(res, isNull);
  });

  test('returns null when referenced product is missing', () async {
    final manager = FirebasePurchasedProductManager(
      firebaseAuth: auth,
      firestore: firestore,
    );

    final category = Category(name: 'Dairy');
    // Seed only category; product intentionally missing
    await firestore
        .collection('Users')
        .doc(uid)
        .collection('Categories')
        .doc(category.id)
        .set(category.toDatabase());

    final listId = 'list-miss-prod';
    final purchasedId = 'pp-1';
    await firestore
        .collection('Users')
        .doc(uid)
        .collection('Shopping Lists')
        .doc(listId)
        .collection('Purchased Products')
        .doc(purchasedId)
        .set({
          'id': purchasedId,
          'list_id': listId,
          'product_id': 'no-such-product',
          'category_id': category.id,
          'price': 0.99,
          'quantity': 1,
        });

    final res = await manager.getPurchasedProductById(listId, purchasedId);
    expect(res, isNull);
  });

  test('returns null when referenced category is missing', () async {
    final manager = FirebasePurchasedProductManager(
      firebaseAuth: auth,
      firestore: firestore,
    );

    final product = Product(name: 'Milk');
    await firestore
        .collection('Users')
        .doc(uid)
        .collection('Products')
        .doc(product.id)
        .set(product.toDatabase());

    final listId = 'list-miss-cat';
    final purchasedId = 'pp-2';
    await firestore
        .collection('Users')
        .doc(uid)
        .collection('Shopping Lists')
        .doc(listId)
        .collection('Purchased Products')
        .doc(purchasedId)
        .set({
          'id': purchasedId,
          'list_id': listId,
          'product_id': product.id,
          'category_id': 'no-such-category',
          'price': 1.20,
          'quantity': 1,
        });

    final res = await manager.getPurchasedProductById(listId, purchasedId);
    expect(res, isNull);
  });

  test('returns null when product_id or category_id missing', () async {
    final manager = FirebasePurchasedProductManager(
      firebaseAuth: auth,
      firestore: firestore,
    );

    final listId = 'list-missing-fields';
    final purchasedId1 = 'pp-no-prod';
    await firestore
        .collection('Users')
        .doc(uid)
        .collection('Shopping Lists')
        .doc(listId)
        .collection('Purchased Products')
        .doc(purchasedId1)
        .set({
          'id': purchasedId1,
          'list_id': listId,
          // 'product_id': missing on purpose
          'category_id': 'cat-1',
          'price': 2.0,
          'quantity': 1,
        });

    final purchasedId2 = 'pp-no-cat';
    await firestore
        .collection('Users')
        .doc(uid)
        .collection('Shopping Lists')
        .doc(listId)
        .collection('Purchased Products')
        .doc(purchasedId2)
        .set({
          'id': purchasedId2,
          'list_id': listId,
          'product_id': 'prod-1',
          // 'category_id': missing on purpose
          'price': 2.0,
          'quantity': 1,
        });

    expect(await manager.getPurchasedProductById(listId, purchasedId1), isNull);
    expect(await manager.getPurchasedProductById(listId, purchasedId2), isNull);
  });

  test(
    'adds multiple purchased products (batch) and lists by shopping list',
    () async {
      final manager = FirebasePurchasedProductManager(
        firebaseAuth: auth,
        firestore: firestore,
      );

      final product1 = Product(name: 'Apple');
      final product2 = Product(name: 'Banana');
      final category = Category(name: 'Fruits');
      await seedProductAndCategory(product: product1, category: category);
      await seedProductAndCategory(product: product2, category: category);

      final listId = 'list-X';
      final p1 = PurchasedProduct(
        listId: listId,
        product: product1,
        category: category,
        price: 0.5,
        quantity: 4,
      );
      final p2 = PurchasedProduct(
        listId: listId,
        product: product2,
        category: category,
        price: 0.3,
        quantity: 6,
      );

      await manager.setAllPurchasedProducts([p1, p2]);

      final items = await manager.getPurchasedProductByList(listId);
      expect(items.length, 2);
      expect(items.map((e) => e.product.getName()).toSet(), {
        'Apple',
        'Banana',
      });
    },
  );

  test('deletes a purchased product', () async {
    final manager = FirebasePurchasedProductManager(
      firebaseAuth: auth,
      firestore: firestore,
    );

    final product = Product(name: 'Chips');
    final category = Category(name: 'Snacks');
    await seedProductAndCategory(product: product, category: category);

    final listId = 'list-Z';
    final purchased = PurchasedProduct(
      listId: listId,
      product: product,
      category: category,
      price: 1.0,
      quantity: 2,
    );

    await manager.setPurchasedProduct(purchased);
    expect((await manager.getPurchasedProductByList(listId)).length, 1);

    await manager.deletePurchasedProduct(purchased);
    final remaining = await manager.getPurchasedProductByList(listId);
    expect(remaining, isEmpty);
  });

  test('throws when user is not authenticated', () async {
    final unauth = MockFirebaseAuth(signedIn: false);
    final manager = FirebasePurchasedProductManager(
      firebaseAuth: unauth,
      firestore: firestore,
    );

    final product = Product(name: 'Soda');
    final category = Category(name: 'Drinks');
    final purchased = PurchasedProduct(
      listId: 'list-U',
      product: product,
      category: category,
      price: 0.9,
      quantity: 1,
    );

    await expectLater(
      manager.setPurchasedProduct(purchased),
      throwsA(isA<Exception>()),
    );
  });

  test('unauthenticated getters safe; batch/delete throw', () async {
    final unauth = MockFirebaseAuth(signedIn: false);
    final manager = FirebasePurchasedProductManager(
      firebaseAuth: unauth,
      firestore: firestore,
    );

    expect(await manager.getPurchasedProductById('l', 'p'), isNull);
    expect(await manager.getPurchasedProductByList('l'), isEmpty);

    await expectLater(
      manager.setAllPurchasedProducts([]),
      completes,
    );

    await expectLater(
      manager.setAllPurchasedProducts([
        PurchasedProduct(
          listId: 'l',
          product: Product(name: 'A'),
          category: Category(name: 'C'),
          price: 1,
          quantity: 1,
        )
      ]),
      throwsA(isA<Exception>()),
    );

    await expectLater(
      manager.deletePurchasedProduct(
        PurchasedProduct(
          listId: 'l',
          product: Product(name: 'A'),
          category: Category(name: 'C'),
          price: 1,
          quantity: 1,
        ),
      ),
      throwsA(isA<Exception>()),
    );
  });
}
