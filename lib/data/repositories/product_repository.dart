import '../database/app_database.dart';
import '../models/product.dart';

class ProductRepository {
  final AppDatabase _db = AppDatabase.instance;

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

  Future<List<Product>> getByCategory(String category, {bool activeOnly = true}) async {
    final db = await _db.database;
    final maps = await db.query(
      'products',
      where: activeOnly
          ? 'category = ? AND is_active = ?'
          : 'category = ?',
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

  Future<int> updateStock(int productId, double newQuantity) async {
    final db = await _db.database;
    return await db.update(
      'products',
      {
        'stock_quantity': newQuantity,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  Future<int> adjustStock(int productId, double delta) async {
    final db = await _db.database;
    return await db.rawUpdate('''
      UPDATE products
      SET stock_quantity = stock_quantity + ?,
          updated_at = ?
      WHERE id = ?
    ''', [delta, DateTime.now().toIso8601String(), productId]);
  }
}
