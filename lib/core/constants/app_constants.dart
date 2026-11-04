class AppConstants {
  static const String appName = 'Grocery Business App';
  static const String dbName = 'grocery_business.db';
  static const int dbVersion = 2; // bumped for stock_movements table

  // Product
  static const List<String> productUnits = [
    'pc',
    'kg',
    'g',
    'L',
    'ml',
    'pack',
    'box',
    'dozen',
  ];

  static const List<String> productCategories = [
    'Uncategorized',
    'Fresh Produce',
    'Meat & Poultry',
    'Seafood',
    'Dairy & Eggs',
    'Bakery',
    'Beverages',
    'Snacks',
    'Canned Goods',
    'Frozen',
    'Household',
    'Personal Care',
    'Others',
  ];

  // Stock movement types
  static const String movementStockIn = 'stock_in';
  static const String movementStockOut = 'stock_out';
  static const String movementAdjustment = 'adjustment';
  static const String movementSale = 'sale';
  static const String movementReturn = 'return';

  static const List<String> movementTypes = [
    movementStockIn,
    movementStockOut,
    movementAdjustment,
    movementSale,
    movementReturn,
  ];
}
