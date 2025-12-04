import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'shopping_app.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  static Future<void> _createDb(Database db, int version) async {
    //shopping_list
    await db.execute('''
      CREATE TABLE shopping_list(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        supermarket_id TEXT,
        total_price REAL,
        is_registered INTEGER NOT NULL,
        image_path TEXT
      )
    ''');

    //purchased_product
    await db.execute('''
      CREATE TABLE purchased_product(
        id TEXT PRIMARY KEY,
        list_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        FOREIGN KEY(list_id) REFERENCES shopping_list(id)
      )
    ''');

    // Product
    await db.execute('''
      CREATE TABLE product(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category_id TEXT
      )
    ''');

    // Category
    await db.execute('''
      CREATE TABLE category(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        is_default INTEGER NOT NULL
      )
    ''');

    // Supermarket
    await db.execute('''
      CREATE TABLE supermarket(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL
      )
    ''');

    // Supermarket → Category (N:N)
    await db.execute('''
      CREATE TABLE supermarket_category(
        supermarket_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        PRIMARY KEY (supermarket_id, category_id),
        FOREIGN KEY (supermarket_id) REFERENCES supermarket(id),
        FOREIGN KEY (category_id) REFERENCES category(id)
      )
    ''');

    // User
    await db.execute('''
      CREATE TABLE user(
        id TEXT PRIMARY KEY,
        provider_id TEXT,
        email TEXT NOT NULL,
        password TEXT,
        user_name TEXT
      )
    ''');
  }
}