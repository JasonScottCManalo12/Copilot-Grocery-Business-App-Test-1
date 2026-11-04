class StockMovement {
  final int? id;
  final int productId;
  final String productName; // denormalized for easy history display
  final String type; // stock_in, stock_out, adjustment, sale, return
  final double quantity; // positive number; direction determined by type
  final double previousStock;
  final double newStock;
  final String? reason;
  final String? reference; // e.g. transaction id later
  final DateTime createdAt;

  const StockMovement({
    this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    this.reason,
    this.reference,
    required this.createdAt,
  });

  bool get isIncrease =>
      type == 'stock_in' || type == 'return' || (type == 'adjustment' && newStock > previousStock);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'type': type,
      'quantity': quantity,
      'previous_stock': previousStock,
      'new_stock': newStock,
      'reason': reason,
      'reference': reference,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      productName: map['product_name'] as String,
      type: map['type'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      previousStock: (map['previous_stock'] as num).toDouble(),
      newStock: (map['new_stock'] as num).toDouble(),
      reason: map['reason'] as String?,
      reference: map['reference'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String get typeLabel {
    switch (type) {
      case 'stock_in':
        return 'Stock In';
      case 'stock_out':
        return 'Stock Out';
      case 'adjustment':
        return 'Adjustment';
      case 'sale':
        return 'Sale';
      case 'return':
        return 'Return';
      default:
        return type;
    }
  }
}
