class AppConstants {
  static const String appName = 'Grocery Business App';
  static const String dbName = 'grocery_business.db';
  static const int dbVersion = 3; // bumped for sales tables

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

  // Payment methods
  static const String paymentCash = 'cash';
  static const String paymentGCash = 'gcash';
  static const String paymentMaya = 'maya';
  static const String paymentCard = 'card';
  static const String paymentOther = 'other';

  static const List<String> paymentMethods = [
    paymentCash,
    paymentGCash,
    paymentMaya,
    paymentCard,
    paymentOther,
  ];
}
