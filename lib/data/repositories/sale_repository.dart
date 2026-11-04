import 'package:intl/intl.dart';
import '../database/app_database.dart';
import '../models/sale.dart';
import '../models/product.dart';
import '../../core/constants/app_constants.dart';

class SaleRepository {
  final AppDatabase _db = AppDatabase.instance;

  /// Generate a simple human-readable transaction ID
  Future<String> _generateTransactionId() async {
    final now = DateTime.now();
    final datePart = DateFormat('yyyyMMdd').format(now);

    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM sales
      WHERE transaction_id LIKE ?
    ''', ['S-$datePart-%']);

    final count = (result.first['count'] as int?) ?? 0;
    final seq = (count + 1).toString().padLeft(3, '0');
    return 'S-$datePart-$seq';
  }

  /// Complete a sale: create sale + items, deduct stock, record movements
  Future<Sale> completeSale({
    required List<SaleItem> items,
    required String paymentMethod,
    required double amountReceived,
    double discount = 0.0,
    String? notes,
  }) async {
    if (items.isEmpty) throw Exception('Cart is empty');

    final db = await _db.database;
    final now = DateTime.now();

    return await db.transaction((txn) async {
      // Calculate totals
      final subtotal = items.fold<double>(0, (sum, i) => sum + i.subtotal);
      final total = subtotal - discount;
      if (total < 0) throw Exception('Total cannot be negative');
      if (amountReceived < total) {
        throw Exception('Amount received is less than total');
      }
      final change = amountReceived - total;

      final transactionId = await _generateTransactionId();

      // Insert sale
      final saleMap = {
        'transaction_id': transactionId,
        'created_at': now.toIso8601String(),
        'subtotal': subtotal,
        'discount': discount,
        'total': total,
        'payment_method': paymentMethod,
        'amount_received': amountReceived,
        'change_amount': change,
        'status': 'completed',
        'notes': notes,
      };

      final saleId = await txn.insert('sales', saleMap);

      // Insert items + deduct stock
      for (final item in items) {
        await txn.insert('sale_items', item.copyWithSaleId(saleId).toMap());

        // Get current product stock
        final productMaps = await txn.query(
          'products',
          where: 'id = ?',
          whereArgs: [item.productId],
        );
        if (productMaps.isEmpty) {
          throw Exception('Product ${item.productName} not found');
        }

        final product = Product.fromMap(productMaps.first);
        final previousStock = product.stockQuantity;
        final newStock = previousStock - item.quantity;

        if (newStock < 0) {
          throw Exception(
              'Insufficient stock for ${item.productName}. Available: $previousStock');
        }

        // Update stock
        await txn.update(
          'products',
          {
            'stock_quantity': newStock,
            'updated_at': now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [item.productId],
        );

        // Record stock movement
        await txn.insert('stock_movements', {
          'product_id': item.productId,
          'product_name': item.productName,
          'type': AppConstants.movementSale,
          'quantity': item.quantity,
          'previous_stock': previousStock,
          'new_stock': newStock,
          'reason': 'Sale $transactionId',
          'reference': transactionId,
          'created_at': now.toIso8601String(),
        });
      }

      return Sale(
        id: saleId,
        transactionId: transactionId,
        createdAt: now,
        subtotal: subtotal,
        discount: discount,
        total: total,
        paymentMethod: paymentMethod,
        amountReceived: amountReceived,
        changeAmount: change,
        status: 'completed',
        notes: notes,
        items: items,
      );
    });
  }

  Future<List<Sale>> getRecentSales({int limit = 50}) async {
    final db = await _db.database;
    final maps = await db.query(
      'sales',
      orderBy: 'created_at DESC',
      limit: limit,
    );

    final sales = <Sale>[];
    for (final map in maps) {
      final items = await _getItemsForSale(map['id'] as int);
      sales.add(Sale.fromMap(map, items: items));
    }
    return sales;
  }

  Future<Sale?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query(
      'sales',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    final items = await _getItemsForSale(id);
    return Sale.fromMap(maps.first, items: items);
  }

  Future<Sale?> getByTransactionId(String transactionId) async {
    final db = await _db.database;
    final maps = await db.query(
      'sales',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
    if (maps.isEmpty) return null;
    final id = maps.first['id'] as int;
    final items = await _getItemsForSale(id);
    return Sale.fromMap(maps.first, items: items);
  }

  Future<List<SaleItem>> _getItemsForSale(int saleId) async {
    final db = await _db.database;
    final maps = await db.query(
      'sale_items',
      where: 'sale_id = ?',
      whereArgs: [saleId],
    );
    return maps.map((m) => SaleItem.fromMap(m)).toList();
  }

  Future<double> getTodayTotal() async {
    final db = await _db.database;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(total), 0) as total FROM sales
      WHERE date(created_at) = ? AND status = 'completed'
    ''', [today]);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}

extension on SaleItem {
  SaleItem copyWithSaleId(int saleId) {
    return SaleItem(
      id: id,
      saleId: saleId,
      productId: productId,
      productName: productName,
      unit: unit,
      quantity: quantity,
      unitPrice: unitPrice,
      subtotal: subtotal,
    );
  }
}
