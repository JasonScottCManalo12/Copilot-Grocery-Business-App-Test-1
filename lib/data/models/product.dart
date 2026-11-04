class Product {
  final int? id;
  final String name;
  final String? sku;
  final String? barcode;
  final String category;
  final String unit;
  final double costPrice;
  final double sellingPrice;
  final double stockQuantity;
  final double lowStockThreshold;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    this.id,
    required this.name,
    this.sku,
    this.barcode,
    this.category = 'Uncategorized',
    this.unit = 'pc',
    this.costPrice = 0.0,
    required this.sellingPrice,
    this.stockQuantity = 0.0,
    this.lowStockThreshold = 5.0,
    this.isActive = true,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLowStock => stockQuantity <= lowStockThreshold && isActive;

  Product copyWith({
    int? id,
    String? name,
    String? sku,
    String? barcode,
    String? category,
    String? unit,
    double? costPrice,
    double? sellingPrice,
    double? stockQuantity,
    double? lowStockThreshold,
    bool? isActive,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'barcode': barcode,
      'category': category,
      'unit': unit,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      'stock_quantity': stockQuantity,
      'low_stock_threshold': lowStockThreshold,
      'is_active': isActive ? 1 : 0,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      sku: map['sku'] as String?,
      barcode: map['barcode'] as String?,
      category: map['category'] as String? ?? 'Uncategorized',
      unit: map['unit'] as String? ?? 'pc',
      costPrice: (map['cost_price'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (map['selling_price'] as num).toDouble(),
      stockQuantity: (map['stock_quantity'] as num?)?.toDouble() ?? 0.0,
      lowStockThreshold: (map['low_stock_threshold'] as num?)?.toDouble() ?? 5.0,
      isActive: (map['is_active'] as int?) == 1,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  @override
  String toString() => 'Product(id: $id, name: $name, stock: $stockQuantity $unit)';
}
