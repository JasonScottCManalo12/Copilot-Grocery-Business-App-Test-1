import 'package:flutter/material.dart';
import '../../../data/models/product.dart';
import '../../../data/models/sale.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/sale_repository.dart';
import 'payment_screen.dart';
import 'sale_complete_screen.dart';

class CartItem {
  final Product product;
  double quantity;

  CartItem({required this.product, this.quantity = 1});

  double get subtotal => product.sellingPrice * quantity;
}

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final ProductRepository _productRepo = ProductRepository();
  final SaleRepository _saleRepo = SaleRepository();

  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  final List<CartItem> _cart = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _productRepo.getAll(activeOnly: true);
      setState(() {
        _products = products;
        _applySearch();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredProducts = _products;
    } else {
      final q = _searchQuery.toLowerCase();
      _filteredProducts = _products.where((p) {
        return p.name.toLowerCase().contains(q) ||
            (p.sku?.toLowerCase().contains(q) ?? false) ||
            (p.barcode?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
  }

  void _addToCart(Product product) {
    if (product.stockQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} is out of stock')),
      );
      return;
    }

    setState(() {
      final existing = _cart.indexWhere((c) => c.product.id == product.id);
      if (existing >= 0) {
        final newQty = _cart[existing].quantity + 1;
        if (newQty > product.stockQuantity) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Only ${product.stockQuantity} available for ${product.name}')),
          );
          return;
        }
        _cart[existing].quantity = newQty;
      } else {
        _cart.add(CartItem(product: product));
      }
    });
  }

  void _updateQuantity(CartItem item, double delta) {
    setState(() {
      final newQty = item.quantity + delta;
      if (newQty <= 0) {
        _cart.remove(item);
      } else if (newQty > item.product.stockQuantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Only ${item.product.stockQuantity} available')),
        );
      } else {
        item.quantity = newQty;
      }
    });
  }

  void _removeFromCart(CartItem item) {
    setState(() => _cart.remove(item));
  }

  double get _cartTotal =>
      _cart.fold<double>(0, (sum, item) => sum + item.subtotal);

  int get _cartCount =>
      _cart.fold<int>(0, (sum, item) => sum + item.quantity.round());

  Future<void> _checkout() async {
    if (_cart.isEmpty) return;

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          total: _cartTotal,
          itemCount: _cartCount,
        ),
      ),
    );

    if (result == null) return;

    try {
      final items = _cart
          .map((c) => SaleItem(
                productId: c.product.id!,
                productName: c.product.name,
                unit: c.product.unit,
                quantity: c.quantity,
                unitPrice: c.product.sellingPrice,
                subtotal: c.subtotal,
              ))
          .toList();

      final sale = await _saleRepo.completeSale(
        items: items,
        paymentMethod: result['paymentMethod'] as String,
        amountReceived: result['amountReceived'] as double,
        discount: result['discount'] as double? ?? 0.0,
      );

      if (mounted) {
        setState(() => _cart.clear());
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SaleCompleteScreen(sale: sale),
          ),
        );
        // Reload products after returning (stock changed)
        _loadProducts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sale failed: $e')),
        );
      }
    }
  }

  void _showCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Cart ($_cartCount items)',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_cart.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                setState(() => _cart.clear());
                                Navigator.pop(context);
                              },
                              child: const Text('Clear'),
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _cart.isEmpty
                          ? const Center(child: Text('Cart is empty'))
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: _cart.length,
                              itemBuilder: (context, index) {
                                final item = _cart[index];
                                return ListTile(
                                  title: Text(item.product.name),
                                  subtitle: Text(
                                    '₱${item.product.sellingPrice.toStringAsFixed(2)} × ${item.quantity}',
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline),
                                        onPressed: () {
                                          _updateQuantity(item, -1);
                                          setModalState(() {});
                                          setState(() {});
                                        },
                                      ),
                                      Text(
                                        item.quantity
                                            .toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 1),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline),
                                        onPressed: () {
                                          _updateQuantity(item, 1);
                                          setModalState(() {});
                                          setState(() {});
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            color: Colors.red),
                                        onPressed: () {
                                          _removeFromCart(item);
                                          setModalState(() {});
                                          setState(() {});
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    if (_cart.isNotEmpty)
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  Text(
                                    '₱${_cartTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _checkout();
                                },
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                ),
                                child: const Text('Proceed to Payment'),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applySearch();
                });
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? const Center(child: Text('No products found'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.1,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          final outOfStock = product.stockQuantity <= 0;
                          return Card(
                            elevation: 1,
                            child: InkWell(
                              onTap: outOfStock
                                  ? null
                                  : () => _addToCart(product),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: outOfStock
                                            ? Colors.grey
                                            : null,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '₱${product.sellingPrice.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: outOfStock
                                            ? Colors.grey
                                            : Colors.green[700],
                                      ),
                                    ),
                                    Text(
                                      outOfStock
                                          ? 'Out of stock'
                                          : '${product.stockQuantity.toStringAsFixed(0)} ${product.unit}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: outOfStock
                                            ? Colors.red
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: _cart.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$_cartCount items',
                              style: TextStyle(color: Colors.grey[600])),
                          Text(
                            '₱${_cartTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _showCart,
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text('View Cart'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
