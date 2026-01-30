import 'package:app_code/models/category.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/services/database/sqlite/manage_shopping_list.dart';
import 'package:app_code/services/database/sqlite/manage_supermarket.dart';
import 'package:app_code/services/database/sqlite/manage_category.dart';
import 'package:app_code/repositories/sync/category_repository_sync.dart';
import 'package:app_code/repositories/sync/supermarket_repository_sync.dart';
import 'package:app_code/utils/default_categories_loader.dart';

/// Seeds local SQLite with a default supermarket and categories, plus mock shopping lists if the DB is empty.
Future<void> seedMockDataIfEmpty() async {
  try {
    print('📦 Checking for existing shopping lists...');
    final existing = await ManageShoppingList.getAllShoppingLists();
    print('📦 Found ${existing.length} existing lists');
    
    if (existing.isNotEmpty) {
      print('📦 Database already has data, skipping seed');
      return;
    }

    print('📦 Starting mock data seed...');

    // ===== SEED DEFAULT CATEGORIES AND SUPERMARKET =====
    print('📦 Loading default categories from JSON...');
    final defaultCategories = await DefaultCategoriesLoader.loadDefaultCategories();
    print('📦 Loaded ${defaultCategories.length} default categories');

    // Save default categories to database using sync-aware repository
    // This ensures they are queued in sync_box and will be synced to Firestore
    final categoryRepo = CategoryRepositoryWithSync();
    for (final category in defaultCategories) {
      await categoryRepo.add(category);
    }
    print('📦 Added ${defaultCategories.length} default categories to database (queued for Firestore sync)');

    // Create default supermarket with these categories using sync-aware repository
    // This ensures the supermarket is queued in sync_box and will be synced to Firestore
    final supermarketRepo = SupermarketRepositoryWithSync();
    final defaultSupermarket = Supermarket(
      name: 'Supermarket',
      categories: defaultCategories,
      isVisible: true,
    );
    await supermarketRepo.add(defaultSupermarket);
    print('📦 Created default supermarket with ${defaultCategories.length} categories (queued for Firestore sync)');

    // ===== SEED MOCK SHOPPING LISTS =====
    final fish = Category(name: 'Fish');
    final drinks = Category(name: 'Drinks');
    final meat = Category(name: 'Meat');
    final veggies = Category(name: 'Vegetables');
    final bakery = Category(name: 'Bakery');

    ShoppingList listForPeriod({required String name, required DateTime date}) {
      return ShoppingList(
        name: name,
        createdAt: date,
        isRegistered: true,
        products: [],
      );
    }

    ShoppingList buildListA() {
      final list = listForPeriod(
        name: 'Weekly Groceries',
        date: DateTime.now().subtract(const Duration(days: 2)),
      );
      final items = [
        PurchasedProduct(
          listId: list.id,
          product: Product(name: 'Salmon'),
          category: fish,
          price: 25.0,
          quantity: 1,
        ),
        PurchasedProduct(
          listId: list.id,
          product: Product(name: 'Steak'),
          category: meat,
          price: 22.0,
          quantity: 1,
        ),
        PurchasedProduct(
          listId: list.id,
          product: Product(name: 'Soda Pack'),
          category: drinks,
          price: 12.0,
          quantity: 1,
        ),
        PurchasedProduct(
          listId: list.id,
          product: Product(name: 'Lettuce'),
          category: veggies,
          price: 4.0,
          quantity: 1,
        ),
      ];
      list.setPurchasedProducts(items);
      list.computeTotalPrice();
      return list;
    }

    ShoppingList buildListB() {
      final list = listForPeriod(
        name: 'Friends Dinner',
        date: DateTime.now().subtract(const Duration(days: 18)),
      );
      final items = [
        PurchasedProduct(
          listId: list.id,
          product: Product(name: 'Wine'),
          category: drinks,
          price: 30.0,
          quantity: 2,
        ),
        PurchasedProduct(
          listId: list.id,
          product: Product(name: 'Sea Bass'),
          category: fish,
          price: 28.0,
          quantity: 2,
        ),
        PurchasedProduct(
          listId: list.id,
          product: Product(name: 'Baguette'),
          category: bakery,
          price: 6.0,
          quantity: 3,
        ),
      ];
      list.setPurchasedProducts(items);
      list.computeTotalPrice();
      return list;
    }

    ShoppingList buildListC() {
      final list = listForPeriod(
        name: 'Summer Barbecue',
        date: DateTime.now().subtract(const Duration(days: 80)),
      );
      final items = [
        PurchasedProduct(
          listId: list.id,
          product: Product(name: 'Ribs'),
          category: meat,
          price: 34.0,
          quantity: 2,
        ),
        PurchasedProduct(
          listId: list.id,
          product: Product(name: 'Beer Crate'),
          category: drinks,
          price: 24.0,
          quantity: 1,
        ),
        PurchasedProduct(
          listId: list.id,
          product: Product(name: 'Corn'),
          category: veggies,
          price: 8.0,
          quantity: 8,
        ),
      ];
      list.setPurchasedProducts(items);
      list.computeTotalPrice();
      return list;
    }

    ShoppingList buildDraftList() {
      final list = ShoppingList(
        name: 'Quick Shop',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        isRegistered: true,
        products: [],
      );
      final items = [
        PurchasedProduct(
          listId: list.id,
          product: Product(name: 'Test Item'),
          category: veggies,
          price: 5.0,
          quantity: 1,
        ),
      ];
      list.setPurchasedProducts(items);
      list.computeTotalPrice();
      return list;
    }

    final mockLists = [
      buildListA(),
      buildListB(),
      buildListC(),
      buildDraftList(),
    ];

    print('📦 Adding ${mockLists.length} mock lists to database...');
    for (final list in mockLists) {
      print('  - Adding: ${list.getName()} with ${list.getProducts().length} products');
      await ManageShoppingList.addShoppingList(list);
    }
    print('📦 Mock data seed completed successfully!');
  } catch (e, stackTrace) {
    print('❌ Error seeding mock data: $e');
    print('Stack trace: $stackTrace');
  }
}


