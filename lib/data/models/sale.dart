class SaleItem {
  final int? id;
  final int? saleId;
  final int productId;
  final String productName;
  final String unit;
  final double quantity;
  final double unitPrice;
  final double subtotal;

  const SaleItem({
    this.id,
    this.saleId,
    required this.productId,
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sale_id': saleId,
      'product_id': productId,
      'product_name': productName,
      'unit': unit,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'] as int?,
      saleId: map['sale_id'] as int?,
      productId: map['product_id'] as int,
      productName: map['product_name'] as String,
      unit: map['unit'] as String? ?? 'pc',
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unit_price'] as num).toDouble(),
      subtotal: (map['subtotal'] as num).toDouble(),
    );
  }
}

class Sale {
  final int? id;
  final String transactionId; // human-readable e.g. S-20261104-001
  final DateTime createdAt;
  final double subtotal;
  final double discount;
  final double total;
  final String paymentMethod;
  final double amountReceived;
  final double changeAmount;
  final String status; // completed, voided
  final String? notes;
  final List<SaleItem> items;

  const Sale({
    this.id,
    required this.transactionId,
    required this.createdAt,
    required this.subtotal,
    this.discount = 0.0,
    required this.total,
    required this.paymentMethod,
    required this.amountReceived,
    required this.changeAmount,
    this.status = 'completed',
    this.notes,
    this.items = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'created_at': createdAt.toIso8601String(),
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'payment_method': paymentMethod,
      'amount_received': amountReceived,
      'change_amount': changeAmount,
      'status': status,
      'notes': notes,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map, {List<SaleItem> items = const []}) {
    return Sale(
      id: map['id'] as int?,
      transactionId: map['transaction_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      subtotal: (map['subtotal'] as num).toDouble(),
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num).toDouble(),
      paymentMethod: map['payment_method'] as String,
      amountReceived: (map['amount_received'] as num).toDouble(),
      changeAmount: (map['change_amount'] as num).toDouble(),
      status: map['status'] as String? ?? 'completed',
      notes: map['notes'] as String?,
      items: items,
    );
  }
}
