import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_constants.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, AppConstants.dbName);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _on recapUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        sku TEXT,
        barcode TEXT,
        category TEXT NOT NULL DEFAULT 'Uncategorized',
        unit TEXT NOT NULL DEFAULT 'pc',
        cost_price REAL NOT NULL DEFAULT 0.0,
        selling_price REAL NOT NULL,
        stock_quantity REAL NOT NULL DEFAULT 0.0,
        low_stock_threshold REAL NOT NULL DEFAULT 5.0,
        is_active INTEGER NOT NULL DEFAULT 1,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_products_name ON products(name)');
    await db.execute('CREATE INDEX idx_products_category ON products(category)');
    await db.execute('CREATE INDEX idx_products_is_active ON products(is_active)');
    await db.execute('CREATE INDEX idx_products_barcode ON products(barcode)');

    await _createStockMovementsTable(db);
    await _createSalesTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createStockMovementsTable(db);
    }
    if (oldVersion < 3) {
      await _createSalesTables(db);
    }
  }

  Future<void> _createStockMovementsTable(Database db) async {
    await db.execute('''
      CREATE TABLE stock_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        type TEXT NOT NULL,
        quantity REAL NOT NULL,
        previous_stock REAL NOT NULL,
        new_stock REAL NOT NULL,
        reason TEXT,
        reference TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_stock_movements_product ON stock_movements(product_id)');
    await db.execute(
        'CREATE INDEX idx_stock_movements_created ON stock_movements(created_at)');
    await db.execute(
        'CREATE INDEX idx_stock_movements_type ON stock_movements(type)');
  }

  Future<void> _createSalesTables(Database db) async {
    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL,
        subtotal REAL NOT NULL,
        discount REAL NOT NULL DEFAULT 0.0,
        total REAL NOT NULL,
        payment_method TEXT NOT NULL,
        amount_received REAL NOT NULL,
        change_amount REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'completed',
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        unit TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        subtotal REAL NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales (id),
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    await db.execute('CREATE INDEX idx_sales_created ON sales(created_at)');
    await db.execute('CREATE INDEX idx_sales_transaction ON sales(transaction_id)');
    await db.execute('CREATE INDEX idx_sale_items_sale ON sale_items(sale_id)');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
