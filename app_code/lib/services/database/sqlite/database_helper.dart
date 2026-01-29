import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'shopping_app.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  static Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE shopping_list(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        supermarket_id TEXT,
        total_price REAL,
        image TEXT,
        is_registered INTEGER NOT NULL,
        last_modified TEXT NOT NULL,
        is_in_the_trash INTEGER NOT NULL DEFAULT 0,
        deletion_timestamp TEXT,
        is_deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE product(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        associations TEXT,
        is_visible INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        last_modified TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE category(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        is_default INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        last_modified TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE associations (
        product_id TEXT NOT NULL,
        supermarket_id TEXT NOT NULL,
        category_id TEXT NOT NULL,

        PRIMARY KEY (product_id, supermarket_id),

        FOREIGN KEY (product_id) REFERENCES product(id),
        FOREIGN KEY (supermarket_id) REFERENCES supermarket(id),
        FOREIGN KEY (category_id) REFERENCES category(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE supermarket(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        is_visible INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        last_modified TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE supermarket_category(
        supermarket_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        order_index INTEGER NOT NULL,
        PRIMARY KEY (supermarket_id, category_id),
        FOREIGN KEY(supermarket_id) REFERENCES supermarket(id),
        FOREIGN KEY(category_id) REFERENCES category(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE purchased_product(
        id TEXT PRIMARY KEY,
        list_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        last_modified TEXT NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY(list_id) REFERENCES shopping_list(id),
        FOREIGN KEY(product_id) REFERENCES product(id),
        FOREIGN KEY(category_id) REFERENCES category(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE recipe_cache(
        list_id TEXT PRIMARY KEY,
        recipe_name TEXT NOT NULL,
        recipe_data TEXT NOT NULL,
        error_message TEXT,
        has_seen_notification INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY(list_id) REFERENCES shopping_list(id)
      )
    ''');
  }
}
