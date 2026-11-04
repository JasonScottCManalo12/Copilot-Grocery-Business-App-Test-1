import '../database/app_database.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';
import '../../core/constants/app_constants.dart';

class ProductRepository {
  final AppDatabase _db = AppDatabase.instance;

  // ─────────────────────────────────────────────
  // Product CRUD
  // ─────────────────────────────────────────────

  Future<int> insert(Product product) async {
    final db = await _db.database;
    return await db.insert('products', product.toMap());
  }

  Future<int> update(Product product) async {
    final db = await _db.database;
    return await db.update(
      'products',
      product.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> softDelete(int id) async {
    final db = await _db.database;
    return await db.update(
      'products',
      {
        'is_active': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> hardDelete(int id) async {
    final db = await _db.database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Product?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  Future<List<Product>> getAll({bool activeOnly = true}) async {
    final db = await _db.database;
    final maps = await db.query(
      'products',
      where: activeOnly ? 'is_active = ?' : null,
      whereArgs: activeOnly ? [1] : null,
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Product>> search(String query, {bool activeOnly = true}) async {
    final db = await _db.database;
    final maps = await db.query(
      'products',
      where: activeOnly
          ? '(name LIKE ? OR sku LIKE ? OR barcode LIKE ?) AND is_active = ?'
          : 'name LIKE ? OR sku LIKE ? OR barcode LIKE ?',
      whereArgs: activeOnly
          ? ['%$query%', '%$query%', '%$query%', 1]
          : ['%$query%', '%$query%', '%$query%'],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Product>> getByCategory(String category,
      {bool activeOnly = true}) async {
    final db = await _db.database;
    final maps = await db.query(
      'products',
      where: activeOnly ? 'category = ? AND is_active = ?' : 'category = ?',
      whereArgs: activeOnly ? [category, 1] : [category],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Product>> getLowStock() async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT * FROM products
      WHERE is_active = 1 AND stock_quantity <= low_stock_threshold
      ORDER BY stock_quantity ASC
    ''');
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  // ─────────────────────────────────────────────
  // Stock Operations (with movement history)
  // ─────────────────────────────────────────────

  /// Stock In - increases stock
  Future<void> stockIn({
    required int productId,
    required double quantity,
    String? reason,
    String? reference,
  }) async {
    await _applyStockChange(
      productId: productId,
      quantity: quantity,
      type: AppConstants.movementStockIn,
      reason: reason,
      reference: reference,
    );
  }

  /// Stock Out - decreases stock
  Future<void> stockOut({
    required int productId,
    required double quantity,
    String? reason,
    String? reference,
  }) async {
    await _applyStockChange(
      productId: productId,
      quantity: -quantity,
      type: AppConstants.movementStockOut,
      reason: reason,
      reference: reference,
    );
  }

  /// Manual adjustment to a specific quantity
  Future<void> adjustStock({
    required int productId,
    required double newQuantity,
    String? reason,
  }) async {
    final product = await getById(productId);
    if (product == null) throw Exception('Product not found');

    final delta = newQuantity - product.stockQuantity;
    await _applyStockChange(
      productId: productId,
      quantity: delta,
      type: AppConstants.movementAdjustment,
      reason: reason,
      absoluteNewStock: newQuantity,
    );
  }

  Future<void> _applyStockChange({
    required int productId,
    required double quantity, // can be negative
    required String type,
    String? reason,
    String? reference,
    double? absoluteNewStock,
  }) async {
    final db = await _db.database;

    await db.transaction((txn) async {
      final maps = await txn.query(
        'products',
        where: 'id = ?',
        whereArgs: [productId],
      );
      if (maps.isEmpty) throw Exception('Product not found');

      final product = Product.fromMap(maps.first);
      final previous = product.stockQuantity;
      final newStock = absoluteNewStock ?? (previous + quantity);

      if (newStock < 0) {
        throw Exception('Stock cannot go below zero');
      }

      // Update product stock
      await txn.update(
        'products',
        {
          'stock_quantity': newStock,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [productId],
      );

      // Record movement
      final movement = StockMovement(
        productId: productId,
        productName: product.name,
        type: type,
        quantity: quantity.abs(),
        previousStock: previous,
        newStock: newStock,
        reason: reason,
        reference: reference,
        createdAt: DateTime.now(),
      );

      await txn.insert('stock_movements', movement.toMap());
    });
  }

  // ─────────────────────────────────────────────
  // Stock Movement History
  // ─────────────────────────────────────────────

  Future<List<StockMovement>> getMovements({
    int? productId,
    int limit = 100,
  }) async {
    final db = await _db.database;
    final maps = await db.query(
      'stock_movements',
      where: productId != null ? 'product_id = ?' : null,
      whereArgs: productId != null ? [productId] : null,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return maps.map((m) => StockMovement.fromMap(m)).toList();
  }

  Future<List<StockMovement>> getRecentMovements({int limit = 50}) async {
    return getMovements(limit: limit);
  }
}
